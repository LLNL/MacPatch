import adal
import uuid
import requests
import json
import datetime
from sqlalchemy import text

from . model import MDMIntuneCorporateDevices, MDMIntuneDevices, MDMIntuneConfigProfiles, MDMIntuneLastSync
from . import db
from . mplogger import *

class MPTaskJobs():

	def __init__(self):
		self.app = None
		self.token = None
		self.user = "Task"

	def init_app(self, app, user=None):
			self.app = app
			if user is not None:
				self.user = user

	def getAccessToken(self):

		AUTHORITY_URL = self.app.config.get('INTUNE_AUTHORITY_HOST_URL') + '/' + self.app.config.get('INTUNE_TENANT')
		auth_context = adal.AuthenticationContext(AUTHORITY_URL)
		token_response = auth_context.acquire_token_with_username_password(self.app.config.get('INTUNE_RESOURCE'),
		self.app.config.get('INTUNE_USER'),
		self.app.config.get('INTUNE_USER_PASS'),
		self.app.config.get('INTUNE_CLIENT_ID'))

		self.token = token_response['accessToken']

#
# Will get all managed/enrolled devices in InTune MDM
# MS Graph API uri: /beta/deviceManagement/managedDevices
# CEH: This method is slow, needs to be changed to sql string in future
#
	def GetEnrolledDevices(self):
		self.getAccessToken()
		devices = []

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/managedDevices'
		http_headers = {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}
		log("[GetEnrolledDevices]: Start Get Records")
		graph_data = requests.get(endpoint, headers=http_headers, stream=False)
		json_data = json.loads(graph_data.content)
		devices = json_data['value']

		# Get all of the paged records
		if "@odata.nextLink" in graph_data:
			_qryStr = graph_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				devices.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break

		log("[GetEnrolledDevices]: Delete all records in db")
		num_rows_deleted = MDMIntuneDevices.query.delete()
		log("[GetEnrolledDevices]: Deleted rows: " + str(num_rows_deleted))
		log("[GetEnrolledDevices]: Start Adding Rows")
		for device in devices:
			udid = None
			new_device = MDMIntuneDevices()
			for key in device:
				setattr(new_device, key, device[key])

			udid = self.getUDIDForDeviceID(device['id'])
			if udid is not None:
				setattr(new_device, 'udid', udid)
			db.session.add(new_device)
		db.session.commit()

		log("[GetEnrolledDevices]: Stop Adding Rows")
		self.AddLastSync(MDMIntuneDevices.__tablename__,'MDMIntuneDevices',self.user)

#
# Will get all corporate devices in InTune MDM
# This is needed for enrolling new devices, cant enroll unless the
# serial number for the devices is present.
# MS Graph API uri: /beta/deviceManagement/importedDeviceIdentities
#
	def GetCorpDevices(self):
		self.getAccessToken()

		devices = []
		# https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities
		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/importedDeviceIdentities'
		http_headers = {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}
		log("[GetCorpDevices]: Start Get Records")
		graph_data = requests.get(endpoint, headers=http_headers, stream=False).json()

		devices = graph_data["value"]
		if "@odata.nextLink" in graph_data:
			_qryStr = graph_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				devices.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break
		log("[GetCorpDevices]: Delete all records in db")
		num_rows_deleted = MDMIntuneCorporateDevices.query.delete()
		db.session.commit()
		log("[GetCorpDevices] Deleted rows: " + str(num_rows_deleted))
		log("[GetCorpDevices]: Start Adding Rows")
		sqlInsertStr = ""
		isFirst = True

		for i, device in enumerate(devices):
			if isFirst:
				sqlInsertStr = self.genSQLInsert('mdm_intune_corporate_devices',device)
				isFirst = False
			else:
				sqlInsertStr = sqlInsertStr + "," + self.genSQLInsert('mdm_intune_corporate_devices',device,onlyData=True)
			if i % 1000 == 0:
				sqlInsertStr = sqlInsertStr + ";"
				with db.engine.connect() as sql_con:
					sql_con.execute(text(sqlInsertStr))
				isFirst = True

		sqlInsertStr = sqlInsertStr + ";"
		with db.engine.connect() as sql_con:
			sql_con.execute(text(sqlInsertStr))

		db.session.commit()
		log("[GetCorpDevices]: Stop Adding Rows")

		self.AddLastSync(MDMIntuneCorporateDevices.__tablename__,'MDMIntuneCorporateDevices',self.user)

