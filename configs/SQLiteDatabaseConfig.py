import os
import sys

basedir = os.path.abspath(os.path.dirname(__file__))


class SQLiteDatabaseConfig(object):
    path = None

    def __init__(self, config_file=None, config_path='DATABASE'):
        self.__read_db_config(config_file, config_path)
        self.__test_sqlite_connection()

        self.DATABASE_URI = f'sqlite://{self.path}'

    @classmethod
    def __read_db_config(cls, config_file, config_path):
        """
        Attempts to load and read the info from the database connection config file
        """
        import configparser

        config = configparser.ConfigParser()
        config.read(config_file)

        try:
            cls.path = config[config_path]['path']

        except KeyError as key_error:
            print("Could not find key in database config file: " + key_error.args[0])
            print("Expecting 'path'")
            sys.exit(6)

    @classmethod
    def __test_sqlite_connection(cls):
        """
        Attempts to connect to the database with provided config files
        """
        import sqlite3

        try:
            conn = sqlite3.connect(cls.path)
            conn.cursor()
            print(f"Successfully connected to the {cls.path} database")
        except sqlite3.InternalError:
            print(f"I am unable to connect to the {cls.path} database")
            print(cls.path)
            sys.exit(7)
