import adal
import uuid
import requests
import json
import datetime
from sqlalchemy import text

from . model import MDMIntuneCorporateDevices, MDMIntuneDevices, MDMIntuneConfigProfiles, MDMIntuneLastSync
from . import db

class MPIntune():

	def __init__(self):
		self.app = None
		self.token = None

	def init_app(self, app, user=None):
		self.app = app

	def getAccessToken(self):
		AUTHORITY_URL = self.app.config.get('INTUNE_AUTHORITY_HOST_URL') + '/' + self.app.config.get('INTUNE_TENANT')
		auth_context = adal.AuthenticationContext(AUTHORITY_URL)
		token_response = auth_context.acquire_token_with_username_password(self.app.config.get('INTUNE_RESOURCE'),
		self.app.config.get('INTUNE_USER'),
		self.app.config.get('INTUNE_USER_PASS'),
		self.app.config.get('INTUNE_CLIENT_ID'))

		self.token = token_response['accessToken']

	def getHTTPHeader(self):
		return {'Authorization': 'Bearer ' + self.token,
				'User-Agent': 'adal-python-sample',
				'Accept': 'application/json',
				'Content-Type': 'application/json',
				'client-request-id': str(uuid.uuid4())}

	def getNextLink(self,url,nextLink):
		endpoint = url + "?" + nextLink
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False).json()

		nxtLink = None
		if "@odata.nextLink" in graph_data:
			nxtLink = graph_data["@odata.nextLink"]

		return graph_data["value"], nxtLink

	def GetGroups(self):
		self.getAccessToken()
		groups = []
		macPatchGroupNameFilter='mp_mdm_'

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/groups?$filter=startswith(mailNickname,\'mpt\')'
		self.app.logger.info("[GetGroups]: Start Get Groups")
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[GetGroups]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		json_data = json.loads(graph_data.content)
		groups = json_data['value']
		self.app.logger.info("[GetGroups]: Groups found {}".format(len(groups)))

		# Get all of the paged records
		if "@odata.nextLink" in graph_data:
			_qryStr = graph_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				groups.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break

		return groups

	def GetGroup(self, groupID):
		self.getAccessToken()
		group = {}

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/groups/' + groupID
		self.app.logger.info("[GetGroup]: Start Get Group")
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[GetGroup]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		json_data = json.loads(graph_data.content)
		group = json_data['displayName']
		self.app.logger.info("[GetGroup]: Group found ")

		return group

	def GetGroupMembers(self, groupID):
		self.getAccessToken()
		members = []

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/groups/'+groupID+'/members'
		self.app.logger.info("[GetGroupMembers]: Start Get Group Members")
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[GetGroupMembers]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		json_data = json.loads(graph_data.content)
		members = json_data['value']
		self.app.logger.info("[GetGroupMembers]: Group members found {}".format(len(members)))

		# Get all of the paged records
		if "@odata.nextLink" in graph_data:
			_qryStr = graph_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				members.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break

		return members

	def DeleteMemberFromGroup(self, groupID, deviceID):
		self.getAccessToken()

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/groups/' + groupID + '/members/' + deviceID + '/$ref'
		self.app.logger.info("[DeleteMemberFromGroup]: " + endpoint)
		self.app.logger.info("[DeleteMemberFromGroup]: Start Delete")
		graph_data = requests.delete(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[DeleteMemberFromGroup]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		return

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
		#print(f"token_response: {token_response}")
		self.token = token_response['accessToken']

	def getHTTPHeader(self): 
		x= {'Authorization': 'Bearer ' + self.token,
						'User-Agent': 'adal-python-sample',
						'Accept': 'application/json',
						'Content-Type': 'application/json',
						'client-request-id': str(uuid.uuid4())}
		#print(x)
		return x

#
# Will get all managed/enrolled devices in InTune MDM
# MS Graph API uri: /beta/deviceManagement/managedDevices
# CEH: This method is slow, needs to be changed to sql string in future
#

	def GetEnrolledDevices(self):
		table_columns = MDMIntuneDevices.__table__.columns.keys()
		table_columns.remove('rid')
		print(table_columns)
		return
	
		self.getAccessToken()
		devices = []

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/managedDevices'
		self.app.logger.info("[GetEnrolledDevices]: Start Get Records")
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[GetEnrolledDevices]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		json_data = json.loads(graph_data.content)
		devices = json_data['value']
		self.app.logger.info("[GetEnrolledDevices]: Devices found {}".format(len(devices)))

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

		#self.app.logger.info("[GetEnrolledDevices]: Delete all records in db")
		#num_rows_deleted = MDMIntuneDevices.query.delete()
		#self.app.logger.info("[GetEnrolledDevices]: Deleted rows: " + str(num_rows_deleted))
		self.app.logger.info("[GetEnrolledDevices]: Start Adding Rows")

		isFirst = True
		idList = []
		#table_columns = MDMIntuneDevices.__table__.columns.keys()
		'''
		sqlInsertStr = ""
		
		for i, device in enumerate(devices):
			print(i)

			idList.append(device['id'])
			if isFirst:
				i = i + 1
				sqlInsertStr = self.genSQLInsertAlt(MDMIntuneDevices().__table__, table_columns, device)
				isFirst = False
			else:
				sqlInsertStr = sqlInsertStr + "," + self.genSQLInsertAlt(MDMIntuneDevices().__table__, table_columns, device, onlyData=True)

			if i % 1000 == 0:
				sqlInsertStr = sqlInsertStr + ";"
				print(sqlInsertStr)
				with db.engine.connect() as conn:
					conn.execute(text(sqlInsertStr))
				isFirst = True
		print("Run it")
		sqlInsertStr = sqlInsertStr + ";"
		print(sqlInsertStr)
		with db.engine.connect() as conn:
			conn.execute(sqlInsertStr)
		# Build the uuid quey str now
		print("commit")
		db.session.commit()
		print("commited")
 		'''
		
		# MDMIntuneDevices
		print(table_columns)
		for i, device in enumerate(devices):
			_dev = {tc: device[tc] for tc in table_columns}
			print(_dev)
			break


		return

		#for device in devices:
		#	if isFirst:
		#		sqlInsertStr = self.genSQLInsertAlt(MDMIntuneDevices().__table__, table_columns, device)
		#		isFirst = False

		#	udid = None
		#	new_device = MDMIntuneDevices()
		#	for key in device:
		#		setattr(new_device, key, device[key])

		#	udid = self.getUDIDForDeviceID(device['id'])
		#	if udid is not None:
		#		setattr(new_device, 'udid', udid)
		#	db.session.add(new_device)
		#db.session.commit()


		self.app.logger.info("[GetEnrolledDevices]: Stop Adding Rows")
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
		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/importedDeviceIdentities'
		self.app.logger.info("[SA][GetCorpDevices]: Start Get Records")

		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[GetCorpDevices]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		json_data = json.loads(graph_data.content)
		devices = json_data['value']
		if "@odata.nextLink" in json_data:
			_qryStr = json_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				devices.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break
		self.app.logger.info("[GetCorpDevices]: Delete all records in db")
		num_rows_deleted = MDMIntuneCorporateDevices.query.delete()
		db.session.commit()
		self.app.logger.info("[GetCorpDevices] Deleted rows: " + str(num_rows_deleted))
		self.app.logger.info("[GetCorpDevices]: Start Adding Rows")
		sqlInsertStr = ""
		isFirst = True

		_records = []
		for i, device in enumerate(devices):
			_records.append(MDMIntuneCorporateDevices(**device))
  
		db.session.add_all(_records)
		db.session.commit()

		self.app.logger.info("[GetCorpDevices]: Stop Adding Rows")
		self.AddLastSync(MDMIntuneCorporateDevices.__tablename__,'MDMIntuneCorporateDevices',self.user)

#
# Will get all devices configuration profiles of type microsoft.graph.macOSCustomConfiguration in InTune MDM
# MS Graph API uri: /beta/deviceManagement/deviceConfigurations?$filter=isof('microsoft.graph.macOSCustomConfiguration')
#
	def GetDeviceConfigProfiles(self):
		self.getAccessToken()

		devices = []
		endpoint = self.app.config.get('INTUNE_RESOURCE') + "/v1.0/deviceManagement/deviceConfigurations?$filter=isof('microsoft.graph.macOSCustomConfiguration')"
		print(endpoint)
		self.app.logger.info("[GetDeviceConfigProfiles]: Start Get Records")
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[GetDeviceConfigProfiles]: Error getting InTune data error code {}".format(graph_data.status_code))
			return

		json_data = json.loads(graph_data.content)
		profiles = json_data['value']
		if "@odata.nextLink" in graph_data:
			_qryStr = graph_data["@odata.nextLink"].split("?")[1]
			while True:
				res = self.getNextLink(endpoint,_qryStr)
				profiles.extend(res[0])
				if res[1] is not None:
					_qryStr = res[1].split("?")[1]
				else:
					break
		self.app.logger.info("[GetDeviceConfigProfiles]: Delete all records in db")
		num_rows_deleted = MDMIntuneConfigProfiles.query.delete()
		db.session.commit()

		self.app.logger.info("[GetDeviceConfigProfiles] Deleted rows: " + str(num_rows_deleted))
		self.app.logger.info("[GetDeviceConfigProfiles]: Start Adding Rows")
		sqlInsertStr = ""
		isFirst = True

		import pprint
		_records = []
		for i, profile in enumerate(profiles):
			del profile['@odata.type']
			_records.append(MDMIntuneConfigProfiles(**profile))
		
		db.session.add_all(_records)
		db.session.commit()

		self.app.logger.info("[GetDeviceConfigProfiles]: Stop Adding Rows")
		self.AddLastSync(MDMIntuneConfigProfiles.__tablename__,'MDMIntuneConfigProfiles',self.user)
		return

#
# MS Graph API has a limit of a Max 1000 returned results
# the next link is the @odata.nextLink for the next page
# of results.
#
# To use this pass the endpoint and the next link query string
# everything after the ?
	def getNextLink(self,url,nextLink):
		endpoint = url + "?" + nextLink
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False).json()

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
				elif isinstance(value, list):
					_valStr = "null"
				elif isinstance(value, dict):
					continue
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

	def genSQLInsertAlt(self, tableName, columns, row, onlyData=False):

		_sqlArrCol = []
		_sqlArrVal = []
		_sqlStrPre = "INSERT INTO {}".format(tableName)
		_sqlStr = ''

		for col in columns:
			col = col.name
			if col == 'rid':
				continue
			else:
				if col in row:
					if not onlyData:
						_sqlArrCol.append(col)

					value = row[col]
					if isinstance(value, bool):
						_valStr = "{}".format(value)
					elif isinstance(value, int):
						_valStr = "'{}'".format(str(value))
					elif isinstance(value, list):
						continue
					elif isinstance(value, dict):
						continue
					else:
						if value is None:
							_valStr = "null"
						else:
							_valStr = "'%s'" % (value.replace("'", "\\'"))

					_sqlArrVal.append(_valStr)

		# Loop through and add the rest

		# Build the SQL string
		if onlyData:
			_sqlStr = "(%s)" % (','.join(_sqlArrVal))
		else:
			_sqlStr = "%s (%s) Values (%s)" % (_sqlStrPre, ','.join(_sqlArrCol),','.join(_sqlArrVal))

		return _sqlStr

	# Work around function as managedDevice does not return a value for udid
	# Eventually this will no longer be needed
	# /beta/deviceManagement/managedDevices('483fe593-8556-4d06-856c-a66d43628c08')?select=udid
	def getUDIDForDeviceID(self,deviceID):
		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/managedDevices(\''+deviceID+'\')?select=udid'
		graph_data = requests.get(endpoint, headers=self.getHTTPHeader(), stream=False)
		if graph_data.ok != True:
			self.app.logger.error("[getUDIDForDeviceID]: Error getting InTune data error code {}".format(graph_data.status_code))
			return
		else:
			graph_data = graph_data.json()

		udid = None
		if 'udid' in graph_data:
			udid = graph_data['udid']

		return  udid

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

		endpoint = self.app.config.get('INTUNE_RESOURCE') + '/beta/deviceManagement/importedDeviceIdentities/importDeviceIdentityList'
		graph_data = requests.post(endpoint, headers=self.getHTTPHeader(), stream=False, data=json.dumps(deviceData))
		if graph_data.ok != True:
			self.app.logger.error("[AddCorporateDevice]: Error adding InTune data error code {}".format(graph_data.status_code))
			return None

		return graph_data.json()

	def AddLastSync(self,table,modelTable,user):
		lastSync = MDMIntuneLastSync()

		setattr(lastSync, 'lastSyncDateTime', datetime.datetime.now())
		setattr(lastSync, 'tableName', table)
		setattr(lastSync, 'modelTableName', modelTable)
		setattr(lastSync, 'syncUser', user)

		db.session.add(lastSync)
		db.session.commit()