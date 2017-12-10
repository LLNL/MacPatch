from flask import render_template, session, request, current_app
from flask.ext.security import login_required
from sqlalchemy import text
from datetime import datetime
import json
import uuid
import os
import os.path
import sys
from operator import itemgetter

from . import clients
from .. import login_manager
from .. model import *
from .. mplogger import *
from .. import db

'''
----------------------------------------------------------------
'''
@clients.route('/clients')
@login_required
def clientsList():
	cList = MpClient.query.all()
	cListCols = MpClient.__table__.columns.keys()
	cListColNames = [{'name':'rid','label':'rid'}, {'name':'cuuid', 'label':'CUUID'},
					{'name':'hostname','label':'Host Name'},{'name':'computername','label':'Computer Name'},
					{'name':'ipaddr','label':'IP Address'}, {'name':'macaddr','label':'MAC Address'},
					{'name': 'serialNo', 'label': 'Serial No'}, {'name':'osver','label':'OS Ver'},
					{'name':'ostype','label':'OS Type'}, {'name':'consoleUser','label':'Console User'},
					{'name':'needsreboot','label':'Needs Reboot'}, {'name':'agent_version','label':'Agent Ver'},
					{'name':'client_version','label':'Client Ver'}, {'name':'mdate','label':'Mod Date'},
					{'name':'cdate','label':'CDate'}]
	# cListCols = cList.keys()
	# print cListColNames
	return render_template('clients.html', cData=cList, columns=cListCols, colNames=cListColNames)

'''
----------------------------------------------------------------
	Client
----------------------------------------------------------------
'''
@clients.route('/dashboard/<client_id>')
@login_required
def clientsInfo(client_id):
	qGet = MpClient.query.filter(MpClient.cuuid == client_id).first()
	rCols = [('patch', 'Patch'),('description', 'Description'),('restart', 'Reboot'),('mdate',' Days Needed')]

	return render_template('client_dashboard.html', cData=qGet, columns={'rPatchCols': rCols}, client_id=client_id, invTypes=inventoryTypes())

# JSON Routes
@clients.route('/dashboard/required/<client_id>')
def clientRequiredPatches(client_id):

	now = datetime.now()
	columns = [('patch', 'Patch'),('description', 'Description'),('restart', 'Reboot'),('type', 'Type'),('mdate', 'Days Needed')]

	qApple = MpClientPatchesApple.query.filter(MpClientPatchesApple.cuuid == client_id).all()
	qThird = MpClientPatchesThird.query.filter(MpClientPatchesThird.cuuid == client_id).all()

	_results = []
	for p in qApple:
		row = {}
		for c, t in columns:
			y = "p."+c
			if c == 'mdate':
				row[c] = daysFromDate(now, eval(y))
			elif c == 'restart':
				if eval(y)[0] == 'Y':
					row[c] = 'Yes'
				else:
					row[c] = 'No'
			else:
				row[c] = eval(y)

		row['type'] = 'Apple'
		_results.append(row)

	for p in qThird:
		row = {}
		for c, t in columns:
			y = "p."+c
			if c == 'mdate':
				row[c] = daysFromDate(now, eval(y))
			elif c == 'restart':
				if eval(y)[0] == 'Y':
					row[c] = 'Yes'
				else:
					row[c] = 'No'
			else:
				row[c] = eval(y)

		row['type'] = 'Third'
		_results.append(row)

	_columns = []
	for c, t in columns:
		row = {}
		row['field'] = c
		row['title'] = t
		row['sortable'] = 'true'
		_columns.append(row)

	return json.dumps({'data':_results, 'columns': _columns}), 200

