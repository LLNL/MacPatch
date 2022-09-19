import os
from dotenv import load_dotenv

basedir = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(basedir, '.env'))

MP_ROOT_DIR = '/opt/MacPatch'
MP_SRV_DIR = MP_ROOT_DIR+'/Server'

class Config(object):

	DEBUG               			= False
	TESTING             			= False

	# Web Server Options
	# Use 127.0.0.1 and port 3601, NGINX will be the outward facing
	# avenue for clients to communicate.
	SRV_HOST            			= '127.0.0.1'
	SRV_PORT            			= 3601

	# URL Options
	API_PREFIX          			= 'api'
	API_VERSION         			= 'v1'
	URL_PREFIX          			= '/' + API_PREFIX + '/' + API_VERSION

	# Database Options
	DB_USER                         = 'mpdbadm'
	DB_PASS                         = 'password'
	DB_HOST                         = 'localhost'
	DB_PORT                         = '3306'
	DB_NAME                         = 'MacPatchDB3'
	DB_CONNECTOR					= 'mysql+pymysql'
	DB_URI_STRING					= ''
	SQLALCHEMY_DATABASE_URI         = DB_CONNECTOR+'://'
	SQLALCHEMY_TRACK_MODIFICATIONS  = False
	SQLALCHEMY_ENGINE_OPTIONS = {  'pool_size' : 200,
								   'pool_recycle':120,
								   'pool_timeout':15,
								   'pool_pre_ping': True }

	# App Options
	SECRET_KEY              		= '~t\x86\xc9\x1ew\x8bOcX\x85O\xb6\xa2\x11kL\xd1\xce\x7f\x14<y\x9e'
	LOGGING_FORMAT          		= '%(asctime)s [%(name)s][%(levelname).3s] --- %(message)s'
	LOGGING_LEVEL           		= 'info'
	LOGGING_LOCATION        		= os.path.join(MP_SRV_DIR, 'logs')
	JSON_SORT_KEYS					= False

	# MacPatch App Options
	SITECONFIG_FILE         		= os.path.join(MP_SRV_DIR, 'etc/siteconfig.json')
	VERIFY_CLIENTID         		= True
	CLIENTID_ZERO 					= False
	REQUIRE_SIGNATURES      		= False
	ALLOW_MIXED_SIGNATURES  		= True
	POST_CHECKIN_TO_SYSLOG  		= False
	REDIRECT_TO_NEW_API				= True
	VERIFY_MIN_AGENT_VER			= False
	MIN_AGENT_VER 					= '0'

	# Content
	CONTENT_DIR             		= '/opt/MacPatch/Content'
	WEB_CONTENT_DIR 	    		= '/opt/MacPatch/Content/Web'
	AGENT_CONTENT_DIR       		= '/opt/MacPatch/Content/Web/clients'
	PATCH_CONTENT_DIR       		= '/opt/MacPatch/Content/Web/patches'
	ALLOW_CONTENT_DOWNLOAD			= False

	# Inventory
	INVENTORY_PROCESS				= 'Hybrid' # DB, File, Hybrid
	INVENTORY_HYBRID_ROWS_LIMIT		= 10

	# Email
	MAIL_SERVER						= 'localhost'
	MAIL_PORT						= 25
	MAIL_USE_TLS					= False
	MAIL_USERNAME					= None
	MAIL_PASSWORD					= None
	
	# Support Email Addresses
	EMAIL_FROM_SENDER				= 'your-email@example.com'
	EMAIL_TO_RECIPIENTS				= ['your-email@example.com']
	

	# AWS
	USE_AWS_S3						= False
	AWS_S3_KEY 						= None
	AWS_S3_SECRET 					= None
	AWS_S3_BUCKET 					= None
	AWS_S3_REGION 					= None

	# InTune - MDM
	ENABLE_INTUNE					= False
	INTUNE_RESOURCE					= "https://graph.microsoft.com"
	INTUNE_TENANT					= ""
	INTUNE_AUTHORITY_HOST_URL		= ""
	INTUNE_CLIENT_ID				= ""
	INTUNE_CLIENT_SECRET			= ""
	INTUNE_USER						= ""
	INTUNE_USER_PASS				= ""