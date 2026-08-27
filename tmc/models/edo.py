import arrow
from sqlalchemy.orm import Mapped

from tmc.models.extensions import UUIDModel
from tmc.models.extensions.mixins import TimestampsMixin

__all__ = ("EDO", "EDO_Admin")


class EDO(UUIDModel, TimestampsMixin):
    __tablename__ = "everyday_ordinary"
    __table_args__ = {"schema": "everyday_ordinary"}

    content: Mapped[str]

    def command_line_str(self) -> str:
        cd = arrow.get(self.created_at)
        return f"{cd.humanize()} - {self.content}"

    def command_line_listing_str(self) -> str:
        cd = arrow.get(self.created_at)
        return f"{self.id} - {cd.humanize()} - {self.content}"

    def __str__(self) -> str:
        return f"{self.id} – {self.created_at} - {self.content}"  # noqa: RUF001

    def __repr__(self) -> str:
        return f"{self.id} – {self.content}"  # noqa: RUF001


# Read vs write is chosen by session (default vs read_only engine), not by class.
# Alias kept so existing write-path call sites (EDO_Admin) keep working.
EDO_Admin = EDO
