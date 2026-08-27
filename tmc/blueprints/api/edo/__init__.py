from . import routes
from .bp import bp as edo
from .v1 import v1

edo.register_blueprint(v1, url_prefix="/v1")

__all__ = ["edo", "routes"]
