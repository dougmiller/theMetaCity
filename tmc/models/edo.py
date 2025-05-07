from sqlalchemy.orm import Mapped
from .extensions import UUIDModel
from .extensions.mixins import TimestampsMixin
from tmc.extensions.marshmallow import ma
from marshmallow_sqlalchemy import SQLAlchemySchema, auto_field

__all__ = ('EDO', 'EDO_Admin')

class EDO_Mixin(UUIDModel, TimestampsMixin):
	__abstract__ = True
	
	content: Mapped[str]
	
	def __str__(self):
		return f"[{self.id} – {self.created_at} - {self.content[:50]}]"
	
	def __repr__(self):
		return f'[{self.id} – {self.content[:50]}]'


class EDO(EDO_Mixin):
	__tablename__ = 'everyday_ordinary'
	__table_args__ = {"schema": "everyday_ordinary"}
	__bind_key__ = "edo_selector"


class EDO_Admin(EDO_Mixin):
	__tablename__ = 'everyday_ordinary'
	__table_args__ = {"schema": "everyday_ordinary"}
	__bind_key__ = "edo_admin"
