<cfcomponent output="false"> 
  <cffunction name="onServerStart"> 
        <cffile action="read" file="/Library/MacPatch/Server/conf/etc/proxy/siteconfig.xml" variable="xml">
		<cfxml variable="xmlData"><cfoutput>#xml#</cfoutput></cfxml>
		
		<!--- main settings --->
		<cfset server.mp = structNew()>
	        <cfset srvconf = server.mp>
         
		<cfif not structKeyExists(xmlData,"settings")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xmlData.settings#">
		   <cfif len(trim(xmlData.settings[key].xmlText))>
			  <cfset srvconf.settings[key] = xmlData.settings[key].xmlText>
		   </cfif>
		</cfloop>
		
        <!--- admin settings --->
		<cfset srvconf.settings.admin = structNew()>
		<cfif structKeyExists(xmlData.settings,"admin")>
		   <cfloop item="key" collection="#xmlData.settings.admin#">
			   <cfif len(trim(xmlData.settings.admin[key].xmlText))>
				  <cfset srvconf.settings.admin[key] = xmlData.settings.admin[key].xmlText>
			   </cfif>
			</cfloop>
		</cfif>
        
		<!--- mail server settings --->
		<cfset srvconf.settings.mailserver = structNew()>
		<cfif structKeyExists(xmlData.settings,"mailserver")>
		   <cfloop item="key" collection="#xmlData.settings.mailserver#">
			   <cfif len(trim(xmlData.settings.mailserver[key].xmlText))>
				  <cfset srvconf.settings.mailserver[key] = xmlData.settings.mailserver[key].xmlText>
			   </cfif>
			</cfloop>
		</cfif>
		
		<!--- proxy server settings --->
		<cfset srvconf.settings.proxyserver = structNew()>
		<cfif structKeyExists(xmlData.settings,"proxyServer")>
			<cfloop item="key" collection="#xmlData.settings.proxyserver#">
			   <cfif len(trim(xmlData.settings.proxyserver[key].xmlText))>
			      <cfset srvconf.settings.proxyserver[key] = xmlData.settings.proxyserver[key].xmlText>
			   </cfif>
			</cfloop>   
		</cfif>
        

		<!--- Gen Server Key and Post it --->
		<cftry>
			<cfset srvconf.settings.proxyserver.serverKey = CreateUuid()>
			<cfset var wsURL = "https://#srvconf.settings.proxyserver.primaryServer#:#srvconf.settings.proxyserver.primaryServerPort#/MPWSController.cfc?wsdl" />
			<cfset var xData = #Encrypt(srvconf.settings.proxyserver.serverKey, srvconf.settings.proxyserver.seedKey)#>
			<!---
			<cfinvoke webservice="#wsURL#" method="PostProxyServerData" returnvariable="res">
					<cfinvokeargument name="proxyData" value="#xData#"/>
			</cfinvoke>
			--->
			<cfsavecontent variable="localscope.soapRequest">
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
				<cfhttpparam type="header" name="content-type" value="text/xml">
				<cfhttpparam type="header" name="charset" value="utf-8">
				<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
			</cfhttp>
			<cfset localscope.soapresponse = XMLParse(cfhttp.FileContent) />
			
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
				<cflog type="error" file="ServerConf" text="#CreateODBCDateTime(now())# -- [PostProxyServerData][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			</cfif>
        	<cfcatch type="any">
                <cflog type="error" file="ServerConf" text="#CreateODBCDateTime(now())# -- #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
			</cfcatch>	
		</cftry>
  </cffunction> 
</cfcomponent> 
