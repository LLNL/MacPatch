<!--- **************************************************************************************** --->
<!---
		MPAdminService 
	 	Database type is MySQL
		MacPatch Version 2.6.6.x
--->
<!---	Notes:
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
    <cfset this.cacheDirName = "cacheIt">
    <cfset this.logTable = "ws_adm_logs">
	<cfset this.settings = server.mpsettings.settings>

	<cffunction name="init" returntype="MPAdminService" output="no">
		<cfreturn this>
	</cffunction>

    <!--- Logging function, replaces need for ws_logger (Same Code) --->
    <cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">

        <cfscript>
			try {
				inet = CreateObject("java", "java.net.InetAddress");
				inet = inet.getLocalHost();
			} catch (any e) {
				inet = "localhost";
			}
		</cfscript>

    	<cfquery datasource="#this.ds#" name="qGet">
            Insert Into #this.logTable# (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
    </cffunction>

    <cffunction name="elogit" access="public" returntype="void" output="no">
        <cfargument name="aEvent">
        
        <cfset l = logit("Error",arguments.aEvent)>
        <cfreturn>
    </cffunction>

	<cffunction name="responseObj" access="private" returntype="struct" output="no">
        <cfargument name="resultType" required="yes" default="0" displayname="0=String,1=Struct">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfif arguments.resultType EQ 0>
        	<cfset response[ "result" ] = "" />
        <cfelse>
        	<cfset response[ "result" ] = {} />    
		</cfif>
		<cfset response[ "machineName" ] = "" />
        <cfset response[ "hostName" ] = "" />
		
        <cftry>
			<cfscript>
                machineName = createObject("java", "java.net.InetAddress").localhost.getCanonicalHostName();
                hostaddress = createObject("java", "java.net.InetAddress").localhost.getHostAddress();
            </cfscript>
    
            <cfset response[ "machineName" ] = "#machineName#" />
            <cfset response[ "hostName" ] = "#hostaddress#" />
	
            <cfcatch type="any">
                <cfset l = elogit("[responseObj]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
        
        <cfreturn response>
    </cffunction>
	
	<cffunction name="patchObj" access="private" returntype="struct" output="no">

		<!--- Not Used Yet, should delete it soon --->
        <cfset response = {} />
        <cfset response[ "OSArch" ] = "X86" />
        <cfset response[ "OSType" ] = "Desktop" />
		<cfset response[ "OSVersion" ] = "*" />
        <cfset response[ "bundle_id" ] = "" />
		<cfset response[ "description" ] = "" />
        <cfset response[ "description_url" ] = "" />
		<cfset response[ "patch_criteria_encoded" ] = arrayNew(1) />
        <cfset response[ "patch_env_var" ] = "" />
		<cfset response[ "patch_install_weight" ] = "" />
        <cfset response[ "patch_name" ] = "" />
		<cfset response[ "patch_postinstall_script" ] = "" />
        <cfset response[ "patch_preinstall_script" ] = "" />
		<cfset response[ "patch_reboot" ] = "No" />
        <cfset response[ "patch_severity" ] = "" />
		<cfset response[ "patch_state" ] = "" />
		<cfset response[ "patch_status" ] = "" />
        <cfset response[ "patch_vendor" ] = "" />
		<cfset response[ "patch_version" ] = "0" />
		
        <cfreturn response>
    </cffunction>

    <cffunction name="autoPKGObj" access="private" returntype="struct" output="no">

    	<cfset response = {} />

        <cfset response[ "puuid" ] = "" />
		<cfset response[ "bundle_id" ] = "" />
		<cfset response[ "patch_name" ] = "" />
		<cfset response[ "patch_ver" ] = "" />
		<cfset response[ "patch_vendor" ] = "" />
		<cfset response[ "patch_install_weight" ] = "30" />
		<cfset response[ "description" ] = "" />
		<cfset response[ "description_url" ] = "" />
		<cfset response[ "patch_severity" ] = "High" />
		<cfset response[ "patch_state" ] = "" />
		<cfset response[ "patch_reboot" ] = "No" />
		<cfset response[ "cve_id" ] = "" />
		<cfset response[ "active" ] = "0" />
		<cfset response[ "pkg_preinstall" ] = "" />
		<cfset response[ "pkg_postinstall" ] = "" />
		<cfset response[ "pkg_name" ] = "AUTOPKG" />
		<cfset response[ "pkg_env_var" ] = "" />
		<!--- Criteria --->
		<cfset response[ "OSArch" ] = "X86" />
		<cfset response[ "OSType" ] = "Mac OS X, Mac OS X Server" />
		<cfset response[ "OSVersion" ] = "*" />
		<cfset response[ "patch_criteria_enc" ] = arrayNew(1) />
		
        <cfreturn response>
    </cffunction>
	
<!--- **************************************************************************************** --->
<!--- Admin User Auth --->

	<cffunction name="logInUserSimple" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
		<cfargument name="password" required="true" />
	
	    <cfset _usr = #this.settings.users.admin.name#>
	    <cfset _pas = #hash(arguments.password,"MD5")#>
		
	    <cfif arguments.username == #_usr# && _pas == #this.settings.users.admin.pass#>
	    	<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	
	</cffunction>

	<cffunction name="logInUserDatabase" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
		<cfargument name="password" required="true" />
	
		<cfset var qry = true>
	    <cftry>
	        <cfquery name="qry" datasource="#this.ds#">
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
	            <cfreturn true>
	        </cfif>
			<cfcatch type="any">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error: On query for user (#arguments.username#)">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
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
	              server="#this.settings.ldap.server#"
	              action="QUERY"
	              name="qry"
	              start="#this.settings.ldap.searchbase#"
	              attributes="#this.settings.ldap.attributes#"
	              filter="(&(objectClass=*)(userPrincipalName=#arguments.username##this.settings.ldap.loginUsrSufix#))"
	              scope="SUBTREE"
	              port="#this.settings.ldap.port#"
	              username="#arguments.username##this.settings.ldap.loginUsrSufix#"
	              password="#arguments.password#"
	              secure="#this.settings.ldap.secure#"
	        >
	        <cfif qry.recordcount == 0>
	            <cfreturn false>
	        <cfelse>
	            <cfreturn true>
	        </cfif>
		    <cfcatch type="any">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error: On query directory user (#arguments.username##this.settings.ldap.loginUsrSufix#)">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
		    </cfcatch>
	    </cftry>
	    
		<cfreturn false>
	</cffunction>

	<cffunction name="logInUserGroupRights" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
		<cfargument name="usertype" required="true"/>
	    
	    <cfset var result = false>

	    <!--- See if the user exists and get properties --->
	    <cfquery name="qGroupRights" datasource="#this.ds#"> 
	        Select user_id, group_id, number_of_logins
	        From mp_adm_group_users
	        Where user_id in ('#arguments.username#')
	    </cfquery>
	    
	    <!--- does not exist, add login entry and put in user group --->
	    <cfif qGroupRights.recordcount EQ 0>
	        <cfquery name="qAddAccount" datasource="#this.ds#"> 
	            Insert Into mp_adm_group_users ( user_id, user_type, last_login, number_of_logins)
	            Values ( '#arguments.username#', '#arguments.usertype#', #CreateODBCDateTime(now())#, '1')
	        </cfquery>
		<cfelseif qGroupRights.recordcount EQ 1 AND qGroupRights.group_id EQ 0>
			<cfset result = true>
		</cfif>

		<cfset tmp = updateLogInInfo(arguments.username,qGroupRights.number_of_logins)>
	    
	    <cfreturn #result#>
	</cffunction>

	<cffunction name="logInUserAutoPKG" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
	    
	    <cfset var result = false>

	    <!--- See if the user exists and get properties --->
	    <cftry>
		    <cfquery name="qGroupRights" datasource="#this.ds#"> 
		        Select user_id, user_type, group_id
		        From mp_adm_group_users
		        Where user_id in ('#arguments.username#')
		    </cfquery>
		    
		    <!--- 0 = Admin, 1 = User, 2 = autopkg --->
		    <cfif qGroupRights.recordcount EQ 1>
		        <cfif qGroupRights.group_id EQ 0>
		        	<cfset result = true>
		        </cfif>
		        <cfif qGroupRights.group_id EQ 2>
		        	<cfset result = true>
		        </cfif>
			</cfif>
			<cfcatch>
				<cflog file="MPAdminLoginError" type="error" application="no" text="#cfcatch.message# #cfcatch.detail#">
			</cfcatch>
		</cftry>

	    <cfreturn #result#>
	</cffunction>

	<cffunction name="updateLogInInfo" access="private" returntype="any">
		<cfargument name="username" required="true"/>
	    <cfargument name="loginCount" default="0">
	    
	    <cfif arguments.loginCount EQ "">
	    	<cfset arguments.loginCount = 0>
	    </cfif>     
	    
	    <cfset logins = arguments.loginCount + 1>
	    <cfquery name="qUpdateAccount" datasource="#this.ds#"> 
	        Update mp_adm_group_users 
	        Set last_login = #CreateODBCDateTime(now())#,
	        	number_of_logins = '#logins#'
	        Where    
	        	user_id = '#arguments.username#'
	    </cfquery>
	</cffunction>	
	
	<cffunction name="userHasAuthToken" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
	
		<cfset var qry = true>
	    <cftry>
	        <cfquery name="qry" datasource="#this.ds#">
	            select authToken1, authToken2
	            from mp_adm_group_users
	            where
	                user_id	= <cfqueryparam value="#LCase(arguments.username)#" />
					and enabled = '1'
	        </cfquery>
	        <cfif qry.recordcount == 0>
	            <cfreturn false>
	        <cfelse>
	        	<cfif qry.authToken1 EQ "">
	            	<cfreturn false>
	            <cfelse>	
	            	<cfreturn true>
	            </cfif>
	        </cfif>
			<cfcatch type="any">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error: On query for user (#arguments.username#)">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
		    </cfcatch>
	    </cftry>
		
	    <cfreturn false>
	</cffunction>
	
	<cffunction name="writeUserAuthToken" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
		<cfargument name="token" required="true"/>
	
		<cfset var qry = true>
	    <cftry>
	        <cfquery name="qry" datasource="#this.ds#">
	            select authToken1, authToken2
	            from mp_adm_group_users
	            where
	                user_id	= <cfqueryparam value="#LCase(arguments.username)#" />
					and enabled = '1'
	        </cfquery>
	        <cfif qry.recordcount == 0>
	            <cfreturn false>
	        <cfelse>
	        	<cfif qry.authToken1 EQ "">
	            	<cfquery name="qryIn" datasource="#this.ds#">
		            	UPDATE mp_adm_group_users 
		            	set authToken1 = <cfqueryparam value="#arguments.token#" />
						Where user_id = <cfqueryparam value="#LCase(arguments.username)#" />
			        </cfquery>
			        <cfreturn true>
	            <cfelse>	
	            	<cflog file="MPAdminLoginError" type="error" application="no" text="Assign new token and backup last token.">
	            	<cfset autht1 = qry.authToken1>
	            	<cfquery name="qryIn2" datasource="#this.ds#">
		            	UPDATE mp_adm_group_users 
		            	set authToken1 = <cfqueryparam value="#arguments.token#" />,
		            	authToken2 = <cfqueryparam value="#autht1#" />
						Where user_id = <cfqueryparam value="#LCase(arguments.username)#" />
			        </cfquery>
			        <cfreturn true>
	            </cfif>
	        </cfif>
			<cfcatch type="any">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error: On query for user (#arguments.username#)">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
		    </cfcatch>
	    </cftry>
		
	    <cfreturn false>
	</cffunction>
	
	<cffunction name="isValidAuthToken" returntype="boolean" access="private">
		<cfargument name="username" required="true"/>
		<cfargument name="token" required="true"/>
	
		<cflog file="MPAdminLoginError" type="error" application="no" text="Verifying token for #arguments.username#.">
		<cfset var qry = true>
	    <cftry>
	        <cfquery name="qry" datasource="#this.ds#">
	            select authToken1, authToken2
	            from mp_adm_group_users
	            where
	                user_id	= <cfqueryparam value="#LCase(arguments.username)#" />
	                and enabled = '1'
	                and (authToken1 = <cfqueryparam value="#arguments.token#" />
	                	or
	                	authToken2 = <cfqueryparam value="#arguments.token#" />) 
	        </cfquery>
	        <cfif qry.recordcount == 0>
	            <cfreturn false>
	        <cfelse>
	        	<cfreturn true>
	        </cfif>
			<cfcatch type="any">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error: On query for user (#arguments.username#)">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
		        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
		    </cfcatch>
	    </cftry>
		
	    <cfreturn false>
	</cffunction>


<!--- **************************************************************************************** --->
<!--- Begin Admin WebServices Methods --->

	<cffunction name="WSLTest" access="remote" returnType="struct" returnFormat="json" output="false">
    
        <cfset response = responseObj(0) />
        <cfset response[ "result" ] = #CreateODBCDateTime(now())# />
        
        <cfreturn response>
    </cffunction>
	
	<cffunction name="GetAuthToken" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="authUser">	
		<cfargument name="authPass">	
    
        <cfset response = responseObj(0) />
		<cfset var userSession = {}>
		<cflog file="MPAdminLoginError" type="error" application="no" text="*******************************************************">
		<cflog file="MPAdminLoginError" type="error" application="no" text="GetAuthToken for #arguments.authUser#">

        <!---	User is attempting to login at this point; we call one of the login functions	--->
		<cfif logInUserSimple( arguments.authUser, arguments.authPass )>
            <cfset userSession.IsAdmin=true>
            <cfset userSession.usrKey=#hash(Generatesecretkey("AES"),"SHA")#>
            <cfset userSession.IsAutoPKG=#logInUserAutoPKG(arguments.authUser)#>
            <!--- <cfset userSession.usrKey=#Generatesecretkey("AES",256)#> --->
        <cfelseif logInUserDatabase( arguments.authUser, arguments.authPass )> 
            <cfset userSession.IsAdmin=#logInUserGroupRights(arguments.authUser,'1')#>
            <cfset userSession.usrKey=#hash(Generatesecretkey("AES"),"SHA")#>
            <cfset userSession.IsAutoPKG=#logInUserAutoPKG(arguments.authUser)#>

        <cfelseif logInUserDirectory( arguments.authUser, arguments.authPass )> 
            <cfset userSession.IsAdmin=#logInUserGroupRights(arguments.authUser,'2')#>
            <cfset userSession.usrKey=#hash(Generatesecretkey("AES"),"SHA")#>
            <cfset userSession.IsAutoPKG=#logInUserAutoPKG(arguments.authUser)#>

		<cfelse>
			<cflog file="MPAdminLoginError" type="error" application="no" text="No authentication scheme was found.">
			<cfset response[ "errorno" ] = 1001 />
			<cfset response[ "errormsg" ] = "Incorrect username or password" />
			<cfset response[ "result" ] = "" />
			<cfreturn response>
		</cfif>
		
		<cfif userSession.IsAdmin EQ False and userSession.IsAutoPKG EQ False>
			<cflog file="MPAdminLoginError" type="error" application="no" text="#arguments.authUser# is not an admin account.">
			<cfset response[ "errorno" ] = 1002 />
			<cfset response[ "errormsg" ] = "User has no rights to perform requests." />
			<cfset response[ "result" ] = "" />
			<cfreturn response>
		</cfif>
		
		<cfif userHasAuthToken(arguments.authUser) EQ true>
			<cflog file="MPAdminLoginError" type="error" application="no" text="userHasAuthToken=true">
			<cfif writeUserAuthToken(arguments.authUser,userSession.usrKey) EQ False>
				<cfset response[ "errorno" ] = 1003 />
				<cfset response[ "errormsg" ] = "Unable to update token." />
				<cfset response[ "result" ] = "" />
				<cfreturn response>
			</cfif>
		<cfelse>
			<cflog file="MPAdminLoginError" type="error" application="no" text="userHasAuthToken=false">
			<cfif writeUserAuthToken(arguments.authUser,userSession.usrKey) EQ False>
				<cfset response[ "errorno" ] = 1004 />
				<cfset response[ "errormsg" ] = "Unable to update token." />
				<cfset response[ "result" ] = "" />
				<cfreturn response>
			</cfif>
		</cfif>
		
		<cflog file="MPAdminLoginError" type="error" application="no" text="GetAuthToken successful for #arguments.authUser#">
		<cflog file="MPAdminLoginError" type="error" application="no" text="-------------------------------------------------------">
		<cfset response[ "result" ] = "#userSession.usrKey#" />
        <cfreturn response>
    </cffunction>
	
	<cffunction name="AgentConfig" access="remote" returnType="struct" returnFormat="json" output="false">
    	<cfargument name="token">
		<cfargument name="user">	
	
        <cfset response = responseObj(0) />
		<cfset var _config = {}>
		
		<cfif NOT isValidAuthToken(arguments.user,arguments.token)>
			<cfset response.errorNo = "9000">
			<cfset response.errorMsg = "Invalid auth data.">
			<cfreturn response>
		</cfif>

		<cftry>
			<cfquery datasource="mpds" name="qGetAgentConfig">
				select * from mp_servers
				Where isMaster = 1 OR isProxy = 1
				AND active = 1
			</cfquery>
			
			<cfif qGetAgentConfig.RecordCount GTE 1>
				<cfset _defaultID = getDefaultAgentConfigID()>
				<cfdump var="#_defaultID#">
				<cfif _defaultID.errorNo NEQ 0>
					<!--- We have a error --->
					<!--- Log the error --->
					<cfset response.errorNo = "1">
					<cfset response.errorMsg = "#_defaultID.errorMsg#">
					<cfreturn response>
				</cfif>
				<cfdump var="#_defaultID.result#">
				<cfset _config = getDefaultAgentConfigUsingID(_defaultID.result)>
				<cfif _config.errorNo NEQ 0>
					<!--- We have a error --->
					<!--- Log the error --->
					<cfset response.errorNo = "1">
					<cfset response.errorMsg = "#_config.errorMsg#">
					<cfreturn response>
				</cfif>
			<cfelse>
				<!--- No Results --->
	            <cfset response.errorNo = "1">
				<cfset response.errorMsg = "Error: No MacPatch servers found. Please make sure you have configured the servers first.">
				<cfreturn response>
			</cfif>
			<cfcatch>
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">
				<cfreturn response>
			</cfcatch>
		</cftry>
		
		<cfset var defaultProxy = 0>
		<cfset var defaultMaster = 0>
		<cfset var enforceProxy = 0>
		<cfset var enforceMaster = 0>
		
		<cfset var proxyConfig = "">
		<cfset var masterConfig = "">
		
		<cfset proxyConfig = getServerDataOfType(qGetAgentConfig,"Proxy")>
		<cfset masterConfig = getServerDataOfType(qGetAgentConfig,"Master")>
	
		
	
		<cfsavecontent variable="thePlist">
		<cfoutput>	
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>default</key>
			<dict>
				<cfloop query="_config.result">
					<cfif _config.result.enforced EQ 0>
						<cfif FindNoCase("Proxy",_config.result.aKey) GTE 1>
							<!--- If Proxy Config is not enforced --->
							<cfset defaultProxy = 1>
						<cfelseif FindNoCase("MPServer",_config.result.aKey) GTE 1>
							<!--- If Mast server Config is not enforced --->	
							<cfset defaultMaster = 1>
						<cfelse>
							<key>#_config.result.aKey#</key>
							<string>#_config.result.aKeyValue#</string>
						</cfif>
					</cfif>
				</cfloop>
				<cfif defaultProxy EQ 1>
					<key>MPProxyServerAddress</key>
					<string>#proxyConfig.result.MPProxyServerAddress#</string>  
					<key>MPProxyServerPort</key>
					<string>#proxyConfig.result.MPProxyServerPort#</string>  
					<key>MPProxyEnabled</key>
					<string>#proxyConfig.result.MPProxyEnabled#</string>
					<key>MPProxyAllowSelfSigned</key>
					<string>#masterConfig.result.MPServerAllowSelfSigned#</string>  
				</cfif>
				<cfif defaultMaster EQ 1>
					<key>MPServerAddress</key>
					<string>#masterConfig.result.MPServerAddress#</string>  
					<key>MPServerPort</key>
					<string>#masterConfig.result.MPServerPort#</string>  
					<key>MPServerSSL</key>
					<string>#masterConfig.result.MPServerSSL#</string> 
					<key>MPServerAllowSelfSigned</key>
					<string>#masterConfig.result.MPServerAllowSelfSigned#</string>  
				</cfif>
			</dict>
			<key>enforced</key>
			<dict>
				<cfloop query="_config.result">
					<cfif _config.result.enforced EQ 1>
						<cfif FindNoCase("Proxy",_config.result.aKey) GTE 1>
						<!--- If Proxy Config is not enforced --->
							<cfset enforceProxy = 1>
						<cfelseif FindNoCase("MPServer",_config.result.aKey) GTE 1>
						<!--- If Mast server Config is not enforced --->
							<cfset enforceMaster = 1>
						<cfelse>
							<key>#_config.result.aKey#</key>
							<string>#_config.result.aKeyValue#</string>
						</cfif>
					</cfif>
				</cfloop>
				<cfif enforceProxy EQ 1>
					<key>MPProxyServerAddress</key>
					<string>#proxyConfig.result.MPProxyServerAddress#</string>  
					<key>MPProxyServerPort</key>
					<string>#proxyConfig.result.MPProxyServerPort#</string>  
					<key>MPProxyEnabled</key>
					<string>#proxyConfig.result.MPProxyEnabled#</string>
					<key>MPProxyAllowSelfSigned</key>
					<string>#masterConfig.result.MPServerAllowSelfSigned#</string>  
				</cfif>
				<cfif enforceMaster EQ 1>
					<key>MPServerAddress</key>
					<string>#masterConfig.result.MPServerAddress#</string>  
					<key>MPServerPort</key>
					<string>#masterConfig.result.MPServerPort#</string>  
					<key>MPServerSSL</key>
					<string>#masterConfig.result.MPServerSSL#</string>
					<key>MPServerAllowSelfSigned</key>
					<string>#masterConfig.result.MPServerAllowSelfSigned#</string>  
				</cfif>
			</dict>
		</dict>
		</plist>
		</cfoutput>
		</cfsavecontent>
		<cfset xy = htmlCompressFormat(thePlist, 2)>
		<cfset response.result = xy>
        
        <cfreturn response>
    </cffunction>

	<cffunction name="postAgentFiles" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="user">
		<cfargument name="token">
		
        <cfset response = responseObj(0) />
		
		<cfif NOT isValidAuthToken(arguments.user,arguments.token)>
			<cfset response.errorNo = "9000">
			<cfset response.errorMsg = "Invalid auth data.">
			<cfreturn response>
		</cfif>
		
		<cftry>
			<cfset reqID = #CreateUUID()#>
			<cfquery name="qAddAccount" datasource="#this.ds#"> 
	            Insert Into mp_agent_upload ( uid, requestID, cDate)
	            Values ( <cfqueryparam value="#Arguments.user#">, '#reqID#', #CreateODBCDateTime(now())#)
	        </cfquery>
	        <cfset response.result = #reqID#>
	        
			<cfcatch>
				<cfset response.errorno = "1">
				<cfset response.errormsg = "Error: #cfcatch.Detail# #cfcatch.message#">
				<cfreturn response>
			</cfcatch>
		</cftry>
        
        <cfreturn response>
    </cffunction>
	
	<cffunction name="postAgentData" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="user" required="true">
		<cfargument name="token" required="true">
		<cfargument name="puuid" required="true">
		<cfargument name="type" required="true">
		<cfargument name="agent_ver" required="true">
		<cfargument name="version" required="true">
		<cfargument name="build" required="false" default="1">
		<cfargument name="pkg_name" required="true">
		<cfargument name="pkg_hash" required="true">
		<cfargument name="osver" required="false" default="*">
		
        <cfset response = responseObj(0) />
		<cfset var pkg_url = "/mp-content/clients/updates/" & #Arguments.puuid# & "/" & #arguments.pkg_name# & ".zip">
		
		<cfif NOT isValidAuthToken(arguments.user,arguments.token)>
			<cfset response.errorNo = "9000">
			<cfset response.errorMsg = "Invalid auth data.">
			<cfreturn response>
		</cfif>
		
		<cftry>
			<cfif agentDataIsUnique(Arguments.type,Arguments.agent_ver,Arguments.version,Arguments.build) EQ true>
				<cfquery datasource="mpds" name="qAddUpdate">
					Insert INTO mp_client_agents (puuid, type, agent_ver, version, build, framework, pkg_name, pkg_url, pkg_hash, osver)
					Values(<cfqueryparam value="#Arguments.puuid#">, <cfqueryparam value="#Arguments.type#">, <cfqueryparam value="#Arguments.agent_ver#">, 
					<cfqueryparam value="#Arguments.version#">, <cfqueryparam value="#Arguments.build#">, '0', <cfqueryparam value="#Arguments.pkg_name#">, 
					<cfqueryparam value="#pkg_url#">, <cfqueryparam value="#Arguments.pkg_hash#">, <cfqueryparam value="#Arguments.osver#">)
				</cfquery>
			<cfelse>
				<cfset response.errorNo = "2">
				<cfset response.errorMsg = "Error: Agent already exists.">		
			</cfif>
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
		</cftry>
        
        <cfreturn response>
    </cffunction>
	
	<cffunction name="postAutoPatchCreate" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="user" required="true">
		<cfargument name="token" required="true">
		<cfargument name="patch" required="true">
		
		
        <cfset response = responseObj(0) />
		<cfset patchDict = patchobj() />
		
		<cfif NOT isValidAuthToken(arguments.user,arguments.token)>
			<cfset response.errorNo = "9000">
			<cfset response.errorMsg = "Invalid auth data.">
			<cfreturn response>
		</cfif>
		
		<cftry>
			
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
		</cftry>
        
        <cfreturn response>
    </cffunction>
	
	<cffunction name="agentDataIsUnique" returntype="boolean" access="private" output="false">
		<cfargument name="type" required="true">
		<cfargument name="agent_ver" required="true">
		<cfargument name="version" required="true">
		<cfargument name="build" required="false" default="1">
		
		<cftry>
			<cfquery datasource="mpds" name="qGet">
				Select rid From mp_client_agents
				Where type = <cfqueryparam value="#Arguments.type#">
				AND agent_ver = <cfqueryparam value="#Arguments.agent_ver#">
				AND version = <cfqueryparam value="#Arguments.version#">
				AND build = <cfqueryparam value="#Arguments.build#"> 
			</cfquery>
			
			<cfif qGet.recordcount == 0>
	            <cfreturn true>
	        <cfelse>
	            <cfreturn false>
	        </cfif>
			
			<cfcatch>
				<cfreturn false>
			</cfcatch>
		</cftry>
	
		<cfreturn false>
	</cffunction>
	
	<cffunction name="getServerDataOfType" access="public" output="no" returntype="any">
	
		<cfargument name="data" hint="Query">
		<cfargument name="type" hint="Master or Proxy">
		
		<cfset var result = Structnew()>
		<cfset result.errorNo = "0">
		<cfset result.errorMsg = "">
		<cfset result.result = {}>
	    
		<cfset var serverInfo = Structnew()>
		
		<cfif arguments.type EQ "Master">
			<cfset serverInfo.MPServerAddress = "">
			<cfset serverInfo.MPServerPort = "2600">
			<cfset serverInfo.MPServerSSL = "1">
			<cfset serverInfo.MPServerAllowSelfSigned = "0">
			
			<cfoutput query="arguments.data">
				<cfif arguments.data.isMaster EQ 1>
					<cfset serverInfo.MPServerAddress = arguments.data.server>
					<cfset serverInfo.MPServerPort = arguments.data.port>
					<cfset serverInfo.MPServerSSL = arguments.data.useSSL>
					<cfset serverInfo.MPServerAllowSelfSigned = arguments.data.allowSelfSignedCert>
				</cfif>
			</cfoutput>
			
		<cfelseif arguments.type EQ "Proxy">
			<cfset serverInfo.MPProxyServerAddress = "">
			<cfset serverInfo.MPProxyServerPort = "2600">
			<cfset serverInfo.MPProxyEnabled = "0">
			<cfset serverInfo.MPProxyAllowSelfSigned = "0">
			
			<cfoutput query="arguments.data">
				<cfif arguments.data.isProxy EQ 1>
					<cfset serverInfo.MPProxyServerAddress = arguments.data.server>
					<cfset serverInfo.MPProxyServerPort = arguments.data.port>
					<cfset serverInfo.MPProxyEnabled = 1>
					<cfset serverInfo.MPProxyAllowSelfSigned = arguments.data.allowSelfSignedCert>
				</cfif>
			</cfoutput>
		<cfelse>	
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "Invalid argument.">
			<cfreturn result>
		</cfif>
		
		<cfset result.result = serverInfo>
		<cfreturn result>
	</cffunction>
	
	<cffunction name="getDefaultAgentConfigID" access="public" output="no" returntype="any">
	
		<cfset var result = Structnew()>
		<cfset result.errorNo = "0">
		<cfset result.errorMsg = "">
		<cfset result.result = "">
	    
		<cftry>
			<cfquery datasource="#this.ds#" name="qGetAgentConfigID">
				Select aid From mp_agent_config
				Where isDefault = 1
			</cfquery>
			<cfif qGetAgentConfigID.RecordCount EQ 1>
				<cfset result.result = qGetAgentConfigID.aid>
			<cfelse>
				<cfset result.errorNo = "1">
				<cfset result.errorMsg = "Error: No config data found.">	
			</cfif>
			<cfcatch>
				<cfset result.errorNo = "1">
				<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
			</cfcatch>
		</cftry>
	
		<cfreturn result>
	</cffunction>

	<cffunction name="getDefaultAgentConfigUsingID" access="public" output="no" returntype="any">
		<cfargument name="ConfigID">
		
		<cfset var result = Structnew()>
		<cfset result.errorNo = "0">
		<cfset result.errorMsg = "">
		<cfset result.result = {}>
		
		<cftry>
			<cfquery datasource="#this.ds#" name="qGetAgentConfigData">
				Select * From mp_agent_config_data
				Where aid = "#Arguments.ConfigID#"
			</cfquery>
			<cfif qGetAgentConfigData.RecordCount GTE 1>
				<cfset result.result = qGetAgentConfigData>
			<cfelse>
				<cfset result.errorNo = "2">
				<cfset result.errorMsg = "Error: No config data found for ID #Arguments.ConfigID#">	
			</cfif>
			<cfcatch>
				<cfset result.errorNo = "1">
				<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
			</cfcatch>
		</cftry>
		
		<cfreturn result>
	</cffunction>
<!--- **************************************************************************************** --->
<!---	AutoPKG Support --->
	
	<cffunction name="postAutoPKGPatch" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="user">
		<cfargument name="token">
		<cfargument name="autoPKGData">
		
        <cfset var response = responseObj(0) />
		
		<!--- Make Sure the Auth info is Good --->
		<cfif NOT isValidAuthToken(arguments.user,arguments.token)>
			<cfset response.errorNo = "9000">
			<cfset response.errorMsg = "Invalid auth data.">
			<cfreturn response>
		</cfif>

		<cfif NOT logInUserAutoPKG(arguments.user)>
			<cfset response.errorNo = "9000">
			<cfset response.errorMsg = "Invalid auth user.">
			<cfreturn response>
		</cfif>

		<!--- Is Valid JSON Data --->
		<cfif NOT IsJSON(arguments.autoPKGData)> 
			<cfset response.errorNo = "9001">
			<cfset response.errorMsg = "Invalid data type.">
			<cfreturn response>
		</cfif>
		<cfset var aPKGJSON = DeserializeJSON(arguments.autoPKGData) />

		<!--- Check to see if required fields are included --->
		<cfif NOT IsValidPatchObj(aPKGJSON)>
			<cfset response.errorNo = "9002">
			<cfset response.errorMsg = "Invalid data.">
			<cfreturn response>
		</cfif>

		<!--- Populate patch object with values --->
		<cfset var patch = autoPKGObj() />
		<cfset autoPKGKeys = StructKeyList(aPKGJSON,",")>
		<cfloop index="key" list="#autoPKGKeys#" delimiters = ",">  
		    <cfif structkeyexists(patch,key)>
		    	<cfset patch[key] = aPKGJSON[key]>
		    </cfif>   
		</cfloop>

		<!--- Check to see if the same patch has already been added --->
		<cfif patchExists(patch.bundle_id,patch.patch_name,patch.patch_ver)>
			<cfset response.errorNo = "9003">
			<cfset response.errorMsg = "Patch already exists.">
			<cfreturn response>
		</cfif>
		
		<!--- Add Patch to Database --->
		<cftry>
			<cfset patchID = #CreateUUID()#>
			<cfset patch.puuid = patchID>
			<cfset preInstallScpt = ToString( ToBinary( patch.pkg_preinstall ) ) />
			<cfset postInstallScpt = ToString( ToBinary( patch.pkg_postinstall ) ) />

			<!--- Insert Main Patch Data --->
			<cfquery name="qAddPatch" datasource="#this.ds#"> 
	            Insert Into mp_patches ( puuid,bundle_id,patch_name,patch_ver,
	            							  patch_severity,patch_state,active, patch_vendor,
	            							  patch_install_weight,description,description_url,patch_reboot,
	            							  cve_id,pkg_preinstall,pkg_postinstall,pkg_env_var, 
	            							  cDate, mDate )
	            Values ( <cfqueryparam value="#patch.puuid#">, <cfqueryparam value="#patch.bundle_id#">, <cfqueryparam value="#patch.patch_name#">, <cfqueryparam value="#patch.patch_ver#">,
	            	<cfqueryparam value="#patch.patch_severity#">, <cfqueryparam value="AutoPKG">, <cfqueryparam value="1">, <cfqueryparam value="#patch.patch_vendor#">,
	            	<cfqueryparam value="#patch.patch_install_weight#">, <cfqueryparam value="#patch.description#">, <cfqueryparam value="#patch.description_url#">, <cfqueryparam value="#patch.patch_reboot#">,
	            	<cfqueryparam value="#patch.cve_id#">, <cfqueryparam value="#preInstallScpt#">,<cfqueryparam value="#postInstallScpt#">, <cfqueryparam value="#patch.pkg_env_var#">,
	            	#CreateODBCDateTime(now())#, #CreateODBCDateTime(now())#)
	        </cfquery>

	        <!--- Criteria --->
	        <cfquery name="qAddPatchC1" datasource="#this.ds#"> 
	            Insert Into mp_patches_criteria ( puuid, type, type_data, type_order )
	            Values ( <cfqueryparam value="#patch.puuid#">, "OSType", <cfqueryparam value="#patch.OSType#">, <cfqueryparam value="1">)
	        </cfquery>
	        <cfquery name="qAddPatchC2" datasource="#this.ds#"> 
	            Insert Into mp_patches_criteria ( puuid, type, type_data, type_order )
	            Values ( <cfqueryparam value="#patch.puuid#">, "OSVersion", <cfqueryparam value="#patch.OSVersion#">, <cfqueryparam value="2">)
	        </cfquery>
	        <cfquery name="qAddPatchC3" datasource="#this.ds#"> 
	            Insert Into mp_patches_criteria ( puuid, type, type_data, type_order )
	            Values ( <cfqueryparam value="#patch.puuid#">, "OSArch", <cfqueryparam value="#patch.OSArch#">, <cfqueryparam value="3">)
	        </cfquery>
	        <!--- Criteria Array --->
	        <cfloop index="i" from="1" to="#arrayLen(patch.patch_criteria_enc)#">
	        	<cfset xOrder = i + 3>
	        	<cfset criteriaString = ToString( ToBinary( patch.patch_criteria_enc[i] ) ) />
	        	<cfset cList = criteriaString>
	        	<cfset cType = #trim(listGetAt(cList, 1, "@"))#>
	        	<cfset cQry =  #ListDeleteAt(cList, 1, "@")#>
	        	<!--- Might Have to use Base64 if the type is script --->
		        <cfquery name="qAddPatchC4" datasource="#this.ds#"> 
		             Insert Into mp_patches_criteria ( puuid, type, type_data, type_order )
		             Values ( <cfqueryparam value="#patch.puuid#">, <cfqueryparam value="#cType#">, <cfqueryparam value="#cQry#">, <cfqueryparam value="#xOrder#">)
		        </cfquery>
	        </cfloop>
	        
	        <!--- Add the request to the package can be uploaded --->
	        <cfquery name="qAddAccount" datasource="#this.ds#"> 
	            Insert Into mp_agent_upload ( uid, requestID, cDate)
	            Values ( <cfqueryparam value="#Arguments.user#">, '#patchID#', #CreateODBCDateTime(now())#)
	        </cfquery>

	        <cfset response.result = patch.puuid>
	        <cfset eres = sendNewAutoPKGEmail(arguments.user, patch.puuid, patch.patch_name, patch.patch_ver, patch.bundle_id)>

			<cfcatch>
				<cfset response.errorno = "9004">
				<cfset response.errormsg = "Error: #cfcatch.Detail# #cfcatch.message#">
				<cfreturn response>
			</cfcatch>
		</cftry>
        
        <cfreturn response>
    </cffunction>

    <cffunction name="IsValidPatchObj" access="private" returntype="any" output="no">
        <cfargument name="model" required="true" type="struct" />
        <cfset result = 0 />

		<cfset reqObjKeys=["bundle_id","patch_name","patch_ver","patch_severity","OSType","OSVersion","patch_criteria_enc"]>
        
        <cfloop array=#reqObjKeys# index="o">
        	<cflog file="MPAdminServiceDebug" type="error" application="no" text="#o#">
            <cfif NOT structkeyexists(arguments.model,o)>
            	<cflog file="MPAdminServiceDebug" type="error" application="no" text="Error: #o#">
                <cfset result = 1 />
            </cfif>
        </cfloop>
        
        <cfif result EQ 0>
            <cfreturn True>
        <cfelse>
            <cfreturn False>
        </cfif>
    </cffunction>

    <!--- Not In Use Yet, will be used to validate criteria query --->
    <cffunction name="IsValidCriteria" access="private" returntype="any" output="no">
        <cfargument name="model" required="true" type="struct" />
        <cfset result = 0 />

		<cfset reqObjKeys=["bundle_id","patch_name","patch_ver","patch_severity","patch_state","OSArch","OSType","OSVersion","patch_criteria_enc"]>
        
        <cfloop array=#reqObjKeys# index="o">
            <cfif NOT structkeyexists(arguments.model,o)>
                <cfset result = 1 />
            </cfif>
        </cfloop>
        
        <cfif result EQ 0>
            <cfreturn True>
        <cfelse>
            <cfreturn False>
        </cfif>
    </cffunction>

    <cffunction name="patchExists" access="private" returntype="any" output="no">
        <cfargument name="bundle_id" required="true" />
        <cfargument name="patch_name" required="true" />
        <cfargument name="patch_ver" required="true" />

        <cfquery name="qGet" datasource="#this.ds#"> 
        	Select * from mp_patches
        	Where bundle_id = <cfqueryparam value="#arguments.bundle_id#">
        	AND patch_ver = <cfqueryparam value="#arguments.patch_ver#">
        </cfquery>

        <!--- Orig
        <cfquery name="qGet" datasource="#this.ds#"> 
        	Select * from mp_patches
        	Where bundle_id = <cfqueryparam value="#arguments.bundle_id#">
        	AND patch_name = <cfqueryparam value="#arguments.patch_name#">
        	AND patch_ver = <cfqueryparam value="#arguments.patch_ver#">
        </cfquery>
        --->

        <cfif qGet.RecordCount GTE 1>
            <cfreturn True>
        <cfelse>
            <cfreturn False>
        </cfif>
    </cffunction>

    <cffunction name="sendNewAutoPKGEmail" access="private" returntype="any" output="no">
        <cfargument name="userID" required="true" />
        <cfargument name="puuid" required="true" />
        <cfargument name="name" required="true" />
        <cfargument name="ver" required="true" />
        <cfargument name="bundleID" required="true" />

		<cfsavecontent variable="emailBody" trim="true">
			<cfoutput>
			User: #arguments.userID# 
			-----------------------------------------------
			Patch info
			PatchID: #arguments.puuid#
			Patch Name: #arguments.name# 
			Patch Version: #arguments.ver# 
			Patch Bundle ID: #arguments.bundleID# 
			</cfoutput>
		</cfsavecontent>

        <cflog file="MPAdminService_AutoPKG" type="error" application="no" text="**************************************************************************">	
        <cflog file="MPAdminService_AutoPKG" type="error" application="no" text="New AutoPKG Patch Created">
        <cflog file="MPAdminService_AutoPKG" type="error" application="no" text="#emailBody#">	

        <cfquery name="qNotify" datasource="#this.ds#">
        	Select user_email from mp_adm_group_users
        	Where email_notification = 1
        	AND user_email IS NOT NULL
        </cfquery>

        <cfif qNotify.RecordCount GTE 1>
        	<cfset emailList = ValueList(qNotify.user_email,",")>
        <cfelse>
        	<cfreturn>
        </cfif>

        <cftry>
        	<cfparam name="this.settings.mailserver.username" default="">
			<cfparam name="this.settings.mailserver.password" default="">
			<cfparam name="this.settings.mailserver.port" default="25">
	        <cfmail from="MacPatch WebServices" to="#emailList#" subject="New AutoPKG Patch Created" 
				type="text" server="#this.settings.mailserver.server#" port="#this.settings.mailserver.port#"
				username="#IIF(this.settings.mailserver.username EQ "bObama",DE(''),DE(this.settings.mailserver.username))#" 
				password="#IIF(this.settings.mailserver.password EQ "imdumberthanbush",DE(''),DE(this.settings.mailserver.username))#">#emailBody#</cfmail>
		<cfcatch>
			<cflog file="MPAdminService_AutoPKG" type="error" application="no" text="[sendNewAutoPKGEmail]: #cfcatch.detail#">	
		</cfcatch>
		</cftry>
    </cffunction>

	<cfscript>
	/**
	 * Replaces a huge amount of unnecessary whitespace from your HTML code.
	 * 
	 * @param sInput      HTML you wish to compress. (Required)
	 * @return Returns a string. 
	 * @author Jordan Clark (JordanClark@Telus.net) 
	 * @version 1, November 19, 2002 
	 */
	function HtmlCompressFormat(sInput)
	{
	   var level = 2;
	   if( arrayLen( arguments ) GTE 2 AND isNumeric(arguments[2]))
	   {
	      level = arguments[2];
	   }
	   // just take off the useless stuff
	   sInput = trim(sInput);
	   switch(level)
	   {
	      case "3":
	      {
	         //   extra compression can screw up a few little pieces of HTML, doh         
	         sInput = reReplace( sInput, "[[:space:]]{2,}", " ", "all" );
	         sInput = replace( sInput, "> <", "><", "all" );
	         sInput = reReplace( sInput, "<!--[^>]+>", "", "all" );
	         break;
	      }
	      case "2":
	      {
	         sInput = reReplace( sInput, "[[:space:]]{2,}", chr( 13 ), "all" );
	         break;
	      }
	      case "1":
	      {
	         // only compresses after a line break
	         sInput = reReplace( sInput, "(" & chr( 10 ) & "|" & chr( 13 ) & ")+[[:space:]]{2,}", chr( 13 ), "all" );
	         break;
	      }
	   }
	   return sInput;
	}
	</cfscript>
	
</cfcomponent>
