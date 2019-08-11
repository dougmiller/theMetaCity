from flask import Blueprint
from flask_caching import Cache
cache = Cache(config={'CACHE_TYPE': 'simple', 'CACHE_DEFAULT_TIMEOUT': 0})

blog = Blueprint(
    'blog',
    __name__,
    template_folder='templates',
    static_folder='static'
)

from . import routes
