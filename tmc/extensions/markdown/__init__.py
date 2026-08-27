import markdown

from .GIFV import GifV
from .schemas import TMCBlogMetadataSchema

md: markdown.Markdown = markdown.Markdown(extensions=["meta", GifV()])

__all__ = ["TMCBlogMetadataSchema", "md"]
