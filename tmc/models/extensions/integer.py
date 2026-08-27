from sqlalchemy.orm import Mapped, mapped_column

from ._base import _BaseModel

__all__ = ["IntegerModel"]


class IntegerModel(_BaseModel):
    __abstract__ = True

    id: Mapped[int] = mapped_column(
        primary_key=True,
        autoincrement=True,
    )
