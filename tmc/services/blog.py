"""Blog document service — Markdown-frontmatter ingest and article management.

The CLI (`flask blog ...`) is a thin wrapper over these functions. Everything
that touches the filesystem or the database lives here.
"""

from __future__ import annotations

import os
import re
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, cast

from flask import current_app
from marshmallow import ValidationError
from psycopg.errors import UniqueViolation
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from tmc import queries
from tmc.extensions import md
from tmc.extensions.markdown import TMCBlogMetadataSchema
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
    """Ingest a Markdown document (with frontmatter) into an Article.

    Inserts a new record, or updates the one named by the ``id`` frontmatter
    field. On insert, writes the new id back into the file's frontmatter so
    re-runs update in place. Raises BlogProcessingError for user-facing failures.
    """
    if not filename.lower().endswith(".md"):
        raise BlogProcessingError("Only Markdown (.md) files are supported.")

    full_path = find_document(filename)
    if not full_path:
        docs = current_app.config.get("DOCUMENTS_FOLDER_PATH", ".")
        raise BlogProcessingError(f"File '{filename}' not found in the documents directory ({docs}).")

    with open(full_path, encoding="utf-8") as f:
        content = f.read()

    md.reset()
    md.convert(content)
    body = strip_metadata(content)

    meta_source: dict[str, list[str]] = getattr(md, "Meta", {})
    meta_raw = {key: value[0] for key, value in meta_source.items() if value}
    try:
        meta: dict[str, Any] = cast("dict[str, Any]", TMCBlogMetadataSchema().load(meta_raw))
    except ValidationError as err:
        messages = [m for msgs in err.messages_dict.values() for m in msgs]
        raise BlogProcessingError("Metadata validation failed: " + "; ".join(messages)) from err

    variant_changed = False
    if meta.get("id"):
        article = get_article(session, meta["id"])
        if article is None:
            raise BlogProcessingError(f"Supplied ID ({meta['id']}) does not match a record.")
        if article.variant != meta.get("variant"):
            variant_changed = True
            queries.delete(session, article)
            article = Article(id=meta.get("id"))
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
            field = match.group(1) if match else None
            if field:
                raise BlogProcessingError(f"The {field} '{meta.get(field, '')}' already exists (must be unique).") from err
            raise BlogProcessingError("Duplicate value violates a unique constraint.") from err
        raise

    if action == "inserted":
        _write_id_to_file(full_path, str(article.id))

    return ProcessResult(action=action, article_id=str(article.id), title=meta["title"], variant_changed=variant_changed)


def _write_id_to_file(full_path: str, new_id: str) -> None:
    with open(full_path, encoding="utf-8") as f:
        original = f.read()
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(f"id: {new_id}\n" + original)
