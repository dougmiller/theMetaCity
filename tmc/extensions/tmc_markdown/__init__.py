from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

from flask import Flask

if TYPE_CHECKING:
    import markdown


def _new_markdown() -> markdown.Markdown:
    """Build a fresh, fully-configured Markdown instance.

    python-markdown instances are stateful and not thread-safe, and they carry
    document state (link references, ``Meta``) across ``convert()`` calls unless
    ``reset()`` is called. Rather than share one, every render gets its own:
    correct under any worker model, and cheap at this app's volume.
    """
    import markdown

    from .GIFV import GifV

    return markdown.Markdown(extensions=["meta", GifV()])


@dataclass
class MarkdownExtension:
    blog_metadata_schema: Any = None

    @staticmethod
    def make() -> markdown.Markdown:
        """A fresh instance — use when you need ``.Meta`` after converting."""
        return _new_markdown()

    @staticmethod
    def convert(text: str) -> str:
        """Render Markdown to HTML on a throwaway instance."""
        return _new_markdown().convert(text)


def init_app(app: Flask) -> None:
    from .schemas import TMCBlogMetadataSchema

    app.extensions["markdown"] = MarkdownExtension(blog_metadata_schema=TMCBlogMetadataSchema())
