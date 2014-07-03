<cfcomponent output="false">

<cfscript>
	// The name of the application
	this.name					= "MP_ADMIN";
	// We wish to enable the session managment
	this.sessionmanagement 		= true;
	this.applicationTimeout 	= createTimeSpan( 0, 5, 0, 0 );
	// Sets the session timeout to be 4 hour; when logged in we will make the timeout 4 hours
	this.sessiontimeout 		= CreateTimeSpan( 0, 5, 0, 0 );
</cfscript>

<!--- Define the request settings. --->
<cfsetting showdebugoutput="false" />

<!--- Create mapping for cfc objects --->
<cfmapping logicalpath="/root" relativepath="/">
<!---
<cfmapping logicalpath="/admin" relativepath="/admin">
<cfmapping logicalpath="/inc" relativepath="/admin/includes">
--->
<!--- ---------------------------------------------
	This is where we can set some variables for the application scope
	http://openbd.org/manual/?/app_application
--->
<cffunction name="onApplicationStart">
	<cfset StructClear(application) />
	<cfset application.starttime = now()>
    <cfreturn true />
</cffunction>

<cffunction name="onApplicationEnd" returnType="void" output="false">
    <cfargument name="applicationScope" required="true" />
    <cfreturn />
</cffunction>

<!--- ---------------------------------------------
	This is called for each request
	http://openbd.org/manual/?/app_application
	--->
<cffunction name="onRequestStart">
	<cfargument name="uri" required="true"/>
    
    <!--- Is Site using HTTPS --->
    <cfset isSecure = false>
    <cfif isDefined("CGI.HTTP_REFERER")>
		<cfif FindNoCase("https",CGI.HTTP_REFERER) NEQ 0>
            <cfset isSecure = true>
        </cfif> 
    </cfif>
    <cfif isDefined("CGI.HTTP_ORIGIN")>
		<cfif FindNoCase("https",CGI.HTTP_ORIGIN) NEQ 0>
            <cfset isSecure = true>
        </cfif> 
    </cfif>
	<!--- Error Page 
	<cferror type="exception" template="/admin/error/error.cfm" exception="any">
	--->
	
	<!---
		This tells the browser never to cache the secure pages so people are prevented from going
		'back' in their browser history to see this page
	--->
	<cfheader name="Cache-Control" value="no-cache,no-store,must-revalidate">
	<cfheader name="Pragma" value="no-cache">
	<cfheader name="Expires" value="Tues, 13 Sep 2000 00:00:00 GMT">
	
	<cfif StructKeyExists(form, "_user") && StructKeyExists(form, "_pass")>
		<!---	User is attempting to login at this point; we call one of the login functions	--->
		<cfif logInUserSimple( form._user, form._pass )>
        	<cflog file="MPLoginErrorDEV" type="error" application="no" text="logInUserSimple">
			<cfset session.loggedin = true>
            <cfset session.Username="#form._user#">
            <cfset session.RealName = #session.Username#>
            <cfset session.IsAdmin=#logInUserGroupRights(form._user,'0')#>
            <cfset session.dbsource="mpds">
            <cfset session.cgrp="">
            <cfset session.usrKey=#Generatesecretkey("AES")#>
        <cfelseif logInUserDatabase( form._user, form._pass )> 
        	<cflog file="MPLoginErrorDEV" type="error" application="no" text="logInUserDatabase">
        	<cfset session.loggedin = true>
            <cfset session.Username="#form._user#">
            <cfset session.IsAdmin=#logInUserGroupRights(form._user,'1')#>
            <cfset session.dbsource="mpds">
            <cfset session.cgrp="">
            <cfset session.usrKey=#Generatesecretkey("AES")#>
        <cfelseif logInUserDirectory( form._user, form._pass )> 
        	<cflog file="MPLoginErrorDEV" type="error" application="no" text="logInUserDirectory">
        	<cfset session.loggedin = true>
            <cfset session.Username="#form._user#">
            <cfset session.IsAdmin=#logInUserGroupRights(form._user,'2')#>
            <cfset session.dbsource="mpds">
            <cfset session.cgrp="">
            <cfset session.usrKey=#Generatesecretkey("AES")#>
		<cfelse>
        	<cflog file="MPLoginErrorDEV" type="error" application="no" text="else">
			<cfset StructDelete(session,"loggedin")>
			<cfset session.error = "Incorrect username or password">
            <cfif _AppSettings.j2eeType EQ "JETTY">
                <cfset location("https://#cgi.HTTP_HOST#/")>
            <cfelse>
                <cfset location("/admin")>
            </cfif>   
		</cfif>
        
        <cfinvoke component="root.Server.settings" method="getAppSettings" returnvariable="_AppSettings" />
        <cfif isSecure>
			<cfset session.cflocFix = "https://#cgi.HTTP_HOST#">
        <cfelse>
        	<cfset session.cflocFix = "http://#cgi.HTTP_HOST#">    
        </cfif>                        
    	<cfset application.settings = _AppSettings>
        <cfset application.settings.users.admin.pass = "">

        <!--- Clear the login form variables, so they dont get re-used --->
        <cfset StructClear(form)>
        <cfscript>
        	this.start=now();
    	</cfscript>
	</cfif>

	<!---
		We do a check to make sure the user is still logged in; if not we throw
		them back to the main page
		--->
	<cfif !StructKeyExists( session, "loggedin" )>
		<cfset session.error = "Session has expired">
		<cfset location("/admin")>
	</cfif>

