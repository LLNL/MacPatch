from flask import render_template, jsonify, request, session
from werkzeug import secure_filename
from flask.ext.security import login_required
from sqlalchemy import text, or_

from flask.ext.cors import CORS, cross_origin

import base64
import re
import uuid
from time import strftime
import unicodedata
import sys
import os
import hashlib

from datetime import datetime
import json

from . import patches
from .. model import *
from .. import db

'''
----------------------------------------------------------------
Apple Patches
----------------------------------------------------------------
'''
@patches.route('/apple')
@login_required
def apple():
    #aList = ApplePatch.query.all()
    aListCols = ApplePatch.__table__.columns

    aList = ApplePatch.query.join(ApplePatchAdditions, ApplePatch.supatchname == ApplePatchAdditions.supatchname).add_columns(
        ApplePatchAdditions.severity,ApplePatchAdditions.patch_state).order_by(ApplePatch.postdate.desc()).all()

    return render_template('patches_apple.html', data=aList, columns=aListCols)

@patches.route('/apple/state',methods=['POST'])
def appleState():
    suname = request.form.get('pk')
    state = request.form.get('value')

    patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == suname).first()
    setattr(patchAdds, 'patch_state', state)
    db.session.commit()

    return apple()

@patches.route('/apple/severity',methods=['POST'])
def appleSeverity():
    suname = request.form.get('pk')
    severity = request.form.get('value')

    patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == suname).first()
    setattr(patchAdds, 'severity', severity)
    db.session.commit()

    return apple()

