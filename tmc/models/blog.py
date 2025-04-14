from typing import Optional
from enum import Enum as PyEnum
import arrow
from sqlalchemy import ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .extensions import IntegerModel, UUIDModel, BasicModel
from .extensions.mixins import TimestampsMixin, SoftDeleteMixin

__all__ = ('Article', 'Blog', 'Workshop', 'Tag')


class ArticleTags(BasicModel):
	__tablename__ = "article_tags_joiner"
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_selector"
	tag_id: Mapped[int] = mapped_column(ForeignKey("com.tags.id"), primary_key=True)
	article_id: Mapped[int] = mapped_column(ForeignKey("com.articles.id"), primary_key=True)
	
	def __repr__(self):
		return f"[ArticleTags: Article {self.article_id} - Tag {self.tag_id}]"


class ArticleType(PyEnum):
	blog = 'blog'
	workshop = 'workshop'


class Article(IntegerModel, TimestampsMixin, SoftDeleteMixin):
	__tablename__ = 'articles'
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_selector"
	
	title: Mapped[str] = mapped_column(unique=True)
	url: Mapped[str] = mapped_column(unique=True)	
	blurb: Mapped[Optional[str]]
	text: Mapped[str]
	parent_id: Mapped[int] = mapped_column(ForeignKey("com.articles.id"), nullable=True)
	parent: Mapped["Article"] = relationship(
		"Article",
		remote_side="Article.id",
		backref="children",
		order_by="Article.id",
		lazy="selectin"
	)
	tags: Mapped[list["Tag"]] = relationship(
		"Tag",
		secondary=ArticleTags.__table__,
		back_populates="articles",
		lazy="subquery"
	)
	article_type: Mapped[ArticleType] = mapped_column(
		SQLEnum(
			ArticleType,
			name="article_type_enum",
			schema="com"
		), 
		nullable=False, 
		default=ArticleType.blog, 
		server_default=ArticleType.blog.value
	)
	
	__mapper_args__ = {
		'polymorphic_on': article_type,
	}
	
	def __repr__(self):
		return f"[Article {self.id}: {self.title} ({self.article_type.name})]"


class Blog(Article):
	__mapper_args__ = {
		'polymorphic_identity': ArticleType.blog
	}


class Workshop(Article):
	__mapper_args__ = {
		'polymorphic_identity': ArticleType.workshop
	}


class Tag(BasicModel):
	__tablename__ = 'tags'
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_selector"
	
	id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
	tag: Mapped[str] = mapped_column(unique=True)
	blurb: Mapped[str] = mapped_column()
	articles: Mapped[list["Article"]] = relationship(
		"Article",
		secondary=ArticleTags.__table__,
		back_populates="tags",
		lazy="subquery"
	)
	def __repr__(self):
		return f"[Tag {self.id}: {repr(self.tag)}]"
