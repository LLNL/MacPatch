from flask import render_template, jsonify, request, session, g
import json

from . import console
from .. model import *
from .. import db
from .. modes import *

''' Global '''



'''
    User/Admin Roles
'''
@console.route('/accounts')
def accounts():
    _columns = [('user_id', 'User ID', '0'), ('user_type', 'User Type', '1'), 
               ('number_of_logins', 'No of Logins', '1'), ('last_login', 'Last Login', '1'), ('enabled', 'Enabled', '1')]

    _accounts = AdmUsersInfo.query.all()

    return render_template('accounts.html', data=_accounts, columns=_columns)

@console.route('/account/<user_id>',methods=['GET'])
def accountEdit(user_id):
    _columns = [('user_id', 'User ID', '0'), ('user_type', 'User Type', '1'), 
               ('number_of_logins', 'No of Logins', '1'), ('last_login', 'Last Login', '1'), ('enabled', 'Enabled', '1')]

    _accounts = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
    if _accounts:
        return render_template('account_update.html', data=_accounts, columns=_columns)
    else:
        return

    
@console.route('/account/<user_id>',methods=['POST'])
def accountUpdate(user_id):

    if adminRole():
        print "Admin"
    else:
        print "User"
    _form = request.form
    #print _form
    #print session.get('user')


'''
----------------------------------------------------------------
    Console
----------------------------------------------------------------
'''
@console.route('/admin')
def admin():
    return render_template('blank.html', data={}, columns={})

@console.route('/tasks')
def tasks():
    return render_template('console_tasks.html')

@console.route('/tasks/assignClientsToGroups',methods=['POST'])
def assignClientsToGroup():

    q_defaultGroup = MpClientGroups.query.filter(MpClientGroups.group_name == "default").first()
    if q_defaultGroup:
        defaultGroupID = q_defaultGroup.group_id
    else:
        return json.dumps({'error': 404, 'errormsg': 'Default group not found.'}), 404

    clients = MpClient.query.all()
    clientsInGroups = MpClientGroupMembers.query.all()

    for client in clients:
        if not client.cuuid in clientsInGroups:
            addToGroup = MpClientGroupMembers()
            setattr(addToGroup, 'group_id', defaultGroupID)
            setattr(addToGroup, 'cuuid', client.cuuid)
            db.session.add(addToGroup)
            db.session.commit()

    return json.dumps({'error': 0}), 200

'''
----------------------------------------------------------------
    Client Agents
----------------------------------------------------------------
'''
@console.route('/agent/deploy')
def agentDeploy(tab=1):

    columns1 = [('puuid', 'puuid', '0'), ('type', 'Type', '0'), ('osver', 'OS Ver', '1'), ('agent_ver', 'Agent Ver', '1'),
               ('version', 'Version', '1'), ('build', 'Build', '1'), ('pkg_name', 'Package', '1'), ('pkg_url', 'Package URL', '1'),
               ('pkg_hash', 'Package Hash', '1'), ('active', 'Active', '1'), ('state', 'State', '1'), ('mdate', 'Mod Date', '1')]  

    columns2 = [('rid', 'rid', '0'), ('type', 'Type', '0'), ('attribute', 'Attribute', '1'), ('attribute_oper', 'Operator', '1'),
               ('attribute_filter', 'Filter', '1'), ('attribute_condition', 'Condition', '1')]

    groupResult = {}

    qGet1 = MpClientAgent.query.all()
    cListCols = MpClientAgent.__table__.columns
    cListHiddenCols = ['state']
    cListEditCols = ['state']
    # Sort the Columns based on "doc" attribute
    sortedCols = sorted(cListCols, key=getDoc)

    qGet2 = MpClientAgentsFilter.query.all()
    cListFiltersCols = MpClientAgentsFilter.__table__.columns
    # Sort the Columns based on "doc" attribute
    sortedFilterCols = sorted(cListFiltersCols, key=getDoc)

    _agents = []
    for v in qGet1:
        _row = {}
        for column, value in v.asDict.items():
            if column != "cdate":
                if column == "active":
                    _row[column] = "Yes" if value == 1 else "No"
                else:
                    _row[column] = value

        _agents.append(_row)

    _filters = []
    for v in qGet2:
        _row = {}
        for column, value in v.asDict.items():
            _row[column] = value
            
        _row['rid'] = v.rid
        print _row
        _filters.append(_row)
        
    groupResult['Agents'] = {'data': _agents, 'columns': sortedCols}
    groupResult['Filters'] = {'data': _filters, 'columns': sortedFilterCols}
    groupResult['Admin'] = True

    return render_template('adm_agent_deploy.html', gResults=groupResult, agentCols=columns1, filterCols=columns2, selectedTab=tab)

