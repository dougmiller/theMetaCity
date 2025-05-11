from .basic import basic_config
from .database import database_config

class Configs:
	def __init__(self, app = None):
		if app is not None:
			basic_config.init_app(app)
			database_config.init_app(app)
	
	def init_app(self, app):
		basic_config.init_app(app)
		database_config.init_app(app)

configs = Configs()
