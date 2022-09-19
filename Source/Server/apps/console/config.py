import os
from dotenv import load_dotenv

basedir = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(basedir, '.env'))

MP_ROOT_DIR = '/opt/MacPatch'
MP_SRV_DIR = MP_ROOT_DIR+'/Server'

class Config(object):

	DEBUG   						= False
	TESTING 						= False

	BASEDIR 						= basedir
	APPDIR							= os.path.join(basedir, 'app')
	
	MAX_CONTENT_LENGTH              = 9000 * 1024 * 1024    # 9000 Mb limit

	# Web Server Options
	# Use 127.0.0.1 and port 3601, NGINX will be the outward facing
	# avenue for clients to communicate.
	SRV_HOST                        = '127.0.0.1'
	SRV_PORT                        = 3602

	CORS_HEADERS 					= 'Content-Type'
	ALLOW_CONTENT_DOWNLOAD 			= False

	# Database Options
	DB_USER                         = 'mpdbadm'
	DB_PASS                         = 'password'
	DB_HOST                         = 'localhost'
	DB_PORT                         = '3306'
	DB_NAME                         = 'MacPatchDB3'
	SQLALCHEMY_DATABASE_URI         = 'mysql+pymysql://'
	SQLALCHEMY_TRACK_MODIFICATIONS  = False
	SQLALCHEMY_ENGINE_OPTIONS = { 'pool_size' : 50,
                                  'pool_recycle': 120,
                                  'pool_timeout': 20,
                                  'pool_pre_ping': True }

	# App Options
	SECRET_KEY          			= '~t\x86\xc9\x1ew\x8bOcX\x85O\xb6\xa2\x11kL\xd1\xce\x7f\x14<y\x9e'
	LOGGING_FORMAT      			= '%(asctime)s [%(name)s][%(levelname).3s] --- %(message)s'
	LOGGING_LEVEL       			= 'info'
	LOGGING_LOCATION    			= os.path.join(MP_SRV_DIR, 'logs')

	# MacPatch App Options
	SITECONFIG_FILE     			= os.path.join(MP_SRV_DIR, 'etc/siteconfig.json')
	CONTENT_DIR         			= os.path.join(MP_ROOT_DIR, 'Content')
	AGENT_CONTENT_DIR   			= os.path.join(CONTENT_DIR, 'Web/clients')
	PATCH_CONTENT_DIR   			= os.path.join(CONTENT_DIR, 'Web/patches')
	SW_CONTENT_DIR      			= os.path.join(CONTENT_DIR, 'Web/sw')

	STATIC_DIR 						= os.path.join(APPDIR, 'static')
	STATIC_JSON_DIR 				= os.path.join(STATIC_DIR, 'json')

	JOBS_FILE 						= os.path.join(STATIC_JSON_DIR, 'jobs.json')
	JOBS 							= []

	SCHEDULER_API_ENABLED 			= True
	REDIRECT_TO_NEW_API 			= True

	# AWS - MP
	USE_AWS_S3						= False
	AWS_S3_KEY						= None
	AWS_S3_SECRET					= None
	AWS_S3_BUCKET					= None
	AWS_S3_REGION					= None

	# InTune - MDM
	ENABLE_INTUNE					= True
	INTUNE_RESOURCE					= "https://graph.microsoft.com"
	INTUNE_TENANT					= ""
	INTUNE_AUTHORITY_HOST_URL		= ""
	INTUNE_CLIENT_ID				= ""
	INTUNE_CLIENT_SECRET			= ""
	INTUNE_USER						= ""
	INTUNE_USER_PASS				= ""