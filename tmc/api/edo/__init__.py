from flask import Blueprint

edo = Blueprint(
    'edo',
    __name__
)


from . import routes