@clients.route('/dashboard/installed/<client_id>')
def clientInstalledPatches(client_id):

	columns = [('patch_name', 'Patch'),('type', 'Type'),('mdate', 'Installed On')]
	query = MpInstalledPatch.query.filter(MpInstalledPatch.cuuid == client_id).order_by(MpInstalledPatch.mdate.desc()).limit(10)

	_results = []
	for p in query:
		row = {}
		for c, t in columns:
			y = "p."+c
			row[c] = eval(y)
		_results.append(row)

	_columns = []
	for c, t in columns:
		row = {}
		row['field'] = c
		row['title'] = t
		row['sortable'] = 'true'
		_columns.append(row)

	return json.dumps({'data':_results, 'columns': _columns}, default=json_serial), 200

@clients.route('/dashboard/inventory/<client_id>/<inv_id>')
def clientInventoryReport(client_id, inv_id):

	sql = text("""select * From """ + inv_id + """
				Where cuuid = '""" + client_id + """'""")

	print sql

	_q_result = db.engine.execute(sql)

	_results = []
	_columns = []

	for v in _q_result:
		_row = {}
		for column, value in v.items():
			if column != "cdate" or column != "rid" or column != "cuuid":
				if column == "mdate":
					_row[column] = value.strftime("%Y-%m-%d %H:%M:%S")
				else:
					_row[column] = value

		_results.append(_row)

	for column in _q_result.keys():
		if column != "cdate" and column != "rid" and column != "cuuid":
			_col = {}
			_col['field'] = column
			if column == "mdate":
				_col['title'] = 'Inv Date'
			else:
				_col['title'] = column.replace('mpa_', '', 1).replace("_", " ")

			_col['sortable'] = 'true'
			_columns.append(_col)

	return json.dumps({'data':_results, 'columns':_columns}), 200

def daysFromDate(now, date):
	x = now - date
	return x.days

'''
********************************
	Groups
********************************
'''
@clients.route('/groups')
@login_required
def clientGroups():
	groups = MpClientGroups.query.all()
	cols = MpClientGroups.__table__.columns

	'''
	# Convert Query Result to Array or Dicts to add the count column
	'''
	_data = []
	for g in groups:
		x = g.asDict
		x['count'] = 0
		_data.append(x)

	'''
	# Get Reboot Count
	'''
	sql = text("""select group_id, count(*) as total
				From mp_client_group_members
				Group By group_id""")

	result = db.engine.execute(sql)
	_results = []
	for v in result:
		_row = {}
		for column, value in v.items():
			_row[column] = value

		_results.append(_row)

	# print _data
	# print _results
	_rights = list(accessToGroups())

	''' Return Data '''
	return render_template('client_groups.html', data=_data, columns=cols, counts=_results, rights=_rights)

@clients.route('/group/add')
@login_required
def clientGroupAdd():
	''' Returns an empty set of data to add a new record '''
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
	_owner = usr.user_id

	clientGroup = MpClientGroups()
	setattr(clientGroup, 'group_id', str(uuid.uuid4()))
	setattr(clientGroup, 'group_owner', _owner)

	return render_template('update_client_group.html', data=clientGroup, type="add")

@clients.route('/group/<id>/user/add',methods=['GET'])
@login_required
def clientGroupUserAdd(id):
	return render_template('client_group_user_mod.html', data={'group_id':id}, type="add")

@clients.route('/group/<id>/<user_id>/remove')
def clientGroupUserRemove(id, user_id):
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
	if usr.user_id == user_id or isOwnerOfGroup(id):
		uadm = MpClientGroupAdmins().query.filter(MpClientGroupAdmins.group_id == id, MpClientGroupAdmins.group_admin == user_id).first()
		if uadm:
			db.session.delete(uadm)
			db.session.commit()
		else:
			return json.dumps({'error': 404, 'errormsg': 'User could not be removed.'}), 404

	log("Remove user {} from client group {}".format(user_id, id))
	return json.dumps({'error': 0}), 200

