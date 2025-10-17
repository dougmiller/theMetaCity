from extensions.configs.database.connectors import PSQLDatabaseConfig, SQLiteDatabaseConfig

class DatabaseConfig:
    REQUIRED_BIND_NAMES = [
        'tmc_master',
        'com_admin',
        'com_selector',
        'media_admin',
        'media_selector',
        'edo_admin',
        'edo_selector',
    ]

    def __init__(self):
        pass

    def get_dict_of_binds(self, raw_config: dict) -> dict:
        """Return a dict of SQLAlchemy bind URIs."""
        binds = {}

        for bind_name in self.REQUIRED_BIND_NAMES:

            conn_type = raw_config.get(bind_name + '.type', 'postgres')

            if conn_type == 'postgres':
                binds[bind_name] = PSQLDatabaseConfig(
                    host=raw_config.get(bind_name + '.hostname'),
                    port=raw_config.get(bind_name + '.port'),
                    name=raw_config.get(bind_name + '.name'),
                    user=raw_config.get(bind_name + '.user')
                ).DATABASE_URI
            elif conn_type == 'sqlite':
                binds[bind_name] = SQLiteDatabaseConfig(
                    path=raw_config.get(bind_name + '.path')
                ).DATABASE_URI
            else:
                raise ValueError(f"Unsupported database type '{conn_type}' for bind '{bind_name}'")

        return binds
