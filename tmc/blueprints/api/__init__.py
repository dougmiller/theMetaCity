from flask import Blueprint
from .edo import edo
from .media import media

api = Blueprint(
    'api',
    __name__
)

api.register_blueprint(edo, url_prefix="/edo")
api.register_blueprint(media, url_prefix="/media")

from . import routes