@console.route('/agents', methods=['GET'])
def agentsList():
    
    columns = [('puuid', 'puuid', '0'), ('type', 'Type', '0'), ('osver', 'OS Ver', '1'), ('agent_ver', 'Agent Ver', '1'),
               ('version', 'Version', '1'), ('build', 'Build', '1'), ('pkg_name', 'Package', '1'), ('pkg_url', 'Package URL', '1'),
               ('pkg_hash', 'Package Hash', '1'), ('active', 'Active', '1'), ('state', 'State', '1'), ('mdate', 'Mod Date', '1')]           
    
    agents = MpClientAgent.query.all()

    _results = []
    for p in agents:
        row = {}
        for c in columns:
            y = "p."+c[0]
            row[c[0]] = eval(y)

        _results.append(row)
        print row

    return json.dumps({'data': _results, 'total': 0}, default=json_serial), 200

@console.route('/agent/filters', methods=['GET'])
def agentsFiltersList():
    
    columns = [('rid', 'rid', '0'), ('type', 'Type', '0'), ('attribute', 'Attribute', '1'), ('attribute_oper', 'Operator', '1'),
               ('attribute_filter', 'Filter', '1'), ('attribute_condition', 'Condition', '1')]           
    
    agents = MpClientAgentsFilter.query.all()

    _results = []
    for p in agents:
        row = {}
        for c in columns:
            y = "p."+c[0]
            row[c[0]] = eval(y)

        _results.append(row)
        print row

    return json.dumps({'data': _results, 'total': 0}, default=json_serial), 200

@console.route('/agent/filter/<id>', methods=['GET'])
def agentFilter(id):
    
    if id != 0:
        columns = [('rid', 'rid', '0'), ('type', 'Type', '0'), ('attribute', 'Attribute', '1'), ('attribute_oper', 'Operator', '1'),
                   ('attribute_filter', 'Filter', '1'), ('attribute_condition', 'Condition', '1')]           
        
        _filter = MpClientAgentsFilter.query.filter(MpClientAgentsFilter.rid == id).first()
    else:
        _filter = {}

    return render_template('agent_filter.html', data=_filter )

@console.route('/agent/filter/<id>', methods=['POST'])
def agentFilterPost(id):
    
    _form = request.form

    if int(id) == 0:
        # Add New
        _filter = MpClientAgentsFilter()
        setattr(_filter, 'type', 'app')
        setattr(_filter, 'attribute', _form['attribute'])
        setattr(_filter, 'attribute_oper', _form['attribute_oper'])
        setattr(_filter, 'attribute_filter', _form['attribute_filter'])
        setattr(_filter, 'attribute_condition', _form['attribute_condition'])
        db.session.add(_filter)

    else:
        # Update
        _filter = MpClientAgentsFilter.query.filter(MpClientAgentsFilter.rid == id).first()
        setattr(_filter, 'attribute', _form['attribute'])
        setattr(_filter, 'attribute_oper', _form['attribute_oper'])
        setattr(_filter, 'attribute_filter', _form['attribute_filter'])
        setattr(_filter, 'attribute_condition', _form['attribute_condition'])
        
    db.session.commit()
    return json.dumps({'error': 0}), 200

@console.route('/agent/configure')
def agentConfig():
    return render_template('console_tasks.html')

@console.route('/agent/deploy', methods=['DELETE'])
def agentDeployRemove():

    _filters = request.form['filters'].split(",")
    print request.form
    for f in _filters:
        q_remove = MpClientAgent.query.filter(MpClientAgent.puuid == str(f)).delete()
        if q_remove:
            db.session.commit()
    
    return json.dumps({'error': 0}), 200

@console.route('/agent/deploy/filter', methods=['DELETE'])
def agentDeployFilterRemove():

    _filters = request.form['filters'].split(",")
    for f in _filters:
        print "Remove " + f
        q_remove = MpClientAgentsFilter.query.filter(MpClientAgentsFilter.rid == int(f)).delete()
        if q_remove:
            db.session.commit()
    
    return json.dumps({'error': 0}), 200

'''
----------------------------------------------------------------
    Agent plugins
----------------------------------------------------------------
'''

