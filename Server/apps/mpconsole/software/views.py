from flask import render_template, jsonify, request, session
from werkzeug.utils import secure_filename
import os
import json
import base64
import re
import collections
import uuid

from datetime import datetime

from . import software
from .. import login_manager
from .. model import *
from .. import db

''' -------------------------------------------------
	Groups 
------------------------------------------------- '''

@software.route('/groups')
def groups():

	qGet = MpSoftwareGroup.query.all()
	qGetCols = MpSoftwareGroup.__table__.columns

	_cols = []
	for c in qGetCols:
		if c.name != 'rid' and c.name != 'gHash' and c.name != 'gType' and c.name != 'cdate':
			_row = {}

			if c.name == 'gid':
				_row['visible'] = False
			else:
				_row['visible'] = True
				
			_row['field'] = c.name
			_row['title'] = c.info
			_cols.append(_row)	


	options = {0 : "Development",
           1 : "Production",
           2 : "QA" }


	_rows = []
	for r in qGet:
		_drow = {}
		for c in _cols:
			_obj = "r." + c['field']
			_objVal = eval(_obj)

			if c['field'] == 'mdate':
				_drow[c['field']] = _objVal.strftime("%Y-%m-%d %H:%M:%S")
			elif c['field'] == 'state':
				_drow[c['field']] = options[_objVal]
			else:
				_drow[c['field']] = _objVal

		_rows.append(_drow)

	return render_template('software_groups.html', data={"columns":_cols, "rows":_rows}, title="Software Groups")

@software.route('/group/add/<id>')
def swGroupAdd(id):

	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
	return render_template('software_group_modify.html', group_id=id, user=usr.user_id)

@software.route('/group/edit/<id>')
def swGroupEdit(id):

	group_name = None
	group_description = None
	group_owner = None

	mpsg = MpSoftwareGroup.query.filter(MpSoftwareGroup.gid == id).first()
	mpsgp = MpSoftwareGroupPrivs.query.filter(MpSoftwareGroupPrivs.gid == id, MpSoftwareGroupPrivs.isowner == 1).first()

	if mpsg:
		group_name = mpsg.gName
		group_description = mpsg.gDescription

	if mpsgp:
		group_owner = mpsgp.uid

	return render_template('software_group_modify.html', group_id=id, group_name=group_name, group_description=group_description, user=group_owner)

@software.route('/group/save', methods=['POST'])
def swGroupSave():
	group_id = request.form.get('group_id')
	group_name = request.form.get('group_name')
	group_description = request.form.get('group_description')
	group_owner = request.form.get('user_id')

	mpsg = MpSoftwareGroup.query.filter(MpSoftwareGroup.gid == group_id).first()
	if mpsg:
		setattr(mpsg, 'gName', group_name)
		setattr(mpsg, 'gDescription', group_description)
	else:
		mpsqp = MpSoftwareGroupPrivs()
		mpsg = MpSoftwareGroup()
		setattr(mpsg, 'gid', group_id)
		setattr(mpsg, 'gName', group_name)
		setattr(mpsg, 'gDescription', group_description)
		setattr(mpsqp, 'gid', group_id)
		setattr(mpsqp, 'uid', group_owner)
		setattr(mpsqp, 'isowner', 1)

		db.session.add(mpsg)
		db.session.add(mpsqp)

	db.session.commit()
	return groups()


@software.route('/group/delete/<id>', methods=['POST'])
def swDroupDelete(id):
	suname = request.form.get('pk')
	state = request.form.get('value')

	return groups()


''' -------------------------------------------------
	 Tasks 
------------------------------------------------- '''

