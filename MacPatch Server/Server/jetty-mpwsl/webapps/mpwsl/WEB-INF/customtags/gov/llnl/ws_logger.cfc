<cfcomponent>
	<!--- Logging Info --->
    <!---
    <cflog type="information" file="MP_WSL_files" text="ws_logger.cfc">
	--->
	<cfset this.ds = "mpds">

	<cffunction name="init" returntype="ws_logger" output="no">
		<cfreturn this>
	</cffunction>

	<!--- Private Function called by AddSWUServerPatches function --->
    <cffunction name="LogEvent" access="public" returntype="void" output="no">

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
    	<cfquery datasource="#this.ds#" name="qInsert">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">, <cfqueryparam value="#CGI.SERVER_NAME#">, <cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
    </cffunction>
</cfcomponent>