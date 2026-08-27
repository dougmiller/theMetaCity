import os

from dotenv import dotenv_values

from .basic import BasicConfig
from .database import DatabaseConfig


class Configs:
    def __init__(self, app=None) -> None:
        if app is not None:
            self.init_app(app)

    @staticmethod
    def _raw_config() -> dict:
        return {
            **dotenv_values(".env.basic"),  # shared development variables
            **dotenv_values(".env.database"),  # connection variables
            **os.environ,  # environment overrides
        }

    @staticmethod
    def init_app(app) -> None:
        raw_config = Configs._raw_config()

        basic_config = BasicConfig()
        app.config.from_mapping(basic_config.get_dict_of_configs(raw_config))

        db_config = DatabaseConfig()
        app.config.from_mapping({"SQLALCHEMY_ENGINES": db_config.get_dict_of_engines(raw_config)})

    @staticmethod
    def preflight() -> list[str]:
        """Eagerly build engine URLs so bad config fails fast. Returns errors."""
        errors: list[str] = []
        try:
            DatabaseConfig().get_dict_of_engines(Configs._raw_config())
        except Exception as exc:
            errors.append(f"database config: {exc}")
        return errors


configs = Configs()