@software.route('/tasks')
def tasks():

	columns = [('tuuid','Task ID',0),('primary_suuid','Software ID',0),('name','Name',1),('active','Active',1),('sw_task_type','Task Type',1),
	('sw_start_datetime','Valid From',1),('sw_end_datetime','Valid To',1),('mdate','Mod Date',1)]
	colsForQuery = ['tuuid','primary_suuid','name','active','sw_task_type','sw_start_datetime','sw_end_datetime','mdate']

	qSWTasks = MpSoftwareTask.query.all()
	_data = []
	for d in qSWTasks:
		row = {}
		for c in colsForQuery:

			if c in ('sw_start_datetime','sw_end_datetime','mdate'):
				row[c] = eval("d."+c).strftime("%Y-%m-%d %H:%M:%S")
			elif c == 'active':
				_a = eval("d."+c)
				row[c] = "Yes" if _a == 1 else "No" 
			else:
				row[c] = eval("d."+c)

		_data.append(row)

	_columns = []
	for c, t, v in columns:
			row = {}
			row['field'] = c
			row['title'] = t
			row['sortable'] = True
			if v == 0:
				row['visible'] = False

			_columns.append(row)

	return render_template('software_tasks.html', data={'rows':_data,'columns': _columns}, isAdmin=True)

@software.route('/task/edit/<id>')
def taskEdit(id):

	mpst = MpSoftwareTask.query.filter(MpSoftwareTask.tuuid == id).first() 
	mps = MpSoftware.query.all()
	_data = {}
	_swPkgs = []
	for s in mps:
		_swPkgs.append((s.suuid,s.sName,s.sVersion))

	_data["Task"] = mpst.asDict
	_data["SoftwareList"] = _swPkgs

	return render_template('software_task_modify.html', data=_data, type='edit', isAdmin=True)

@software.route('/task/new')
def taskNew():

	_data = {}
	mps = MpSoftware.query.all()

	_swPkgs = []
	for s in mps:
		_swPkgs.append((s.suuid,s.sName,s.sVersion))

	_data["Task"] = {}
	_data["SoftwareList"] = _swPkgs
	_data["NEWID"] = str(uuid.uuid4())

	return render_template('software_task_modify.html', data=_data, type='new', isAdmin=True)

@software.route('/task/save/<id>', methods=['POST'])
def taskSave(id):

	return render_template('software_packages.html', data={}, isAdmin=True)

@software.route('/task/remove/<id>')
def taskRemove(id):

	return render_template('software_packages.html', data={}, isAdmin=True)

@software.route('/group/<id>/tasks')
def swGroupTasks(id):

	columns = [('sw_task_id','Task ID',0),('name','Name',1),('active','Active',1),('sw_task_type','Task Type',1),
	('sw_start_datetime','Start Date',1),('sw_end_datetime','End Date',1)]
	colsForQuery = ['sw_task_id','name','active','sw_task_type','sw_start_datetime','sw_end_datetime']


	qSWTasks = MpSoftwareTask.query.all()
	qGetSel = MpSoftwareGroupTasks.query.filter(MpSoftwareGroupTasks.sw_group_id == id).all()

	_selected = []
	for s in qGetSel:
		row1 = {}
		row1['tuuid'] = s.sw_task_id
		row1['selected'] = s.selected
		_selected.append(row1)

	_data = []
	for d in qSWTasks:
		row2 = {}
		row2['selected'] = False
		for c in colsForQuery:
			if c == 'sw_task_id':
				row2[c] = d.tuuid
			else:	
				row2[c] = eval("d."+c)

		_data.append(row2)

	for d in _data:
		for s in _selected:
			if d['sw_task_id'] == s['tuuid']:
				if s['selected'] == 1:
					d['selected'] = True
				else:
					d['selected'] = False
				continue

	_columns = []
	for c, t, v in columns:
			row = {}
			row['field'] = c
			row['title'] = t
			row['sortable'] = True
			if v == 0:
				row['visible'] = False

			_columns.append(row)

	_isOwner = isOwnerOfSWGroup(id)
	_isAdmin = isAdminForSWGroup(id)		

	return render_template('software_group_tasks.html', data={'rows':_data,'columns': _columns}, group_id=id, isOwner=_isOwner, isAdmin=_isAdmin)

