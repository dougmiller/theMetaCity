"""Audio model and bind-specific subclass factory for media items."""

from typing import Type

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from tmc.models.extensions.mixins import SmartQueryMixin
from tmc.models.media.asset import Asset, AssetType
from tmc.models.media.audio.file import File
from tmc.models.media.audio.track import Track

__all__ = ["Audio", "AudioAdmin"]


class Audio(Asset, SmartQueryMixin):
    """Represents an audio media item in the polymorphic Asset hierarchy."""

    __tablename__ = "audio"
    __table_args__ = {"schema": "media"}
    __bind_key__ = "media_selector"

    id: Mapped[int] = mapped_column(ForeignKey("media.media_item.id"), primary_key=True)
    files: Mapped[list[File]] = relationship(backref="asset")
    tracks: Mapped[list[Track]] = relationship(backref="asset")

    __mapper_args__ = {
        "polymorphic_identity": AssetType.audio,
        "with_polymorphic": "*",
    }


def bind_specific_audio_class(bind_key: str) -> Type[Audio]:
    """
    Generate a bind-specific, abstract subclass of Audio.

    This is useful for environments like Flask-Admin or separate session routing,
    where different bind_keys (e.g., 'media_admin', 'media_selector') are used.

    The returned class is abstract and not polymorphically loadable from the base Asset queries.
    """
    class BoundAudio(Audio):
        __abstract__ = True
        __bind_key__ = bind_key
        __mapper_args__ = {
            "with_polymorphic": "*",
        }

    BoundAudio.__name__ = f"Audio{bind_key.title().replace('_', '')}"
    return BoundAudio


AudioAdmin: Type[Audio] = bind_specific_audio_class("media_admin")