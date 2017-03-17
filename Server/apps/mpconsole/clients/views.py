from flask import render_template, session, request, current_app
from sqlalchemy import text
from datetime import datetime, timedelta
import json
import uuid
import os
import os.path
import operator
from collections import OrderedDict

from . import clients
from .. import login_manager
from .. model import *
from .. import db
@clients.route('/clients')
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
    #cListCols = cList.keys()
    #print cListColNames
    return render_template('clients.html', cData=cList, columns=cListCols, colNames=cListColNames)

''' Client '''
@clients.route('/dashboard/<client_id>')
def clientsInfo(client_id):
    qGet = MpClient.query.filter(MpClient.cuuid == client_id).first()
    rCols = [('patch','Patch'),('description','Description'),('restart','Reboot'),('mdate','Days Needed')]


    return render_template('client_dashboard.html', cData=qGet, columns={'rPatchCols':rCols}, client_id=client_id, invTypes=inventoryTypes())

# JSON Routes
@clients.route('/dashboard/required/<client_id>')
def clientRequiredPatches(client_id):
    
    now = datetime.now()
    columns = [('patch','Patch'),('description','Description'),('restart','Reboot'),('type','Type'),('mdate','Days Needed')]

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

    return json.dumps({'data':_results,'columns': _columns}), 200

@clients.route('/dashboard/inventory/<client_id>/<inv_id>')
def clientInventoryReport(client_id, inv_id):

    rbData = []
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
                _col['title'] = column.replace('mpa_','',1).replace("_", " ")

            _col['sortable'] = 'true'
            _columns.append(_col)

    return json.dumps({'data':_results,'columns': _columns}), 200

def daysFromDate(now,date):
    x = now - date
    return x.days

''' Groups '''
@clients.route('/groups')
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
    rbData = []
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

    print _data
    print _results

    ''' Return Data '''
    return render_template('client_groups.html', data=_data, columns=cols, counts=_results, rights=list(accessToGroups()) )

@clients.route('/group/add')
def clientGroupAdd():
    ''' Returns an empty set of data to add a new record '''
    usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
    _owner = usr.user_id

    clientGroup = MpClientGroups()
    setattr(clientGroup, 'group_id', str(uuid.uuid4()))
    setattr(clientGroup, 'group_owner', _owner)

    return render_template('update_client_group.html', data=clientGroup, type="add")

@clients.route('/group/<id>/user/add',methods=['GET'])
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

    return json.dumps({'error': 0}), 200

@clients.route('/group/user/modify',methods=['POST'])
def clientGroupUserModify():
    id = request.form.get('group_id')
    uid = request.form.get('user_id')
    
    adm = MpClientGroupAdmins().query.filter(MpClientGroupAdmins.group_id == id, MpClientGroupAdmins.group_admin == uid).first()
    if adm:
        setattr(adm, 'patch_state', state)
    else:
        adm = MpClientGroupAdmins()
        setattr(adm, 'group_id', id)
        setattr(adm, 'group_admin', uid)
        db.session.add(adm)

    db.session.commit()
    return clientGroup(id,4)  

@clients.route('/group/update',methods=['POST'])
def patchGroupUpdate():

    _add = False
    _group_id    = request.form['group_id']
    _group_name  = request.form['group_name']
    _group_owner = request.form['group_owner']

    clientGroup = MpClientGroups().query.filter(MpClientGroups.group_id == _group_id).first()
    if clientGroup == None:
        _add = True
        clientGroup = MpClientGroups()

    '''
    if _owner:
        patchGroupMember = PatchGroupMembers().query.filter(PatchGroupMembers.patch_group_id == _gid,PatchGroupMembers.is_owner == 1).first()
        _owner = patchGroupMember.user_id
    else:
        patchGroupMember = PatchGroupMembers()
        usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
        _owner = usr.user_id
    '''

    setattr(clientGroup, 'group_name', _group_name)
    setattr(clientGroup, 'group_owner', _group_owner)
    if _add:
        setattr(clientGroup, 'group_id', _group_id)
        db.session.add(clientGroup)


    '''
    setattr(patchGroupMember, 'user_id', _owner)
    setattr(patchGroupMember, 'patch_group_id', _gid)
    setattr(patchGroupMember, 'is_owner', 1)

    if _add:
        db.session.add(patchGroupMember)
    '''

    db.session.commit()

    return clientGroups()

