import uuid
from typing import Optional
from enum import Enum as PyEnum
import arrow
from sqlalchemy import ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from tmc.models.extensions import IntegerModel, UUIDModel, BasicModel
from tmc.models.extensions.mixins.timestamps import TimestampsMixin

__all__ = ('Article', 'Blog', 'Workshop', 'TagSelector', 'TagAdmin')

class ArticleTagsBase(BasicModel):
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


class ArticleType(PyEnum):
	blog = 'blog'
	workshop = 'workshop'


class ArticleBase(UUIDModel, TimestampsMixin):
	__abstract__ = True

	title: Mapped[str] = mapped_column(unique=True)
	url: Mapped[str] = mapped_column(unique=True)	
	blurb: Mapped[Optional[str]]
	content: Mapped[str]
	parent_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("com.articles.id"), nullable=True)

	variant: Mapped[ArticleType] = mapped_column(
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
		'polymorphic_on': variant,
	}
	
	def __repr__(self):
		return f"[Article {self.id}: {self.title} ({self.variant.name})]"


class ArticleSelector(ArticleBase):
	__tablename__ = 'articles'
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_selector"
	
	parent: Mapped["Article"] = relationship(
		"ArticleSelector",
		remote_side="ArticleSelector.id",
		backref="children",
		order_by="ArticleSelector.id",
		lazy="selectin"
	)

	tags: Mapped[list["Tag"]] = relationship(
		"TagSelector",
		secondary=ArticleTagsSelector.__table__,
		back_populates="articles",
		lazy="subquery"
	)


class ArticleAdmin(ArticleBase):
	__tablename__ = 'articles'
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_admin"

	parent: Mapped["Article"] = relationship(
		"ArticleAdmin",
		remote_side="ArticleAdmin.id",
		backref="children",
		order_by="ArticleAdmin.id",
		lazy="selectin"
	)
	
	tags: Mapped[list["Tag"]] = relationship(
		"TagAdmin",
		secondary=ArticleTagsAdmin.__table__,
		back_populates="articles",
		lazy="subquery"
	)

class BlogSelector(ArticleSelector):
	__mapper_args__ = {
		'polymorphic_identity': ArticleType.blog
	}
	
class BlogAdmin(ArticleAdmin):
	__mapper_args__ = {
		'polymorphic_identity': ArticleType.blog
	}

class WorkshopSelector(ArticleSelector):
	__mapper_args__ = {
		'polymorphic_identity': ArticleType.workshop
	}

class WorkshopAdmin(ArticleAdmin):
	__mapper_args__ = {
		'polymorphic_identity': ArticleType.workshop
	}


class TagBase(BasicModel):
	__abstract__ = True

	id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
	tag: Mapped[str] = mapped_column(unique=True)
	blurb: Mapped[str] = mapped_column()

	def __repr__(self):
		return f"[Tag {self.id}: {repr(self.tag)}]"


class TagSelector(TagBase):
	__tablename__ = 'tags'
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_selector"
	
	articles: Mapped[list["Article"]] = relationship(
		"ArticleSelector",
		secondary=ArticleTagsSelector.__table__,
		back_populates="tags",
		lazy="subquery"
	)


class TagAdmin(TagBase):
	__tablename__ = 'tags'
	__table_args__ = {"schema": "com"}
	__bind_key__ = "com_admin"
	
	articles: Mapped[list["Article"]] = relationship(
		"ArticleAdmin",
		secondary=ArticleTagsAdmin.__table__,
		back_populates="tags",
		lazy="subquery"
	)
