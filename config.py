import os
import sys
from configs import PSQLDatabaseConfig

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

        tmc_master = PSQLDatabaseConfig("database.config", "themetacity.master")
        com_admin = PSQLDatabaseConfig("database.config", "themetacity.com.admin")
        com_selector = PSQLDatabaseConfig("database.config", "themetacity.com.selector")
        media_admin = PSQLDatabaseConfig("database.config", "themetacity.media.admin")
        media_selector = PSQLDatabaseConfig("database.config", "themetacity.media.selector")
        edo = PSQLDatabaseConfig("database.config", "everyday_ordinary.admin")
        edo_selector = PSQLDatabaseConfig("database.config", "everyday_ordinary.selector")

        cls.SQLALCHEMY_BINDS = {
            'tmc_master': tmc_master.DATABASE_URI,
            'com': com_admin.DATABASE_URI,
            'com_selector': com_selector.DATABASE_URI,
            'media': media_admin.DATABASE_URI,
            'media_selector': media_selector.DATABASE_URI,
            'edo': edo.DATABASE_URI,
            'edo_selector': edo_selector.DATABASE_URI
        }

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
            cls.SERVER_NAME = config['SETTINGS']['SERVER_NAME']
            cls.EDO_UPLOAD_PATH = config['EDO']['UPLOAD_PATH']
            cls.ASSETS_PATH = config['ASSETS']['UPLOAD_PATH']
        except KeyError as key_error:
            print("Could not find key in settings config file: " + key_error.args[0])
            print("Expecting 'DEBUG', 'SECRET_KEY', 'CSRF_ENABLED', 'SERVER_NAME', 'EDO_UPLOAD_PATH', 'ASSETS_PATH'")
            sys.exit(6)




