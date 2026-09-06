"""Small media helpers shared by the EDO upload/post endpoints."""

from __future__ import annotations

__all__ = ["kind_from_content_type"]

_KNOWN_KINDS = ("image", "video", "audio")


def kind_from_content_type(content_type: str | None) -> str:
    """Coarse media ``kind`` for rendering/filtering, from a MIME type.

    ``image/jpeg`` -> ``"image"``, ``video/mp4`` -> ``"video"``,
    ``audio/mpeg`` -> ``"audio"``; anything else (or missing) -> ``"file"``.
    """
    if not content_type:
        return "file"
    main = content_type.split("/", 1)[0].strip().lower()
    return main if main in _KNOWN_KINDS else "file"