#
# Will get all devices configuration profiles of type microsoft.graph.macOSCustomConfiguration in InTune MDM
# MS Graph API uri: /beta/deviceManagement/deviceConfigurations?$filter=isof('microsoft.graph.macOSCustomConfiguration')
#
	def GetDeviceConfigProfiles(self):
		self.getAccessToken()

		devices = []
		endpoint = self.app.config.get('INTUNE_RESOURCE') + "/beta/deviceManagement/deviceConfigurations?$filter=isof('microsoft.graph.macOSCustomConfiguration')"
		http_headers = {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}
		log("[GetDeviceConfigProfiles]: Start Get Records")
		graph_data = requests.get(endpoint, headers=http_headers, stream=False).json()

		profiles = graph_data["value"]
		if "@odata.nextLink" in graph_data:
			_qryStr = graph_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				profiles.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break
		log("[GetDeviceConfigProfiles]: Delete all records in db")
		num_rows_deleted = MDMIntuneConfigProfiles.query.delete()
		db.session.commit()

		log("[GetDeviceConfigProfiles] Deleted rows: " + str(num_rows_deleted))
		log("[GetDeviceConfigProfiles]: Start Adding Rows")
		sqlInsertStr = ""
		isFirst = True

		for i, profile in enumerate(profiles):
			if isFirst:
				sqlInsertStr = self.genSQLInsert('mdm_intune_devices_config_profiles',profile)
				isFirst = False
			else:
				sqlInsertStr = sqlInsertStr + "," + self.genSQLInsert('mdm_intune_devices_config_profiles',profile,onlyData=True)
			if i % 1000 == 0:
				sqlInsertStr = sqlInsertStr + ";"
				with db.engine.connect() as sql_con:
					sql_con.execute(text(sqlInsertStr))
				isFirst = True

		sqlInsertStr = sqlInsertStr + ";"
		with db.engine.connect() as sql_con:
			sql_con.execute(text(sqlInsertStr))
		db.session.commit()
		log("[GetDeviceConfigProfiles]: Stop Adding Rows")

		self.AddLastSync(MDMIntuneConfigProfiles.__tablename__,'MDMIntuneConfigProfiles',self.user)

#
# MS Graph API has a limit of a Max 1000 returned results
# the next link is the @odata.nextLink for the next page
# of results.
#
# To use this pass the endpoint and the next link query string
# everything after the ?
	def getNextLink(self,url,nextLink):
		endpoint = url + "?" + nextLink
		http_headers = {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}
		graph_data = requests.get(endpoint, headers=http_headers, stream=False).json()

		nxtLink = None
		if "@odata.nextLink" in graph_data:
			nxtLink = graph_data["@odata.nextLink"]

		return graph_data["value"], nxtLink

	def genSQLInsert(self, tableName, row, onlyData=False):

		_sqlArrCol = []
		_sqlArrVal = []
		_sqlStrPre = "INSERT INTO {}".format(tableName)
		_sqlStr = ''

		# Loop through and add the rest
		for key, value in row.items():
			if key == 'rid':
				continue
			elif "@odata" in key:
				continue
			else:
				if not onlyData:
					_colStr = "`%s`" % (key)
					_sqlArrCol.append(_colStr)

				if isinstance(value, list):
					_valStr = "'{}'".format(json.dumps(value))
				elif isinstance(value, bool):
					_valStr = "{}".format(value)
				elif isinstance(value, int):
					_valStr = "'{}'".format(str(value))
				else:
					if value is None:
						_valStr = "null"
					else:
						_valStr = "'%s'" % (value.replace("'", "\\'"))

				_sqlArrVal.append(_valStr)

		# Build the SQL string
		if onlyData:
			_sqlStr = "(%s)" % (','.join(_sqlArrVal))
		else:
			_sqlStr = "%s (%s) Values (%s)" % (_sqlStrPre, ','.join(_sqlArrCol),','.join(_sqlArrVal))

		return _sqlStr

	def getUDIDForDeviceID(self,deviceID):
		# Work around function as managedDevice does not return a value for udid
		# Eventually this will no longer be needed
		# /beta/deviceManagement/managedDevices('483fe593-8556-4d06-856c-a66d43628c08')?select=udid
		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/managedDevices(\''+deviceID+'\')?select=udid'
		http_headers = {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}
		graph_data = requests.get(endpoint, headers=http_headers, stream=False).json()
		udid = None
		if 'udid' in graph_data:
			udid = graph_data['udid']

		return  udid
#
# Will add a last sync db record for a given task.
#
	def AddCorporateDevice(self, serialno, description):
		self.getAccessToken()

		deviceData = {
		'overwriteImportedDeviceIdentities': True,
		'importedDeviceIdentities': [ {
		'importedDeviceIdentifier': serialno,
		'importedDeviceIdentityType': 'serialNumber',
		'lastContactedDateTime': '0001-01-01T00:00:00Z',
		'description': description,
		'enrollmentState': 'notContacted',
		'platform': 'unknown' } ] }

		self.app.logger.info("Add Corporate Device to InTune")
		self.app.logger.info("Adding serial no {} for {}".format(serialno, description))

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/importedDeviceIdentities/importDeviceIdentityList'
		http_headers = {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}

		graph_data = requests.post(endpoint, headers=http_headers, stream=False, data=json.dumps(deviceData)).json()
		self.app.logger.info("POST Result: {}".format(graph_data))
		return graph_data

	def AddLastSync(self,table,modelTable,user):
		lastSync = MDMIntuneLastSync()

		setattr(lastSync, 'lastSyncDateTime', datetime.datetime.now())
		setattr(lastSync, 'tableName', table)
		setattr(lastSync, 'modelTableName', modelTable)
		setattr(lastSync, 'syncUser', user)

		db.session.add(lastSync)
		db.session.commit()