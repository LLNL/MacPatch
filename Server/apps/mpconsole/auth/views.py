from flask import render_template, flash, redirect, url_for, request, session
from flask_login import login_user, logout_user

from ldap3 import Server, Connection, ALL, AUTO_BIND_NO_TLS, SUBTREE, ALL_ATTRIBUTES
import ldap3

from . import auth
from .. import db
from ..model import *
from .forms import LoginForm


@auth.route("/login", methods=["GET", "POST"])
def login():

    form = LoginForm()
    if form.validate_on_submit():
        user = AdmUsers.query.filter(AdmUsers.user_id == form.username.data ).first()
        if user is not None and user.check_password(form.password.data):
            
            if accountIsEnabled(user.user_id):
                login_user(user, form.remember_me.data)
                session['user'] = form.username.data
                recordLoginAndAssignIfNeeded(user.user_id, 1)
                setLoginSessionInfo(user.user_id)
                return redirect(url_for('dashboard.index', username=user.user_id))
            
        else:
            userID = form.username.data + "@llnl.gov"
            server = Server(host='adroot-1.empty-root.llnl.gov', port=3269, use_ssl=True)
            conn = Connection(server, user=userID, password=form.password.data)

            if conn.bind():
                conn.search(search_base='DC=llnl,DC=gov',
                            search_filter='(&(objectClass=*)(userPrincipalName=userID))',
                            search_scope=SUBTREE, attributes=ALL_ATTRIBUTES, get_operational_attributes=True)
                
                # print conn.response_to_json()
                
                if accountIsEnabled(user.user_id):

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
                    return redirect(url_for('dashboard.index', username=user.user_id))

        #flash('Incorrect username or password.')
    return render_template("login.html", form=form)

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

def setLoginSessionInfo(user_id):

    # (admin,autopkg,agentUpload,apiAccess)
    _role = (0,0,0,0)
    
    _account = AdmUsersInfo.query.filter(AdmUsersInfo.user_id == user_id).first()
    if _account:
        _role = (_account.admin,_account.autopkg,_account.agentUpload,_account.apiAccess)

    session['role'] = _role

@auth.route("/logout")
def logout():
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