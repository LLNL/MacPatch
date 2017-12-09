'''
	Extent flask_restful.Resource

	Need access to HTTP_X header data

	This module should be renamed to be more descriptive :)
'''

from flask import current_app
import json
import os.path
from . mplogger import log_Debug, log_Info, log_Error

import json
import hashlib
from M2Crypto import RSA, util

from . import db
from . model import MPAgentRegistration, MpClient, AdmGroupUsers, AdmUsers, AdmUsersInfo, MpSiteKeys
from . mplogger import log_Debug, log_Info, log_Error

# ----------------------------------------------------------------------------
'''
	Read Server Config file
'''

def read_config_file(configFile):

	data = {}
	if os.path.exists(configFile.strip()):
		try:
			with open(configFile.strip()) as data_file:
				data = json.load(data_file)

		except OSError:
			print('Well darn.')

	else:
		print("Error, could not open file " + configFile.strip())

	return data

def mpConfig():
	cnfFile = current_app.config['SITECONFIG_FILE']
	_config = read_config_file(cnfFile)
	return _config

def return_data_for_root_key(key):
	_config = mpConfig()
	if _config is None:
		return None

	_config = _config['settings']
	if key in _config:
		return _config[key]
	else:
		return None

def return_data_for_server_key(key):
	_config = mpConfig()
	if _config is None:
		return None

	_config = _config['settings']['server']
	if key in _config:
		return _config[key]
	else:
		return _config

def signResultData(data):
	qKeys = MpSiteKeys.query.filter(MpSiteKeys.active == '1').first()
	if qKeys is not None:
		message = json.dumps(data)
		sha1_hash = hashlib.sha1(message).digest()
		rsa = RSA.load_key_string(qKeys.priKey.encode('utf-8'), callback=util.no_passphrase_callback)
		signature = rsa.private_encrypt(sha1_hash, RSA.pkcs1_padding).encode('hex')

		return signature
	else:
		return None