</cffunction>

<!---
<cffunction name="onSessionStart">
    <cflock timeout="5" throwontimeout="No" type="EXCLUSIVE" scope="SESSION">
        <cfset Application.sessions = Application.sessions + 1>
    </cflock>
</cffunction>
--->

<cffunction name="onSessionEnd" access="public" returntype="void" output="false">
	<!--- Define arguments. --->
    <cfargument name="sessionScope" type="any" required="true"/>
    <cfargument name="applicationScope" type="any" required="true"/>

    <!--- Output the CFID and CFTOKEN values to the log. --->
    <cffile
        action="append"
        file="#getDirectoryFromPath( getCurrentTemplatePath() )#log.cfm"
        output="ENDED: #arguments.sessionScope.cfid#<br />"
        />
        
    <cfloop item="name" collection="#cookie#">
        <cfcookie name="#name#" value="" expires="now" />
    </cfloop>    
	<cfset StructClear(session)>
	<cfset session.error = "Session has expired">
	<cfset location("..")>
    <!--- Return out. --->
    <cfreturn />
</cffunction>

<!--- ----------------------------------------------------------------------
	Error handeling for the app.
	--->
    
<cffunction name="onError">
    <cfargument name="Exception" required=true/>
    <cfargument type="String" name="EventName" required=true/>
    <!--- Log all errors. --->
    <cflog file="#This.Name#" type="error" text="Event Name: #Eventname#">
    <cflog file="#This.Name#" type="error" text="Message: #exception.message#">
    <!--- Some exceptions, including server-side validation errors, do not
             generate a rootcause structure. --->
    <cfif isdefined("exception.rootcause")>
        <cflog file="#This.Name#" type="error" text="Root Cause Message: #exception.rootcause.message#">
    </cfif>    
    <!--- Display an error message if there is a page context. --->
    <cfif NOT (Arguments.EventName EQ "onSessionEnd") OR (Arguments.EventName EQ "onApplicationEnd")>
        <cfoutput>
            <h2>An unexpected error occurred.</h2>
            <p>Please provide the following information to technical support:</p>
            <p>Error Event: #EventName#</p>
            <p>Error details:<br>
            <cfdump var=#exception#></p>
            <cfdump var=#application#></p>
        </cfoutput>
    </cfif>
 </cffunction>

<!--- ----------------------------------------------------------------------
	A very basic login script that will simply authenticate against some hardcoded
	values; not at all practical and only here for demonstration purposes
	--->
<cffunction name="logInUserSimple" returntype="boolean" access="private">
	<cfargument name="username" required="true"/>
	<cfargument name="password" required="true" />

	<cfinvoke component="root.Server.settings" method="getAppSettings" returnvariable="_AppSettings" />
    <cfset _usr = #_AppSettings.users.admin.name#>
    <cfset _pas = #hash(arguments.password,"MD5")#>

	<cfif arguments.username == "demo" && arguments.password == "password">
		<cfreturn true>
    <cfelseif arguments.username == #_usr# && _pas == #_AppSettings.users.admin.pass#>
    	<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<!--- ----------------------------------------------------------------------
	This one will authenticate against a table in a remote database; let us assume
	the database is under the datasource "mydatabase" and the table has fields:

	username varchar(32)
	password varchar(32) which is an MD5 of the password

	You should _never_ store the raw password in the database, instead think of
	storing it as an MD5/SHA1 with a unique salt against it.  Usually you use their
	username and another token as their salt.  That way every user does not have the
	same salt.  Making it hard to do a reverse dictionary lookup.

	This will then return back that particular users row as a structure and put it
	in the session scope for later retrieval
	--->
