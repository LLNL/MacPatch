<cfcomponent output="false"> 

	<!--- Default logName --->
	<cfset this.logName = "server" />
	<cfset this.logLevel = "INF" />

  	<cffunction name="onServerStart"> 

  		<cfset var jFile = "/Library/MacPatch/Server/conf/etc/proxy/siteconfig.json">
  		
  		<cfif fileExists(jFile)>

  			<cfset siteconfigData = structNew()>    
		    <cfset jData = DeserializeJSON(file=jFile)>

		    <!--- main settings --->
		    <cfif not structKeyExists(jData,"settings")>
		    	<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="Siteconfig file does not contain settings.">
		    	<cfthrow message="Siteconfig file does not contain settings.">
		    	<cfreturn>
		    <cfelse>
		        <cfset siteconfigData.settings = jData.settings>    
		    </cfif>

        <cfelse>
        	<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="No siteconfig file found.">
        	<cfthrow message="No App Settings file found.">
        	<cfreturn>
        </cfif>
		
		<!--- main settings --->
		<cfset server.mp = structNew()>
	    <cfset server.mp.settings = siteconfigData.settings>
	  
	    <!--- Validate users settings - user --->
		<cfif not structKeyExists(server.mp.settings,"admin")>
			<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="Invalid settings, admin section missing!">
			<cfthrow message="Invalid settings, admin section missing!">
		</cfif>

		<!--- Validate Mail server settings --->
		<cfif not structKeyExists(server.mp.settings,"mailserver")>
			<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="Invalid settings, SMTP!">
			<cfthrow message="Invalid settings, SMTP!">
		</cfif>
		
		<!--- Validate proxy server settings --->
		<cfif not structKeyExists(server.mp.settings,"proxyserver")>
			<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="Invalid settings, Proxy Server!">
			<cfthrow message="Invalid settings, Proxy Server!">
		</cfif>

		<!--- Gen Server Key and Post it --->
		<cftry>
			<cfset server.mp.settings.proxyserver.serverKey = CreateUuid()>
			<cfset var wsURL = "https://#server.mp.settings.proxyserver.primaryServer#:#server.mp.settings.proxyserver.primaryServerPort#/Service/MPProxyService.cfc" />
			<cfset var xData = #Encrypt(server.mp.settings.proxyserver.serverKey, server.mp.settings.proxyserver.seedKey)#>

           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="#PostProxyServerData#">
                <cfhttpparam type="formfield" name="proxyData" value="#xData#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
				<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="[PostProxyServerData][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
				<cfthrow message="STATUS_CODE: #cfhttp.responseheader.STATUS_CODE#">
			</cfif>
			<!---
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			--->
			<cfcatch>
				<cflog file="#this.logName#" type="ERR" THREAD="no" application="no" text="[PostProxyServerData][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfthrow message="#cfcatch.message#">
			</cfcatch>
		</cftry>

  </cffunction> 
</cfcomponent> 
