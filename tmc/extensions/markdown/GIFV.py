from markdown.extensions import Extension
from markdown.preprocessors import Preprocessor
import xml.etree.ElementTree as etree  # Use standard library directly
import re


class GifVPreprocessor(Preprocessor):
	"""
	Processes custom <gifv filename ext1,ext2 /> tags into <video> HTML elements.
	"""

	GIFV_RE = re.compile(r'<gifv\s+([\w0-9_-]+)\s+([\w0-9_-]+(?:,[\w0-9_-]+)*)\s*/?>')

	def __init__(self, md, config):
		super().__init__(md)
		self.video_url_base = config.get('video_url_base', '//assets.themetacity.com/gifv/')
		self.css_class = config.get('css_class', 'gifv')

	def run(self, lines):
		new_lines = []
		for line in lines:
			match = self.GIFV_RE.match(line.strip())
			if match:
				filename = match.group(1)
				extensions = match.group(2).split(',')

				video = etree.Element('video', {
					'autoplay': 'true',
					'loop': 'true',
					'muted': 'true',
					'playsinline': 'true',
					'class': self.css_class
				})

				for ext in extensions:
					etree.SubElement(video, 'source', {
						'src': f"{self.video_url_base}{filename}.{ext.strip()}"
					})

				# Convert XML element to string and insert as raw HTML
				new_lines.append(etree.tostring(video, encoding='unicode'))
			else:
				new_lines.append(line)
		return new_lines


class GifV(Extension):
	"""
	Markdown extension for <gifv ... /> syntax.
	"""

	def __init__(self, **kwargs):
		self.config = {
			'video_url_base': ['//assets.themetacity.com/gifv/', 'Base URL for video files'],
			'css_class': ['gifv', 'CSS class for the <video> element'],
		}
		super().__init__(**kwargs)

	def extendMarkdown(self, md):
		config = self.getConfigs()
		md.preprocessors.register(GifVPreprocessor(md, config), 'gifv', 25)


def makeExtension(**kwargs):
	return GifV(**kwargs)