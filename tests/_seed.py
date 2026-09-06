"""Test data helpers: a UUIDv7 generator and minimal row factories.

UUID-PK models (EDO, Image) use ``server_default=FetchedValue()`` — the real DB
supplies the id via a column default that a bare ``create_all()`` test DB does
not have, so tests set ``id`` explicitly to a valid v7 UUID. ``created_at`` /
``updated_at`` are DB-computed from that id, so the value must be a real v7.
"""

import os
import time
import uuid

import arrow

from tmc.models.edo import EDO, EdoMedia
from tmc.models.media import Audio, Gallery, Image, Licence, Postcard
from tmc.models.media.audio.file import File


def uuid7() -> uuid.UUID:
    """Minimal RFC 9562 UUIDv7 (48-bit ms timestamp + version/variant + random)."""
    unix_ms = int(time.time() * 1000)
    rand = os.urandom(10)
    b = bytearray(16)
    b[0] = (unix_ms >> 40) & 0xFF
    b[1] = (unix_ms >> 32) & 0xFF
    b[2] = (unix_ms >> 24) & 0xFF
    b[3] = (unix_ms >> 16) & 0xFF
    b[4] = (unix_ms >> 8) & 0xFF
    b[5] = unix_ms & 0xFF
    b[6] = 0x70 | (rand[0] & 0x0F)  # version 7
    b[7] = rand[1]
    b[8] = 0x80 | (rand[2] & 0x3F)  # variant
    b[9:16] = rand[3:10]
    return uuid.UUID(bytes=bytes(b))


_seq = 0


def _uniq(prefix: str) -> str:
    global _seq
    _seq += 1
    return f"{prefix}-{_seq}"


def make_licence(session) -> Licence:
    from tmc.models.media.licence import Licence

    lic = Licence(
        name=_uniq("licence-name"),
        text=_uniq("licence-text"),
        url=_uniq("licence-url"),
        image=_uniq("licence-image"),
    )
    session.add(lic)
    session.flush()
    return lic


def make_postcard(session) -> Postcard:
    from tmc.models.media.postcard import Postcard

    pc = Postcard(
        url=_uniq("postcard-url"),
        title=_uniq("postcard-title"),
        alt_text=_uniq("postcard-alt"),
    )
    session.add(pc)
    session.flush()
    return pc


def make_edo(session, content="hello world") -> EDO:
    from tmc.models.edo import EDO

    edo = EDO(id=uuid7(), content=content)
    session.add(edo)
    session.flush()
    return edo


def make_audio(session, title="An Audio") -> Audio:
    from tmc.models.media.audio.audio import Audio

    lic = make_licence(session)
    pc = make_postcard(session)
    audio = Audio(
        title=title,
        about="about this audio",
        date_published=arrow.now(),
        licence_id=lic.id,
        postcard_id=pc.id,
    )
    session.add(audio)
    session.flush()
    return audio


def make_image(session, gallery_id=None) -> Image:
    from tmc.models.media import Image

    img = Image(id=uuid7(), path=_uniq("path"), gallery_id=gallery_id)
    session.add(img)
    session.flush()
    return img


def make_gallery(session, title="A Gallery") -> Gallery:
    from tmc.models.media import Gallery

    lic = make_licence(session)
    pc = make_postcard(session)
    gallery = Gallery(
        title=title,
        about="about this gallery",
        date_published=arrow.now(),
        licence_id=lic.id,
        postcard_id=pc.id,
        blurb="a blurb",
    )
    session.add(gallery)
    session.flush()
    return gallery


def make_audio_file(session, audio) -> File:
    from tmc.models.media.audio.file import AudioCodecType, Extension, File, MimeType

    f = File(
        parent_video=audio.id,
        bit_rate=320,
        bit_depth="16",
        sample_rate="44100",
        vbr_encoded=False,
        audio_codec=AudioCodecType.mp3,
        mime_type=MimeType.mp3,
        extension=Extension.mp3,
    )
    session.add(f)
    session.flush()
    return f


def make_edo_media(session, edo, s3_key=None, content_type=None, kind="file", position=0) -> EdoMedia:
    from tmc.models.edo import EdoMedia

    media = EdoMedia(
        id=uuid7(),
        edo_id=edo.id,
        s3_key=s3_key or _uniq("s3key"),
        content_type=content_type,
        kind=kind,
        position=position,
    )
    session.add(media)
    session.flush()
    return media
