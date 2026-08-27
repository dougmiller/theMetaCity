import uuid
from enum import Enum as PyEnum

from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, declared_attr, has_inherited_table, mapped_column, relationship

from tmc.models.extensions import BasicModel, UUIDModel
from tmc.models.extensions.mixins import TimestampsMixin

__all__ = (
    "Article",
    "ArticleAdmin",
    "ArticleTags",
    "ArticleTagsAdmin",
    "ArticleTagsSelector",
    "Blog",
    "BlogAdmin",
    "Tag",
    "TagAdmin",
    "Workshop",
    "WorkshopAdmin",
)


class ArticleTags(BasicModel):
    """Many-to-many Article <-> Tag join table."""

    __tablename__ = "article_tags_joiner"
    __table_args__ = {"schema": "com"}

    tag_id: Mapped[int] = mapped_column(ForeignKey("com.tags.id"), primary_key=True)
    article_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("com.articles.id"), primary_key=True)

    def __repr__(self) -> str:
        return f"[ArticleTags: Article {self.article_id} - Tag {self.tag_id}]"


# Back-compat aliases (read/write is now a session concern, not a class concern).
ArticleTagsSelector = ArticleTags
ArticleTagsAdmin = ArticleTags


class Variant(PyEnum):
    """Article type discriminator (maps to a PG enum)."""

    blog = "blog"
    workshop = "workshop"


class Article(UUIDModel, TimestampsMixin):
    # Single-table inheritance: Blog/Workshop must NOT get their own table, so
    # resolve tablename/table_args to None on inherited (subclass) mappings.
    @declared_attr.directive
    def __tablename__(cls) -> str | None:
        return None if has_inherited_table(cls) else "articles"  # type: ignore[arg-type]

    @declared_attr.directive
    def __table_args__(cls) -> dict | None:
        return None if has_inherited_table(cls) else {"schema": "com"}  # type: ignore[arg-type]

    title: Mapped[str] = mapped_column(unique=True)
    url: Mapped[str] = mapped_column(unique=True)
    blurb: Mapped[str | None]
    content: Mapped[str]
    parent_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("com.articles.id"), nullable=True)

    variant: Mapped[Variant] = mapped_column(
        SQLEnum(Variant, name="variant_enum", schema="com"),
        nullable=False,
        default=Variant.blog,
        server_default=Variant.blog.value,
    )

    parent: Mapped[Article] = relationship("Article", remote_side="Article.id", backref="children", order_by="Article.id", lazy="selectin")
    tags: Mapped[list[Tag]] = relationship("Tag", secondary=ArticleTags.__table__, back_populates="articles", lazy="subquery")

    __mapper_args__ = {"polymorphic_on": variant}

    def __repr__(self) -> str:
        return f"[Article {self.id}: {self.title} ({self.variant.name})]"


class Blog(Article):
    __mapper_args__ = {"polymorphic_identity": Variant.blog}


class Workshop(Article):
    __mapper_args__ = {"polymorphic_identity": Variant.workshop}


class Tag(BasicModel):
    __tablename__ = "tags"
    __table_args__ = {"schema": "com"}

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    tag: Mapped[str] = mapped_column(unique=True)
    blurb: Mapped[str | None] = mapped_column(default=None)

    articles: Mapped[list[Article]] = relationship("Article", secondary=ArticleTags.__table__, back_populates="tags", lazy="subquery")

    def __repr__(self) -> str:
        return f"[Tag {self.id}: {self.tag!r}]"


# Back-compat aliases for former *_admin classes.
ArticleAdmin = Article
BlogAdmin = Blog
WorkshopAdmin = Workshop
TagAdmin = Tag