<cffunction name="logInUserDatabase" returntype="boolean" access="private">
	<cfargument name="username" required="true"/>
	<cfargument name="password" required="true" />
	
	<cfset var qry = true>
    <cftry>
        <cfquery name="qry" datasource="mpds">
            select *
            from mp_adm_users
            where
                user_id	= <cfqueryparam value="#LCase(arguments.username)#" />
                and user_pass = <cfqueryparam value="#hash(arguments.password,'MD5')#" />
				and enabled = '1'
        </cfquery>
        <cfif qry.recordcount == 0>
            <cfreturn false>
        <cfelse>
        	<cfset session.RealName = #qry.user_RealName#>
            <cfset session.userrecord = QueryRowstruct( qry, 1 )>
            <cfreturn true>
        </cfif>
	<cfcatch type="any">
        <cflog file="MPLoginError" type="error" application="no" text="Error: On query for user (#arguments.username#)">
        <cflog file="MPLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
        <cflog file="MPLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
    </cfcatch>
    </cftry>
	
    <cfreturn false>
</cffunction>

<cffunction name="logInUserDirectory" returntype="boolean" access="private">
	<cfargument name="username" required="true"/>
	<cfargument name="password" required="true" />

	<cfset var qry = true>
    <cftry>
        <cfldap
              server="#application.settings.ldap.server#"
              action="QUERY"
              name="qry"
              start="#application.settings.ldap.searchbase#"
              attributes="#application.settings.ldap.attributes#"
              filter="(&(objectClass=*)(userPrincipalName=#arguments.username##application.settings.ldap.loginUsrSufix#))"
              scope="SUBTREE"
              port="#application.settings.ldap.port#"
              username="#arguments.username##application.settings.ldap.loginUsrSufix#"
              password="#arguments.password#"
              secure="#application.settings.ldap.secure#"
        >
        <cfif qry.recordcount == 0>
            <cfreturn false>
        <cfelse>
        	<cfset session.RealName = "#qry.givenname# #qry.sn#">
            <cfset session.userrecord = QueryRowstruct( qry, 1 )>
            <cfreturn true>
        </cfif>
    <cfcatch type="any">
        <cflog file="MPLoginError" type="error" application="no" text="Error: On query directory user (#arguments.username##application.settings.ldap.loginUsrSufix#)">
        <cflog file="MPLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
        <cflog file="MPLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
    </cfcatch>
    </cftry>
    
	<cfreturn false>
</cffunction>

<cffunction name="logInUserGroupRights" returntype="boolean" access="private">
	<cfargument name="username" required="true"/>
	<cfargument name="usertype" required="true"/>
    
    <cfset var result = false>
    <cfquery name="qGroupRights" datasource="mpds"> 
        Select user_id, group_id, number_of_logins
        From mp_adm_group_users
        Where user_id in ('#arguments.username#')
    </cfquery>
    
    <cfif qGroupRights.recordcount EQ 0>
        <cfquery name="qAddAccount" datasource="mpds"> 
            Insert Into mp_adm_group_users ( user_id, user_type, last_login, number_of_logins)
            Values ( '#arguments.username#', '#arguments.usertype#', #CreateODBCDateTime(now())#, '1')
        </cfquery>
	<cfelseif qGroupRights.recordcount EQ 1 AND qGroupRights.group_id EQ 0>
		<cfset result = true>
	</cfif>
	<cfif #arguments.username# EQ application.settings.users.admin.name>
		<cfset result = true>
    <cfelseif #arguments.username# EQ application.settings.users.admin.pass>
    	<cfset result = true>     
	</cfif>
    
	<cfset tmp = updateLogInInfo(arguments.username,qGroupRights.number_of_logins)>
    
    <cfreturn #result#>
</cffunction>

<cffunction name="updateLogInInfo" access="private" returntype="any">
	<cfargument name="username" required="true"/>
    <cfargument name="loginCount" default="0">
    
    <cfif arguments.loginCount EQ "">
    	<cfset arguments.loginCount = 0>
    </cfif>     
    
    <cfset logins = arguments.loginCount + 1>
    <cfquery name="qUpdateAccount" datasource="mpds"> 
        Update mp_adm_group_users 
        Set last_login = #CreateODBCDateTime(now())#,
        	number_of_logins = '#logins#'
        Where    
        	user_id = '#arguments.username#'
    </cfquery>
</cffunction>

</cfcomponent>
