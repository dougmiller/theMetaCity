from . import routes
from .audio import audio
from .bp import bp as media
from .gallery import gallery
from .video import video

media.register_blueprint(video, url_prefix="/video")
media.register_blueprint(audio, url_prefix="/audio")
media.register_blueprint(gallery, url_prefix="/gallery")

__all__ = ["media", "routes"]
