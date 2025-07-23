import os
from dotenv import dotenv_values

from .basic import BasicConfig
from .database import DatabaseConfig

class Configs:
    def __init__(self, app = None):
        if app is not None:
            pass

    @staticmethod
    def init_app(app):
        raw_config = {
            **dotenv_values(".env.basic"),  # load shared development variables
            **dotenv_values(".env.database"),  # load sensitive variables
            **os.environ,  # override loaded values with environment variables
        }

        basic_config = BasicConfig()
        app.config.from_mapping(
            basic_config.get_dict_of_configs(raw_config)
        )

        db_config = DatabaseConfig()
        app.config.from_mapping({
            'SQLALCHEMY_BINDS': db_config.get_dict_of_binds(raw_config)
        })

configs = Configs()
