<!---
	This Server.cfc is used to get server settings populated in the 
	server settings scope. 
	Settings are gathered in the settings.cfc file.
--->
<cfcomponent output="false"> 
  <cffunction name="onServerStart"> 
  		
	    <cfinvoke component="Server.settings" method="getAppSettings" returnvariable="_AppSettings" />
		
		<!--- main settings --->
		<cfset srvconf.settings = _AppSettings>
		
		<!--- Validate users settings - user --->
		<cfif not structKeyExists(srvconf.settings.users,"admin")>
		   <cfthrow message="Invalid settings, user info!">
		</cfif>
		
		<!--- Validate LDAP settings - prod --->
		<cfif not structKeyExists(srvconf.settings,"ldap")>
		   <cfthrow message="Invalid settings, LDAP!">
		</cfif>
		
		<!--- Validate Database settings - prod --->
		<cfif not structKeyExists(srvconf.settings.database,"prod")>
		   <cfthrow message="Invalid settings, Database!">
		</cfif>
		
		<!--- Validate Mail server settings --->
		<cfif not structKeyExists(srvconf.settings,"mailserver")>
		   <cfthrow message="Invalid settings, SMTP!">
		</cfif>
        
        <cftry> 
            <!--- Create Datasource --->
            <cfif structKeyExists(srvconf.settings.database,"prod")>
				<cfset dsName = srvconf.settings.database.prod.dsName>
                <cfif Datasourceisvalid(dsName)>
                	<cfset rmDS = Datasourcedelete(dsName)>
                </cfif>
                <cfset DataSourceCreate( dsName , srvconf.settings.database.prod )>
                <cfset srvconf.settings.database.prod.password = Hash(srvconf.settings.database.prod.password,'MD5')>
        	</cfif>
            <cfif structKeyExists(srvconf.settings.database,"ro")>
				<cfset dsNameRO = srvconf.settings.database.ro.dsName>
                <cfif Datasourceisvalid(dsNameRO)>
                	<cfset rmDS = Datasourcedelete(dsNameRO)>
                </cfif>
                <cfset DataSourceCreate( dsNameRO , srvconf.settings.database.ro )>
                <cfset srvconf.settings.database.ro.password = Hash(srvconf.settings.database.ro.password,'MD5')>
        	</cfif>
            
            <cfcatch type="any"> 
                <cfthrow message="Error trying to create datasource.">
            </cfcatch> 
        </cftry>
        
        <!--- Assign settings to server settings scope --->
        <cfset server.mpsettings = srvconf>
  </cffunction> 
</cfcomponent> 