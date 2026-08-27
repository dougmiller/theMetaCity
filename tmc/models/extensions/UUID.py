import uuid

from sqlalchemy import text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from ._base import _BaseModel

__all__ = ["UUIDModel"]


class UUIDModel(_BaseModel):
    """A model based on UUIDv7 as the PK

    This inheritible model proivides an ID based on UUID v7
     - the function that generates the UUID is in the 'functions' schema
    """

    __abstract__ = True

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("uuidv7()"),
    )
