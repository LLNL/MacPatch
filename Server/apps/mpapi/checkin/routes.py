from flask import request
from flask_restful import reqparse
from sqlalchemy.exc import IntegrityError
from datetime import datetime

from . import *
from .. import db
from .. mputil import *
from .. model import *
from .. mplogger import *

parser = reqparse.RequestParser()

# Client Reg Process
class AgentBase(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		mpc = MpClient()
		for column in mpc.columns:
			self.reqparse.add_argument(column, type=str, required=False, location='json')

		super(AgentBase, self).__init__()

	def post(self, cuuid):

		try:
			args = self.reqparse.parse_args()
			_body = request.get_json(silent=True)

			if not isValidSignature(self.req_signature, cuuid, request.data, self.req_ts):
				if current_app.config['ALLOW_MIXED_SIGNATURES']:
					log_Info('[AgentBase][Post]: ALLOW_MIXED_SIGNATURES is enabled.')
				else:
					log_Error('[AgentBase][Post]: Failed to verify Signature for client (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			client_obj = MpClient.query.filter_by(cuuid=cuuid).first()
			log_Debug('[AgentBase][Post]: Client (%s) Data %s' % (cuuid, _body))

			if client_obj:
				# Update
				log_Info('[AgentBase][Post]: Updating client (%s) record.' % (cuuid))
				for col in client_obj.columns:
					if col == 'mdate':
						setattr(client_obj, col, datetime.now())
					else:
						setattr(client_obj, col, args[col])

				db.session.commit()
				return {"result": '', "errorno": 0, "errormsg": 'none'}, 201
			else:
				# Add
				log_Info('[AgentBase][Post]: Adding client (%s) record.' % (cuuid))
				client_object = MpClient()
				# print client_object.columns

				client_object.cuuid = cuuid
				for col in client_object.columns:
					if col == 'mdate':
						setattr(client_object, col, datetime.now())
					else:
						setattr(client_object, col, args[col])

				db.session.add(client_object)
				db.session.commit()
				return {"result": '', "errorno": 0, "errormsg": 'none'}, 201

		except IntegrityError, exc:
			log_Error('[AgentBase][Post][IntegrityError]: CUUID: %s Message: %s' % (cuuid, exc.message))
			return {"result": '', "errorno": 500, "errormsg": exc.message}, 500
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			log_Error('[AgentBase][Post][Exception][Line: %d] CUUID: %s Message: %s' % (
				exc_tb.tb_lineno, cuuid, e.message))
			return {'errorno': 500, 'errormsg': e.message, 'result': ''}, 500


# Client Reg Status
class AgentPlist(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		mpc = MpClientPlist()
		for column in mpc.columns:
			self.reqparse.add_argument(column, type=str, required=False, location='json')

		super(AgentPlist, self).__init__()

	def post(self, cuuid):
		try:
			args = self.reqparse.parse_args()
			_body = request.get_json(silent=True)

			if not isValidClientID(cuuid):
				log_Error('[AgentPlist][Post]: Failed to verify ClientID (%s)' % (cuuid))
				return {"result": '', "errorno": 424, "errormsg": 'Failed to verify ClientID'}, 424

			if not isValidSignature(self.req_signature, cuuid, request.data, self.req_ts):
				if current_app.config['ALLOW_MIXED_SIGNATURES'] == True:
					log_Info('[AgentPlist][Post]: ALLOW_MIXED_SIGNATURES is enabled.')
				else:
					log_Error('[AgentPlist][Post]: Failed to verify Signature for client (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			client_obj = MpClientPlist.query.filter_by(cuuid=cuuid).first()
			log_Debug('[AgentPlist][Post]: Client (%s) Data %s' % (cuuid, _body))

			if client_obj:
				# Update
				log_Info('[AgentPlist][Post]: Updating client (%s) record.' % (cuuid))
				for col in client_obj.columns:
					if col == 'mdate':
						setattr(client_obj, col, datetime.now())
					else:
						setattr(client_obj, col, args[col])

				db.session.commit()
				return {"result": '', "errorno": 0, "errormsg": 'none'}, 201
			else:
				# Add
				log_Info('[AgentPlist][Post]: Adding client (%s) record.' % (cuuid))
				client_object = MpClientPlist()
				print client_object.columns

				client_object.cuuid = cuuid
				for col in client_object.columns:
					if col == 'mdate':
						setattr(client_object, col, datetime.now())
					else:
						setattr(client_object, col, args[col])

				db.session.add(client_object)
				db.session.commit()
				return {"result": '', "errorno": 0, "errormsg": 'none'}, 201

		except IntegrityError, exc:
			log_Error('[AgentPlist][Post][IntegrityError]: CUUID: %s Message: %s' % (cuuid, exc.message))
			return {"result": '', "errorno": 500, "errormsg": exc.message}, 500
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			log_Error('[AgentPlist][Post][Exception][Line: %d] CUUID: %s Message: %s' % (exc_tb.tb_lineno, cuuid, e.message))
			return {'errorno': 500, 'errormsg': e.message, 'result': ''}, 500


# Client Info/Status
class AgentStatus(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		super(AgentStatus, self).__init__()

	def get(self,cuuid):
		try:

			if not isValidClientID(cuuid):
				log_Error('[AgentStatus][Get]: Failed to verify ClientID (%s)' % (cuuid))
				return {"result": '', "errorno": 424, "errormsg": 'Failed to verify ClientID'}, 424

			if not isValidSignature(self.req_signature, cuuid, self.req_uri, self.req_ts):
				if current_app.config['ALLOW_MIXED_SIGNATURES'] == True:
					log_Info('[AgentStatus][Get]: ALLOW_MIXED_SIGNATURES is enabled.')
				else:
					log_Error('[AgentStatus][Get]: Failed to verify Signature for client (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			client_obj = MpClient.query.filter_by(cuuid=cuuid).first()

			if client_obj:

				_mdate = "{:%B %d, %Y %H:%M:%S}".format(client_obj.mdate)
				_mdateAlt = "{:%m/%d/%Y %H:%M:%S}".format(client_obj.mdate)
				res = {'mdate1':_mdate, 'mdate2': _mdateAlt}
				return {"result": res, "errorno": 0, "errormsg": 'none'}, 200
			else:
				log_Error('[AgentStatus][Get]: Client (%s) not found' % (cuuid))
				return {"result": '', "errorno": 404, "errormsg": 'Client not found.'}, 404

		except IntegrityError, exc:
			log_Error('[AgentStatus][Get][IntegrityError]: CUUID: %s Message: %s' % (cuuid, exc.message))
			return {"result": '', "errorno": 500, "errormsg": exc.message}, 500
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			log_Error('[AgentStatus][Get][Exception][Line: %d] CUUID: %s Message: %s' % (exc_tb.tb_lineno, cuuid, e.message))
			return {'errorno': 500, 'errormsg': e.message, 'result': ''}, 500



# Add Routes Resources
checkin_api.add_resource(AgentBase, '/client/checkin/<string:cuuid>')
checkin_api.add_resource(AgentPlist, '/client/checkin/plist/<string:cuuid>')

checkin_api.add_resource(AgentStatus, '/client/checkin/info/<string:cuuid>')
