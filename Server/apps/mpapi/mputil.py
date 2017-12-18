'''
	Extent flask_restful.Resource

	Need access to HTTP_X header data

	This module should be renamed to be more descriptive :)
'''

from flask import request, current_app
import flask_restful
import hashlib
import sys
import json
import os.path
import hmac
from ldap3 import Server, Connection
from itsdangerous import TimedJSONWebSignatureSerializer as Serializer, BadSignature, SignatureExpired

from Crypto.PublicKey import RSA
from Crypto.Signature import PKCS1_v1_5
from Crypto.Hash import SHA256, SHA
from base64 import b64encode, b64decode, encodestring

from . import db
from . model import MPAgentRegistration, MpClient, AdmGroupUsers, AdmUsers, AdmUsersInfo, MpSiteKeys
from . mplogger import log_Debug, log_Info, log_Error

# ----------------------------------------------------------------------------
'''
	Extended flask_restful.Resource
	Use on all API resources.
	Includes requires MacPatch HTTP Header Fields
'''
class MPResource(flask_restful.Resource):
	def __init__(self):
		req = request.environ
		self.req_signature  = self.reqKeyValue(req, 'HTTP_X_API_SIGNATURE')
		self.req_akey       = self.reqKeyValue(req, 'HTTP_X_API_KEY')
		self.req_ts         = self.reqKeyValue(req, 'HTTP_X_API_TS')
		self.req_agent      = self.reqKeyValue(req, 'HTTP_X_AGENT_ID')
		self.req_uri        = self.reqKeyValue(req, 'PATH_INFO')

	def reqKeyValue(self, req, key):
		if key in req:
			return req[key]
		else:
			return 'NA'

# ----------------------------------------------------------------------------
'''
	Verify Signature
	Verify ClientID
	Verify API Key
'''

def isValidSignature(Signature, ClientID, Data, TimeStamp):

	if not current_app.config['REQUIRE_SIGNATURES']:
		# REQUIRE_SIGNATURES is false, return true on signature
		# evaluation
		return True

	qGet = MPAgentRegistration.query.filter_by(cuuid=ClientID).first()
	if qGet is not None:
		rec = qGet.asDict
		cKey = rec['clientKey']

		log_Debug('[isValidSignature][Data]: (%s)' % (str(Data)))
		log_Debug('[isValidSignature][Time]: (%s)' % (TimeStamp))

		secret = bytes(cKey).encode('utf-8')
		message_str = '%s-%s' % (str(Data), TimeStamp)
		message = bytes(message_str).encode('utf-8')

		log_Debug('[isValidSignature][secret]: (%s)' % (secret[-4:]))
		log_Debug('[isValidSignature][message_str]: (%s)' % (message_str))

		xSigHash = hmac.new(secret, message, hashlib.sha256).hexdigest()

		log_Debug('[isValidSignature][Signature][Expected]: %s' % (Signature))
		log_Debug('[isValidSignature][Signature][Verified]: %s' % (xSigHash))

		if xSigHash.lower() == Signature.lower():
			print "Verified"
			return True
		else:
			print "Failed"
			return False
	else:
		return False

def isValidClientID(ClientID):

	if 'VERIFY_CLIENTID' not in current_app.config:
		return True
	else:
		if not current_app.config['VERIFY_CLIENTID']:
			return True

	# Old Way, now check if client is registered
	# client_obj = MpClient.query.filter_by(cuuid=ClientID).first()
	client_obj = MPAgentRegistration.query.filter_by(cuuid=ClientID).first()

	if client_obj:
		return True
	else:
		return False

def isValidAPIKey(key_hash, dtstamp):

	# Get the API Key from the siteconfig.json
	apiKey = return_data_for_server_key('apiKey')
	apiKeyExtra = "%s-%s" % (apiKey, dtstamp)
	_apiKeyHash = hashlib.sha1(apiKeyExtra).hexdigest()

	if _apiKeyHash.lower() == key_hash.lower():
		return True
	else:
		return False


# ----------------------------------------------------------------------------
'''
	Authentication for users & User rights
'''
def authUser(username_or_token, password):

	res = False
	# first try to authenticate by token
	user = verify_auth_token(username_or_token)
	if not user or (user == "BadSignature" or user == "SignatureExpired"):
		# First Check Local Admin Account
		res = defaultAdminAuth(username_or_token, password)
		if res:
			return res

		# Check Database Accounts
		res = dbUserAuth(username_or_token, password)
		if res:
			return res

		# Last Check LDAP Accounts
		_ldap_conf = return_data_for_root_key('ldap')
		if _ldap_conf:
			if _ldap_conf['enabled']:
				res = ldapAuth(_ldap_conf, username_or_token, password)
				if res:
					return res
	else:
		# Token Was Good
		return True

	print "Error unable to verify user against any datasource."
	return res

'''
	Default Auth User
'''
def defaultAdminAuth(user, password):
	users = return_data_for_root_key('users')
	if "admin" in users:
		admin = users['admin']
		if admin['enabled']:
			if user == admin['name'] and password.lower() == admin['pass'].lower():
				return True
			else:
				return False
		else:
			print "Default admin account is disabled."
			return False
	else:
		return False

'''
	Database Auth User
'''
def dbUserAuth(user, password):

	try:
		admUser = AdmUsers.query.filter(AdmUsers.user_id == user, AdmUsers.enabled == 1).first()
		if admUser:
			hash_pass = hashlib.md5(password).hexdigest()
			if admUser.user_pass.lower() == hash_pass.lower():
				return True
			else:
				print "Error with user name or password."
				return False
		else:
			print "Error with user name or password."
			return False

	except:  # catch *all* exceptions
		e = sys.exc_info()[0]
		print e
		return False

