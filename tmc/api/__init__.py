from flask import Blueprint
from .edo import edo

api = Blueprint(
    'api',
    __name__
)

api.register_blueprint(edo, url_prefix="/edo", subdomain='api')

from . import routes