@console.route('/agent/plugins')
def agentPluginsView():
    columns = [('rid', 'rid', '0'), ('pluginName', 'Name', '1'), ('pluginBundleID', 'Bundle ID', '1'), 
               ('pluginVersion', 'Version', '1'), ('hash', 'Hash', '1'), ('active', 'Enabled', '1')] 

    return render_template('agent_plugins.html', data={}, columns=columns)

@console.route('/agent/plugins/list', methods=['GET'])
def agentPluginsList():
    
    columns = [('rid', 'rid', '0'), ('pluginName', 'Name', '1'), ('pluginBundleID', 'Bundle ID', '1'), 
               ('pluginVersion', 'Version', '1'), ('hash', 'Hash', '1'), ('active', 'Enabled', '1')]        
    
    #agents = MPPluginHash.query.all()
    plugins = MPPluginHash.query.order_by("mp_agent_plugins.pluginBundleID").order_by("mp_agent_plugins.rid desc").all()

    _results = []
    for p in plugins:
        row = {}
        for c in columns:
            y = "p."+c[0]
            row[c[0]] = eval(y)

        _results.append(row)

    return json.dumps({'data': _results, 'total': 0}, default=json_serial), 200

@console.route('/agent/plugins/<id>', methods=['GET'])
def agentPluginsEdit(id):
    
    if id != 0:       
        _filter = MPPluginHash.query.filter(MPPluginHash.rid == id).first()
    else:
        _filter = {}

    return render_template('agent_plugins_update.html', data=_filter )

@console.route('/agent/plugins/update', methods=['POST'])
def agentPluginsUpdate():
    
    _form = request.form
    isNew = False
    if _form['rid'] == '':
        isNew = True
        x = MPPluginHash()
    else:
        x = MPPluginHash.query.filter(MPPluginHash.rid == _form['rid']).first()

    setattr(x, 'pluginName', _form['pluginName'])
    setattr(x, 'pluginBundleID', _form['pluginBundleID'])
    setattr(x, 'pluginVersion', _form['pluginVersion'])
    setattr(x, 'hash', _form['hash'])
    setattr(x, 'active', _form['active'])

    if isNew:
        db.session.add(x)

    db.session.commit()

    return json.dumps({'error': 0}), 200

@console.route('/agent/plugins', methods=['DELETE'])
def agentPluginsRemove():

    _rids = request.form['rid'].split(",")
    for r in _rids:
        q_remove = MPPluginHash.query.filter(MPPluginHash.rid == str(r)).delete()
        if q_remove:
            db.session.commit()
    
    return json.dumps({'error': 0}), 200

'''
----------------------------------------------------------------
    MacPatch Servers
----------------------------------------------------------------
'''
@console.route('/servers/mp')
def mpServerView():

    columns = [('rid', 'rid', '0'), ('server', 'Server', '1'), ('port', 'Port', '1'), ('useSSL', 'Use SSL', '1'),
                ('allowSelfSignedCert', 'Allow Self-Signed Cert', '1'),('isMaster', 'Master', '1'), ('isProxy', 'Proxy', '1'), 
                ('active', 'Enabled', '1')]  

    return render_template('mp_servers.html', columns=columns)

@console.route('/servers/mp/list', methods=['GET'])
def mpServersList():

    columns = [('rid', 'rid', '0'), ('server', 'Server', '1'), ('port', 'Port', '1'), ('useSSL', 'Use SSL', '1'),
                ('allowSelfSignedCert', 'Allow Self-Signed Cert', '1'), ('isMaster', 'Master', '1'),
                ('isProxy', 'Proxy', '1'),
                ('active', 'Enabled', '1')]

    _servers = MpServer.query.all()
    
    _results = []
    for p in _servers:
        row = {}
        for c in columns:
            y = "p."+c[0]
            res = eval(y)
            if res == 1:
                row[c[0]] = 'Yes'
            elif res == 0:
                row[c[0]] = 'No'
            else:
                row[c[0]] = res

        _results.append(row)
        print row

    return json.dumps({'data': _results, 'total': 0}, default=json_serial), 200

