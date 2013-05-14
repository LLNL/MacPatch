<cfcomponent>
	<!--- Configure Datasource --->
	<cfparam name="mpDBSource" default="mpds">

    <!--- Used to make xml look pretty --->
    <cfsavecontent variable="myXSLT">
   		<?xml version="1.0" encoding="UTF-8"?>
    	<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
		<xsl:output method="xml" indent="yes" />
		<xsl:strip-space elements="*" />
		<xsl:template match="/">
			<xsl:copy-of select="." />
		</xsl:template>
		</xsl:transform>
	</cfsavecontent>
	
	<cffunction name="logger" access="public" returntype="void" output="no">
		<cfargument name="aEventType">
		<cfargument name="aEvent">
		
		<cfscript>
			inet = CreateObject("java", "java.net.InetAddress");
			inet = inet.getLocalHost();
		</cfscript>
		
		<cflog file="MPWSController" type="#arguments.aEventType#" application="no" text="[#inet#]: #arguments.aEvent#">
	</cffunction>
	
	<cffunction name="ilog" access="public" returntype="void" output="no">
		<cfargument name="aEvent">
		<cfset var tmp = logger("Information",arguments.aEvent)>
	</cffunction>
	<cffunction name="elog" access="public" returntype="void" output="no">
		<cfargument name="aEvent">
		<cfset var tmp = logger("Error",arguments.aEvent)>
	</cffunction>

    <!--- Logging function, replaces need for ws_logger (Same Code) --->
    <cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">

        <cfscript>
			inet = CreateObject("java", "java.net.InetAddress");
			inet = inet.getLocalHost();
		</cfscript>
	
    	<cfquery datasource="#mpDBSource#" name="qGet">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
    </cffunction>
	
	<cffunction name="client_checkin_base" access="remote" returntype="any" output="no">
		<cfargument name="data" hint="Encoded Data">
		<cfargument name="type" hint="Encodign Type">
		
		<cfset var l_data = "">
		<cfif arguments.type EQ "JSON">
			<cfif isJson(arguments.data) EQ false>
				<!--- Log issue --->
				<cfset elog("Not JSON Data.")>
				<cfreturn false>	
			</cfif>
			
			<cfset l_data = Deserializejson(arguments.data)>
			<cfset ilog(l_data)>
		<cfelseif arguments.type EQ "XML">
			<!--- Will Fill This In Later--->	
			<cfreturn false>
		</cfif>	
	
		<cfreturn false>
	</cffunction>
	
	<cffunction name="test" access="remote" returntype="any" output="yes">
		<cfquery datasource="#mpDBSource#" name="qGet">
			SHOW TABLES IN MacPatchDBGen2
		</cfquery>
		
		<cfdump var="#qGet#">
	</cffunction>
	
</cfcomponent>	