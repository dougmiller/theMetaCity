from . import routes
from .audio import audio
from .bp import bp as v1
from .gallery import gallery
from .image import image
from .video import video

v1.register_blueprint(audio, url_prefix="/audio")
v1.register_blueprint(video, url_prefix="/video")
v1.register_blueprint(image, url_prefix="/image")
v1.register_blueprint(gallery, url_prefix="/gallery")

__all__ = ["routes", "v1"]
