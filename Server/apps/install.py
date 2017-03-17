import pip
import os
from sys import platform

_pre_ = [
	"pip",
	"setuptools"
]

_all_ = [
	"alembic>=0.8.7",
	"aniso8601>=1.1.0",
	"blinker>=1.4",
	"click>=6.6",
	"enum34>=1.1.6",
	"Flask>=0.11.1",
	"Flask-DebugToolbar==0.10.0",
	"Flask-Cache>=0.13.1",
	"flask-ldap3-login>=0.9.12",
	"Flask-Login>=0.3.2",
	"Flask-Migrate>=1.8.1",
	"Flask-RESTful>=0.3.5",
	"flask-restful-swagger==0.19",
	"Flask-Script>=2.0.5",
	"Flask-SQLAlchemy>=2.1",
	"Flask-WTF>=0.13.1",
	"gevent>=1.1.2",
	"greenlet>=0.4.10",
	"gunicorn>=19.6.0",
	"healthcheck>=1.3.1",
	"itsdangerous>=0.24",
	"Jinja2>=2.8",
	"ldap3>=2.1.0",
	"Mako>=1.0.4",
	"MarkupSafe>=0.23",
	"pyasn1>=0.1.9",
	"python-dateutil>=2.5.3",
	"python-editor>=1.0.1",
	"pytz>=2016.6.1",
	"six>=1.10.0",
	"Werkzeug>=0.11.11",
	"WTForms>=2.1",
]

_failed_ = []

MP_HOME     = "/opt/MacPatch"
MP_SRV_BASE = MP_HOME+"/Server"

srcDir      = MP_SRV_BASE+"/apps/_src_"
cryptoPKG   = srcDir+"/M2Crypto-0.21.1-py2.7-macosx-10.8-intel.egg"

linux = ["M2Crypto==0.24.0", "uWSGI>=2.0.14", "mysql-connector-python-rf>=2.1.3"]
darwin = ["mysql-connector-python-rf>=2.1.3", ]

def easyInstall(package):
	print "Running Easy Install"
	print package
	if os.path.exists(package):
		print("Easy Install Python Module: " + package)
		os.system("easy_install --quiet " + package)

def installAlt(package):
	# Debugging
	# pip.main(["install", "--pre", "--upgrade", "--no-index",
	#         "--find-links=.", package, "--log-file", "log.txt", "-vv"])
	pip.main(["install", "--quiet", "--no-cache-dir", "--no-index", "--find-links=.", package])

def upgrade(packages, platformStr="linux"):
	for package in packages:
		if platformStr == 'linux':
			res = pip.main(['install', "--quiet", "--egg", "--no-cache-dir", "--upgrade", "--trusted-host", "pypi.python.org", package])
		else:
			res = pip.main(['install', "--quiet", "--egg", "--no-cache-dir", "--upgrade", package])

		if res != 0:
			_failed_.append(package)
			print("Error installing " + package + ". Please verify env.")

def install(packages, platformStr="linux"):
	for package in packages:
		print("Installing Python Module: " + package)
		if platformStr == 'linux':
			res = pip.main(['install', "--quiet", "--egg", "--no-cache-dir", "--trusted-host", "pypi.python.org", package])
		else:
			res = pip.main(['install', "--quiet", "--egg", "--no-cache-dir", package])

		if res != 0:
			_failed_.append(package)
			print("Error installing " + package + ". Please verify env.")

if __name__ == '__main__':

	isMac = platform.startswith('darwin')
	isLinux = platform.startswith('linux')

	osType = 'NA'
	if isMac:
		osType = 'darwin'
	elif isLinux:
		osType = 'linux'

	print "Running python package installs for operating system type " + osType

	upgrade(_pre_, osType)
	install(_all_, osType)

	if len(_failed_) > 0:
		print "Retrying failed packages"
		install(_failed_, osType)

	if platform.startswith('linux'):
		print "Install Linux Packages"
		install(linux, osType)

	if platform.startswith('darwin'):
		print "Install Darwin Packages"
		install(darwin, osType)
		easyInstall(cryptoPKG)
