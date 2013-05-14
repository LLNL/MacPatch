<cfcomponent>
	<!--- Logging Info --->
    
	<!--- Private Function called by AddSWUServerPatches function --->
    <cffunction name="LogEvent" access="public" returntype="void" output="no">
    	
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">
        
        <cfscript> 
			inet = CreateObject("java", "java.net.InetAddress");
			inet = inet.getLocalHost();
			//writeOutput(inet);
		</cfscript>
        
    	<cfquery datasource="#session.dbsource#" name="qGet">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, '#aEventType#', '#aEvent#', '#CGI.REMOTE_HOST#', '#CGI.SCRIPT_NAME#', '#CGI.PATH_TRANSLATED#','#CGI.SERVER_NAME#','#CGI.SERVER_SOFTWARE#', '#inet#') 
        </cfquery>
    </cffunction>
</cfcomponent>    