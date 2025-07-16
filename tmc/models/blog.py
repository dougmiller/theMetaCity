import uuid
from enum import Enum as PyEnum

from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions import BasicModel, UUIDModel
from tmc.models.extensions.mixins import SmartQueryMixin, TimestampsMixin

__all__ = (
    "Article",
    "ArticleAdmin",
    "Blog",
    "BlogAdmin",
    "Workshop",
    "WorkshopAdmin",
    "Tag",
    "TagAdmin",
)


class ArticleTagsBase(BasicModel):
    """
    Many to many Article <-> Tag intermediary mapping
    Probably dont invoke this directly
    """

    __abstract__ = True

    tag_id: Mapped[int] = mapped_column(ForeignKey("com.tags.id"), primary_key=True)
    article_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("com.articles.id"), primary_key=True)

    def __repr__(self):
        return f"[ArticleTags: Article {self.article_id} - Tag {self.tag_id}]"


class ArticleTagsSelector(ArticleTagsBase):
    __tablename__ = "article_tags_joiner"
    __table_args__ = {"schema": "com"}
    __bind_key__ = "com_selector"


class ArticleTagsAdmin(ArticleTagsBase):
    __tablename__ = "article_tags_joiner"
    __table_args__ = {"schema": "com"}
    __bind_key__ = "com_admin"


"""
Articles (Blog, Workshop)
"""


class Variant(PyEnum):
    """
    Articles Type enum.
    Used to differentiate the article type.
    Maps to DB enum types in PG.
    """

    blog = "blog"
    workshop = "workshop"


class _ArticleBase(UUIDModel, TimestampsMixin, SmartQueryMixin):
    __abstract__ = True

    title: Mapped[str] = mapped_column(unique=True)
    url: Mapped[str] = mapped_column(unique=True)
    blurb: Mapped[str | None]
    content: Mapped[str]
    parent_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("com.articles.id"), nullable=True)

    variant: Mapped[Variant] = mapped_column(
        SQLEnum(Variant, name="variant_enum", schema="com"), nullable=False, default=Variant.blog, server_default=Variant.blog.value
    )

    __mapper_args__ = {
        "polymorphic_on": variant,
    }

    def __repr__(self):
        return f"[Article {self.id}: {self.title} ({self.variant.name})]"


class Article(_ArticleBase):
    __tablename__ = "articles"
    __table_args__ = {"schema": "com"}
    __bind_key__ = "com_selector"

    parent: Mapped["Article"] = relationship("Article", remote_side="Article.id", backref="children", order_by="Article.id", lazy="selectin")

    tags: Mapped[list["Tag"]] = relationship("Tag", secondary=ArticleTagsSelector.__table__, back_populates="articles", lazy="subquery")


class ArticleAdmin(_ArticleBase):
    __tablename__ = "articles"
    __table_args__ = {"schema": "com"}
    __bind_key__ = "com_admin"

    parent: Mapped["ArticleAdmin"] = relationship(
        "ArticleAdmin", remote_side="ArticleAdmin.id", backref="children", order_by="ArticleAdmin.id", lazy="selectin"
    )

    tags: Mapped[list["TagAdmin"]] = relationship("TagAdmin", secondary=ArticleTagsAdmin.__table__, back_populates="articles", lazy="subquery")


class Blog(Article):
    __mapper_args__ = {"polymorphic_identity": Variant.blog}


class BlogAdmin(ArticleAdmin):
    __mapper_args__ = {"polymorphic_identity": Variant.blog}


class Workshop(Article):
    __mapper_args__ = {"polymorphic_identity": Variant.workshop}


class WorkshopAdmin(ArticleAdmin):
    __mapper_args__ = {"polymorphic_identity": Variant.workshop}


"""
Tags
"""


class TagBase(BasicModel, SmartQueryMixin):
    __abstract__ = True

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    tag: Mapped[str] = mapped_column(unique=True)
    blurb: Mapped[str] = mapped_column()

    def __repr__(self):
        return f"[Tag {self.id}: {repr(self.tag)}]"


class Tag(TagBase):
    __tablename__ = "tags"
    __table_args__ = {"schema": "com"}
    __bind_key__ = "com_selector"

    articles: Mapped[list[Article]] = relationship("Article", secondary=ArticleTagsSelector.__table__, back_populates="tags", lazy="subquery")


class TagAdmin(TagBase):
    __tablename__ = "tags"
    __table_args__ = {"schema": "com"}
    __bind_key__ = "com_admin"

    articles: Mapped[list[ArticleAdmin]] = relationship("ArticleAdmin", secondary=ArticleTagsAdmin.__table__, back_populates="tags", lazy="subquery")
