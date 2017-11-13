import json
import hashlib
from M2Crypto import RSA, util

from . model import MpSiteKeys

class WSResult():

	def __init__(self):
		self.errorno = 0
		self.errormsg = ''
		self.data = {}
		self.signature = ''

	def resultWithSignature(self, **kwargs):
		self.data = kwargs.get('data', self.data)

		_dict = {}
		_dict['errorno'] = kwargs.get('errorno', self.errorno)
		_dict['errormsg'] = kwargs.get('errormsg', self.errormsg)
		_dict['result'] = self.data
		_dict['signature'] = self.genSignature()

		return _dict

	def resultNoSignature(self, **kwargs):
		_dict = {}
		_dict['errorno'] = kwargs.get('errorno', self.errorno)
		_dict['errormsg'] = kwargs.get('errormsg', self.errormsg)
		_dict['result'] = kwargs.get('data', self.data)
		_dict['signature'] = 'NA'

		return _dict

	def genSignature(self):
		if self.data['data'] is not None:
			return self.signResultData(self.data['data'])
		else:
			return "ERRDATA"

	def signResultData(self, data):
		qKeys = MpSiteKeys.query.filter(MpSiteKeys.active == '1').first()
		if qKeys is not None:
			message = json.dumps(data)
			sha1_hash = hashlib.sha1(message).digest()
			rsa = RSA.load_key_string(qKeys.priKey.encode('utf-8'), callback=util.no_passphrase_callback)
			signature = rsa.private_encrypt(sha1_hash, RSA.pkcs1_padding).encode('hex')

			return signature
		else:
			return None

class WSData():

	def __init__(self):
		self.data = None
		self.type = None

	def toDict(self):
		_dict = {}
		_dict['data'] = self.data
		_dict['type'] = self.type

		return _dict