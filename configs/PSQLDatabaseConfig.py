import os
import sys
from urllib.parse import quote_plus

basedir = os.path.abspath(os.path.dirname(__file__))


class PasswordNotFoundInPGPass(Exception):
    def __init__(self, host, port, name, user):
        super().__init__(f"The password combination given did not return a password for {host}, {port}, {name}, {user}")


class PSQLDatabaseConfig(object):
    host = None
    port = None
    name = None
    user = None
    password = None

    def __init__(self, config_file=None, config_path='DATABASE'):
        self.__read_db_config(config_file, config_path)
        self.__read_password()
        self.__test_psql_connection()

        self.DATABASE_URI = f'postgresql+psycopg2://{self.user}:{self.password}@{self.host}:{self.port}/{self.name}'

    @classmethod
    def __read_db_config(cls, config_file, config_path):
        """
        Attempts to load and read the info from the database connection config file
        Requires that the connection specific password be saved in a .pgpass file
        """
        import configparser

        config = configparser.ConfigParser()
        config.read(config_file)

        try:
            cls.host = config[config_path]['hostname']
            cls.port = config[config_path]['port']
            cls.name = config[config_path]['name']
            cls.user = config[config_path]['user']
        except KeyError as key_error:
            print("Could not find key in database config file: " + key_error.args[0])
            print("Expecting 'host', 'port', 'name', 'user'")
            sys.exit(6)

    @classmethod
    def __read_password(cls):
        import pgpasslib

        try:
            cls.password = pgpasslib.getpass(
                cls.host,
                cls.port,
                cls.name,
                cls.user
            )

            if cls.password is None:
                raise PasswordNotFoundInPGPass(cls.host, cls.port, cls.name, cls.user)

            cls.password = quote_plus(cls.password)
        except pgpasslib.FileNotFound:
            print('.pgpass file not found. Please create and populate it.')
            sys.exit(7)
        except pgpasslib.InvalidEntry:
            print('.pgpass file has unreadable field.')
            sys.exit(7)
        except pgpasslib.InvalidPermissions:
            print('.pgpass file has invalid permissions (file as group or world readable bit set).')
            sys.exit(7)
        except pgpasslib.PgPassException as ex:
            print('Error with .pgpass system')
            print(ex)
            sys.exit(6)
        except PasswordNotFoundInPGPass as ex:
            print(ex)
            sys.exit(7)

    @classmethod
    def __test_psql_connection(cls):
        """
        Attempts to connect to the database with provided config files
        """
        import psycopg2

        try:
            psycopg2.connect(
                host=cls.host,
                port=cls.port,
                dbname=cls.name,
                user=cls.user,
                password=cls.password
            )
            print(f"Successfully connected to the {cls.name} database with user: {cls.user}")
        except psycopg2.OperationalError:
            print(f"I am unable to connect to the {cls.name} database")
            print(
                cls.host,
                cls.port,
                cls.user,
                cls.password
            )
            sys.exit(7)
