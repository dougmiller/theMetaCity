import markdown

from .GIFV import GifV


md = markdown.Markdown(extensions=[GifV()])