@software.route('/group/<id>/task/add/<task_id>')
def swGroupTasksAdd(id, task_id):

	qGet = MpSoftwareGroupTasks.query.filter(MpSoftwareGroupTasks.sw_group_id == id, MpSoftwareGroupTasks.sw_task_id == task_id).first()
	if qGet:
		setattr(qGet, 'selected', 1)
	else:
		mpt = MpSoftwareGroupTasks()
		setattr(mpt, 'sw_group_id', id)
		setattr(mpt, 'sw_task_id', task_id)
		setattr(mpt, 'selected', 1)
		db.session.add(mpt)

	db.session.commit()
	return json.dumps({'error':0}), 200

@software.route('/group/<id>/task/remove/<task_id>')
def swGroupTasksRemove(id, task_id):

	qGet = MpSoftwareGroupTasks.query.filter(MpSoftwareGroupTasks.sw_group_id == id, MpSoftwareGroupTasks.sw_task_id == task_id).first()
	if qGet:
		setattr(qGet, 'selected', 0)
	else:
		mpt = MpSoftwareGroupTasks()
		setattr(mpt, 'sw_group_id', id)
		setattr(mpt, 'sw_task_id', task_id)
		setattr(mpt, 'selected', 0)
		db.session.add(mpt)

	db.session.commit()
	return json.dumps({'error':0}), 200

	return json.dumps({'error':0}), 200

''' -------------------------------------------------
	 Packages 
------------------------------------------------- '''

@software.route('/packages')
def packages():
	# MpSoftware
	colsForQuery = ['suuid','sw_url','sName','sVersion','sReboot','sState','sw_type','sw_size','mdate']
	colsToHide = ['suuid','sw_url']

	options = {2:"Production",1:"QA",0:"Create",3:"Disabled"}

	qGet 	 = MpSoftware.query.all()
	qGetCols = MpSoftware.__table__.columns
	qGetColsSorted = sorted(qGetCols, key=getDoc)

	_data = []
	for d in qGet:
		row = {}
		for c in colsForQuery:
			if c in ('mdate'):
				row[c] = eval("d."+c).strftime("%Y-%m-%d %H:%M:%S")
			elif c == 'sReboot':
				_a = eval("d."+c)
				row[c] = "Yes" if _a == 1 else "No" 
			elif c == 'sState':
				_a = eval("d."+c)
				row[c] = options[_a]
			else:
				row[c] = eval("d."+c)

		_data.append(row)

	_columns = []
	for c in qGetColsSorted:
		if c.name in colsForQuery:
			row = {}
			row['field'] = c.name
			row['title'] = c.info
			row['sortable'] = True
			if c.name in colsToHide:
				row['visible'] = False

			_columns.append(row)

	return render_template('software_packages.html', data={'rows':_data,'columns':_columns}, isAdmin='True')

@software.route('/package/add')
def addSWPackage():
	# MpSoftware

	_data = {}
	_data['SUUID'] = str(uuid.uuid4())
	_data['PKG'] = None
	_data['PKGCRI_OSArch'] = None
	_data['PKGCRI_OSType'] = None
	_data['PKGCRI_OSVer'] = None
	_data['SWLIST'] = []

	qGet1 = MpSoftware.query.all()
	for s in qGet1:
		if s.suuid == id:
			_data['PKG'] = s

		_data['SWLIST'].append((s.suuid,s.sName))

	_data['PKGCRILEN'] = 0
	_data['PKGPREREQ'] = []
	_data['PKGPOSTREQ'] = []

	_patchBundleIDs = []
	qGet3 = MpPatch.query.all()
	for y in qGet3:
		_patchBundleIDs.append((y.bundle_id,y.patch_name))

	_data['BUNDLEIDS'] = _patchBundleIDs

	return render_template('software_package_modify.html', data=_data, isAdmin='True')


