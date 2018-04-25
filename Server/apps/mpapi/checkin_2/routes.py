from flask import request, current_app
from flask_restful import reqparse
from sqlalchemy.exc import IntegrityError
from datetime import datetime
import syslog

from . import *
from .. import db
from .. mputil import *
from .. model import *
from .. mplogger import *

from .. register.routes import Registration

parser = reqparse.RequestParser()

# Client Info/Status
class AgentStatus(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		super(AgentStatus, self).__init__()

	def get(self,client_id):
		try:

			if not isValidClientID(client_id):
				log_Error('[AgentStatus][Get]: Failed to verify ClientID (%s)' % (client_id))
				return {"result": {'data': {}, 'type':'AgentStatus'}, "errorno": 424, "errormsg": 'Failed to verify ClientID'}, 424

			if not isValidSignature(self.req_signature, client_id, self.req_uri, self.req_ts):
				if current_app.config['ALLOW_MIXED_SIGNATURES'] == True:
					log_Info('[AgentStatus][Get]: ALLOW_MIXED_SIGNATURES is enabled.')
				else:
					log_Error('[AgentStatus][Get]: Failed to verify Signature for client (%s)' % (client_id))
					return {"result": {'data': {}, 'type':'AgentStatus'}, "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			client_obj = MpClient.query.filter_by(cuuid=client_id).first()

			if client_obj:
				if "POST_CHECKIN_TO_SYSLOG" in current_app.config:
					if current_app.config['POST_CHECKIN_TO_SYSLOG'] == True:
						self.postClientDataToSysLog(client_obj)

				_mdate = "{:%B %d, %Y %H:%M:%S}".format(client_obj.mdate)
				_mdateAlt = "{:%m/%d/%Y %H:%M:%S}".format(client_obj.mdate)
				res = {'mdate1':_mdate, 'mdate2': _mdateAlt}
				return {"result": {'data': res, 'type':'AgentStatus'}, "errorno": 0, "errormsg": 'none'}, 200
			else:
				log_Error('[AgentStatus][Get]: Client (%s) not found' % (client_id))
				return {"result": {'data': {}, 'type':'AgentStatus'}, "errorno": 404, "errormsg": 'Client not found.'}, 404

		except IntegrityError, exc:
			log_Error('[AgentStatus][Get][IntegrityError]: client_id: %s Message: %s' % (client_id, exc.message))
			return {"result": {'data': {}, 'type':'AgentStatus'}, "errorno": 500, "errormsg": exc.message}, 500
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			log_Error('[AgentStatus][Get][Exception][Line: %d] client_id: %s Message: %s' % (exc_tb.tb_lineno, client_id, e.message))
			return {'errorno': 500, 'errormsg': e.message, 'result': {'data': {}, 'type':'AgentStatus'}}, 500

	def postClientDataToSysLog(self, client_obj):
		# Collection for Syslog and Splunk

		dataStr = "client_id: {}, hostname: {}, ip: {}, mac_address: {}, fileVault_status: {}, os_ver: {}, loggedin_user: {}".format(client_obj.cuuid,
																																	 client_obj.hostname,
																																	 client_obj.ipaddr,
																																	 client_obj.macaddr,
																																	 client_obj.fileVaultStatus,
																																	 client_obj.osver,
																																	 client_obj.consoleuser)
		syslog.syslog(dataStr)
		return

# Add Routes Resources
checkin_2_api.add_resource(AgentStatus, '/client/checkin/info/<string:client_id>')