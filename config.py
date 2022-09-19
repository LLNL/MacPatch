import os
from dotenv import load_dotenv

basedir = os.path.abspath(os.path.dirname(__file__))
appsdir = os.path.dirname(basedir)
load_dotenv(os.path.join(basedir, '.env'))

class Config(object):

	DEBUG   						= False
	TESTING 						= False

	BASEDIR 						= basedir
	APPSDIR							= appsdir
	APPDIR							= os.path.join(basedir, 'app')
	
	MAX_CONTENT_LENGTH              = 9000 * 1024 * 1024    # 9000 Mb limit

	# Web Server Options
	# Use 127.0.0.1 and port 3601, NGINX will be the outward facing
	# avenue for clients to communicate.
	SRV_HOST                        = '127.0.0.1'
	SRV_PORT                        = 5000

	CORS_HEADERS 					= 'Content-Type'
	ALLOW_CONTENT_DOWNLOAD 			= False

	# Database Options
	DB_USER                         = 'jamfdbrousr'
	DB_PASS                         = 'password'
	DB_HOST                         = 'localhost'
	DB_PORT                         = '3306'
	DB_NAME                         = 'JAMFDB'
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
	LOGGING_LOCATION    			= APPSDIR+'/apps/logs'

	STATIC_DIR 						= APPDIR + '/static'

	# LDAP Config
	LDAP_ENABLED			= True
	LDAP_SERVER				= 'example.com'
	LDAP_PORT				= 636
	LDAP_SEARCHBASE			= ''
	LDAP_ATTRS				= 'givenname,initials,sn,mail,memberOf,dn,samAccountName,userPrincipalName'
	LDAP_USE_SSL			= True
	LDAP_LOGIN_ATTR			= 'LOGIN-ATTRIBUTE'
	LDAP_LOGIN_USR_PREFIX	= 'LOGIN-PREFIX'
	LDAP_LOGIN_USR_SUFFIX	= 'LOGIN-SUFFIX'
	

