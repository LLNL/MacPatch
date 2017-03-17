from flask import request
from flask_restful import reqparse
from sqlalchemy.exc import IntegrityError

from . import *
from .. import db
from .. mputil import *
from .. model import *
from .. mplogger import *

parser = reqparse.RequestParser()

class PatchGroups(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		super(PatchGroups, self).__init__()

	def get(self, cuuid):
		try:
			if self.req_agent == 'iLoad':
				log_Info("[PatchGroups][Get]: iLoad Request from %s" % (cuuid))
			else:
				if not isValidClientID(cuuid):
					log_Error('[PatchGroups][Get]: Failed to verify ClientID (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify ClientID'}, 424

				if not isValidSignature(self.req_signature, cuuid, self.req_uri, self.req_ts):
					log_Error('[PatchGroups][Get]: Failed to verify Signature for client (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			qGet = MpPatchGroup.query.with_entities(MpPatchGroup.name).distinct('name').all()

			groups = []
			if qGet is not None:
				for row in qGet:
					groups.append(row[0])
			else:
				return {"result": [], "errorno": 0, "errormsg": 'No data found.'}, 204

			log_Debug('[PatchGroups][Get]: Result: %s' % (groups))
			return {"result": groups, "errorno": 0, "errormsg": ''}, 200

		except IntegrityError, exc:
			log_Error('[PatchGroups][Get][IntegrityError] CUUID: %s Message: %s' % (cuuid, exc.message))
			return {"result": '', "errorno": 500, "errormsg": exc.message}, 500
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			log_Error('[PatchGroups][Get][Exception][Line: %d] CUUID: %s Message: %s' % (exc_tb.tb_lineno, cuuid, e.message))
			return {'errorno': 500, 'errormsg': e.message, 'result': ''}, 500


class ClientGroups(MPResource):

	def __init__(self):
		self.reqparse = reqparse.RequestParser()
		super(ClientGroups, self).__init__()

	def get(self, cuuid):
		try:
			if self.req_agent == 'iLoad':
				log_Info("[ClientGroups][Get]: iLoad Request from %s" % (cuuid))
			else:
				if not isValidClientID(cuuid):
					log_Error('[ClientGroups][Get]: Failed to verify ClientID (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify ClientID'}, 424

				if not isValidSignature(self.req_signature, cuuid, self.req_uri, self.req_ts):
					log_Error('[ClientGroups][Get]: Failed to verify Signature for client (%s)' % (cuuid))
					return {"result": '', "errorno": 424, "errormsg": 'Failed to verify Signature'}, 424

			qGet = MpClientPlist.query.with_entities(MpClientPlist.Domain).distinct('Domain').all()

			groups = []
			if qGet is not None:
				for row in qGet:
					groups.append(row[0])
			else:
				return {"result": [], "errorno": 0, "errormsg": 'No data found.'}, 204

			log_Debug('[ClientGroups][Get]: Result: %s' % (groups))
			return {"result": groups, "errorno": 0, "errormsg": ''}, 200

		except IntegrityError, exc:
			log_Error('[ClientGroups][Get][IntegrityError] CUUID: %s Message: %s' % (cuuid, exc.message))
			return {"result": '', "errorno": 500, "errormsg": exc.message}, 500
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			log_Error('[ClientGroups][Get][Exception][Line: %d] CUUID: %s Message: %s' % (exc_tb.tb_lineno, cuuid, e.message))
			return {'errorno': 500, 'errormsg': e.message, 'result': ''}, 500

# Add Routes Resources
provisioning_api.add_resource(PatchGroups,     '/provisioning/groups/patch/<string:cuuid>')
provisioning_api.add_resource(ClientGroups,    '/provisioning/groups/client/<string:cuuid>')
