import os
import json
from flask import Flask, session, redirect, url_for
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, logout_user
from flask_debugtoolbar import DebugToolbarExtension
from healthcheck import HealthCheck, EnvironmentDump

from flask_apscheduler import APScheduler

import logging, logging.handlers
from .config import DevelopmentConfig, ProductionConfig

from flask.ext.cors import CORS, cross_origin

def loadJobs(jobsFile, scheduler):

    jData = None
    with open(jobsFile) as json_data:
        jData = json.load(json_data)

    if jData:
        for j in jData:
            scheduler.add_job(j['id'], eval(j['func']), trigger=j['trigger'], seconds=j['seconds'])

def job1(a=0, b=0):
    print(str(a) + ' ' + str(b))

db = SQLAlchemy()

# Configure authentication
login_manager = LoginManager()
login_manager.session_protection = "strong"
#login_manager.login_view = "auth.login"

toolbar = DebugToolbarExtension()

if os.getenv("MPCONSOLE_ENV") == 'prod':
    DefaultConfig = ProductionConfig
else:
    DefaultConfig = DevelopmentConfig

def create_app(config_object=DefaultConfig):
    app = Flask(__name__)
    cors = CORS(app)

    app.config.from_object(config_object)
    app.config.from_pyfile('../config.cfg', silent=True)
    app.config.from_pyfile('../conf_console.cfg', silent=True)

    # Job Scheduler
    # Using flask-apscheduler
    #
    #scheduler = APScheduler()
    #loadJobs(app.config['JOBS_FILE'], scheduler)
    #scheduler.init_app(app)
    #scheduler.start()


    # Configure SQLALCHEMY_DATABASE_URI for MySQL
    _uri = "mysql+mysqlconnector://%s:%s@%s:%s/%s" % (app.config['DB_USER'],app.config['DB_PASS'],app.config['DB_HOST'],app.config['DB_PORT'],app.config['DB_NAME'])
    app.config['SQLALCHEMY_DATABASE_URI'] = _uri

    db.init_app(app)
    # Configure authentication
    login_manager.init_app(app)
    login_manager.login_view = "auth.login"
    toolbar.init_app(app)

    # wrap the flask app and give a heathcheck url
    health = HealthCheck(app, "/healthcheck")
    envdump = EnvironmentDump(app, "/environment")

    '''
    @app.errorhandler(Exception)
    def all_exception_handler(error):
        return 'Error yo', 500
    '''

    @app.teardown_request
    def shutdown_session(exception):
        db.session.rollback()
        db.session.remove()

    @app.context_processor
    def example():
        return dict(patchGroupCount=patchGroupCount(), clientCount=clientCount())


    # Configure logging
    handler = logging.handlers.TimedRotatingFileHandler(app.config['LOGGING_LOCATION'], when='midnight', interval=1, backupCount=30)
    handler.setLevel(app.config['LOGGING_LEVEL'])
    formatter = logging.Formatter(app.config['LOGGING_FORMAT'])
    handler.setFormatter(formatter)
    app.logger.addHandler(handler)
    
    read_siteconfig_server_data(app)        

    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint, url_prefix='/')

    from .auth import auth as auth_blueprint
    app.register_blueprint(auth_blueprint, url_prefix='/auth')

    from .dashboard import dashboard as dashboard_blueprint
    app.register_blueprint(dashboard_blueprint, url_prefix='/dashboard')

    from .clients import clients as clients_blueprint
    app.register_blueprint(clients_blueprint, url_prefix='/clients')

    from .patches import patches as patches_blueprint
    app.register_blueprint(patches_blueprint, url_prefix='/patches')

    from .software import software as software_blueprint
    app.register_blueprint(software_blueprint, url_prefix='/software')

    from .osmanage import osmanage as osmanage_blueprint
    app.register_blueprint(osmanage_blueprint, url_prefix='/osmanage')

    from .reports import reports as reports_blueprint
    app.register_blueprint(reports_blueprint, url_prefix='/reports')

    from .console import console as console_blueprint
    app.register_blueprint(console_blueprint, url_prefix='/console')



    return app

'''
----------------------------------------------------------------
Global
----------------------------------------------------------------
'''
def read_siteconfig_server_data(app):

    data = {}
    if os.path.exists(app.config['SITECONFIG_FILE'].strip()):
        try:
            with open(app.config['SITECONFIG_FILE'].strip()) as data_file:
                data = json.load(data_file)

        except OSError:
            print('Well darn.')
            return

    else:
        print("Error, could not open file " + app.config['SITECONFIG_FILE'].strip())
        return

    if "settings" in data:
        app.config['MP_SETTINGS'] = data['settings']
        return

def patchGroupCount():
    from .model import MpPatchGroup
    qGet = MpPatchGroup.query.all()
    count = len(qGet)
    return count

def clientCount():
    from .model import MpClient
    qGet = MpClient.query.with_entities(MpClient.cuuid).all()
    count = len(qGet)
    return count