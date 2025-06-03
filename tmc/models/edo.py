import arrow
from sqlalchemy.orm import Mapped

from tmc.models.extensions.mixins import TimestampsMixin, QueryMixin
from tmc.models.extensions import UUIDModel

__all__ = ('EDO', 'EDO_Admin')


class EDO_Base(UUIDModel, TimestampsMixin, QueryMixin):
	__abstract__ = True
	
	content: Mapped[str]
	
	def command_line_str(self):
		cd = arrow.get(self.created_at)
		return f"{cd.humanize()} - {self.content}"

	def command_line_listing_str(self):
		cd = arrow.get(self.created_at)
		return f"{self.id} - {cd.humanize()} - {self.content}"		
    
	def __str__(self):
		return f"{self.id} – {self.created_at} - {self.content}"
	
	def __repr__(self):
		return f'{self.id} – {self.content}'


class EDO(EDO_Base):
	__tablename__ = 'everyday_ordinary'
	__table_args__ = {"schema": "everyday_ordinary"}
	__bind_key__ = "edo_selector"


class EDO_Admin(EDO_Base):
	__tablename__ = 'everyday_ordinary'
	__table_args__ = {"schema": "everyday_ordinary"}
	__bind_key__ = "edo_admin"