@clients.route('/group/user/modify',methods=['POST'])
@login_required
def clientGroupUserModify():
	id = request.form.get('group_id')
	uid = request.form.get('user_id')
	log("{} added user {} to client group {}".format(session['user'], uid, id))

	try:
		adm = MpClientGroupAdmins().query.filter(MpClientGroupAdmins.group_id == id, MpClientGroupAdmins.group_admin == uid).first()
		if adm:
			setattr(adm, 'group_id', id)
			setattr(adm, 'group_admin', uid)
		else:
			adm = MpClientGroupAdmins()
			setattr(adm, 'group_id', id)
			setattr(adm, 'group_admin', uid)
			db.session.add(adm)

		db.session.commit()

	except:
		log_Error("Error {}".format(sys.exc_info()[0]))

	return clientGroup(id,5)

@clients.route('/group/update',methods=['POST'])
@login_required
def patchGroupUpdate():

	_add = False
	_group_id    = request.form['group_id']
	_group_name  = request.form['group_name']
	_group_owner = request.form['group_owner']

	clientGroup = MpClientGroups().query.filter(MpClientGroups.group_id == _group_id).first()
	if clientGroup is None:
		_add = True
		clientGroup = MpClientGroups()

	setattr(clientGroup, 'group_name', _group_name)
	setattr(clientGroup, 'group_owner', _group_owner)
	if _add:
		setattr(clientGroup, 'group_id', _group_id)
		db.session.add(clientGroup)
		# Add Default Settings
		groupDefaultSettings(_group_id)

	db.session.commit()
	return clientGroups()

@clients.route('/group/<name>',methods=['GET','DELETE'])
@login_required
def clientGroup(name,tab=1):
	q_defaultGroup = MpClientGroups.query.filter(MpClientGroups.group_id == name, MpClientGroups.group_name == 'Default').first()

	if request.method == 'DELETE':
		if q_defaultGroup:
			return json.dumps({{'errormsg':'Can not delete default group.'}}), 403

		qMembers = MpClientGroupMembers.query.filter(MpClientGroupMembers.group_id == name).all()
		print len(qMembers)
		if qMembers is not None and len(qMembers) >= 1:
			return json.dumps({'errormsg':'Group still contains agents. Can not delete group while agents are assigned.'}), 401
		else:
			MpClientGroupMembers.query.filter(MpClientGroupMembers.group_id == name).delete()
			MpClientTasks.query.filter(MpClientTasks.group_id == name).delete()
			MpClientSettings.query.filter(MpClientSettings.group_id == name).delete()
			MpOsProfilesGroupAssigned.query.filter(MpOsProfilesGroupAssigned.groupID == name).delete()
			MpClientGroups.query.filter(MpClientGroups.group_id == name).delete()
			db.session.commit()
			return json.dumps({}), 201
	else:
		canEditGroup = False
		if not isOwnerOfGroup(name) and not isAdminForGroup(name):
			if q_defaultGroup:
				canEditGroup = True
			else:
				return clientGroups()

		groupResult = {}

		# cList = MpClient.query.all()
		cListCols = MpClient.__table__.columns
		# Cort the Columns based on "doc" attribute
		sortedCols = sorted(cListCols, key=getDoc)

		# Get All Client IDs in with in our group
		_qcg = MpClientGroups.query.filter(MpClientGroups.group_id == name).with_entities(MpClientGroups.group_name).first()
		_res = MpClientGroupMembers.query.filter(MpClientGroupMembers.group_id == name).with_entities(MpClientGroupMembers.cuuid).all()
		_cuuids = [r for r, in _res]

		# Get All Client Group Admins
		_admins = []
		_qadm = MpClientGroupAdmins.query.filter(MpClientGroupAdmins.group_id == name).all()
		if _qadm:
			for u in _qadm:
				_row = {'user_id':u.group_admin,'owner': 'False'}
				_admins.append(_row)

		_owner = MpClientGroups.query.filter(MpClientGroups.group_id == name).first()
		_admins.append({'user_id':_owner.group_owner,'owner': 'True'})
		_admins = sorted(_admins, key=itemgetter('owner'), reverse=True)

		# Run Query of all clients that contain the Client ID
		sql = text("""select * From mp_clients;""")
		_q_result = db.engine.execute(sql)

		_results = []
		for v in _q_result:
			if v.cuuid in _cuuids:
				_row = {}
				for column, value in v.items():
					if column != "cdate":
						if column == "mdate":
							_row[column] = value.strftime("%Y-%m-%d %H:%M:%S")
							_row['clientState'] = clientStatusFromDate(value)
						else:
							_row[column] = value

				_results.append(_row)

		# Client Tasks Columns
		_qTasksCols = MpClientTasks.__table__.columns

		# Data in one dict
		groupResult['Clients'] = {'data': _results, 'columns': sortedCols}
		groupResult['Group'] = {'name': _qcg.group_name, 'id':name}
		groupResult['Software'] = {'catalogs':softwareCatalogs()}  # Used to populate UI for setting
		groupResult['Patches'] = {'groups': patchGroups()}  # Used to populate UI for setting
		groupResult['Users'] = {'users': _admins, 'columns': [('user_id','User ID'),('owner','Owner')]}
		groupResult['Admin'] = isAdminForGroup(name)
		groupResult['Owner'] = isOwnerOfGroup(name)

		# Group Settings
		_settings = getGroupSettings(name)
		print _settings
		profileCols = [('profileID', 'Profile ID', '0'), ('gPolicyID', 'Policy Identifier', '0'), ('pName', 'Profile Name', '1'), ('title', 'Title', '1'),
						('description', 'Description', '1'), ('enabled', 'Enabled', '1')]
		'''
		return render_template('client_group.html', data=_results, columns=sortedCols, group_name=_qcg.group_name, group_id=name,
							tasks=_jData['mpTasks'], tasksCols=_qTasksCols, gResults=groupResult, selectedTab=tab,
							profileCols=profileCols, readOnly=canEditGroup)
		'''
		return render_template('client_group.html', data=_results, columns=sortedCols, group_name=_qcg.group_name, group_id=name,
							tasksCols=_qTasksCols, gResults=groupResult, selectedTab=tab,
							profileCols=profileCols, readOnly=canEditGroup, settings=_settings)

