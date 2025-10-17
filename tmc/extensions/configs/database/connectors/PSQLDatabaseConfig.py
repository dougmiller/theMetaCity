import os
import sys
from urllib.parse import quote_plus

basedir = os.path.abspath(os.path.dirname(__file__))


class PasswordNotFoundInPGPass(Exception):
    def __init__(self, host, port, name, user):
        super().__init__(f"The password combination given did not return a password for {host}, {port}, {name}, {user}")


class PSQLDatabaseConfig():
    def __init__(self, host=None, port=None, name=None, user=None):
        self.host = host
        self.port = port
        self.name = name
        self.user = user
        self.password = None
        
        self.__read_password()

        self.DATABASE_URI = f'postgresql+psycopg://{self.user}:{self.password}@{self.host}:{self.port}/{self.name}'

    def __read_password(self):
        import pgpasslib

        try:
            self.password = pgpasslib.getpass(
                self.host,
                self.port,
                self.name,
                self.user
            )

            if self.password is None:
                raise PasswordNotFoundInPGPass(self.host, self.port, self.name, self.user)

            self.password = quote_plus(self.password)
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

    def test_psql_connection(self):
        """
        Attempts to connect to the database with provided config files
        """
        import psycopg

        try:
            psycopg.connect(
                host=self.host,
                port=self.port,
                dbname=self.name,
                user=self.user,
                password=self.password
            )
        except psycopg.OperationalError as e:
            return False
		
        return True