@patches.route('/applePatchWizard/<rid>')
@login_required
def applePatchWizard(rid):

    cList = ApplePatch.query.filter(ApplePatch.rid == rid).first()
    # Base64 Encoded Description needs to be decoded and cleaned up
    desc = base64.b64decode(cList.description64)
    if "<!DOCTYPE" in desc or "<HTML>" in desc:
        desc = desc.replace("Data('","")
        desc = desc.replace("\\n", "")
        desc = desc.replace("\\t", "")
        desc = desc.replace("')", "")
        desc = desc.replace("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">", "")
        desc = desc.replace("<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">", "")
        desc = desc.replace("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">", "")
        desc = desc.replace("<html>", "")
        desc = desc.replace("<head>", "")
        desc = desc.replace("<body>", "")
        desc = desc.replace("<title>", "")
        desc = desc.replace("</title>", "")
        desc = desc.replace("</html>", "")
        desc = desc.replace("</head>", "")
        desc = desc.replace("</body>", "")
        replaced = re.sub('<style([\S\s]*?)>([\S\s]*?)<\/style>', '', desc)
        setattr(cList,'description64',replaced)

    cListCols = ApplePatch.__table__.columns

    patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == cList.supatchname).first()
    patchCrit = ApplePatchCriteria.query.filter(ApplePatchCriteria.supatchname == cList.supatchname).order_by(ApplePatchCriteria.type_order.asc()).all()
    patchCritLen = len(patchCrit)

    return render_template('apple_patch_wizard.html', data=cList ,columns=cListCols, dataAdds=patchAdds, dataCrit=patchCrit, dataCritLen=patchCritLen)

@patches.route('/applePatchWizard/update',methods=['POST'])
@login_required
def applePatchWizardUpdate():

    print request.form
    critDict = dict(request.form)
    suname = request.form['supatchname']
    akey = request.form['akey']

    # Set / Update Values in MP Apple Patch Additions table
    patchAdds = ApplePatchAdditions.query.filter(ApplePatchAdditions.supatchname == request.form['supatchname']).first()
    setattr(patchAdds, 'patch_reboot', request.form['patch_reboot'])
    setattr(patchAdds, 'patch_install_weight', request.form['patchInstallWeight'])
    setattr(patchAdds, 'severity', request.form['patch_severity'])
    db.session.commit()

    # Remove Criteria before adding new / updating
    criDel = ApplePatchCriteria.query.filter(ApplePatchCriteria.supatchname == request.form['supatchname']).delete()
    db.session.commit()

    for key in critDict:
        if "reqCri_Order_" in key:
            nid = str(str(critDict[key][0]).split("_")[-1])
            order = critDict[key][0]

            patchCrit = ApplePatchCriteria()
            setattr(patchCrit, 'puuid', akey)
            setattr(patchCrit, 'supatchname', suname)
            setattr(patchCrit, 'type', critDict["reqCri_type_" + nid][0])
            setattr(patchCrit, 'type_action', critDict["reqCri_type_action_" + nid][0])
            setattr(patchCrit, 'type_data', critDict["reqCri_type_data_" + nid][0])
            setattr(patchCrit, 'type_order', order)
            setattr(patchCrit, 'cdate', datetime.now())
            setattr(patchCrit, 'mdate', datetime.now())

            db.session.add(patchCrit)
            db.session.commit()

    return render_template('patches_apple.html')

'''
----------------------------------------------------------------
Custom Patches
----------------------------------------------------------------
'''
@patches.route('/custom')
@login_required
def custom():
    cList = MpPatch.query.all()
    cListCols = MpPatch.__table__.columns
    cListColsLimited = ['puuid', 'patch_name', 'patch_ver', 'bundle_id', 'description', 'patch_severity', 'patch_state', 'patch_reboot', 'active', 'pkg_size', 'pkg_path', 'pkg_url', 'mdate']

    return render_template('patches_custom.html', data=cList, columns=cListColsLimited, columnsAll=cListCols)

@patches.route('/customPatchWizardAdd')
@login_required
def customPatchWizardAdd():

    cList = MpPatch()
    setattr(cList,'puuid',str(uuid.uuid4()))
    cListCols = MpPatch.__table__.columns

    return render_template('custom_patch_wizard.html',data=cList, columns=cListCols,
                           dataCrit={}, dataCritLen=0,
                           hasOSArch=False, dataReq={})

@patches.route('/customPatchWizard/<puuid>')
@login_required
def customPatchWizard(puuid):

    cList = MpPatch.query.filter(MpPatch.puuid == puuid).first()
    cListCols = MpPatch.__table__.columns

    patchCrit = MpPatchesCriteria.query.filter(MpPatchesCriteria.puuid == puuid).order_by("mp_patches_criteria.type_order asc").all()
    patchCritLen = len(patchCrit)
    patchReq = MpPatchesRequisits.query.filter(MpPatchesRequisits.puuid_ref == puuid).all()

    _hasOSArch = False
    for cri in patchCrit:
        if cri.type == "OSArch":
            _hasOSArch = True
            break

    return render_template('custom_patch_wizard.html', data=cList, columns=cListCols,
                           dataCrit=patchCrit, dataCritLen=patchCritLen,
                           hasOSArch=_hasOSArch, dataReq=patchReq)

@patches.route('/customPatchWizard/update',methods=['POST'])
@login_required
def customPatchWizardUpdate():

    _form = request.form
    print _form

    # Get Patch ID
    puuid = request.form['puuid']

    # Save File, returns path to file
    _file = request.files['mainPatchFile']
    _fileData = savePatchFile(puuid, _file)

    #print request.form
    critDict = dict(request.form)

    mpPatch = MpPatch.query.filter(MpPatch.puuid == puuid).first()
    mpPatchCols = MpPatch.__table__.columns

    criteria = []

    for key in critDict:
        for col in mpPatchCols:
            if col.name == key:
                _val = request.form[col.name]
                print("(%s) %s = (%s)" % (col.type, col.name, _val))
                setattr(mpPatch, col.name, _val)
                continue

    # Save Patch Package Info
    if _fileData['fileName'] is not None:
        setattr(mpPatch, 'pkg_name', os.path.splitext(_fileData['fileName'])[0])
        setattr(mpPatch, 'pkg_size', _fileData['fileSize'])
        setattr(mpPatch, 'pkg_hash', _fileData['fileHash'])
        setattr(mpPatch, 'pkg_path', _fileData['filePath'])
        setattr(mpPatch, 'pkg_url', _fileData['fileURL'])

    patchesCriteriaDel = MpPatchesCriteria.query.filter(MpPatchesCriteria.puuid == puuid).delete()

    for key in critDict:
        if key.startswith('req_'):

            patchesCriteria = MpPatchesCriteria()
            setattr(patchesCriteria, 'puuid', puuid)
            if key == 'req_os_type':
                setattr(patchesCriteria, 'type', 'OSType')
                setattr(patchesCriteria, 'type_data', request.form[key])
                setattr(patchesCriteria, 'type_order', 1)
                db.session.add(patchesCriteria)
                continue

            if key == 'req_os_ver':
                setattr(patchesCriteria, 'type', 'OSVersion')
                setattr(patchesCriteria, 'type_data', request.form[key])
                setattr(patchesCriteria, 'type_order', 2)
                db.session.add(patchesCriteria)
                continue

            if key == 'req_os_arch':
                setattr(patchesCriteria, 'type', 'OSArch')
                setattr(patchesCriteria, 'type_data', request.form[key])
                setattr(patchesCriteria, 'type_order', 3)
                db.session.add(patchesCriteria)
                continue

        if key.startswith('reqCri_'):

            formLst = key.split('_')
            print formLst
            nid = formLst[1]
            norder = int(request.form['reqCri_Order_'+str(nid)]) + 3
            formData = request.form['reqCri_type_data_'+str(nid)]
            formType = request.form['reqCri_type_'+str(nid)]

            patchesCriteria = MpPatchesCriteria()
            setattr(patchesCriteria, 'puuid', puuid)
            setattr(patchesCriteria, 'type', formType)
            setattr(patchesCriteria, 'type_data', formData)
            setattr(patchesCriteria, 'type_order', norder)

            print patchesCriteria

            db.session.add(patchesCriteria)
            continue

    try:
        db.session.commit()
    except Exception as e:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        print('Message: %s' % (e.message))
        return {'errorno': 500, 'errormsg': e.message, 'result': {}}, 500



    return json.dumps({'data': {}}, default=json_serial), 200


def savePatchFile(puuid, file):

    result = {}
    result['fileName'] = None
    result['filePath'] = None
    result['fileURL']  = None
    result['fileHash'] = None
    result['fileSize'] = 0

    # Save uploaded files
    upload_dir = os.path.join("/tmp", puuid)
    if not os.path.isdir(upload_dir):
        os.makedirs(upload_dir)

    if file is not None and len(file.filename) > 4:
        result['fileName'] = file.filename
        filename = secure_filename(file.filename)
        _file_path = os.path.join(upload_dir, filename)
        result['filePath'] = _file_path
        result['fileURL']  = os.path.join('patches', puuid, file.filename)

        if os.path.exists(_file_path):
            print('Removing existing file (%s)' % (_file_path))
            os.remove(_file_path)

        file.save(_file_path)

        result['fileHash'] = hashlib.md5(open(_file_path, 'rb').read()).hexdigest()
        result['fileSize'] = os.path.getsize(_file_path)

    return result

@patches.route('/custom/delete',methods=['POST'])
@login_required
def customDelete():
    print request.form
    return custom()

@patches.route('/custom/picker',methods=['GET'])
@cross_origin()
def customPatchPicker():

    query = MpPatch.query.filter(MpPatch.active == 1, or_(MpPatch.patch_state == "Production",MpPatch.patch_state == "QA")).order_by(MpPatch.patch_name.desc(),MpPatch.patch_ver.desc()).all()

    _results = []
    for p in query:
        row = {}
        row['puuid'] = p.puuid
        row['patch_name'] = p.patch_name
        row['patch_ver'] = p.patch_ver
        _results.append(row)


    return json.dumps({'data': _results}, default=json_serial), 200

'''
----------------------------------------------------------------
Patch Groups
----------------------------------------------------------------
'''
@patches.route('/patchGroups')
@login_required
def patchGroups():

    cListColsLimited = [('name','Name'), ('id', 'ID'), ('type','Type'), ('user_id', 'Owner'), ('mdate', 'Updated Last')]

    gmList = PatchGroupMembers.query.filter(PatchGroupMembers.is_owner == '1').all()
    #gmListCount = PatchGroupMembers.query.filter(PatchGroupMembers.is_owner == '1').all()

    gmListAlt = MpPatchGroup.query.join(PatchGroupMembers, MpPatchGroup.id == PatchGroupMembers.patch_group_id).add_columns(
        PatchGroupMembers.is_owner, PatchGroupMembers.user_id).filter(PatchGroupMembers.is_owner == '1') .all()

    return render_template('patch_groups.html', data=gmListAlt, columns=cListColsLimited, groupOwners=gmList)

@patches.route('/patchGroups/add')
@login_required
def patchGroupAdd():
    patchGroup = MpPatchGroup()
    setattr(patchGroup, 'id', str(uuid.uuid4()))
    patchGroupCols = MpPatchGroup.__table__.columns

    return render_template('update_patch_group.html', data=patchGroup, columns=patchGroupCols, type="add")

@patches.route('/patchGroups/edit/<id>')
@login_required
def patchGroupEdit(id):
    patchGroup = MpPatchGroup().query.filter(MpPatchGroup.id == id).first()
    patchGroupMember = PatchGroupMembers().query.filter(PatchGroupMembers.patch_group_id == id,
                                                        PatchGroupMembers.is_owner == 1).first()
    patchGroupCols = MpPatchGroup.__table__.columns

    return render_template('update_patch_group.html', data=patchGroup, columns=patchGroupCols, owner=patchGroupMember.user_id, type="edit")

@patches.route('/patchGroups/update',methods=['POST'])
@login_required
def patchGroupUpdate():

    _add = False
    _gid  = request.form['gid']
    _name = request.form['name']
    _type = request.form['type']
    if 'owner' in request.form:
        _owner = request.form['owner']
    else:
        _owner = None

    patchGroup = MpPatchGroup().query.filter(MpPatchGroup.id == _gid).first()
    if patchGroup == None:
        _add = True
        patchGroup = MpPatchGroup()

    if _owner:
        patchGroupMember = PatchGroupMembers().query.filter(PatchGroupMembers.patch_group_id == _gid,PatchGroupMembers.is_owner == 1).first()
        _owner = patchGroupMember.user_id
    else:
        patchGroupMember = PatchGroupMembers()
        usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()
        _owner = usr.user_id

    setattr(patchGroup, 'name', _name)
    setattr(patchGroup, 'type', _type)
    setattr(patchGroup, 'mdate', datetime.now())
    if _add:
        setattr(patchGroup, 'id', _gid)
        db.session.add(patchGroup)


    setattr(patchGroupMember, 'user_id', _owner)
    setattr(patchGroupMember, 'patch_group_id', _gid)
    setattr(patchGroupMember, 'is_owner', 1)

    if _add:
        db.session.add(patchGroupMember)

    db.session.commit()

    return patchGroups()

@patches.route('/patchGroups/delete/<id>',methods=['POST'])
@login_required
def patchGroupDelete(id):
    #print id
    #print session
    #print session.get('user_id')

    if isOwnerOfGroup(id):
        print "Will Remove Group"
    else:
        print "Will Not Remove Group"

    return json.dumps({'error': 399}), 200

''' Patch Group Content '''
@patches.route('/group/edit/<id>')
@login_required
def patchGroupContentEdit(id):
    patchGroup = MpPatchGroup().query.filter(MpPatchGroup.id == id).first()
    patchGroupCols = MpPatchGroup.__table__.columns
    patchGroupPatches = MpPatchGroupPatches().query.filter(MpPatchGroupPatches.patch_group_id == id).all()

    columns = [('Enabled','Enabled'), ('id','id'), ('suname', 'suname'), ('name','Patch'), ('title', 'Title'), ('version','Version'),
                ('reboot', 'Reboot'), ('type', 'Patch Type'), ('severity','Severity'),
               ('patch_state','Patch State'),  ('postdate','Post Date')]

    if patchGroup.type == 0:
        _pType = "'Production'"
    elif patchGroup.type == 1:
        _pType = "'Production','QA'"
    elif patchGroup.type == 2:
        _pType = "'Production','QA','Dev'"
    else:
        _pType = "'Production'"

    # Get Reboot Count
    rbData = []
    sql = text("""SELECT DISTINCT b.*, IFNULL(p.patch_id,'NA') as Enabled
                FROM
                    combined_patches_view b
                LEFT JOIN (
                    SELECT patch_id FROM mp_patch_group_patches
                    Where patch_group_id = '""" + id + """'
                ) p ON p.patch_id = b.id
                WHERE b.patch_state IN (""" + _pType + """)""")

    result = db.engine.execute(sql)
    _results = []
    for v in result:
        _row = {}
        for column, value in v.items():
            if column != 'patch_install_weight' and column != 'patch_reboot_override' and column != 'size' and column != 'active':
                if column == 'postdate':
                    if value is not None:
                        _row[column] = value.strftime("%Y-%m-%d %H:%M:00")
                    else:
                        _row[column] = "1970-01-01 12:00:00"
                else:
                    # Check for \r\n in tile to clean up, javascript does not like it
                    if isinstance(value, unicode):
                        _row[column] = value.replace('\n', ' ').replace('\r', '')
                    else:
                        _row[column] = value



        _results.append(_row)

    _type = "false"
    if isOwnerOfGroup(id):
        _type = "true"

    return render_template('patch_group_patches.html', name=patchGroup.name, pid=id, data=_results, columns=columns, isOwner=_type, groupID=id)

@patches.route('/group/add/<group_id>/<patch_id>')
def patchGroupContentAdd(group_id, patch_id):

    if isOwnerOfGroup(group_id):
        patchGroupPatch = MpPatchGroupPatches()
        setattr(patchGroupPatch, 'patch_group_id', group_id)
        setattr(patchGroupPatch, 'patch_id', patch_id)
        db.session.add(patchGroupPatch)
        db.session.commit()
    else:
        return json.dumps({'error': 401, 'errormsg': 'Unauthorized user.'}),401

    return json.dumps({'error': 0}), 200

@patches.route('/group/remove/<group_id>/<patch_id>')
def patchGroupContentDel(group_id, patch_id):

    if isOwnerOfGroup(group_id):
        patchGroupPatch = MpPatchGroupPatches().query.filter(MpPatchGroupPatches.patch_group_id == group_id,
                                                               MpPatchGroupPatches.patch_id == patch_id).first()
        if patchGroupPatch != None:
            db.session.delete(patchGroupPatch)
            db.session.commit()
    else:
        return json.dumps({'error': 401, 'errormsg': 'Unauthorized user.'}), 401

    return json.dumps({'error': 0}), 200

'''
----------------------------------------------------------------
Patch Status
----------------------------------------------------------------
'''
@patches.route('/required')
@login_required
def requiredList():
    columns = [('cuuid', 'Client ID', '0'), ('patch', 'Patch', '1'), ('description', 'Description', '1'),
               ('restart', 'Reboot', '1'),
               ('hostname', 'HostName', '1'), ('ipaddr', 'IP Address', '1'), ('osver', 'OS Version', '1'),
               ('type', 'Type', '1'),('mdate', 'Date', '1')]

    return render_template('patches_detected.html', columns=columns, pageTitle="Required Patches")
'''
def requiredList():

    now = datetime.now()
    columns = [('cuuid','Client ID','0'),('patch','Patch','1'),('description','Description','1'),('restart','Reboot','1'),
    ('hostname','HostName','1'),('ipaddr','IP Address','1'),('osver','OS Version','1'),('type','Type','1'),('mdate','Days Needed','1')]

    colsForQuery = ['cuuid','patch','description','restart','mdate']
    qApple = MpClientPatchesApple.query.join(MpClient, MpClient.cuuid == MpClientPatchesApple.cuuid).add_columns(
        MpClient.hostname, MpClient.osver, MpClient.ipaddr).all()

    qThird = MpClientPatchesThird().query.join(MpClient, MpClient.cuuid == MpClientPatchesThird.cuuid).add_columns(
        MpClient.hostname, MpClient.osver, MpClient.ipaddr).all()

    _results = []
    for p in qApple:
        row = {}
        for x in colsForQuery:
            y = "p[0]."+x
            if x == 'mdate':
                row[x] = daysFromDate(now, eval(y))
            elif x == 'restart':
                if eval(y)[0] == 'Y':
                    row[x] = 'Yes'
                else:
                    row[x] = 'No'
            else:
                row[x] = eval(y)

        row['type'] = 'Apple'
        row['hostname'] = p.hostname
        row['ipaddr'] = p.ipaddr
        row['osver'] = p.osver
        _results.append(row)

    for p in qThird:
        row = {}
        for x in colsForQuery:
            y = "p[0]."+x
            if x == 'mdate':
                row[x] = daysFromDate(now, eval(y))
            elif x == 'restart':
                if eval(y)[0] == 'Y':
                    row[x] = 'Yes'
                else:
                    row[x] = 'No'
            else:
                row[x] = eval(y)

        row['type'] = 'Third'
        row['hostname'] = p.hostname
        row['ipaddr'] = p.ipaddr
        row['osver'] = p.osver
        _results.append(row)       


    return render_template('patch_status.html', data=_results, columns=columns, pageTitle="Required Patches")
'''

''' AJAX Route '''
@patches.route('/required/<limit>/<offset>/<search>/<sort>/<order>')
def requiredListPaged(limit,offset,search,sort,order):

    total = 0
    getNewTotal = True
    if 'my_search_name' in session:
        if session['my_search_name'] == 'requiredList':
            if 'my_search' in session and 'my_search_total' in session:
                if session['my_search'] == search:
                    getNewTotal = False
                    total = session['my_search_total']
    else:
        session['my_search_name'] ='requiredList'
        session['my_search_total'] = 0
        session['my_search'] = None

    colsForQuery = ['cuuid', 'patch', 'description', 'type', 'restart', 'mdate']
    qResult = requiredQuery(search, int(offset), int(limit), sort, order, getNewTotal)
    query = qResult[0]

    session['my_search_name'] = 'requiredList'

    if getNewTotal:
        total = qResult[1]
        session['my_search_total'] = total
        session['my_search'] = search

    _results = []
    for p in query:
        row = {}
        for x in colsForQuery:
            y = "p[0]."+x
            if x == 'mdate':
                row[x] = eval(y)
            elif x == 'type':
                row[x] = eval(y).title()
            else:
                row[x] = eval(y)

        row['hostname'] = p.hostname
        row['ipaddr'] = p.ipaddr
        row['osver'] = p.osver
        _results.append(row)

    return json.dumps({'data': _results, 'total': total}, default=json_serial), 200

def requiredQuery(filterStr='undefined', page=0, page_size=0, sort='mdate', order='desc', getCount=True):

    if sort == 'undefined':
        sort = 'mp_client_patches.mdate'

    if sort in ['mdate', 'patch', 'patch_id', 'type', 'description', 'restart']:
        sort = 'mp_client_patches.'+sort

    if sort in ['hostname', 'ipaddr', 'osver']:
        sort = 'mp_clients.' + sort

    order_by_str = sort + ' ' + order

    filterStr = str(filterStr)
    if filterStr == 'undefined' or len(filterStr) <= 0:
        query = MpClientPatches.query.join(MpClient, MpClient.cuuid == MpClientPatches.cuuid).add_columns(
            MpClient.hostname, MpClient.osver, MpClient.ipaddr).order_by(str(order_by_str))
    else:
        query = MpClientPatches.query.join(MpClient, MpClient.cuuid == MpClientPatches.cuuid).add_columns(
            MpClient.hostname, MpClient.osver, MpClient.ipaddr).filter(or_(MpClientPatches.patch.contains(filterStr),
                                                                           MpClientPatches.patch_id.contains(filterStr),
                                                                           MpClientPatches.type.contains(filterStr),
                                                                           MpClientPatches.description.contains(filterStr),
                                                                           MpClientPatches.restart.contains(
                                                                               filterStr),
                                                                           MpClient.hostname.contains(filterStr),
                                                                           MpClient.osver.contains(filterStr),
                                                                           MpClient.ipaddr.contains(filterStr))).order_by(str(order_by_str))

    # count of rows
    if getCount:
        rowCounter = query.count()
    else:
        rowCounter = 0


    if page_size:
        query = query.limit(page_size)
    if page:
        #query = query.offset(page*page_size)
        query = query.offset(page)
    return (query, rowCounter)

@patches.route('/installed')
@login_required
def installedList():

    columns = [('cuuid','Client ID','0'),('patch','Patch','0'),('patch_name','Patch Name','1'),('hostname','HostName','1'),('ipaddr','IP Address','1'),
    ('osver','OS Version','1'),('type','Type','1'),('mdate','Install Date','1')]

    return render_template('patches_installed.html', columns=columns, pageTitle="Installed Patches")

''' AJAX Route '''
@patches.route('/installed/<limit>/<offset>/<search>')
def installedListPaged(limit,offset,search):

    total = 0
    getNewTotal = True
    if 'my_search_name' in session:
        if session['my_search_name'] == 'installedList':
            if 'my_search' in session and 'my_search_total' in session:
                if session['my_search'] == search:
                    getNewTotal = False
                    total = session['my_search_total']
    else:
        session['my_search_name'] ='installedList'
        session['my_search_total'] = 0
        session['my_search'] = None

    colsForQuery = ['cuuid', 'patch', 'patch_name', 'type', 'mdate']
    qResult = installedQuery(search, int(offset), int(limit), getNewTotal)
    query = qResult[0]

    session['my_search_name'] = 'installedList'

    if getNewTotal:
        total = qResult[1]
        session['my_search_total'] = total
        session['my_search'] = search

    _results = []
    for p in query:
        row = {}
        for x in colsForQuery:
            y = "p[0]."+x
            if x == 'mdate':
                row[x] = eval(y)
            elif x == 'type':
                row[x] = eval(y).title()
            else:
                row[x] = eval(y)

        row['hostname'] = p.hostname
        row['ipaddr'] = p.ipaddr
        row['osver'] = p.osver
        _results.append(row)

    return json.dumps({'data': _results, 'total': total}, default=json_serial), 200

def installedQuery(filterStr='undefined', page=0, page_size=0, getCount=True):

    if filterStr == 'undefined' or len(filterStr) <= 0:
        query = MpInstalledPatch.query.join(MpClient, MpClient.cuuid == MpInstalledPatch.cuuid).add_columns(
            MpClient.hostname, MpClient.osver, MpClient.ipaddr)
    else:
        query = MpInstalledPatch.query.join(MpClient, MpClient.cuuid == MpInstalledPatch.cuuid).add_columns(
            MpClient.hostname, MpClient.osver, MpClient.ipaddr).filter(or_(MpInstalledPatch.patch.contains(filterStr),
                                                                           MpInstalledPatch.patch_name.contains(filterStr),
                                                                           MpInstalledPatch.type.contains(filterStr),
                                                                           MpClient.hostname.contains(filterStr),
                                                                           MpClient.ipaddr.contains(filterStr)))

    # count of rows
    if getCount:
        rowCounter = query.count()
    else:
        rowCounter = 0

    if page_size:
        query = query.limit(page_size)
    if page:
        #query = query.offset(page*page_size)
        query = query.offset(page)
    return (query, rowCounter)


''' Global '''
def isOwnerOfGroup(id):
    usr = AdmUsers.query.filter(AdmUsers.rid == session.get('user_id')).first()

    if usr:
        pgroup = PatchGroupMembers.query.filter(PatchGroupMembers.patch_group_id == id,
                                                PatchGroupMembers.is_owner == 1).first()
        if pgroup:
            if pgroup.user_id == usr.user_id:
                return True
            else:
                return False

    return False

def getDoc(col_obj):
    return col_obj.doc    

def daysFromDate(now,date):
    x = now - date
    return x.days

def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(obj, datetime):
        #serial = obj.isoformat()
        serial = obj.strftime('%Y-%m-%d %H:%M:%S')
        return serial
    raise TypeError ("Type not serializable")