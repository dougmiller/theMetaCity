from sqlalchemy.orm import Mapped
from .extensions import UUIDModel
from .extensions.mixins import TimestampsMixin
from tmc.extensions.marshmallow import ma
from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

__all__ = ('EDO')


class EDO(UUIDModel, TimestampsMixin):
	__tablename__ = 'everyday_ordinary'
	__table_args__ = {"schema": "everyday_ordinary"}
	__bind_key__ = "edo_selector"
	
	contents: Mapped[str]
