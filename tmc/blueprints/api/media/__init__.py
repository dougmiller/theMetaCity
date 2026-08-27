from . import routes
from .bp import bp as media
from .v1 import v1

media.register_blueprint(v1, url_prefix="/v1")

__all__ = ["media", "routes"]