@software.route('/package/edit/<id>')
def editSWPackage(id):
	# MpSoftware

	_data = {}
	_data['SUUID'] = id
	_data['PKG'] = None
	_data['PKGCRI_OSArch'] = None
	_data['PKGCRI_OSType'] = None
	_data['PKGCRI_OSVer'] = None
	_data['SWLIST'] = []

	qGet1 = MpSoftware.query.all()
	for s in qGet1:
		if s.suuid == id:
			_data['PKG'] = s

		_data['SWLIST'].append((s.suuid,s.sName))

	qGet2 = MpSoftwareCriteria.query.filter(MpSoftwareCriteria.suuid == id).all()
	for x in qGet2:
		if x.type == 'OSArch':
			_data['PKGCRI_OSArch'] = x.type_data
		elif x.type == 'OSType':
			_data['PKGCRI_OSType'] = x.type_data
		elif x.type == 'OSVersion':
			_data['PKGCRI_OSVer'] = x.type_data

	_data['PKGCRILEN'] = len(qGet2)

	_preReq  = []
	_postReq = []
	swReq = MpSoftwareRequisits.query.filter(MpSoftwareRequisits.suuid == id).join(MpSoftware, MpSoftware.suuid == MpSoftwareRequisits.suuid_ref).add_columns(MpSoftware.sName).all()

	for r in swReq:
		if r[0].type == 0:
			_pre = {}
			_pre['suuid'] = r[0].suuid_ref
			_pre['name'] = r.sName
			_pre['order'] = r[0].type_order
			_preReq.append(_pre)
		else:
			_post = {}
			_post['suuid'] = r[0].suuid_ref
			_post['name'] = r.sName
			_post['order'] = r[0].type_order
			_postReq.append(_post)

	_data['PKGPREREQ'] = _preReq
	_data['PKGPOSTREQ'] = _postReq		

	_patchBundleIDs = []
	qGet3 = MpPatch.query.all()
	for y in qGet3:
		_patchBundleIDs.append((y.bundle_id,y.patch_name))

	_data['BUNDLEIDS'] = _patchBundleIDs

	return render_template('software_package_modify.html', data=_data, isAdmin='True')

