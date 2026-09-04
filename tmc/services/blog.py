"""Blog document service — Markdown-frontmatter ingest and article management.

The CLI (`flask blog ...`) is a thin wrapper over these functions. Everything
that touches the filesystem or the database lives here.
"""

from __future__ import annotations

import os
import re
from collections.abc import Sequence
from dataclasses import dataclass, field
from typing import Any, cast

from flask import current_app
from marshmallow import ValidationError
from psycopg.errors import UniqueViolation
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from tmc import queries
from tmc.models.blog import Article, Tag
from tmc.queries import blog as blog_queries


class BlogProcessingError(Exception):
    """Raised for expected, user-facing failures while processing a document."""


@dataclass
class ProcessResult:
    action: str  # "inserted" | "updated"
    article_id: str
    title: str
    variant_changed: bool = False


@dataclass
class BatchResult:
    inserted: int = 0
    updated: int = 0
    failures: list[tuple[str, str]] = field(default_factory=list)  # (filename, error message)


def find_document(filename: str, base_dir: str | None = None) -> str | None:
    """Return the full path of ``filename`` under the documents dir, or None."""
    search_dir: str = base_dir if base_dir is not None else str(current_app.config.get("DOCUMENTS_FOLDER_PATH", "."))
    for root, _, files in os.walk(search_dir):
        if filename in files:
            return os.path.join(root, filename)
    return None


def strip_metadata(markdown_text: str) -> str:
    """Drop leading ``key: value`` frontmatter lines, keep the body."""
    lines = markdown_text.splitlines()
    body_lines: list[str] = []
    meta_done = False
    for line in lines:
        if not meta_done and (line.strip() == "" or ":" in line):
            continue
        meta_done = True
        body_lines.append(line)
    return "\n".join(body_lines)


def get_or_create_tags(session: Session, tag_names: Sequence[str]) -> list[Tag]:
    tags: list[Tag] = []
    for name in tag_names:
        tag = blog_queries.tag_by_name(session, name)
        if tag is None:
            tag = Tag(tag=name)
            queries.save(session, tag)
        tags.append(tag)
    return tags


def list_recent_articles(session: Session, count: int = 10) -> Sequence[Article]:
    return session.scalars(select(Article).order_by(Article.created_at.desc()).limit(count)).all()


def get_article(session: Session, record_id: Any) -> Article | None:
    return queries.get_by_pk(session, Article, record_id)


def delete_article(session: Session, article: Article) -> None:
    queries.delete(session, article)


def process_markdown_file(session: Session, filename: str) -> ProcessResult:
    """Ingest a single Markdown document (resolved by name under the docs dir).

    Strict by design: a frontmatter ``id`` that matches no row raises, so a
    typo in a hand-run ``blog process`` is caught rather than silently
    inserting a stray record. Use ``process_published_directory`` for bulk
    re-import, which inserts under the existing id instead.
    """
    if not filename.lower().endswith(".md"):
        raise BlogProcessingError("Only Markdown (.md) files are supported.")

    full_path = find_document(filename)
    if not full_path:
        docs = current_app.config.get("DOCUMENTS_FOLDER_PATH", ".")
        raise BlogProcessingError(f"File '{filename}' not found in the documents directory ({docs}).")

    return _process_document(session, full_path)


def process_published_directory(session: Session, subdir: str = "published") -> BatchResult:
    """Ingest every Markdown file directly under ``<DOCUMENTS_FOLDER_PATH>/<subdir>``.

    Each already-published file carries its UUIDv7 ``id`` in frontmatter, so the
    record is inserted under that id and the generated ``created_at`` /
    ``updated_at`` columns take their value from the id's embedded timestamp —
    no timestamp is (or can be) written directly. Re-runnable: a file whose id
    already exists is updated in place. One failing file is recorded and
    skipped rather than aborting the whole batch. Files are processed in name
    order, which (UUIDv7 being time-ordered) ingests parents before children.
    """
    docs = str(current_app.config.get("DOCUMENTS_FOLDER_PATH", "."))
    target = os.path.join(docs, subdir)
    if not os.path.isdir(target):
        raise BlogProcessingError(f"Directory not found: {target}")

    summary = BatchResult()
    for name in sorted(os.listdir(target)):
        if not name.lower().endswith(".md"):
            continue
        full_path = os.path.join(target, name)
        if not os.path.isfile(full_path):
            continue
        try:
            result = _process_document(session, full_path, allow_insert_with_id=True)
        except (BlogProcessingError, SQLAlchemyError) as err:
            session.rollback()
            summary.failures.append((name, str(err)))
            continue
        if result.action == "inserted":
            summary.inserted += 1
        else:
            summary.updated += 1
    return summary


def _process_document(session: Session, full_path: str, *, allow_insert_with_id: bool = False) -> ProcessResult:
    """Core ingest: read the document at ``full_path`` and upsert its Article.

    Inserts a new record, or updates the one named by the ``id`` frontmatter
    field. When ``allow_insert_with_id`` is true, a frontmatter ``id`` with no
    matching row is inserted under that id (so already-published files can be
    re-imported into a fresh database) rather than raising. On a genuine insert
    of a file that had no id, the new id is written back to the file's
    frontmatter so re-runs update in place. Raises BlogProcessingError for
    user-facing failures.
    """
    with open(full_path, encoding="utf-8") as f:
        content = f.read()

    md = current_app.extensions["markdown"].make()
    md.convert(content)  # populates md.Meta from the document frontmatter
    body = strip_metadata(content)

    meta_source: dict[str, list[str]] = getattr(md, "Meta", {})
    meta_raw = {key: value[0] for key, value in meta_source.items() if value}
    try:
        meta: dict[str, Any] = cast("dict[str, Any]", current_app.extensions["markdown"].blog_metadata_schema.load(meta_raw))
    except ValidationError as err:
        messages = [m for msgs in err.messages_dict.values() for m in msgs]
        raise BlogProcessingError("Metadata validation failed: " + "; ".join(messages)) from err

    had_id = meta.get("id") is not None
    variant_changed = False
    if had_id:
        article = get_article(session, meta["id"])
        if article is None:
            if not allow_insert_with_id:
                raise BlogProcessingError(f"Supplied ID ({meta['id']}) does not match a record.")
            article = Article(id=meta["id"])
            action = "inserted"
        else:
            if article.variant != meta.get("variant"):
                variant_changed = True
                queries.delete(session, article)
                article = Article(id=meta["id"])
            action = "updated"
    else:
        article = Article()
        action = "inserted"

    article.title = meta["title"]
    article.url = meta["url"]
    article.blurb = meta["blurb"]
    article.variant = meta["variant"]
    article.parent_id = meta.get("parent")
    article.content = body

    try:
        queries.save(session, article)
        article.tags = get_or_create_tags(session, meta.get("tags", []))
        queries.save(session, article)
    except IntegrityError as err:
        session.rollback()
        if isinstance(err.orig, UniqueViolation):
            match = re.search(r"Key \((.*?)\)=", str(err.orig))
            field_name = match.group(1) if match else None
            if field_name:
                raise BlogProcessingError(f"The {field_name} '{meta.get(field_name, '')}' already exists (must be unique).") from err
            raise BlogProcessingError("Duplicate value violates a unique constraint.") from err
        raise

    if action == "inserted" and not had_id:
        _write_id_to_file(full_path, str(article.id))

    return ProcessResult(action=action, article_id=str(article.id), title=meta["title"], variant_changed=variant_changed)


def _write_id_to_file(full_path: str, new_id: str) -> None:
    with open(full_path, encoding="utf-8") as f:
        original = f.read()
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(f"id: {new_id}\n" + original)