'''
********************************
	Groups - > Clients
********************************
'''
# Not working yet, will add in future, right now clients
# list is gathered durning clientGroup request
@clients.route('/group/<name>/clients')
def clientGroupClients(name):

	# Get All Client IDs in with in our group
	_res = MpClientGroupMembers.query.filter(MpClientGroupMembers.group_id == name).with_entities(MpClientGroupMembers.cuuid).all()
	_cuuids = [r for r, in _res]

	# Run Query of all clients that contain the Client ID
	sql = text("""select * From mp_clients
				Where cuuid in ('""" + '\',\''.join(_cuuids) + """')""")
	_q_result = db.engine.execute(sql)

	_results = []
	for v in _q_result:
		_row = {}
		for column, value in v.items():
			if column != "cdate":
				if column == "mdate":
					_row[column] = value.strftime("%Y-%m-%d %H:%M:%S")
					_row['clientState'] = clientStatusFromDate(value)
				else:
					_row[column] = value

		_results.append(_row)

	jResult = json.dumps(_results)

	return jResult, 200

# Remove/Delete Client
@clients.route('/group/<id>/remove/clients',methods=['POST'])
def clientGroupClientsRemove(id):

	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
	if usr is not None or isOwnerOfGroup(id):
		for x in request.form['clients'].split(","):
			client = MpClient.query.filter(MpClient.cuuid == x).first()
			clientGroupMember = MpClientGroupMembers.query.filter(MpClientGroupMembers.cuuid == x, MpClientGroupMembers.group_id == id).first()
			if clientGroupMember:
				print "Delete client %s from group %s" %(x, id)
				db.session.delete(clientGroupMember)
				db.session.commit()

			if client:
				print "Delete client " + x
				db.session.delete(client)
				db.session.commit()
			else:
				return json.dumps({'error': 404, 'errormsg': 'User could not be removed.'}), 404

	'''
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
	if usr.user_id == user_id or isOwnerOfGroup(id):
		uadm = MpClientGroupAdmins().query.filter(MpClientGroupAdmins.group_id == id, MpClientGroupAdmins.group_admin == user_id).first()
		if uadm:
			db.session.delete(uadm)
			db.session.commit()
		else:
			return json.dumps({'error': 404, 'errormsg': 'User could not be removed.'}), 404
	'''
	return json.dumps({}), 200

