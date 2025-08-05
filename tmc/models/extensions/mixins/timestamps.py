import arrow
from sqlalchemy import Computed
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy_utils import ArrowType


class TimestampsMixin:
    __abstract__ = True

    @declared_attr
    def created_at(cls) -> Mapped[ArrowType]:
        """Timestamp extracted from the 'id' UUID v7.

        - **Generated Column** (computed automatically by the database).
        - Derived using `functions.extract_timestamp_from_uuid_v7(id)`.
        - **Read-Only**: Cannot be manually inserted or updated.
        """
        return mapped_column(
            ArrowType,
            Computed("functions.extract_timestamp_from_uuid_v7(id)", persisted=True),
            nullable=False,
            index=True,
        )

    @declared_attr
    def updated_at(cls) -> Mapped[ArrowType]:
        """Timestamp extracted from the 'id' UUID v7.

        - **Generated Column** (computed automatically by the database).
        - Default value is `functions.extract_timestamp_from_uuid_v7(id)`.
        - Trigger updates the value to now() on update to the row
        """
        return mapped_column(
            ArrowType,
            Computed("functions.extract_timestamp_from_uuid_v7(id)", persisted=True),
            nullable=False,
        )

    @property
    def dateline(self):
        """Helper function that can humanises the created/updated at line"""
        created = arrow.get(self.created_at).humanize()
        updated = f"; Updated {arrow.get(self.updated_at).humanize()}" if self.created_at < self.updated_at else ""
        return f"Published: {created}{updated}"

    @property
    def sitemap_lastmod(self):
        """ sitemap.xml <lastmod> format """
        return arrow.get(self.updated_at).format('YYYY-MM-DDTHH:mm:ssZZ') if self.created_at < self.updated_at else self.created_at.format('YYYY-MM-DDTHH:mm:ssZZ')


class SoftDeleteMixin:
    __abstract__ = True

    def deleted_at(cls) -> Mapped[ArrowType]:
        return mapped_column(ArrowType)
