<cfcomponent output="false">
	<cffunction name="synchronizeContent" access="remote" returntype="any" output="no">
		<cfargument name="contentKey" required="true">
		
		<cfif arguments.contentKey NEQ server.mp.settings.proxyserver.serverKey>
			<cflog type="error" file="MPProxyController" text="#CreateODBCDateTime(now())# -- Non-matching keys from #CGI.REMOTE_HOST#">
			<cfreturn false>
		</cfif>
		
		<cfhttp url="http://127.0.0.1:2601/MPProxy.cfm" method="GET" throwOnError="Yes"/>
		<cfreturn true>
	</cffunction>
	
	<cffunction name="testMPProxy" access="remote" returntype="any" output="no">
		<cfargument name="contentKey" required="true">
		
		<cfif arguments.contentKey NEQ server.mp.settings.proxyserver.serverKey>
			<cflog type="error" file="MPProxyController" text="#CreateODBCDateTime(now())# -- Non-matching keys from #CGI.REMOTE_HOST#">
			<cfreturn "#CreateODBCDateTime(now())# -- Non-matching keys from #CGI.REMOTE_HOST#">
		<cfelse>
			<cfreturn "#CreateODBCDateTime(now())# -- Test from #CGI.REMOTE_HOST# was succesful.">
		</cfif>
	</cffunction>
	
	<cffunction name="genNewKey" access="remote" returntype="any" output="no">
		<cfargument name="contentKey" required="true">
		
		<cfif arguments.contentKey NEQ server.mp.settings.proxyserver.serverKey>
			<cflog type="error" file="MPProxyController" text="#CreateODBCDateTime(now())# -- Non-matching keys from #CGI.REMOTE_HOST#">
			<cfreturn false>
		</cfif>
		
		<cfset server.mp.settings.proxyserver.serverKey = CreateUuid()>
		
        <cfset var wsURL = "https://"& #server.mp.settings.proxyserver.primaryServer# & ":" & #server.mp.settings.proxyserver.primaryServerPort# & "/MPWSController.cfc?wsdl" />
		<cfset var xData = Encrypt(server.mp.settings.proxyserver.serverKey, server.mp.settings.proxyserver.seedKey)>
		
		<!--- This is not working with https
		<cfinvoke webservice="#wsURL#" method="PostProxyServerData" returnvariable="res">
    		<cfinvokeargument name="proxyData" value="#xData#"/>
		</cfinvoke>
        --->
        
        <cfsavecontent variable="soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:PostProxyServerData soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <proxyData xsi:type="xsd:string">#xData#</proxyData>
              </na:PostProxyServerData>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        <cfhttpparam type="header" name="SOAPAction" value="PostProxyServerData"> 
        <cfhttpparam type="xml" name="body" value="#soapRequest#">
        </cfhttp>
        <cfset soapresponse = XMLParse(cfhttp.FileContent) />	
		
		<cfreturn true>
	</cffunction>
</cfcomponent>