from arrow import now
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.ext.declarative import declared_attr, has_inherited_table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy_utils import ArrowType
from sqlalchemy import text as sa_text

from tmc.extensions import db
from .mixins import QueryMixin

__all__ = ('_BaseModel')


class _BaseModel(db.Model, QueryMixin):
    """ Abstract base class for all CRUD models.
    Provides an 'created_at', `updated_at` and `deleted_at` column to every model.
    """
    __abstract__ = True

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
        return cls.__name__ in ('BasicModel', 'UUIDModel', 'IntegerModel')  # can add more abstract base classes here

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
