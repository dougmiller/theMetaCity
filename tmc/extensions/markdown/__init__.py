import re
import misaka as m
from flask_misaka import Misaka
from .GIFV import GifVM


class CustomMisaka(m.Markdown):
	
	CUSTOM_GIFV = 1 << 20  # <gifv>{}</gifv> → <video>text</video>

	def __init__(self, renderer=None, extensions=0):
		"""Enable standard Misaka extensions plus custom ones."""
		extensions |= (m.EXT_FENCED_CODE | self.CUSTOM_GIFV)
		super().__init__(renderer or m.HtmlRenderer(), extensions=extensions)
	
	def preprocess(self, text):
		"""Apply multiple complex custom transformations before Markdown parsing."""

		if self.extensions & self.CUSTOM_GIFV:		
			text = re.sub(r"<gifv>(.*)</gifv>", GifVM.format, text, flags=re.MULTILINE)
	
		return text


md = Misaka(misaka=CustomMisaka())