<cfcomponent output="false">
	<cffunction name="synchronizeContent" access="remote" returntype="any" output="no">
		<cfargument name="contentKey" required="true">
		
		<cfif arguments.contentKey NEQ srvconf.settings.proxyserver.serverKey>
			<cflog type="error" file="MPProxyController" text="#CreateODBCDateTime(now())# -- Non-matching keys from #CGI.REMOTE_HOST#">
			<cfreturn false>
		</cfif>
		
		<cfhttp url="http://127.0.0.1:2601/MPProxy.cfm" method="GET" throwOnError="Yes"/>
		<cfreturn true>
	</cffunction>
	
	<cffunction name="genNewKey" access="remote" returntype="any" output="no">
		<cfargument name="contentKey" required="true">
		
		<cfif arguments.contentKey NEQ srvconf.settings.proxyserver.serverKey>
			<cflog type="error" file="MPProxyController" text="#CreateODBCDateTime(now())# -- Non-matching keys from #CGI.REMOTE_HOST#">
			<cfreturn false>
		</cfif>
		
		<cfset srvconf.settings.proxyserver.serverKey = CreateUuid()>
		
		<cfset var wsURL = "https://"&#srvconf.settings.proxyserver.primaryServer#&"/MPWSController.cfc?wsdl">
		<cfset var xData = Encrypt(srvconf.settings.proxyserver.serverKey, srvconf.settings.proxyserver.seedKey)>
		
		<cfinvoke webservice="#wsURL#" method="PostProxyServerData" returnvariable="res">
    		<cfinvokeargument name="proxyData" value="#xData#"/>
		</cfinvoke>
		
		<cfreturn true>
	</cffunction>
</cfcomponent>