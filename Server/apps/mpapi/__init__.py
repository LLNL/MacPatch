import os
import logging, logging.handlers
import json
import subprocess
from flask import Flask
from mpapi.config import DevelopmentConfig, ProductionConfig
from mpapi.extensions import db, migrate

if os.getenv("MPAPI_ENV") == 'prod':
	DefaultConfig = ProductionConfig
else:
	DefaultConfig = DevelopmentConfig

def create_app(config_object=DefaultConfig):

	app = Flask(__name__)

	# Add teardown_request to the app, here we ensure the db session is removed after the
	# request has been completed in any way.
	# db.session.remove will call rollback explicitly if needed
	@app.teardown_request
	def shutdown_session(exception):
		if not exception:
			db.session.commit()

		db.session.remove()

	app.config.from_object(config_object)
	app.config.from_pyfile('../config.cfg', silent=True)
	app.config.from_pyfile('../conf_wsapi.cfg', silent=True)

	# Configure SQLALCHEMY_DATABASE_URI for MySQL
	_uri = "mysql+mysqlconnector://%s:%s@%s:%s/%s" % (app.config['DB_USER'], app.config['DB_PASS'], app.config['DB_HOST'], app.config['DB_PORT'], app.config['DB_NAME'])
	app.config['SQLALCHEMY_DATABASE_URI'] = _uri

	# Configure logging
	log_file = app.config['LOGGING_LOCATION'] + "/mpwsapi.log"
	if not os.path.exists(app.config['LOGGING_LOCATION']):
		os.makedirs(app.config['LOGGING_LOCATION'])
		subprocess.call(['chmod', '2775', app.config['LOGGING_LOCATION']])

	handler = logging.handlers.TimedRotatingFileHandler(log_file, when='midnight', interval=1, backupCount=30)

	# Set default log level
	if app.config['DEBUG']:
		app.logger.setLevel(logging.DEBUG)
	else:
		app.logger.setLevel(logging.INFO)

	if app.config['LOGGING_LEVEL'].lower() == 'info':
		app.logger.setLevel(logging.INFO)
	elif app.config['LOGGING_LEVEL'].lower() == 'debug':
		app.logger.setLevel(logging.DEBUG)
	elif app.config['LOGGING_LEVEL'].lower() == 'warning':
		app.logger.setLevel(logging.WARNING)
	elif app.config['LOGGING_LEVEL'].lower() == 'error':
		app.logger.setLevel(logging.ERROR)
	elif app.config['LOGGING_LEVEL'].lower() == 'critical':
		app.logger.setLevel(logging.CRITICAL)
	else:
		app.logger.setLevel(logging.INFO)

	formatter = logging.Formatter(app.config['LOGGING_FORMAT'])
	handler.setFormatter(formatter)
	app.logger.addHandler(handler)

	read_siteconfig_server_data(app)
	register_extensions(app)
	register_blueprints(app)
	return app

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

def register_extensions(app):
	db.init_app(app)
	migrate.init_app(app, db)

def register_blueprints(app):
	from .agent import agent as bp_agent
	app.register_blueprint(bp_agent, url_prefix=app.config['URL_PREFIX'])

	from .antivirus import antivirus as bp_antivirus
	app.register_blueprint(bp_antivirus, url_prefix=app.config['URL_PREFIX'])

	from .auth import auth as bp_auth
	app.register_blueprint(bp_auth, url_prefix=app.config['URL_PREFIX'])

	from .autopkg import autopkg as bp_autopkg
	app.register_blueprint(bp_autopkg, url_prefix=app.config['URL_PREFIX'])

	from .checkin import checkin as bp_checkin
	app.register_blueprint(bp_checkin, url_prefix=app.config['URL_PREFIX'])

	from .inventory import inventory as bp_inventory
	app.register_blueprint(bp_inventory, url_prefix=app.config['URL_PREFIX'])

	from .mac_profiles import mac_profiles as bp_mac_profiles
	app.register_blueprint(bp_mac_profiles, url_prefix=app.config['URL_PREFIX'])

	from .patches import patches as bp_patches
	app.register_blueprint(bp_patches, url_prefix=app.config['URL_PREFIX'])

	from .provisioning import provisioning as bp_provisioning
	app.register_blueprint(bp_provisioning, url_prefix=app.config['URL_PREFIX'])

	from .register import register as bp_register
	app.register_blueprint(bp_register, url_prefix=app.config['URL_PREFIX'])

	from .servers import servers as bp_servers
	app.register_blueprint(bp_servers, url_prefix=app.config['URL_PREFIX'])

	from .software import software as bp_software
	app.register_blueprint(bp_software, url_prefix=app.config['URL_PREFIX'])

	from .srv_utils import srv as bp_srv_utils
	app.register_blueprint(bp_srv_utils, url_prefix=app.config['URL_PREFIX'])

	from .status import status as bp_status
	app.register_blueprint(bp_status, url_prefix=app.config['URL_PREFIX'])
