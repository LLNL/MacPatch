import os
import json
import subprocess
from flask import Flask, abort, jsonify, session, render_template
from flask_mail import Mail
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import SQLAlchemyError, OperationalError
from flask_login import LoginManager
from flask_cors import CORS, cross_origin
from werkzeug.exceptions import HTTPException, InternalServerError
from http import HTTPStatus

import logging
import logging.handlers

from config import Config
from app.mplogger import *

db = SQLAlchemy()
login_manager = LoginManager()
mail = Mail()

def create_app(config_class=Config):
	
	app = Flask(__name__)
	cors = CORS(app)

	# Import Config Files
	app.config.from_object(config_class)
	app.config.from_pyfile('../config.cfg', silent=True)
	app.config.from_pyfile('../../config.cfg', silent=True)

	db.init_app(app)

	# Trim White Space from templates
	app.jinja_env.trim_blocks = True
	app.jinja_env.lstrip_blocks = True

	# Configure SQLALCHEMY_DATABASE_URI for MySQL
	_uri = "mysql+pymysql://%s:%s@%s:%s/%s" % (app.config['DB_USER'],app.config['DB_PASS'],app.config['DB_HOST'],app.config['DB_PORT'],app.config['DB_NAME'])
	app.config['SQLALCHEMY_DATABASE_URI'] = _uri

	# Configure authentication
	login_manager.init_app(app)
	login_manager.session_protection = "strong"
	login_manager.login_view = "auth.login"

	# Configure logging
	register_logging(app)
	read_siteconfig_server_data(app)
	register_blueprints(app)

	# This config option will convert all date objects to string
	app.config['RESTFUL_JSON'] = {'default': json_serial}

	@app.teardown_request
	def shutdown_session(exception):
		db.session.rollback()
		db.session.remove()

	@app.context_processor
	def baseData():
		enableIntune = 0
		if app.config['ENABLE_INTUNE']:
			enableIntune = 1

		return dict(patchGroupCount=patchGroupCount(), clientCount=clientCount(), intune=enableIntune)


	# MDM Schema Setup
	if app.config['ENABLE_INTUNE']:
		# Read Schema File and Store In App Var
		mdm_schema_file = app.config['STATIC_JSON_DIR']+"/mdm_schema.json"
		if os.path.exists(mdm_schema_file.strip()):
			schema_data = {}
			try:
				with open(mdm_schema_file.strip()) as data_file:
					schema_data = json.load(data_file)

				app.config["MDM_SCHEMA"] = schema_data
			except OSError:
				print('Well darn.')
				return

	@app.errorhandler(InternalServerError)
	def handle_exception1(e):
		return render_template('500.html'), 200

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

def register_logging(app):
	log_file = app.config['LOGGING_LOCATION'] + "/console.log"
	if not os.path.exists(app.config['LOGGING_LOCATION']):
		os.makedirs(app.config['LOGGING_LOCATION'])
		subprocess.call(['chmod', '2775', app.config['LOGGING_LOCATION']])

	# Set default log level
	_log_level = logging.INFO

	# If app is set to debug set logging to debug
	if app.config['DEBUG']:
		app.config['LOGGING_LEVEL'] = 'debug'

	if app.config['LOGGING_LEVEL'].lower() == 'info':
		_log_level = logging.INFO
	elif app.config['LOGGING_LEVEL'].lower() == 'debug':
		_log_level = logging.DEBUG
	elif app.config['LOGGING_LEVEL'].lower() == 'warning':
		_log_level = logging.WARNING
	elif app.config['LOGGING_LEVEL'].lower() == 'error':
		_log_level = logging.ERROR
	elif app.config['LOGGING_LEVEL'].lower() == 'critical':
		_log_level = logging.CRITICAL
	else:
		_log_level = logging.INFO

	# Set and Enable Logging
	# handler = logging.handlers.TimedRotatingFileHandler(log_file, when='midnight', interval=1, backupCount=30)
	handler = logging.handlers.RotatingFileHandler(log_file, maxBytes=10485760, backupCount=30)
	handler.setLevel(_log_level) # This is needed for log rotation
	# Set log file formatting
	formatter = logging.Formatter(app.config['LOGGING_FORMAT'])
	handler.setFormatter(formatter)
	# Add handler and set app log level
	app.logger.addHandler(handler)
	app.logger.setLevel(_log_level)

def register_blueprints(app):
	from .errors import errors as errors_blueprint
	app.register_blueprint(errors_blueprint)

	from .main import main as main_blueprint
	app.register_blueprint(main_blueprint, url_prefix='/')

	if app.config['ALLOW_CONTENT_DOWNLOAD']:
		from .content import content as content_blueprint
		app.register_blueprint(content_blueprint, url_prefix='/mp-content')

	from .auth import auth as auth_blueprint
	app.register_blueprint(auth_blueprint, url_prefix='/auth')

	from .agent import agent as agent_blueprint
	app.register_blueprint(agent_blueprint, url_prefix='/agent')

	from .dashboard import dashboard as dashboard_blueprint
	app.register_blueprint(dashboard_blueprint, url_prefix='/dashboard')

	from .clients import clients as clients_blueprint
	app.register_blueprint(clients_blueprint, url_prefix='/clients')

	from .patches import patches as patches_blueprint
	app.register_blueprint(patches_blueprint, url_prefix='/patches')

	from .registration import registration as registration_blueprint
	app.register_blueprint(registration_blueprint, url_prefix='/registration')

	from .reports import reports as reports_blueprint
	app.register_blueprint(reports_blueprint, url_prefix='/reports')

	from .software import software as software_blueprint
	app.register_blueprint(software_blueprint, url_prefix='/software')

	from .osmanage import osmanage as osmanage_blueprint
	app.register_blueprint(osmanage_blueprint, url_prefix='/osmanage')

	from .provision import provision as provision_blueprint
	app.register_blueprint(provision_blueprint, url_prefix='/provision')

	from .console import console as console_blueprint
	app.register_blueprint(console_blueprint, url_prefix='/console')

	from .test import test as test_blueprint
	app.register_blueprint(test_blueprint, url_prefix='/test')

	from .maint import maint as maint_blueprint
	app.register_blueprint(maint_blueprint, url_prefix='/maint')

	from .mdm import mdm as mdm_blueprint
	app.register_blueprint(mdm_blueprint, url_prefix='/mdm')

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

def json_serial(obj):
	"""JSON serializer for objects not serializable by default json code"""

	if isinstance(obj, (date, datetime)):
		serial = obj.isoformat()
		return serial

from app import model