# Move a client to a new group
@clients.route('/move/client',methods=['POST'])
@login_required
def clientMove():

	_cuuids     = request.form['cuuids'].split(',')
	_o_group_id = request.form['orig_group_id']
	_group_id   = request.form['group_id']

	for c in _cuuids:
		groupMember = MpClientGroupMembers().query.filter(MpClientGroupMembers.cuuid == c).first()
		setattr(groupMember, 'group_id', str(_group_id))

	db.session.commit()
	return clientGroup(_o_group_id,1)

# Move a client to a new group
@clients.route('/show/move/client/<id>')
@login_required
def showClientMove(id):

	cGroups = MpClientGroups().query.all()
	# curGroup = MpClientGroupMembers().query.filter(MpClientGroupMembers.cuuid == id).first()

	# return render_template('move_client_to_group.html', groups=cGroups, curGroup=curGroup.group_id, cuuid=id )
	return render_template('move_client_to_group.html', groups=cGroups, curGroup=0, cuuid=0)

'''
********************************
	Groups - > Settings
********************************
'''
@clients.route('/group/<id>/settings',methods=['POST'])
@login_required
def groupSettings(id):
	_form = request.form

	# Revision Increment
	cfg = MPGroupConfig().query.filter(MPGroupConfig.group_id == id).first()
	if cfg:
		rev = cfg.rev_settings + 1
		setattr(cfg, 'rev_settings', rev)
	else:
		cfg = MPGroupConfig()
		setattr(cfg, 'group_id', id)
		setattr(cfg, 'rev_settings', 1)
		setattr(cfg, 'rev_tasks', 1)
		db.session.add(cfg)

	# Remove All Settings & Add New, easier than update
	mpc = MpClientSettings().query.filter(MpClientSettings.group_id == id).all()
	if mpc is not None and len(mpc) >= 1:
		sql = "DELETE FROM mp_client_settings WHERE group_id='" + id + "'"
		db.engine.execute(sql)

	for f in _form:
		mpc = MpClientSettings()
		setattr(mpc, 'group_id', id)
		setattr(mpc, 'key', f)
		setattr(mpc, 'value', str(_form[f]))
		db.session.add(mpc)

	db.session.commit()
	return json.dumps({'error': 0}), 200

# Add Default Settings to new group
def groupDefaultSettings(id):
	mpc = MpClientSettings().query.filter(MpClientSettings.group_id == id).all()
	if mpc is not None and len(mpc) >= 1:
		# Log that group settings already exist
		return False

	patchGroup = MpPatchGroup.query.filter(MpPatchGroup.name == 'Default').first()
	swGroup = MpSoftwareGroup.query.filter(MpSoftwareGroup.gName == 'Default').first()
	form = {'patch_group': patchGroup.id,
			'software_group': swGroup.gid,
			'inherited_software_group':'None',
			'allow_client':'1',
			'allow_server':'1',
			'allow_reboot':'1',
			'verify_signatures':'0',
			'patch_state':'Production',
			'pre_stage_patches':'1'}

	# Revision Increment
	cfg = MPGroupConfig().query.filter(MPGroupConfig.group_id == id).first()
	if cfg:
		rev = cfg.rev_settings + 1
		setattr(cfg, 'rev_settings', rev)
	else:
		cfg = MPGroupConfig()
		setattr(cfg, 'group_id', id)
		setattr(cfg, 'rev_settings', 1)
		setattr(cfg, 'rev_tasks', 1)
		db.session.add(cfg)

	for key, value in form.iteritems():
		mpc = MpClientSettings()
		setattr(mpc, 'group_id', id)
		setattr(mpc, 'key', key)
		setattr(mpc, 'value', str(value))
		db.session.add(mpc)

	db.session.commit()
	return True

