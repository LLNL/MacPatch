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
            <cfif Datasourceisvalid("mpds")>
                <cfset rmDS = Datasourcedelete("mpds")>
            </cfif>
            
            <cfset DataSourceCreate( "mpds", srvconf.settings.database.prod )>
            <cfset srvconf.settings.database.prod.password = Hash(srvconf.settings.database.prod.password,'MD5')>
            
            <cfcatch type="any"> 
                <cfthrow message="Error trying to create datasource.">
            </cfcatch> 
        </cftry>
        
        <!--- Assign settings to server settings scope --->
        <cfset server.mpsettings = srvconf>
  </cffunction> 
</cfcomponent> 