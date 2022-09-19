from flask import request, current_app
from flask_restful import reqparse
from sqlalchemy.exc import IntegrityError
import datetime
import json
import sys

from . import *
from .. import db
from .. mputil import *
from .. model import *
from .. mplogger import *

parser = reqparse.RequestParser()

class AddInventoryData(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		super(AddInventoryData, self).__init__()

	def post(self, cuuid):

		if not isValidClientID(cuuid):
			log_Error('[AddInventoryData][Post]: Failed to verify ClientID (%s)' % (cuuid))
			return {"result": '', "errorno": 412, "errormsg": 'Failed to verify ClientID'}, 412

		if not isValidSignature(self.req_signature, cuuid, request.data, self.req_ts):
			log_Error('[AddInventoryData][Post]: Failed to verify Signature for client (%s)' % (cuuid))
			return {"result": '', "errorno": 412, "errormsg": 'Failed to verify Signature'}, 412

		_server_config = current_app.config['MP_SETTINGS']['server']
		log_Debug('[AddInventoryData][Post]: _server_config = %s' % (_server_config))
		_dt = datetime.now().strftime('%Y%m%d%H%M%S')

		jData = request.get_json(force=True)
		if jData:
			try:
				if 'inventory_dir' in _server_config:

					_file_Dir = os.path.join(_server_config['inventory_dir'], 'files')
					log_Debug('[AddInventoryData][Post]: _file_Dir = %s' % (_file_Dir))
					if not os.path.exists(_file_Dir):
						log_Debug('[AddInventoryData][Post]: Create _file_Dir: %s' % (_file_Dir))
						os.makedirs(_file_Dir)

					if os.path.exists(_file_Dir):
						log_Debug('[AddInventoryData][Post]: Save Inventory Data to file')
						_file_str = (str(_dt), jData['table'], ".mpd")
						_file_Name = "_".join(_file_str)
						_file_Path = os.path.join(_file_Dir, _file_Name)
						log_Debug('[AddInventoryData][Post]: file = %s' % (_file_Path))
						with open(_file_Path, 'w') as outfile:
							json_string = json.dumps(jData)
							log_Debug('[AddInventoryData][Post]: json_string = %s' % (json_string))
							outfile.write(json_string)

						log_Info('[AddInventoryData][Post]: Writing inventory file (%s) to disk.' % (_file_Name))

					return {"result": '', "errorno": 0, "errormsg": ''}, 201

				else:
					log_Error('[AddInventoryData][Post]: Inventory directory object not found in config.')
					return {"result": '', "errorno": 412, "errormsg": 'Inventory directory object not found in config.'}, 412

			except Exception as e:
				exc_type, exc_obj, exc_tb = sys.exc_info()
				message=str(e.args[0]).encode("utf-8")
				log_Error('[AddInventoryData][Post][Exception][Line: {}] CUUID: {} Message: {}'.format(exc_tb.tb_lineno, cuuid, message))
				return {'errorno': 500, 'errormsg': message, 'result': {}}, 500

		log_Error('[AddInventoryData][Post]: Inventory data is empty.')
		return {"result": '', "errorno": 412, "errormsg": 'Inventory Data empty'}, 412


class InventoryState(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		super(InventoryState, self).__init__()

	def get(self, client_id):

		try:
			if not isValidClientID(client_id):
				log_Error('[InventoryState][Get]: Failed to verify ClientID (%s)' % (client_id))
				return {"result": {'data': False}, "errorno": 412, "errormsg": 'Failed to verify ClientID'}, 412

			if not isValidSignature(self.req_signature, client_id, self.req_uri, self.req_ts):
				log_Error('[InventoryState][Get]: Failed to verify Signature for client (%s)' % (client_id))
				return {"result": {'data': False}, "errorno": 412, "errormsg": 'Failed to verify Signature'}, 412

			_result = False
			q_result = MpInvState.query.filter(MpInvState.cuuid == client_id).first()
			if q_result is not None:
				if q_result.cuuid == client_id:
					_result = True

			return {'errorno': '0', 'errormsg': '', 'result': {'data': _result}}, 200

		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			message=str(e.args[0]).encode("utf-8")
			log_Error('[InventoryState][Get][Exception][Line: {}] CUUID: {} Message: {}'.format(exc_tb.tb_lineno, client_id, message))
			return {'errorno': 500, 'errormsg': message, 'result': {}}, 500

	def post(self, client_id):
		try:
			if not isValidClientID(client_id):
				log_Error('[InventoryState][Post]: Failed to verify ClientID (%s)' % (client_id))
				return {"result": '', "errorno": 424, "errormsg": 'Failed to verify ClientID'}, 424

			if not isValidSignature(self.req_signature, client_id, self.req_uri, self.req_ts):
				log_Error('[InventoryState][Post]: Failed to verify Signature for client (%s)' % (client_id))
				return {"result": '', "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			try:
				q_InvObj = MpInvState.query.filter(MpInvState.cuuid == client_id).first()
				if q_InvObj is None:
					# Add
					_mpInvObj = MpInvState()

					setattr(_mpInvObj, 'cuuid', client_id)
					setattr(_mpInvObj, 'mdate', datetime.now())

					db.session.add(_mpInvObj)
					db.session.commit()

				return {'errorno': '0', 'errormsg': '', 'result': {'data': True}}, 200

			except IntegrityError as exc:
				db.engine.rollback()
				log_Error('[except] client_id: %s Message: %s' % (client_id, exc.message))
				return {'errorno': 500, 'errormsg': exc.message, 'result': {'data': False}}, 500

		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			message=str(e.args[0]).encode("utf-8")
			log_Error('[InventoryState][Post][Exception][Line: {}] CUUID: {} Message: {}'.format(exc_tb.tb_lineno, client_id, message))
			return {'errorno': 500, 'errormsg': message, 'result': {}}, 500
	


# Add Routes Resources
inventory_2_api.add_resource(AddInventoryData,    '/client/inventory/<string:client_id>')
inventory_2_api.add_resource(InventoryState,      '/client/inventory/state/<string:client_id>')
