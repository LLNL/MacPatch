<cfcomponent output="false"> 
  <cffunction name="onServerStart"> 
  		<cfset jvmObj = CreateObject("java","java.lang.System").getProperties() />
        <cfset _localConf = "#jvmObj.jetty.home#/app_conf/siteconfig.xml">
        
		<cfif fileExists(_localConf)>
        	<cfset _confFile = #_localConf#>
        <cfelse>
        	<cfset _confFile = "/Library/MacPatch/Server/conf/etc/siteconfig.xml">
        </cfif>
  
        <cffile action="read" file="#_confFile#" variable="xml">
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
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xmlData.settings.mailserver#">
		   <cfif len(trim(xmlData.settings.mailserver[key].xmlText))>
			  <cfset srvconf.settings.mailserver[key] = xmlData.settings.mailserver[key].xmlText>
		   </cfif>
		</cfloop>
        
        <cftry> 
        <!--- <cfset StructAppend(server.mpsettings,srvconf.settings)> --->
        <cfset server.mpsettings = srvconf>
        
        <!--- Create Datasource --->
		<cfif Datasourceisvalid("mpds")>
			<cfset rmDS = Datasourcedelete("mpds")>
		</cfif>
		<cfset DataSourceCreate( "mpds", srvconf.settings.database.prod )>
        <cfcatch type="any"> 
			<cfthrow message="Error trying to create datasource.">
        </cfcatch> 
        </cftry>
  </cffunction> 
</cfcomponent> 