<!---
	This Server.cfc is used to get server settings populated in the 
	server settings scope. 
	Settings are gathered in the settings.cfc file.

	Version: 1.1.0
	History:
	- Initial XML Support
	- Added JSON support
--->
<cfcomponent output="false"> 
  <cffunction name="onServerStart"> 
  		
  		<cfset var xFile = "/Library/MacPatch/Server/conf/etc/siteconfig.xml">
  		<cfset var jFile = "/Library/MacPatch/Server/conf/etc/siteconfig.json">
  		
  		<cfif fileExists(jFile)>
			<cfinvoke component="Server.settings" method="getJSONAppSettings" returnvariable="_AppSettings">
				<cfinvokeargument name="cFile" value="#jFile#">
			</cfinvoke>
        <cfelseif fileExists(xFile)>
        	<cfinvoke component="Server.settings" method="getAppSettings" returnvariable="_AppSettings">
        		<cfinvokeargument name="cFile" value="#xFile#">
			</cfinvoke>
        <cfelse>
        	<cfthrow message="No App Settings file found.">
        	<cfreturn>
        </cfif>
		
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
                <cfset dbConf1 = genDBStruct(srvconf.settings.database.prod)>
                <cfset DataSourceCreate( dsName , dbConf1 )>
                <cfset srvconf.settings.database.prod.password = Hash(srvconf.settings.database.prod.password,'MD5')>
        	</cfif>
            <cfif structKeyExists(srvconf.settings.database,"ro")>
				<cfset dsNameRO = srvconf.settings.database.ro.dsName>
                <cfif Datasourceisvalid(dsNameRO)>
                	<cfset rmDS = Datasourcedelete(dsNameRO)>
                </cfif>
                <cfset dbConf2 = genDBStruct(srvconf.settings.database.prod)>
                <cfset DataSourceCreate( dsNameRO , dbConf2 )>
                <cfset srvconf.settings.database.ro.password = Hash(srvconf.settings.database.ro.password,'MD5')>
        	</cfif>
            
            <cfcatch type="any"> 
                <cfthrow message="Error trying to create datasource.">
            </cfcatch> 
        </cftry>
        
        <!--- Assign settings to server settings scope --->
        <cfset server.mpsettings = srvconf>
  </cffunction> 

  <!--- Quick Function to Generate the right db struct --->
	<cffunction name="genDBStruct" access="private" returntype="struct">
    	<cfargument name="dbData" type="struct" required="true">
    	
    	<cfset dbConf= structNew()>
    	<cfset dbConf['dsName']= dbData.dsName>
    	<cfset dbConf['hoststring']= dbData.hoststringPre & "//" &  dbData.dbHost & ":" & dbData.dbPort & "/" & dbData.dbName & dbData.hoststringURI>
    	<cfset dbConf['drivername']= dbData.drivername>
    	<cfset dbConf['databasename']= dbData.dbName>
    	<cfset dbConf['username']= dbData.username>
    	<cfset dbConf['password']= dbData.password>
    	<cfset dbConf['maxconnections']= dbData.maxconnections>
    	<cfset dbConf['logintimeout']= dbData.logintimeout>
    	<cfset dbConf['connectiontimeout']= dbData.connectiontimeout>
    	<cfset dbConf['connectionretries']= dbData.connectionretries>

        <cfreturn dbConf>	
	</cffunction>
</cfcomponent> 