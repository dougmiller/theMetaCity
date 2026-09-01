from dataclasses import dataclass
from typing import Any

from flask import Flask


@dataclass
class MarkdownExtension:
    md: Any = None
    blog_metadata_schema: Any = None


def init_app(app: Flask) -> None:
    import markdown

    from .GIFV import GifV
    from .schemas import TMCBlogMetadataSchema

    md: markdown.Markdown = markdown.Markdown(extensions=["meta", GifV()])
    app.extensions["markdown"] = MarkdownExtension(md=md, blog_metadata_schema=TMCBlogMetadataSchema())
