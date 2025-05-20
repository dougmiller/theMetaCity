import markdown

from .GIFV import GifV
from .schemas import TMCBlogMetadataSchema


md = markdown.Markdown(extensions=['meta', GifV()])