@clients.route('/group/<name>')
def clientGroup(name,tab=1):
    q_defaultGroup = MpClientGroups.query.filter(MpClientGroups.group_id == name, MpClientGroups.group_name == 'Default').first()
    canEditGroup = False
    if not isOwnerOfGroup(name) and not isAdminForGroup(name):
        if q_defaultGroup:
            canEditGroup = True
        else:
            return clientGroups()

    groupResult = {}

    #cList = MpClient.query.all()
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


    # Run Query of all clients that contain the Client ID
    rbData = []
    #sql = text("""select * From mp_clients
    #              Where cuuid in ('""" + '\',\''.join(_cuuids) + """')""")

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

    # Get Client Tasks
    _jData = None
    _qTasks = MpClientTasks.query.filter(MpClientTasks.group_id == name).all()
    _qTasksCols = MpClientTasks.__table__.columns
    if not _qTasks:
        default_tasks = os.path.join(current_app.config['BASEDIR'], 'static/json', 'default_tasks.json')
        fileISOk = os.path.exists(default_tasks)
        if fileISOk:
            with open(default_tasks) as data_file:
                _jData = json.load(data_file)

    groupResult['Clients'] = {'data': _results, 'columns': sortedCols}
    groupResult['Group'] = {'name': _qcg.group_name, 'id':name}
    groupResult['Tasks'] = {'data': _jData['mpTasks'], 'columns': _qTasksCols}
    groupResult['Software'] = {'catalogs':softwareCatalogs()}
    groupResult['Patches'] = {'groups': patchGroups()}
    groupResult['Users'] = {'users': _admins, 'columns': [('user_id','User ID'),('owner','Owner')]}
    groupResult['Admin'] = isAdminForGroup(name)
    groupResult['Owner'] = isOwnerOfGroup(name)

    profileCols = [('profileID', 'Profile ID', '0'), ('gPolicyID', 'Policy Identifier', '0'), ('pName', 'Profile Name', '1'), ('title', 'Title', '1'),
               ('description', 'Description', '1'), ('enabled', 'Enabled', '1')]    

    return render_template('client_group.html', data=_results, columns=sortedCols, group_name=_qcg.group_name, group_id=name,
                           tasks=_jData['mpTasks'], tasksCols=_qTasksCols, gResults=groupResult, selectedTab=tab, 
                           profileCols=profileCols, readOnly=canEditGroup)

@clients.route('/group/<name>/clients')
def clientGroupClients(name):

    groupResult = {}

    cList = MpClient.query.all()
    cListCols = MpClient.__table__.columns
    # Cort the Columns based on "doc" attribute
    sortedCols = sorted(cListCols, key=getDoc)

    # Get All Client IDs in with in our group
    _qcg = MpClientGroups.query.filter(MpClientGroups.group_id == name).with_entities(MpClientGroups.group_name).first()
    _res = MpClientGroupMembers.query.filter(MpClientGroupMembers.group_id == name).with_entities(MpClientGroupMembers.cuuid).all()
    _cuuids = [r for r, in _res]

    # Run Query of all clients that contain the Client ID
    rbData = []
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

''' Clients '''
@clients.route('/group/<id>/remove/clients',methods=['POST'])
def clientGroupClientsRemove(id):
    
    print id
    print request.form['clients']
    for x in request.form['clients'].split(","):
        print x


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
def clientMove():

    _cuuid      = request.form['cuuid']
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
def showClientMove(id):

    cGroups = MpClientGroups().query.all()
    #curGroup = MpClientGroupMembers().query.filter(MpClientGroupMembers.cuuid == id).first()

    return render_template('move_client_to_group.html', groups=cGroups, curGroup=0, cuuid=0)
    #return render_template('move_client_to_group.html', groups=cGroups, curGroup=curGroup.group_id, cuuid=id )

# Settings
@clients.route('/group/<id>/settings',methods=['POST'])
def groupSettings(id):
    _form = request.form
    for x in _form:
        print x
        print _form[x]

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
    if mpc != None and len(mpc) >= 1:
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


# Tasks
@clients.route('/group/<id>/task/active',methods=['POST'])
def taskState(id):
    suname = request.form.get('pk')
    state = request.form.get('value')
    print id
    print request.form

    #patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == suname).first()
    #setattr(patchAdds, 'patch_state', state)
    #db.session.commit()
    return clientGroup(id)

@clients.route('/group/<id>/task/interval',methods=['POST'])
def taskInterval(id):
    suname = request.form.get('pk')
    state = request.form.get('value')
    print id
    print request.form

    #patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == suname).first()
    #setattr(patchAdds, 'patch_state', state)
    #db.session.commit()
    return clientGroup(id)

@clients.route('/group/<id>/task/<datetype>',methods=['POST'])
def taskDate(id, datetype):
    suname = request.form.get('pk')
    state = request.form.get('value')
    print id
    print datetype
    print request.form

    #patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == suname).first()
    #setattr(patchAdds, 'patch_state', state)
    #db.session.commit()
    return clientGroup(id)

''' Client Group Methods '''
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


''' Global '''
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