@software.route('/package/save', methods=['POST'])
def saveSWPackage():
	#print request.form.get('suuid')
	#print request.form

	''' Process Requisists '''
	_reqs = []
	_reqsPre = []
	_reqsPost = []
	for v in request.form:
		if "preSWPKG" in v or "postSWPKG" in v:
			_rowPre = {}
			_rowPost = {}
			if "preSWPKG" in v:
				if "preSWPKG_" in v:
					x = v.split("_")[1]
					_rowPre['suuid'] = request.form.get('suuid')
					_rowPre['suuid_ref'] = request.form[v]
					_rowPre['type'] =  0
					_rowPre['type_txt'] = "PRE" 
					_rowPre['type_order'] = eval("request.form.get('preSWPKGOrder_"+x+"')")
					_reqsPre.append(_rowPre)

			elif "postSWPKG" in v:
				if "postSWPKG_" in v:
					x = v.split("_")[1]
					_rowPost['suuid'] = request.form.get('suuid')
					_rowPost['suuid_ref'] = request.form[v]
					_rowPost['type'] =  1
					_rowPost['type_txt'] = "POST"
					_rowPost['type_order'] = eval("request.form.get('postSWPKGOrder_"+x+"')")
					_reqsPost.append(_rowPost)


	_new = False
	qSW = MpSoftware.query.filter(MpSoftware.suuid == request.form.get('suuid')).first()
	qSWC = MpSoftwareCriteria.query.filter(MpSoftwareCriteria.suuid == request.form.get('suuid')).all()
	qSWR = MpSoftwareRequisits.query.filter(MpSoftwareRequisits.suuid == request.form.get('suuid')).all()
	if not qSW:
		_new = True
		qSW = MpSoftware()
		setattr(qSW, 'suuid', request.form.get('suuid'))
		setattr(qSW, 'cdate', datetime.now())

	for v in request.form:
		if v != 'suuid':
			setattr(qSW, v, request.form[v])

	setattr(qSW, 'mdate', datetime.now())

	if qSWC:
		for c in qSWC:
			db.session.delete(c)

	''' Criteria '''		
	qSWCAdd = MpSoftwareCriteria()
	setattr(qSWCAdd, 'type', 'OSType')
	setattr(qSWCAdd, 'type_data', request.form['req_os_type'])
	setattr(qSWCAdd, 'type_order', 1)
	setattr(qSWCAdd, 'suuid', request.form.get('suuid'))	
	db.session.add(qSWCAdd)

	qSWCAdd = MpSoftwareCriteria()
	setattr(qSWCAdd, 'type', 'OSVersion')
	setattr(qSWCAdd, 'type_data', request.form['req_os_ver'])
	setattr(qSWCAdd, 'type_order', 2)
	setattr(qSWCAdd, 'suuid', request.form.get('suuid'))	
	db.session.add(qSWCAdd)

	qSWCAdd = MpSoftwareCriteria()
	setattr(qSWCAdd, 'type', 'OSArch')
	setattr(qSWCAdd, 'type_data', request.form['req_os_arch'])
	setattr(qSWCAdd, 'type_order', 3)
	setattr(qSWCAdd, 'suuid', request.form.get('suuid'))	
	db.session.add(qSWCAdd)

	''' Requisits '''
	if qSWR:
		for r in qSWR:
			db.session.delete(r)

	if len(_reqsPre) >= 1 or len(_reqsPost) >= 1:
		
		for rpre in _reqsPre:
			qSWRAdd = MpSoftwareRequisits()
			for k, v in rpre.items():
				setattr(qSWRAdd, k, v)

			db.session.add(qSWRAdd)

		for rpst in _reqsPost:
			qSWRAdd = MpSoftwareRequisits()
			for k, v in rpst.items():
				setattr(qSWRAdd, k, v)

			db.session.add(qSWRAdd)

	if _new:
		db.session.add(qSW)
			
	db.session.commit()


	'''
	Save the file
    '''
	for f in request.files:
		file = request.files[f]
		if file.filename != '':
			filename = secure_filename(file.filename)
			print filename
			file.save(os.path.join("/tmp", filename))
		else:
			print "No File"


	return json.dumps({'error': 0}), 200
	#return packages()

@software.route('/package/delete/<id>')
def deleteSWPackage(id):
	'''
	qSW = MpSoftware.query.filter(MpSoftware.suuid == id).first()
	qSWC = MpSoftwareCriteria.query.filter(MpSoftwareCriteria.suuid == id).all()
	qSWR = MpSoftwareRequisits.query.filter(MpSoftwareRequisits.suuid == id).all()

	db.session.delete(qSW)

	if qSWC:
		for c in qSWC:
			db.session.delete(c)

	if qSWR:
		for c in qSWR:
			db.session.delete(c)

	db.session.commit()
	'''
	return json.dumps({'error': 0}), 200


''' -------------------------------------------------
	 Global 
------------------------------------------------- '''
def getDoc(col_obj):
    return col_obj.doc

def isOwnerOfSWGroup(id):

	result = False
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()

	if usr:
		pgroup = MpSoftwareGroupPrivs.query.filter(MpSoftwareGroupPrivs.gid == id).first()
		if pgroup:
			if pgroup.uid == usr.user_id:
				if pgroup.isowner == 1:
					result = True

	return result

def isAdminForSWGroup(id):

	result = False
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()

	if usr:
		q_admin = MpSoftwareGroupPrivs.query.filter(MpSoftwareGroupPrivs.gid == id).all()
		if q_admin:
			for row in q_admin:
				if row.uid == usr.user_id:
					result = True
					break

	return result
