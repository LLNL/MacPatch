from flask import render_template, jsonify, request
from datetime import *
import json
import base64
import re
import collections
from datetime import datetime
import uuid

from . import osmanage
from .. import login_manager
from .. model import *
from .. import db

@osmanage.route('/profiles')
def profiles():

	columns = [('profileID', 'Profile ID', '0'), ('profileIdentifier', 'Profile Identifier', '1'), ('profileName', 'Name', '1'),
	           ('profileDescription', 'Description', '1'), ('profileRev', 'Revision', '1'), ('enabled', 'Enabled', '1'), 
	           ('uninstallOnRemove', 'Uninstall On Remove', '1')]

	profileQuery = MpOsConfigProfiles.query.all()

	_results = []
	for p in profileQuery:
		row = {}
		for c in columns:
			y = "p."+c[0]
			if c[0] == 'enabled' or c[0] == 'uninstallOnRemove':
				row[c[0]] = "Yes" if eval(y) == 0 else "No"
			else:
				row[c[0]] = eval(y)

		_results.append(row)

	return render_template('os_profiles.html', data=_results, columns=columns)

@osmanage.route('/profile/group/<group_id>/add',methods=['GET'])
def addProfileToGroup(group_id):

	profilesQuery = MpOsConfigProfiles.query.filter(MpOsConfigProfiles.enabled == 1).all()
	profilesRes = []
	for p in profilesQuery: 
		row = {}
		row['profileID'] = p.profileID
		row['title'] = p.profileName + " (" + p.profileIdentifier +")"
		profilesRes.append(row)

	_result = {}

	return render_template('os_profile_wizard.html', profileData={}, profileCriteria={}, profileArray=profilesRes, groupID=group_id)

@osmanage.route('/profile/group/<group_id>/edit/<policy_id>',methods=['GET'])
def editProfileInGroup(group_id, policy_id):

	profilesQuery = MpOsConfigProfiles.query.filter(MpOsConfigProfiles.enabled == 1).all()

	profilesRes = []
	for p in profilesQuery: 
		row = {}
		row['profileID'] = p.profileID
		row['title'] = p.profileName + " (" + p.profileIdentifier +")"
		profilesRes.append(row)

	policyQuery = MpOsProfilesGroupAssigned.query.filter(MpOsProfilesGroupAssigned.gPolicyID == policy_id).first()
	criteriaQuery = MpOsProfilesCriteria.query.filter(MpOsProfilesCriteria.gPolicyID == policy_id).all()

	return render_template('os_profile_wizard.html', profileData=policyQuery, profileCriteria=criteriaQuery, profileArray=profilesRes, groupID=group_id)

@osmanage.route('/profile/<gprofile_id>',methods=['GET','DELETE'])
def profile(gprofile_id):
	if request.method == 'DELETE':
		profileQuery = MpOsProfilesGroupAssigned.query.filter(MpOsProfilesGroupAssigned.gPolicyID == gprofile_id).delete()
		profileCriQuery = MpOsProfilesCriteria.query.filter(MpOsProfilesCriteria.gPolicyID == gprofile_id).delete()
		db.session.commit()

		return json.dumps({'error': 0}), 200  

	if request.method == 'GET':
		profileQuery = MpOsConfigProfiles.query.filter(MpOsConfigProfiles.profileid == gprofile_id).first()
		_result = {}

		return json.dumps({'error': 0}), 200  

	return json.dumps({'error': 0}), 200   

@osmanage.route('/profiles/group/<group_id>', methods=['GET'])
def groupProfiles(group_id):
	
	columns = [('profileID', 'Profile ID', '0'), ('gPolicyID', 'Policy Identifier', '0'), ('pName', 'Profile Name', '1'), ('title', 'Title', '1'),
	           ('description', 'Description', '1'), ('enabled', 'Enabled', '1')]           
	
	profiles = MpOsProfilesGroupAssigned.query.filter(MpOsProfilesGroupAssigned.groupID == group_id).join(
		MpOsConfigProfiles, MpOsConfigProfiles.profileID == MpOsProfilesGroupAssigned.profileID).add_columns(
		MpOsConfigProfiles.profileName).all()


	_results = []
	for p in profiles:
		row = {}
		for c in columns:
			if c[0] == 'pName':
				row[c[0]] = p.profileName
			else:
				y = "p[0]."+c[0]
				row[c[0]] = eval(y)

		_results.append(row)

	return json.dumps({'data': _results, 'total': 0}), 200

@osmanage.route('/group/profile', methods=['POST'])
def postProfile():
	
	_form = request.form
	_formDict = dict(request.form)

	gPolicyID = request.form['gPolicyID']

	if gPolicyID == None or len(gPolicyID) <= 0:
		gPolicyID = str(uuid.uuid4())

	groupID = request.form['groupID']

	if groupID == None or len(groupID) <= 0:
		return json.dumps({'error': 404}), 404   

	profileID = request.form['profileID']
	
	addNew = False
	qPolicy = MpOsProfilesGroupAssigned.query.filter(MpOsProfilesGroupAssigned.gPolicyID == gPolicyID).first()
	if not qPolicy:
		addNew = True
		qPolicy = MpOsProfilesGroupAssigned()


	setattr(qPolicy, 'gPolicyID', gPolicyID)
	setattr(qPolicy, 'profileID', profileID)
	setattr(qPolicy, 'groupID', groupID)
	setattr(qPolicy, 'title', request.form['title'])
	setattr(qPolicy, 'description', request.form['description'])
	setattr(qPolicy, 'enabled', request.form['enabled'])
	if addNew:
		db.session.add(qPolicy)
    

	qPolicyCriDel = MpOsProfilesCriteria.query.filter(MpOsProfilesCriteria.gPolicyID == gPolicyID).delete()

	for key in _formDict:
	    if key.startswith('cri_'):
	            cri = MpOsProfilesCriteria()
	            setattr(cri, 'gPolicyID', gPolicyID)
	            if key == 'cri_os_type':
	                setattr(cri, 'type', 'OSType')
	                setattr(cri, 'type_data', request.form[key])
	                setattr(cri, 'type_order', 1)
	                db.session.add(cri)
	                continue

	            if key == 'cri_os_ver':
	                setattr(cri, 'type', 'OSVersion')
	                setattr(cri, 'type_data', request.form[key])
	                setattr(cri, 'type_order', 2)
	                db.session.add(cri)
	                continue

	            if key == 'cri_system_type':
	                setattr(cri, 'type', 'SYSType')
	                setattr(cri, 'type_data', request.form[key])
	                setattr(cri, 'type_order', 3)
	                db.session.add(cri)
	                continue

	            if key == 'cri_model_type':
	                setattr(cri, 'type', 'ModelType')
	                setattr(cri, 'type_data', request.form[key])
	                setattr(cri, 'type_order', 4)
	                db.session.add(cri)
	                continue

	    if key.startswith('rec_cri_type_'):

	    	formLst = key.split('_')
	        nid = formLst[1]
	        ntitle = formLst[0]
	        norder = int(request.form['req_cri_order_'+str(nid)]) + 4
	        formData = request.form['req_cri_data_'+str(nid)]
	        formType = request.form['req_cri_type_'+str(nid)]

	        cri = MpOsProfilesCriteria()
	        setattr(cri, 'gPolicyID', gPolicyID)
	        setattr(cri, 'type', formType)
	        setattr(cri, 'type_data', formData)
	        setattr(cri, 'type_order', norder)
	        db.session.add(cri)

	db.session.commit()


	return json.dumps({'error': 0}), 200   
	
