from arrow import utcnow
from sqlalchemy.ext.declarative import declared_attr, has_inherited_table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy_utils import ArrowType
from sqlalchemy import text as sa_text

from tmc import db
from .mixins import QueryMixin

__all__ = ('UUIDModel', 'IntegerModel')


class Model(db.Model, QueryMixin):
    """Abstract base class for all app models.

    Provides an `id`, 'updated_at', `created_at` and ` deleted_at` column to every model.

    To use these, extend this class when defining models:

        from .base import Model

        class MyModel(Model):
            # model definition
    """
    __abstract__ = True

    @declared_attr
    def created_at(cls):
        return db.Column(
            ArrowType,
            default=utcnow,
            server_default=sa_text("(now() at time zone 'utc')"),
            nullable=False,
            index=True
        )

    @declared_attr
    def updated_at(cls):
        return db.Column(
            ArrowType,
            default=utcnow,
            server_default=sa_text("(now() at time zone 'utc')"),
            nullable=False,
            index=True
        )

    @declared_attr
    def deleted_at(cls):
        return db.Column(
            ArrowType,
            index=True
        )

    @property
    def class_name(self):
        """Shortcut for returning class name."""
        return self.__class__.__name__

    @classmethod
    def __ignore__(cls):
        """Custom class attr that lets us control which models get ignored.

        We are using this because knowing whether or not we're actually dealing
        with an abstract base class is only possible late in the class's init
        lifecycle.

        This is used by the dynamic model loader to know if it should ignore.
        """
        return cls.__name__ in ('Model', 'UUIDModel', 'IntegerModel')  # can add more abstract base classes here

    def __repr__(self):
        return f"[{self.class_name}: {self.id}]"

    @declared_attr
    def __tablename__(cls):
        """Generate a __tablename__ attr for every model that does not have
        inherited tables.

        Ensures table names match the model name without needing to declare it.
        """
        if has_inherited_table(cls):
            return None
        return cls.__name__.lower()


class UUIDModel(Model):
    def __init__(self, **kwargs):
        super(UUIDModel, self).__init__(**kwargs)

    id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=sa_text("uuid_generate_v4()")
    )


class IntegerModel(Model):
    def __init__(self, **kwargs):
        super(IntegerModel, self).__init__(**kwargs)

    id = db.Column(
        db.Integer,
        primary_key=True
    )