@console.route('/servers/mp/<id>', methods=['GET'])
def mpServerEdit(id):
    
    if id != 0:
        columns = [('rid', 'rid', '0'), ('server', 'Server', '1'), ('port', 'Port', '1'), ('useSSL', 'Use SSL', '1'),
                ('allowSelfSignedCert', 'Allow Self-Signed Cert', '1'), ('isMaster', 'Master', '1'),
                ('isProxy', 'Proxy', '1'),
                ('active', 'Enabled', '1')]      
        
        _filter = MpServer.query.filter(MpServer.rid == id).first()
    else:
        _filter = {}

    return render_template('mp_server_update.html', data=_filter )

@console.route('/servers/mp/update', methods=['POST'])
def mpServerUpdate():
    
    _form = request.form
    isNew = False
    if _form['rid'] == '':
        isNew = True
        x = MpServer()
    else:
        x = MpServer.query.filter(MpServer.rid == _form['rid']).first()

    setattr(x, 'server', _form['server'])
    setattr(x, 'port', _form['port'])
    setattr(x, 'useSSL', _form['useSSL'])
    setattr(x, 'allowSelfSignedCert', _form['allowSelfSignedCert'])
    setattr(x, 'isMaster', _form['isMaster'])
    setattr(x, 'isProxy', _form['isProxy'])
    setattr(x, 'active', _form['active'])

    if isNew:
        db.session.add(x)

    db.session.commit()

    return json.dumps({'error': 0}), 200

'''
----------------------------------------------------------------
    ASUS Servers
----------------------------------------------------------------
'''
@console.route('/servers/asus')
def asusServersView():

    columns = [('rid', 'rid', '0'), ('catalog_url', 'Catalog URL', '1'), ('os_major', 'OS Major', '1'), 
    ('os_minor', 'OS Minor', '1'),('proxy', 'Proxy', '1'), ('active', 'Enabled', '1')]  

    return render_template('asus_servers.html', columns=columns)

@console.route('/servers/asus/list', methods=['GET'])
def asusServersList():

    columns = [('rid', 'rid', '0'), ('catalog_url', 'Catalog URL', '1'), ('os_major', 'OS Major', '1'), 
    ('os_minor', 'OS Minor', '1'),('proxy', 'Proxy', '1'), ('active', 'Enabled', '1')]  

    _servers = MpAsusCatalog.query.order_by("mp_asus_catalogs.os_minor desc").all()
    
    _results = []
    for p in _servers:
        row = {}
        for c in columns:
            y = "p."+c[0]
            res = eval(y)
            if c[0] == 'proxy' or c[0] == 'active':
                if res == 1:
                    row[c[0]] = 'Yes'
                else:
                    row[c[0]] = 'No'
            else:
                row[c[0]] = res

        _results.append(row)
        print row

    return json.dumps({'data': _results, 'total': 0}, default=json_serial), 200

@console.route('/servers/asus/<id>', methods=['GET'])
def asusServerEdit(id):
    
    if id != 0:
        columns = [('rid', 'rid', '0'), ('catalog_url', 'Catalog URL', '1'), ('os_major', 'OS Major', '1'), 
        ('os_minor', 'OS Minor', '1'),('proxy', 'Proxy', '1'), ('active', 'Enabled', '1')]      
        
        _filter = MpAsusCatalog.query.filter(MpAsusCatalog.rid == id).first()
    else:
        _filter = {}

    return render_template('asus_server_update.html', data=_filter )

@console.route('/servers/asus/update', methods=['POST'])
def asusServerUpdate():
    
    _form = request.form
    isNew = False
    if _form['rid'] == '':
        isNew = True
        x = MpServer()
    else:
        x = MpServer.query.filter(MpServer.rid == _form['rid']).first()

    setattr(x, 'server', _form['server'])
    setattr(x, 'port', _form['port'])
    setattr(x, 'useSSL', _form['useSSL'])
    setattr(x, 'allowSelfSignedCert', _form['allowSelfSignedCert'])
    setattr(x, 'isMaster', _form['isMaster'])
    setattr(x, 'isProxy', _form['isProxy'])
    setattr(x, 'active', _form['active'])

    if isNew:
        db.session.add(x)

    db.session.commit()

    return json.dumps({'error': 0}), 200    

'''
----------------------------------------------------------------
    DataSources
----------------------------------------------------------------
'''
@console.route('/server/datasources')
def dataSourcesView():
    return render_template('datasources.html')

''' Global '''
def getDoc(col_obj):
    return col_obj.doc

def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(obj, datetime):
        #serial = obj.isoformat()
        serial = obj.strftime('%Y-%m-%d %H:%M:%S')
        return serial
    raise TypeError ("Type not serializable")    