from configdetails import SQLUSER, SQLPASSWORD, SQLDB, SQLHOST, SECRET_KEY_STRING, SERVER_REAL_NAME, DEBUG_FLAG
import os

CSRF_ENABLED = True
SECRET_KEY = SECRET_KEY_STRING

basedir = os.path.abspath(os.path.dirname(__file__))

class Config(object):
    SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://'+SQLUSER+':'+SQLPASSWORD+'@'+SQLHOST+'/'+SQLDB
    SQLALCHEMY_MIGRATE_REPO = os.path.join(basedir, 'db_repository')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    DEBUG = DEBUG_FLAG

    SERVER_NAME = SERVER_REAL_NAME
