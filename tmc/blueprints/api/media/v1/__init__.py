from flask import Blueprint

from .audio import audio
from .video import video
from .image import image
from .gallery import gallery


v1 = Blueprint(
	'v1',
	__name__
)

v1.register_blueprint(audio, url_prefix="/audio")
v1.register_blueprint(video, url_prefix="/video")
v1.register_blueprint(image, url_prefix="/image")
v1.register_blueprint(gallery, url_prefix="/gallery")

from . import routes