def getGroupSettings(id):
	mpc = MpClientSettings().query.filter(MpClientSettings.group_id == id).all()
	result = {}
	if mpc is not None:
		for s in mpc:
			result[s.key] = s.value

	return result

def patchGroups():
	_qget = MpPatchGroup.query.with_entities(MpPatchGroup.id, MpPatchGroup.name).all()
	_results = []
	for x in _qget:
		_results.append((x.id,x.name))

	return _results

def softwareCatalogs():
	_qget = MpSoftwareGroup.query.with_entities(MpSoftwareGroup.gid, MpSoftwareGroup.gName).all()
	_results = []
	for x in _qget:
		_results.append((x.gid,x.gName))

	return _results

'''
********************************
	Groups - > Tasks
********************************
'''
@clients.route('/group/<group_id>/tasks', methods=['GET'])
@login_required
def groupTasks(group_id):

	# Get Tasks from default_tasks.json file, then query db to see if client group
	# is using the correct version of the default tasks. If not, we will
	# add the missing tasks to the group.
	# TODO: Add method to mpconsole.py to upgrade all groups so that admins
	# dont have to click on the tasks tab to refresh

	add_tasks=False
	file_tasks = defaultTasks()
	grp_conf = MPGroupConfig.query.filter(MPGroupConfig.group_id == group_id).first()
	if "version" in file_tasks:
		if grp_conf is not None:
			if grp_conf.tasks_version != file_tasks['version']:
				add_tasks = True
		else:
			add_tasks = True

	if add_tasks:
		# Add Missing Tasks
		print "Add Tasks"
		addMissingTasks(group_id, file_tasks['mpTasks'], file_tasks['version'])

	tasks = MpClientTasks.query.filter(MpClientTasks.group_id == group_id).all()
	_results = []
	if tasks is not None and len(tasks) >= 1:
		for t in tasks:
			_row = t.__dict__.copy()
			del _row['_sa_instance_state']
			_results.append(_row)

	return json.dumps({'data': _results, 'total': len(_results)}), 200

# Private Method to Add Missing tasks, used by groupTasks
#
# TODO, need to remove tasks if removed from default_tasks
#
def addMissingTasks(group_id, fileTasks, new_task_version):

	# List of Current commands in db
	_cmds = []
	tasks = MpClientTasks.query.filter(MpClientTasks.group_id == group_id).all()
	if tasks is not None and len(tasks) >= 1:
		for t in tasks:
			_row = t.__dict__.copy()
			_cmds.append(_row['cmd'])

	# Loop over default tasks, if cmd is not found then add it
	for task in fileTasks:
		if task['cmd'] not in _cmds:
			_task = MpClientTasks()
			setattr(_task, 'group_id', group_id)
			for key in task.keys():
				setattr(_task, key, task[key])

			db.session.add(_task)
			db.session.commit()

	# Update Tasks Version to new version
	grp_conf = MPGroupConfig.query.filter(MPGroupConfig.group_id == group_id).first()
	if grp_conf is not None:
		rev_tasks = grp_conf.rev_tasks + 1
		setattr(grp_conf, "tasks_version", new_task_version)
		setattr(grp_conf, "rev_tasks", rev_tasks)
		db.session.commit()

def revGroupTasks(group_id):
	grp_conf = MPGroupConfig.query.filter(MPGroupConfig.group_id == group_id).first()
	if grp_conf is not None:
		rev_tasks = grp_conf.rev_tasks + 1
		setattr(grp_conf, "rev_tasks", rev_tasks)
		db.session.commit()

