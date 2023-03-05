from flask import Blueprint
from .v1 import v1

edo = Blueprint(
    'edo',
    __name__
)

edo.register_blueprint(v1, url_prefix="/v1", subdomain='api')

from . import routes
