import os
import sys

basedir = os.path.abspath(os.path.dirname(__file__))


class Config(object):
    host = None
    port = None
    name = None
    user = None
    password = None

    SQLALCHEMY_MIGRATE_REPO = os.path.join(basedir, 'db_repository')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    @classmethod
    def __init__(cls):
        cls.__read_settings_config()
        cls.__read_db_config()
        cls.__read_password()

        cls.__test_connection()

        cls.SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://' + cls.user + ':' + cls.password + '@' + cls.host + ':' + cls.port + '/' + cls.name

    @classmethod
    def __test_connection(cls):
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
        except psycopg2.InternalError:
            print("I am unable to connect to the database")
            print(
                cls.host,
                cls.port,
                cls.user,
                cls.password
            )
            sys.exit(7)

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
            sys.exit(6)\


    @classmethod
    def __read_db_config(cls):
        """
        Attempts to load and read the info from the database connection config file
        Requires that the connection specific password be saved in a .pgpass file
        """
        import configparser

        config = configparser.ConfigParser()
        config.read('database.config')

        try:
            cls.host = config['DATABASE']['hostname']
            cls.port = config['DATABASE']['port']
            cls.name = config['DATABASE']['name']
            cls.user = config['DATABASE']['user']
        except KeyError as key_error:
            print("Could not find key in database config file: " + key_error.args[0])
            print("Expecting 'host', 'port', 'name', 'user'")
            sys.exit(6)

    @classmethod
    def __read_settings_config(cls):
        """
        Attempts to load and read the info from the app settings config file
        """
        import configparser

        config = configparser.ConfigParser()
        config.read('settings.config')

        try:
            cls.DEBUG = config['SETTINGS']['DEBUG']
            cls.SECRET_KEY = config['SETTINGS']['SECRET_KEY']
            cls.CSRF_ENABLED = config['SETTINGS']['CSRF_ENABLED']
            #cls.SERVER_NAME = config['SETTINGS']['SERVER_NAME']
        except KeyError as key_error:
            print("Could not find key in settings config file: " + key_error.args[0])
            print("Expecting 'DEBUG', 'SECRET_KEY', 'CSRF_ENABLED', 'SERVER_NAME'")
            sys.exit(6)




