<cfcomponent output="false"> 
  <cffunction name="onServerStart"> 
        <cffile action="read" file="/Library/MacPatch/Server/conf/etc/siteconfig.xml" variable="xml">
		<cfxml variable="xmlData"><cfoutput>#xml#</cfoutput></cfxml>
		
		<!--- main settings --->
		<cfset srvconf.settings = structNew()>
		
		<cfif not structKeyExists(xmlData,"settings")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xmlData.settings#">
		   <cfif len(trim(xmlData.settings[key].xmlText))>
			  <cfset srvconf.settings[key] = xmlData.settings[key].xmlText>
		   </cfif>
		</cfloop>
		<!--- users settings - user --->
		<cfset srvconf.settings.users.admin = structNew()>
		<cfif not structKeyExists(xmlData.settings.users,"admin")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xmlData.settings.users.admin#">
		   <cfif len(trim(xmlData.settings.users.admin[key].xmlText))>
			  <cfif xmlData.settings.users.admin[key].XmlName EQ "pass">
				<cfset srvconf.settings.users.admin[key] = Hash(xmlData.settings.users.admin[key].xmlText,'MD5')>
			  <cfelse>
				<cfset srvconf.settings.users.admin[key] = xmlData.settings.users.admin[key].xmlText>
			  </cfif>
		   </cfif>
		</cfloop>
		
		<!--- database settings - prod --->
		<cfset srvconf.settings.ldap = structNew()>
		<cfif not structKeyExists(xmlData.settings,"ldap")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xmlData.settings.ldap#">
		   <cfif len(trim(xmlData.settings.ldap[key].xmlText))>
			  <cfset srvconf.settings.ldap[key] = xmlData.settings.ldap[key].xmlText>
		   </cfif>
		</cfloop>
		
		<!--- database settings - prod --->
		<cfset srvconf.settings.database.prod = structNew()>
		<cfif not structKeyExists(xmlData.settings.database,"prod")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xmlData.settings.database.prod#">
		   <cfif len(trim(xmlData.settings.database.prod[key].xmlText))>
			  <cfset srvconf.settings.database.prod[key] = xmlData.settings.database.prod[key].xmlText>
		   </cfif>
		</cfloop>
		
		<!--- mail server settings --->
		<cfset srvconf.settings.mailserver = structNew()>
		<cfif not structKeyExists(xmlData.settings,"mailserver")>
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
        
        <cftry> 
        	<!--- Gen Server Key and Post it --->
			<cfset srvconf.settings.proxyserver.serverKey = CreateUuid()>
			<cfparam name="wsURL" default="https://"&#srvconf.settings.proxyserver.primaryServer#&"/MPWSController.cfc?wsdl">
			<cfset xData = Encrypt(srvconf.settings.proxyserver.serverKey, srvconf.settings.proxyserver.seedKey)>
			<cfinvoke webservice="#wsURL#" method="PostProxyServerData" returnvariable="res">
	    		<cfinvokeargument name="proxyData" value="#xData#"/>
			</cfinvoke>
       		<cfcatch type="any">
				<cflog type="error" file="ServerConf" text="#CreateODBCDateTime(now())# -- [PostProxyServerData]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="ServerConf" text="#CreateODBCDateTime(now())# -- [PostProxyServerData][returnvariable]: #res#">
				<cfthrow message="Invalid settings XML file!">
            </cfcatch>
        </cftry>
  </cffunction> 
</cfcomponent> 