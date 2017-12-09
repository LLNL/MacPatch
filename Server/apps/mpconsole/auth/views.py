from flask import render_template, flash, redirect, url_for, request, session
from flask_login import login_user, logout_user

from ldap3 import Server, Connection, ALL, AUTO_BIND_NO_TLS, SUBTREE, ALL_ATTRIBUTES

from . import auth
from .. import db
from .. model import *
from .. mputil import *
from .. mplogger import *
from . forms import LoginForm


@auth.route("/login", methods=["GET", "POST"])
def login():
	form = LoginForm()
	if form.username.data is not None:
		log("Begin login attempt for user %s" % (form.username.data))

	_ldapConf = return_data_for_root_key('ldap')
	_localAdm = return_data_for_root_key('users')

	tryLocalAdmin = False
	if 'admin' in _localAdm:
		tryLocalAdmin = _localAdm['admin']['enabled']

	if form.validate_on_submit():
		user = AdmUsers.query.filter(AdmUsers.user_id == form.username.data).first()
		if tryLocalAdmin:
			_lUser = _localAdm['admin']['name']
			_lPass = _localAdm['admin']['pass']
			if form.username.data == _lUser:
				if _lPass == form.password.data:

					if user is None:
						user = AdmUsers()
						user.user_id = form.username.data
						user.user_pass = "NA"
						db.session.add(user)
						db.session.commit()

						makeUserAdmin(user.user_id, 0)

					login_user(user, form.remember_me.data)
					session['user'] = form.username.data
					recordLoginAndAssignIfNeeded(user.user_id, 0)
					setLoginSessionInfo(user.user_id)

					log("Local admin login sucessful for user %s" % (form.username.data))
					return redirect(url_for('dashboard.index', username=user.user_id))

		if user is not None and user.check_password(form.password.data):

			if accountIsEnabled(user.user_id):
				login_user(user, form.remember_me.data)
				session['user'] = form.username.data
				recordLoginAndAssignIfNeeded(user.user_id, 1)
				setLoginSessionInfo(user.user_id)

				log("Console user login sucessful for user %s" % (form.username.data))
				return redirect(url_for('dashboard.index', username=user.user_id))
			else:
				log("User %s account is not enabled." % (form.username.data))

		else:
			if _ldapConf['enabled']:
				log_Debug("Ldap is enabled.")
				userID = ''
				if 'loginUsrPrefix' in _ldapConf:
					if _ldapConf['loginUsrPrefix'] != 'LOGIN-PREFIX':
						userID = userID + _ldapConf['loginUsrPrefix']

				userID = userID + form.username.data

				if 'loginUsrSufix' in _ldapConf:
					if _ldapConf['loginUsrSufix'] != 'LOGIN-SUFFIX':
						userID = userID + _ldapConf['loginUsrSufix']

				server = None
				if 'server' in _ldapConf and 'port' in _ldapConf and 'useSSL' in _ldapConf:
					_use_ssl = True
					if _ldapConf['useSSL'] is False:
						_use_ssl = False

					server = Server(host=_ldapConf['server'], port=int(_ldapConf['port']), use_ssl=_use_ssl)

				conn = Connection(server, user=userID, password=form.password.data)

				if conn.bind():
					conn.search(search_base=_ldapConf['searchbase'],
								search_filter='(&(objectClass=*)(userPrincipalName=userID))',
								search_scope=SUBTREE, attributes=ALL_ATTRIBUTES, get_operational_attributes=True)

					# print conn.response_to_json()

					if accountExists(form.username.data):
						if accountIsEnabled(form.username.data):
							if user is None:
								user = AdmUsers()
								user.user_id = form.username.data
								user.user_pass = "NA"
								db.session.add(user)
								db.session.commit()

							session['user'] = form.username.data
							login_user(user, form.remember_me.data)
							recordLoginAndAssignIfNeeded(user.user_id, 2)
							setLoginSessionInfo(user.user_id)

							log("LDAP login sucessful for user %s" % (form.username.data))
							return redirect(url_for('dashboard.index', username=user.user_id))
					else:
						user = AdmUsers()
						user.user_id = form.username.data
						user.user_pass = "NA"
						db.session.add(user)
						db.session.commit()

						session['user'] = form.username.data
						login_user(user, form.remember_me.data)
						recordLoginAndAssignIfNeeded(user.user_id, 2)
						setLoginSessionInfo(user.user_id)

						log("LDAP login sucessful for user %s" % (form.username.data))
						return redirect(url_for('dashboard.index', username=user.user_id))

		flash('Incorrect username or password.')
		log_Error("Failed login attempt for user %s" % (form.username.data))

	return render_template("login.html", form=form)

def accountExists(user_id):
	_account = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
	if _account:
		return True

	return False

def accountIsEnabled(user_id):
	_account = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
	if _account:
		# Need to Update
		_enabled = _account.enabled
		if _enabled == 0:
			return False

	return True

def recordLoginAndAssignIfNeeded(user_id,user_type):
	_account = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
	if _account:
		# Need to Update
		_logins = _account.number_of_logins + 1
		setattr(_account, 'last_login', datetime.now())
		setattr(_account, 'number_of_logins', _logins)

	else:
		# Add Info
		_account = AdmUsersInfo()
		setattr(_account, 'user_id', user_id)
		setattr(_account, 'user_type', user_type)
		setattr(_account, 'last_login', datetime.now())
		setattr(_account, 'number_of_logins', 1)
		setattr(_account, 'enabled', 1)
		db.session.add(_account)

	db.session.commit()
	return

def makeUserAdmin(user_id, user_type):
	_account = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
	if _account is None:
		# Add Account and Set as Admin
		_account = AdmUsersInfo()
		setattr(_account, 'user_id', user_id)
		setattr(_account, 'user_type', user_type)
		setattr(_account, 'last_login', datetime.now())
		setattr(_account, 'number_of_logins', 0)
		setattr(_account, 'enabled', 1)
		setattr(_account, 'admin', 1)
		setattr(_account, 'autopkg', 1)
		setattr(_account, 'agentUpload', 1)
		setattr(_account, 'apiAccess', 1)
		db.session.add(_account)

def setLoginSessionInfo(user_id):

	# (admin,autopkg,agentUpload,apiAccess)
	_role = (0,0,0,0)

	_account = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
	if _account:
		_role = (_account.admin,_account.autopkg,_account.agentUpload,_account.apiAccess)

	session['role'] = _role

@auth.route("/logout")
def logout():
	log("Log out user %s" % (session['user']))

	logout_user()
	session.clear()
	return redirect(url_for('main.index'))

'''
@auth.route("/signup", methods=["GET", "POST"])
def signup():
	form = SignupForm()
	if form.validate_on_submit():
		user = User(email=form.email.data,
					username=form.username.data,
					password = form.password.data)
		db.session.add(user)
		db.session.commit()
		flash('Welcome, {}! Please login.'.format(user.username))
		return redirect(url_for('.login'))
	return render_template("signup.html", form=form)
'''