# Tasks inline updates
@clients.route('/group/<id>/task/active',methods=['POST'])
def taskState(id):
	key = request.form.get('pk')
	value = request.form.get('value')

	task = MpClientTasks.query.filter(MpClientTasks.group_id == id, MpClientTasks.cmd == key).first()
	if task is not None:
		setattr(task, 'active', value)
		db.session.commit()
		revGroupTasks(id)

	return clientGroup(id)

@clients.route('/group/<id>/task/interval',methods=['POST'])
def taskInterval(id):
	cmd = request.form.get('pk')
	interval = request.form.get('value')

	task = MpClientTasks.query.filter(MpClientTasks.group_id == id, MpClientTasks.cmd == cmd).first()
	if task is not None:
		setattr(task, 'interval', interval)
		db.session.commit()
		revGroupTasks(id)

	return clientGroup(id)

'''
********************************
	Global
********************************
'''
def getDoc(col_obj):
	return col_obj.doc

def isOwnerOfGroup(id):
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()

	if usr:
		pgroup = MpClientGroups.query.filter(MpClientGroups.group_id == id).first()
		if pgroup:
			if pgroup.group_owner == usr.user_id:
				return True
			else:
				return False

	return False

def isAdminForGroup(id):
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()

	if usr:
		q_admin = MpClientGroupAdmins.query.filter(MpClientGroupAdmins.group_id == id).all()
		if q_admin:
			result = False
			for row in q_admin:
				if row.group_admin == usr.user_id:
					result = True
					break

			return result

	return False

def accessToGroups():
	_groups = set([])
	usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
	if usr:
		q_owner = MpClientGroups.query.filter(MpClientGroups.group_owner == usr.user_id).all()
		if q_owner:
			for row in q_owner:
				_groups.add(row.group_id)

		q_admin = MpClientGroupAdmins.query.filter(MpClientGroupAdmins.group_admin == usr.user_id).all()
		if q_admin:
			for row in q_admin:
				_groups.add(row.group_id)

		return _groups
	else:
		return None

def clientStatusFromDate(date):

	result = 0
	now = datetime.now()
	x = now - date
	if x.days <= 7:
		result = 0
	elif x.days >= 8 and x.days <= 14:
		result = 1
	elif x.days >= 15:
		result = 2

	return result

def inventoryTypes():

	_jData = []
	inv = os.path.join(current_app.config['BASEDIR'], 'static/json', 'inventory.json')
	fileISOk = os.path.exists(inv)
	if fileISOk:
		with open(inv) as data_file:
			_jData = json.load(data_file)

	return _jData
	'''
	return {('HardwareOverview','Hardware Overview'),
			('SoftwareOverview','Software Overview'),
			('NetworkOverview','Network Overview'),
			('Applications','Applications'),
			('ApplicationUsage','Application Usage'),
			('DirectoryService','Directory Service'),
			('Frameworks','Frameworks'),
			('InternetPlugins','Internet Plugins'),
			('ClientTasks','Client Tasks'),
			('DiskInfo','Disk Info'),
			('SWInstalls','Software Installs'),
			('BatteryInfo','Battery Info'),
			('PowerManagment','Power Managment'),
			('FileVault','FileVault Info'),
			('PatchStatus','Patch Status'),
			('PatchHistory','Patch History')}
	'''

def defaultTasks():

	_jData = []
	tasks = os.path.join(current_app.config['BASEDIR'], 'static/json', 'default_tasks.json')
	fileISOk = os.path.exists(tasks)
	if fileISOk:
		with open(tasks) as data_file:
			_jData = json.load(data_file)

	return _jData

def json_serial(obj):
	"""JSON serializer for objects not serializable by default json code"""

	if isinstance(obj, datetime):
		serial = obj.isoformat()
		return serial
	raise TypeError("Type not serializable")
