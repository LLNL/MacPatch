<cfif NOT IsDefined(srvconf.settings.proxyserver.primaryServer)>
	<cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- variable proxyserver.primaryServer is not defined.">
	<cfabort>
</cfif>	

<!--- If Not Being Run By Server --->
<cfsilent>
	<cfif cgi.HTTP_USER_AGENT NEQ "BlueDragon">
		<cflog type="error" file="MPProxy" text="Someone (#cgi.HTTP_X_FORWARDED_FOR#) tried to run the downloader without permission.">
		<cflog type="error" file="MPProxy" text="SCRIPT_NAME:(#cgi.SCRIPT_NAME#), QUERY_STRING:(#cgi.QUERY_STRING#)">
		<cfabort>
	</cfif>

	<cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- Start content replication.">
	<!--- Create Proxy Object --->
	<cfset proxyObj = CreateObject("component","gov.llnl.MPProxy").init(srvconf.settings.proxyserver.primaryServer)>
	
	<!--- Get All Of the Custom Patch Content In XML Format --->
	<cfset xmlDoc = proxyObj.getDistributionContent() />
	
	<!--- Validate all patch content with any local content, return array of needed patches --->
	<cfset patches = proxyObj.validateLocalContent(xmlDoc) />
	<cfif #ArrayLen(patches)# EQ 0>
		<!--- No patches to download or update --->
		<cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- Content replication completed.">
		<cfabort>
	</cfif>
	
	<!--- Download needed patch content --->
	<cfset res = proxyObj.getContentFromArray(patches) />
	<cflog type="error" file="MPProxy" text="#CreateODBCDateTime(now())# -- Content replication completed.">
</cfsilent>