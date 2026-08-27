from . import routes
from .bp import bp as api
from .edo import edo
from .media import media

api.register_blueprint(edo, url_prefix="/edo")
api.register_blueprint(media, url_prefix="/media")

__all__ = ["api", "routes"]
