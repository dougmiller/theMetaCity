from flask import Blueprint
from flask_caching import Cache

cache = Cache(config={'CACHE_TYPE': 'simple', 'CACHE_DEFAULT_TIMEOUT': 60})

api = Blueprint(
    'api',
    __name__
)

from . import routes