'''
	LDAP User Auth
'''
def ldapAuth(ldap_conf, user, password):

	try:
		ldap_server = Server(ldap_conf['server'], port=ldap_conf['port'], use_ssl=ldap_conf['useSSL'])
		conn = Connection(ldap_server, user=user, password=password)
		didBind = conn.bind()
		if not didBind:
			print "Error with user name or password. Unable to bind to ldap server."
			return None

		didSearch = conn.search(ldap_conf['searchbase'], '(&(objectclass=*)('+ldap_conf['loginAttr']+'='+user+'))', attributes=ldap_conf['attributes'].split(','))
		if not didSearch:
			conn.unbind()
			print "Error unable to user info in directory."
			return None
		else:
			res = conn.entries[0]
			conn.unbind()
			return res

	except:  # catch *all* exceptions
		e = sys.exc_info()[0]
		print e
		return None

'''
	User Rights Methods
'''
def adminUserRights(user):
	'''
		Get User Rights for user account id

		:param user:
		:return:
	'''
	try:
		admObj = None
		admUser = AdmUsers.query.filter(AdmUsers.user_id == user, AdmUsers.enabled == 1).first()
		if not admUser:
			print "No user found to check for rights."
			return None

		admObj = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user, AdmUsersInfo.enabled == 1).first()
		if admObj:
			return admObj
		else:
			print "User not found or user is disabled."
			return None

	except:  # catch *all* exceptions
		e = sys.exc_info()[0]
		print e
		return None

def isValidAutoPKGUser(user):
	if isLocalServerAdmin(user):
		return True

	admUsr = adminUserRights(user)
	if admUsr:
		if admUsr.autopkg == 1:
			return True

	return False

def isValidAdminUser(user):
	if isLocalServerAdmin(user):
		return True

	admUsr = adminUserRights(user)
	if admUsr:
		if admUsr.admin == 1:
			return True

	return False

def isValidAgentUploadUser(user):
	if isLocalServerAdmin(user):
		return True

	admUsr = adminUserRights(user)
	if admUsr:
		if admUsr.agentUpload == 1:
			return True

	return False
'''
	Convenience Methods
'''
def isLocalServerAdmin(user):
	'''
	Checks to see if the user id is the local server admin account.
	If it is, and enabled it will pass true.
	This method will be used to pass all rights for the system.

	:param user:
	:return:
	'''
	users = return_data_for_root_key('users')
	if "admin" in users:
		admin = users['admin']
		if admin['enabled'] and user == admin['name']:
			return True

	return False

def isValidToken(user, token):

	_user = verify_auth_token(token)
	if user == _user:
		return True
	else:
		print "Verify auth token " + user
		return False

def verify_auth_token(token):
	s = Serializer(current_app.config['SECRET_KEY'])
	try:
		data = s.loads(token)
	except SignatureExpired:
		return "SignatureExpired"  # valid token, but expired
	except BadSignature:
		return "BadSignature"  # invalid token

	return data['id']

def verify_auth_password(username_or_token, password):
	return authUser(username_or_token, password)

# ----------------------------------------------------------------------------
'''
	Send Email
'''
def sendEmailMessage(subject, message, address=None):

	admUsrLst = []
	admUsr = AdmGroupUsers.query.filter(AdmGroupUsers.email_notification == 1, AdmGroupUsers.user_email != None).all()
	for i in admUsr:
		admUsrLst.append(i.user_email)
	# If No Email Addresses then dont send
	if len(admUsrLst) <= 0:
		return
	admEmlLst = ",".join(admUsrLst)

	import smtplib
	import sys
	try:
		_msrv = return_data_for_root_key('mailserver')
		_srv = _msrv['server']
		_prt = 25
		if 'port' in _msrv:
			_prt = _msrv['port']

		session = smtplib.SMTP(_srv, _prt)
		session.ehlo()
		if 'usetls' in _msrv:
			if _msrv['usetls']:
				session.starttls()
		if 'username' in _msrv and 'password' in _msrv:
			session.login(_msrv['username'], _msrv['password'])

		headers = "\r\n".join(["from: " + 'macpatch@your.macpatch.server.com',
							"subject: " + subject,
							"to: " + admEmlLst,
							"mime-version: 1.0",
							"content-type: text/html"])

		# body_of_email can be plaintext or html!
		content = headers + "\r\n\r\n" + message
		session.sendmail('macpatch@your.macpatch.server.com', admEmlLst, content)
	except:
		print "Unexpected error:", sys.exc_info()[0]

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

# ----------------------------------------------------------------------------
'''
	Sign Message
'''

def signData(data):
	qKeys = MpSiteKeys.query.filter(MpSiteKeys.active == '1').first()
	if qKeys is not None:
		# Using SHA1 padding
		rsakey = RSA.importKey(qKeys.priKey)
		signer = PKCS1_v1_5.new(rsakey)
		digest = SHA.new()

		digest.update(data)
		sign = signer.sign(digest)
		return b64encode(sign)
	else:
		return None

def verifySignedData(signature, data):
	qKeys = MpSiteKeys.query.filter(MpSiteKeys.active == '1').first()
	if qKeys is not None:
		# Using SHA1 padding
		rsakey = RSA.importKey(qKeys.pubKey)
		signer = PKCS1_v1_5.new(rsakey)
		digest = SHA.new()

		digest.update(data)
		if signer.verify(digest, b64decode(signature)):
			return True

	return False
