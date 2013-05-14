<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
	<cfset this.cacheDirName = "cacheIt">

	<cffunction name="init" returntype="MPWSControllerCocoa" output="no">
		<cfreturn this>
	</cffunction>

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
		<!---
    	<cfquery datasource="#this.ds#" name="qGet">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
		--->
		<cflog file="MPAdmin" type="#arguments.aEventType#" application="no" text="[#inet#]: #arguments.aEvent#">
    </cffunction>

<!--- ********************************************************************* --->
<!---  Methods																--->
<!--- ********************************************************************* ---> 

	<!--- Helper --->
	<cffunction name="getGroupID" access="private" returntype="any" output="no">
		<cfargument name="groupName" required="true" />

		<cfquery datasource="#this.ds#" name="qGet" maxrows="1">
			Select * from mp_software_groups
			Where gName = <cfqueryparam value="#arguments.groupName#">
		</cfquery>
		<cfif qGet.RecordCount EQ 1>
			<cfreturn qGet.gid>
		<cfelse>
			<cfreturn "NA">
		</cfif>
	</cffunction>
    
<!--- ********************************************************************* --->
<!--- Start --- Client Methods - for MacPatch 2.1.0							--->
<!--- ********************************************************************* ---> 

<!--- #################################################### --->
<!--- MPHostsListVersionIsCurrent	 		 			   --->
<!--- #################################################### --->
	<cffunction name="GetMacPatchClients" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="keyID" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = {} />

		<cftry>
			<cfquery datasource="#this.ds#" name="qGetClients">
				SELECT *
				FROM 
					mp_clients_view
            </cfquery>
			
			<cfif qGetClients.RecordCount GTE 1>
				<cfset response[ "result" ] = qGetClients />
			<cfelse>
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "No Clients Found">
				<cfreturn #response#>
			</cfif>
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = cfcatch.Message>
            <cfset l = logit("Error","[MPHostsListVersionIsCurrent]: #cfcatch.Detail# -- #cfcatch.Message#")>
		</cfcatch>
		</cftry>

		<cfreturn #response#>
	</cffunction>
	
	<cffunction name="GetClients" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="keyID" required="false" default="0" />

		<cfset response = {} />
		<!--- <cfset response[ "total" ] = "0" /> --->
		<cfset response[ "results" ] = "" />

		<cfquery datasource="mpds" name="qGetClients">
			SELECT cuuid,agent_version,AllowClient,AllowServer
			FROM mp_clients_view
		</cfquery>
		
		<cfset arrSW = ArrayNew(1)>
		<cfset strMsg = "">
		<cfset strMsgType = "Success">
		
		<cfloop from="1" to="#qGetClients.RecordCount#" index="row">
			<cfset arrtxt = ArrayNew(1)>
			<cfloop list="#qGetClients.ColumnList#" index="column" delimiters=",">
				<!---<cfset xData = """#column#"":""#qGetClients[column][row]#""">--->
				<cfset xData = "#column#:#qGetClients[column][row]#">
				<cfset tmp = #ArrayAppend(arrtxt,xData)#>
			</cfloop>
			<cfset arrSW[row] = #ArrayToList(arrtxt,",")#>
		</cfloop>

		<cfset response.total = #qGetClients.RecordCount# />
		<cfset response.results = #arrSW# />
		<cfreturn #response#>
	</cffunction>
</cfcomponent>	