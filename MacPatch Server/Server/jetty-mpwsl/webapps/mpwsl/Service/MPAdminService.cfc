<!--- **************************************************************************************** --->
<!---
		MPAdminService 
	 	Database type is MySQL
		MacPatch Version 2.2.x
--->
<!---	Notes:
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
    <cfset this.cacheDirName = "cacheIt">
    <cfset this.logTable = "ws_adm_logs">

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

<!--- **************************************************************************************** --->
<!--- Begin Admin WebServices Methods --->

	<cffunction name="WSLTest" access="remote" returnType="struct" returnFormat="json" output="false">
    
        <cfset response = {} />
        <cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = #CreateODBCDateTime(now())# />
        
        <cfreturn response>
    </cffunction>

</cfcomponent>
