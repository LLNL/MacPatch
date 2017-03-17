from .. model import *
from .. import db
from .. mplogger import *
from datetime import datetime
import sys

def isClientRegistered(ClientID):
	reg_query_object = MPAgentRegistration.query.filter_by(cuuid=ClientID).first()

	if reg_query_object is not None:
		rec = reg_query_object.asDict
		if rec['enabled'] == 1:
			return True
		else:
			return False

	return False

'''
	Check to see if auto registration is enabled
'''
def isAutoRegEnabled():
	qGet = MpClientsRegistrationSettings.query.first()

	if qGet is not None:
		rec = qGet.asDict
		if rec['autoreg'] == 1:
			return True
		else:
			return False

	return False

'''
	Check to see if auto client_parking is enabled
	client_parking allows a client semi register, requires admin to
	approve before it's enabled.

	Client Will Register in a disabled state, no API's will function
	While client is not registered
'''
def isClientParkingEnabled():
	qGet = MpClientsRegistrationSettings.query.first()

	if qGet is not None:
		rec = qGet.asDict
		if rec['client_parking'] == 1:
			return True
		else:
			return False

	return False

def isKeyRequired(ClientID):
	pass

'''
	Check to see if the reg key for the client id is active
'''
def isKeyValidForClient(aKey, ClientID):
	qGet = MpClientRegKeys.query.filter_by(cuuid=ClientID, regKey=aKey, active=1).first()
	if qGet is not None:
		return True
	else:
		return False

'''
	Check to see if the reg key is valid.

	keyType = 0 = Client, 1 = Group

	Returns a Tuple (True and Row ID)
	-1 for not valid and 0 for groups, they are invalid after valid to date
'''
def isValidRegKey(aKey, AgentConfigDataClientID):

	result = (False, -1)
	qGet = MpRegKeys.query.filter_by(active=1).all()
	if qGet is not None:
		for row in qGet:
			if row.regKey == aKey:
				if isBetweenDates(row.validFromDate, row.validToDate):
					if row.keyType == 0:
						# Client
						if row.keyQuery == ClientID:
							result = (True, row.rid)
							break
					elif row.keyType == 1:
						# Group
						result = (True, 0)
						break

	return result

'''
	Check to see if a date is between 2 others
'''
def isBetweenDates(start, end):
	if start <= datetime.now() <= end:
		# print "in between"
		return True
	else:
		# print "No!"
		return False

'''
	Set the active flag to 0 and set the reg_date that the key was used.
	Client can no longer use this reg key
	OLD
'''
def setClientRegKeyUsed(ClientID, aKey):
	qGet = MpClientRegKeys.query.filter_by(cuuid=ClientID, regKey=aKey, active=1).first()
	setattr(qGet, 'cuuid', ClientID)
	setattr(qGet, 'active', 0)
	setattr(qGet, 'reg_date', datetime.now())
	db.session.commit()

'''
	Set the active flag to 0 and set the reg_date that the key was used.
	Client can no longer use this reg key
'''
def setRegKeyUsed(ClientID, aKey, rid):
	qGet = MpRegKeys.query.filter_by(regKey=aKey, active=1, rid=rid).first()
	if qGet is not None:
		setattr(qGet, 'active', 0)
		db.session.commit()
	else:
		log_Error('[Registration][setRegKeyUsed]: Key (%s) not found.' % (aKey))

'''
	Create the client registration record
	Argument is regInfo, dictionary
	regInfo is what was passed in the body of the post request
'''
def writeRegInfoToDatabase(regInfo, decoded_client_key, enable=1):
	try:
		log_Info('Create Client Registration Data Record')
		regObj = MPAgentRegistration()
		setattr(regObj, 'cuuid', regInfo['cuuid'])
		setattr(regObj, 'enabled', enable)
		setattr(regObj, 'clientKey', decoded_client_key)
		setattr(regObj, 'pubKeyPem', regInfo['CPubKeyPem'])
		setattr(regObj, 'pubKeyPemHash', regInfo['CPubKeyDer'])
		setattr(regObj, 'hostname', regInfo['HostName'])
		setattr(regObj, 'serialno', regInfo['SerialNo'])
		setattr(regObj, 'reg_date', datetime.now())
		log_Debug('Add Registration Data Record')
		db.session.add(regObj)
		db.session.commit()
		return True
	except Exception as e:
		exc_type, exc_obj, exc_tb = sys.exc_info()
		log_Error('[Registration][Post][writeRegInfoToDatabase][Line: %d] Message: %s' % (exc_tb.tb_lineno, e.message))
		db.session.rollback()
		return False

	return False
