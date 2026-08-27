from tmc.extensions.sqlalchemy import Base

__all__ = ["_BaseModel"]


class _BaseModel(Base):
    """Abstract base class for all CRUD models.
    Provides an 'created_at', `updated_at` and `deleted_at` column to every model.
    """

    __abstract__ = True

    @property
    def class_name(self) -> str:
        """Shortcut for returning class name."""
        return self.__class__.__name__

    @classmethod
    def __ignore__(cls) -> bool:
        """Custom class attr that lets us control which models get ignored.

        We are using this because knowing whether or not we're actually dealing
        with an abstract base class is only possible late in the class's init
        lifecycle.

        This is used by the dynamic model loader to know if it should ignore.
        """
        return cls.__name__ in ("BasicModel", "UUIDModel", "IntegerModel")  # can add more abstract base classes here

    def __repr__(self) -> str:
        return f"[{self.class_name}: {getattr(self, 'id', None)}]"
