<!--- **************************************************************************************** --->
<!---
		MPRegister 
	 	Database type is MySQL
		MacPatch Version 2.5.x
--->
<!---	Notes: Used for Clients To Register
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
    <cfset this.logTable = "ws_client_reg_logs">
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
	
	<cffunction name="registerClient" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="true">
		<cfargument name="hostName" required="true">	
		<cfargument name="clientKey" required="false" default="NA">	
		<cfargument name="registrationKey" required="false" default="999999999">
		<cfargument name="clientCSR" required="false" default="NA">

        <cfset response = responseObj(0) />
		
		<!--- Check if client is registred --->
		<cfif isClientRegistered(arguments.clientID) EQ true>
			<cfset response.errorno = "0" />
       		<cfset response.errormsg = "Client is registered." />
			<cfreturn response>
		</cfif>
		
		<!--- Check Reg Key --->
		<cfif isKeyRequired() EQ true>
			<cfif isKeyValid(arguments.registrationKey) EQ false>
				<cfset response.errorno = "1001" />
        		<cfset response.errormsg = "Registration key is invalid." />
				<cfreturn response>
			</cfif>
		</cfif>
		
		<cfif arguments.clientCSR NEQ "NA">
			<!--- clientCSR should be base64 encoded --->
		<cfelse>	
			<cftry>			
				<!--- SystemCommand Outputs ...
					Command: #result.getCommand()#<br>
					ExitValue: #result.getExitValue()#<br>
					Error Output: #result.getErrorOutput()#<br>
					Standard Output: #result.getStandardOutput()#<br>
	  			--->	
	  			<cftry>
					<cfset command = "/Library/MacPatch/Server/conf/ssl/scripts/client.sh -d #arguments.clientID# -n #arguments.hostName# -p #arguments.clientKey#">
					<cfset syscmd = createObject("java","au.com.webcode.util.SystemCommand").init()>
					<cfset result = syscmd.execute(command)>
					<cfcatch>
						<cflog file="MPRegister" type="error" application="no" text="[createClientCert]: #cfcatch.Detail# #cfcatch.message#">
						<cfset response.errorno = "1002" />
 		       			<cfset response.errormsg = "Registration failed signed p12 was not found." />
						<cfreturn response>
					</cfcatch>				
				</cftry>
				
				<cfset exitCode = result.getExitValue() />
				<cfset _signResult = #result.getStandardOutput()# & " " & #result.getErrorOutput()# />
				<cfset fileName = "/Library/MacPatch/Server/conf/ssl/client/#arguments.clientID#/#arguments.clientID#.p12" >
				
				<cfif #exitCode# EQ "0">
					<cfif FileExists(fileName)>
						<cfset p12File = FileReadbinary(fileName) />
		  				<cfset p12B64 = ToBase64(p12File) />
		  				<cfset response.result = p12B64 />
	  				</cfif>
	  				<cfset l = logClientRegistration(arguments.clientID, arguments.hostName, arguments.registrationKey, exitCode, Trim(_signResult), p12B64, arguments.clientKey) />
	  			<cfelse>
	  				<cflog file="MPRegister" type="error" application="no" text="[createClientCert]: ClientID = #arguments.clientID#, HostName = #arguments.hostName#">
	  				<cflog file="MPRegister" type="error" application="no" text="#_signResult#">
	  				<cflog file="MPRegister" type="error" application="no" text="-------------------------------------------------------------------------">
	  				
	  				<cfset l = logClientRegistration(arguments.clientID, arguments.hostName, arguments.registrationKey, '1003', Trim(_signResult), '0', arguments.clientKey) />
	  				<cfset response.errorno = "1003" />
        			<cfset response.errormsg = "Registration failed signed p12 was not found." />	
					<cfreturn response>
				</cfif>
				
	  			<cfcatch>
					<cflog file="MPRegister" type="error" application="no" text="[createClientCert]: #cfcatch.Detail# #cfcatch.message#">
				</cfcatch>
			</cftry>
	  				
		</cfif>
		
        <cfreturn response>
    </cffunction>

	<!--- 
		Used By: registerClient()
	--->
	<cffunction name="isClientRegistered" access="private" returntype="boolean" output="no">
        <cfargument name="clientID" required="yes">
        
        <cftry>
			<!--- 
				Will add more support for time duration
			--->
			<cfquery datasource="mpds" name="qGetAgentID">
				select cuuid from mp_clients
				Where cuuid = <cfqueryparam value="#arguments.clientID#" />
			</cfquery>
			
			<cfif qGetAgentID.RecordCount EQ 1>
				<cfreturn true>
			</cfif>
			<cfcatch>
				<cflog file="MPRegister" type="error" application="no" text="[isClientRegistered]: #cfcatch.Detail# #cfcatch.message#">
			</cfcatch>
		</cftry>
        
        <cfreturn false>
    </cffunction>
	
	<!--- 
		Used By: registerClient()
	--->
	<cffunction name="isKeyRequired" access="private" returntype="boolean" output="no">
        
		<cftry>
			<!--- 
				Will add more support for time duration
			--->
			<cfquery datasource="mpds" name="qGetAgentKeyStatus">
				select * from mp_client_register_conf
			</cfquery>
			
			<cfif qGetAgentKeyStatus.RecordCount EQ 1>
				<cfif qGetAgentKeyStatus.autoRegister EQ "1">
					<cfreturn false>
				</cfif>
			</cfif>
			<cfcatch>
				<cflog file="MPRegister" type="error" application="no" text="[isKeyRequired]: #cfcatch.Detail# #cfcatch.message#">
			</cfcatch>
		</cftry>
        
        <cfreturn true>
    </cffunction>
	
	<!--- 
		Used By: registerClient()
	--->
	<cffunction name="isKeyValid" access="private" returntype="boolean" output="no">
        <cfargument name="registrationKey" required="yes">
        
		<cftry>
			<cfquery datasource="mpds" name="qGetAgentKeyStatus">
				select * from mp_client_register_keys
				Where 
					active = '1'
				AND
					rKey = <cfqueryparam value="#arguments.registrationKey#" />
			</cfquery>
			
			<cfif qGetAgentKeyStatus.RecordCount EQ 1>
				<cfset _k = setKeyUsed(arguments.registrationKey)>
				<cfreturn true>
			</cfif>
			<cfcatch>
				<cflog file="MPRegister" type="error" application="no" text="[isKeyValid]: #cfcatch.Detail# #cfcatch.message#">
			</cfcatch>
		</cftry>
		
        <cfreturn false>
    </cffunction>
	
	
	<!--- 
		Used By: isKeyValid()
	--->
	<cffunction name="setKeyUsed" access="private" returntype="boolean" output="no">
        <cfargument name="registrationKeyID" required="yes">
        
		<cftry>
			<cfquery name="qUpdateAccount" datasource="#this.ds#"> 
		        Update mp_client_register_keys 
		        Set active = '0',
		        	usedOn = #CreateODBCDateTime(now())#
		        Where    
		        	rid = <cfqueryparam value="#arguments.registrationKeyID#" />
		    </cfquery>

			<cfreturn true>
			<cfcatch>
				<cflog file="MPRegister" type="error" application="no" text="[setKeyUsed]: #cfcatch.Detail# #cfcatch.message#">
			</cfcatch>
		</cftry>
		
        <cfreturn false>
    </cffunction>
	
	<!--- 
		Used By: registerClient()
	--->
	<cffunction name="logClientRegistration" access="private" returntype="void" output="no">
        <cfargument name="cuuid" required="yes">
		<cfargument name="hostname" required="yes">
		<cfargument name="regkey" required="yes">
		<cfargument name="errorno" required="yes">
		<cfargument name="sign_result" required="yes">
		<cfargument name="client_cert" required="yes">
		<cfargument name="client_cert_pass" required="yes">
        
		<cftry>
			<cfquery name="qUpdateAccount" datasource="#this.ds#"> 
		        Insert Into mp_client_register_log (cuuid, hostname, regkey, errorno, sign_result, client_cert, client_cert_pass, cdate ) 
		        Values (<cfqueryparam value="#arguments.cuuid#" />,<cfqueryparam value="#arguments.hostname#" />,<cfqueryparam value="#arguments.regkey#" />,
		        <cfqueryparam value="#arguments.errorno#" />,<cfqueryparam value="#arguments.sign_result#" />,<cfqueryparam value="#arguments.client_cert#" />,
		        <cfqueryparam value="#arguments.client_cert_pass#" />, #CreateODBCDateTime(now())#)
		    </cfquery>

			<cfcatch>
				<cflog file="MPRegister" type="error" application="no" text="[logClientRegistration]: #cfcatch.Detail# #cfcatch.message#">
			</cfcatch>
		</cftry>
		
    </cffunction>
</cfcomponent>