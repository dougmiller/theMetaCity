"""Blog / article / tag queries."""

from __future__ import annotations

from collections.abc import Sequence

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from tmc.models.blog import Article, Blog, Tag


def latest_articles(session: Session, limit: int = 10) -> Sequence[Article]:
    return session.scalars(select(Article).order_by(Article.id.desc()).limit(limit)).all()


def latest_blogs(session: Session, limit: int = 10) -> Sequence[Blog]:
    return session.scalars(select(Blog).order_by(Blog.id.desc()).limit(limit)).all()


def all_blogs(session: Session) -> Sequence[Blog]:
    return session.scalars(select(Blog).order_by(Blog.created_at.desc())).all()


def blog_by_url(session: Session, url: str) -> Blog | None:
    return session.scalars(select(Blog).filter_by(url=url).limit(1)).first()


def blogs_by_year(session: Session, year: int) -> Sequence[Blog]:
    return session.scalars(select(Blog).where(func.extract("year", Blog.created_at) == year).order_by(Blog.created_at.desc())).all()


def blog_by_year_and_url(session: Session, year: int, url: str) -> Blog | None:
    return session.scalars(select(Blog).where(Blog.url == url).where(func.extract("year", Blog.created_at) == year).limit(1)).first()


def all_tags(session: Session) -> Sequence[Tag]:
    return session.scalars(select(Tag).order_by(Tag.tag.asc())).all()


def tag_by_name(session: Session, name: str) -> Tag | None:
    return session.scalars(select(Tag).filter_by(tag=name).limit(1)).first()
