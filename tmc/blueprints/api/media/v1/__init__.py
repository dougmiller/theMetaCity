from flask import Blueprint

from .audio import audio
from .video import video


v1 = Blueprint(
	'v1',
	__name__
)

v1.register_blueprint(audio, url_prefix="/audio")
v1.register_blueprint(video, url_prefix="/video")

from . import routes
