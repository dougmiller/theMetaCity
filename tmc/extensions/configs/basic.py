from dotenv import dotenv_values


class BasicConfig:
    """Handles basic environment validation and CLI inspection."""

    REQUIRED_ENV_VARS = [
        'SERVER_NAME',
        'DEBUG',
        'SECRET_KEY',
        'CSRF_ENABLED',
        'EDO_UPLOAD_PATH',
        'ASSETS_PATH',
        'DOCUMENTS_FOLDER_PATH',
    ]

    def __init__(self):
        pass

    def get_dict_of_configs(self, raw_config: dict) -> dict:
        """Return only the required environment variables from a raw config dict."""
		
        return {
            key: raw_config.get(key)
            for key in self.REQUIRED_ENV_VARS
        }