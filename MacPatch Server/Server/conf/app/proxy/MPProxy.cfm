<cfset runReplication = 0>
<cfif NOT IsDefined("server.mp.settings.proxyserver.primaryServer")>
	<cflog type="error" file="MPProxy" text="Variable proxyserver.primaryServer is not defined.">
	<cfabort>
</cfif>	

<cfif cgi.HTTP_USER_AGENT EQ "BlueDragon">
	<cfset runReplication = runReplication + 1>
</cfif>
<cfif cgi.SERVER_PORT EQ "2601" AND cgi.remote_addr EQ "127.0.0.1">
	<cfset runReplication = runReplication + 1>
</cfif>
<cfif IsDefined("server.mp.settings.admin.ip.allow")>
    <cfif FindNoCase(server.mp.settings.admin.ip.allow,cgi.HTTP_X_FORWARDED_FOR) GTE 1>
    	<cfset runReplication = runReplication + 1>
    </cfif>
</cfif>
<cfif IsDefined("server.mp.settings.admin.ip.deny")>
    <cfif FindNoCase(server.mp.settings.admin.ip.deny,cgi.HTTP_X_FORWARDED_FOR) GTE 1>
    	<cfset runReplication = 0>
    </cfif>
</cfif>

<!--- If Not Being Run By Server --->
<cfsilent>
	<cfif runReplication EQ 0>
		<cflog type="error" file="MPProxy" text="Someone (#cgi.HTTP_X_FORWARDED_FOR# or #cgi.HTTP_USER_AGENT# ) tried to run the downloader without permission.">
		<cflog type="error" file="MPProxy" text="SCRIPT_NAME:(#cgi.SCRIPT_NAME#), QUERY_STRING:(#cgi.QUERY_STRING#)">
		<cfabort>
	</cfif>

	<cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- Start content replication.">
	<!--- Create Proxy Object --->
    <cftry>
		<cfset proxyObj = CreateObject("component","gov.llnl.MPProxy").init(server.mp.settings.proxyserver.primaryServer)>
		<cfcatch type="any">
        	<cflog type="error" file="MPProxy" text="[CreateObject]: #cfcatch.Message#">
			<cfabort>
        </cfcatch>
    </cftry>    
	<!--- Get All Of the Custom Patch Content In XML Format --->
    <cftry>
		<cfset xmlDoc = proxyObj.getDistributionContent() />
		<cfcatch type="any">
        	<cflog type="error" file="MPProxy" text="[getDistributionContent]: #cfcatch.Message#">
			<cfabort>
        </cfcatch>
    </cftry> 
	<!--- Validate all patch content with any local content, return array of needed patches --->
	<cftry>
		<cfset patches = proxyObj.validateLocalContent(xmlDoc) />
		<cfcatch type="any">
        	<cflog type="error" file="MPProxy" text="[validateLocalContent]: #cfcatch.Message#">
			<cfabort>
        </cfcatch>
    </cftry>
	<cfif #ArrayLen(patches)# EQ 0>
		<!--- No patches to download or update --->
		<cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- Content replication completed.">
		<cfabort>
	</cfif>
	
	<!--- Download needed patch content --->
    <cftry>
		<cfset res = proxyObj.getContentFromArray(patches) />
    	<cfcatch type="any">
        	<cflog type="error" file="MPProxy" text="[getContentFromArray]: #cfcatch.Message#">
			<cfabort>
        </cfcatch>
    </cftry>
    <cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- Content replication completed."> 
</cfsilent>
