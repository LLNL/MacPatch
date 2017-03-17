<!---
	This Server.cfc is used to get server settings populated in the
	server settings scope.
	Settings are gathered in the settings.cfc file.

	Version: 1.3.0
	History:
	- Initial XML Support
	- Added JSON support
    - Added additional default data to database (SUSList, ServerList)
    - Removed XML conf support
--->
<cfcomponent output="false">
    <cffunction name="onServerStart">

  		<cfset var jFile = "/opt/MacPatch/Server/conf/etc/siteconfig.json">
        <cfif NOT fileExists(jFile)>
            <cfset var jFile = "/opt/MacPatch/Server/etc/siteconfig.json">
        </cfif>

  		<cfif fileExists(jFile)>
			<cfinvoke component="Server.settings" method="getJSONAppSettings" returnvariable="_AppSettings">
				<cfinvokeargument name="cFile" value="#jFile#">
			</cfinvoke>
        <cfelse>
        	<cfthrow message="No App Settings file found.">
        	<cfreturn>
        </cfif>

        <!--- main settings --->
        <cfset srvconf.settings = _AppSettings>

        <!--- DB Schema --->
        <cfset var dFile = "/opt/MacPatch/Server/conf/etc/db/db_schema.json">
        <cfset _dbSchema = structNew() />
        <cfif fileExists(dFile)>
            <cfset dbData = DeserializeJSON(file=dFile)>
            <cfset _schemaVersion = dbData.schemaVersion />
            <cfset _schemaNotes = dbData.schemaNotes />
            <cfset dbData = {} />
        <cfelse>
            <cfset _schemaVersion = "1.0.0.0" />
            <cfset _schemaNotes = "" />
            <!---
            <cfthrow message="No Database Schema Config File Found.">
            <cfreturn>
            --->
        </cfif>

        <cfset _dbSchema.schemaVersion = _schemaVersion />
        <cfset _dbSchema.schemaNotes = _schemaNotes />
        <cfset srvconf.settings.dbSchema = _dbSchema />


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
                <cfset dbConf2 = genDBStruct(srvconf.settings.database.ro)>
                <cfset DataSourceCreate( dsNameRO , dbConf2 )>
                <cfset srvconf.settings.database.ro.password = Hash(srvconf.settings.database.ro.password,'MD5')>
        	</cfif>

            <!--- Populate Default Data --->
			<cflog file="Server" application="no" text="Check DB for default data.">
            <!---
            <cfset dbDefTmp = hasDefaultDBData() />
            --->
            
            <cfcatch type="any">
                <cfset server.mpsettings = srvconf>
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

    <cffunction name="hasDefaultDBData" access="private" returntype="struct">

        <cfset var dbData = structNew() />

        <!--- Query Default Config Data --->
        
        <cfset dbData["ServerListConf"] = serverListConf('query') />
        <cflog file="Server" application="no" text="Check ServerListConf: #dbData["ServerListConf"]#">

        <cfset dbData["ServerConf"] = serverConf('query') />
		<cflog file="Server" application="no" text="Check ServerConf: #dbData["ServerConf"]#">
        
        <cfset dbData["SUSListConf"] = susListConf('query') />
        <cflog file="Server" application="no" text="Check SUSListConf: #dbData["susListConf"]#">
        
        <cfset dbData["ClientConf"] = clientConf('query') />
		<cflog file="Server" application="no" text="Check ClientConf: #dbData["ClientConf"]#">
        
        <cfset dbData["PatchGroupConf"] = patchGroupConf('query') />
		<cflog file="Server" application="no" text="Check PatchGroupConf: #dbData["PatchGroupConf"]#">

        <!--- Queries are done, apply conf if any are false --->

        <cfif dbData["ServerListConf"] EQ false>
            <cfset loadSrvLstConf = serverListConf('populate') />
			<cflog file="Server" application="no" text="Populate ServerListConf: #loadSrvLstConf#">
        </cfif>

        <cfif dbData["ServerConf"] EQ false>
            <cfset loadSrvConf = serverConf('populate') />
            <cflog file="Server" application="no" text="Populate ServerConf: #loadSrvConf#">
        </cfif>

        <cfif dbData["SUSListConf"] EQ false>
            <cfset loadSUSConf = susListConf('populate') />
            <cflog file="Server" application="no" text="Populate SUSListConf: #loadSUSConf#">
        </cfif>

        <cfif dbData["ClientConf"] EQ false>
            <cfset loadClientConf = clientConf('populate') />
			<cflog file="Server" application="no" text="Populate ClientConf: #loadClientConf#">
        </cfif>

        <cfif dbData["PatchGroupConf"] EQ false>
            <cfset loadPatchGroupConf = patchGroupConf('populate') />
			<cflog file="Server" application="no" text="Populate PatchGroupConf: #loadPatchGroupConf#">
        </cfif>

        <cfreturn>
    </cffunction>

    <cffunction name="serverListConf" access="private" returntype="any">
        <cfargument name="action" required="true">

        <cfif arguments.action EQ "query">
            <cftry>
                <cfquery name="queryServer" datasource="mpds">
                    select *
                    from mp_server_list
                    where listid = '1'
                </cfquery>
                <cfif queryServer.recordcount == 0>
                    <cfreturn false>
                <cfelse>
                    <cfreturn true>
                </cfif>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
        <cfif arguments.action EQ "populate">
            <cftry>
                <cfquery name="qAddServer" datasource="mpds">
                    Insert Into mp_server_list ( listid, name, version)
                    Values ( '1', 'Default', 0)
                </cfquery>
                    <cfreturn true>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
    </cffunction>

    <cffunction name="serverConf" access="private" returntype="any">
        <cfargument name="action" required="true">

        <cfif arguments.action EQ "query">
            <cftry>
                <cfquery name="queryServer" datasource="mpds">
                    select *
                    from mp_servers
                    where isMaster = '1'
                </cfquery>
                <cfif queryServer.recordcount == 0>
                    <cfreturn false>
                <cfelse>
                    <cfreturn true>
                </cfif>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
        <cfif arguments.action EQ "populate">
            <cftry>
                <cfquery name="qAddServer" datasource="mpds">
                    Insert Into mp_servers ( listid, server, port, useSSL, useSSLAuth, allowSelfSignedCert, isMaster, isProxy, active)
                    Values ( '1', 'localhost', 2600, 1, 0, 1, 1, 0, 0)
                </cfquery>
                    <cfreturn true>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
    </cffunction>

    <cffunction name="susListConf" access="private" returntype="any">
        <cfargument name="action" required="true">

        <cfif arguments.action EQ "query">
            <cftry>
                <cfquery name="queryServer" datasource="mpds">
                    select *
                    from mp_asus_catalog_list
                    where listid = '1'
                </cfquery>
                <cfif queryServer.recordcount == 0>
                    <cfreturn false>
                <cfelse>
                    <cfreturn true>
                </cfif>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
        <cfif arguments.action EQ "populate">
            <cftry>
                <cfquery name="qAddServer" datasource="mpds">
                    Insert Into mp_asus_catalog_list ( listid, name, version)
                    Values ( '1', 'Default', 0)
                </cfquery>
                    <cfreturn true>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
    </cffunction>

    <cffunction name="clientConf" access="private" returntype="any">
        <cfargument name="action" required="true">

        <cfif arguments.action EQ "query">
            <cftry>
                <cfquery name="queryServer" datasource="mpds">
                    select *
                    from mp_agent_config
                    where isDefault = '1'
                </cfquery>
                <cfif queryServer.recordcount == 0>
                    <cfreturn false>
                <cfelse>
                    <cfreturn true>
                </cfif>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>

        <cfif arguments.action EQ "populate">
            <cftry>
                <cfset cID = CreateUuid()>
                <cfquery name="addConfig" datasource="mpds">
                    Insert Into mp_agent_config (aid, name, isDefault)
                    Values ('#cID#','Default',1)
                </cfquery>
                <cfscript>
                    agentConf = {
                        AllowClient = "1",
                        AllowServer = "0",
                        Description = "Defautl Agent Config",
                        Domain = "Default",
                        PatchGroup = "Default",
                        Reboot = "1",
                        SWDistGroup = "Default",
                        MPProxyServerAddress = "AUTOFILL",
                        MPProxyServerPort = "2600",
                        MPProxyEnabled = "0",
                        MPServerAddress = "AUTOFILL",
                        MPServerPort = "2600",
                        MPServerSSL = "1",
                        CheckSignatures = "0",
                        MPServerAllowSelfSigned = "0"
                    };
                </cfscript>
                <cfloop collection="#agentConf#" item="key">
                    <cfquery name="addConfigData" datasource="mpds">
                        Insert Into mp_agent_config_data (aid, aKey, aKeyValue, enforced)
                        Values ("#cID#","#key#","#agentConf[key]#","0")
                    </cfquery>
                </cfloop>

                <cfset rev = getConfigRevision(cID)>
                <cfif rev.errorNo NEQ 0>
                    <cfreturn false>
                </cfif>

                <cfquery name="qUpdateRev" datasource="mpds">
                    Update mp_agent_config
                    Set revision = <cfqueryparam value="#rev.result#">
                    Where aid = <cfqueryparam value="#cID#">
                </cfquery>

                <cfreturn true>
            <cfcatch>
				<cflog file="Server" application="no" text="#cfcatch.message#">
				<cflog file="Server" application="no" text="#cfcatch.detail#">
                <cfreturn false>
            </cfcatch>
            </cftry>
        </cfif>
    </cffunction>

    <cffunction name="getConfigRevision" access="private" output="no" returntype="any">
        <cfargument name="configID">

        <cfset var result = Structnew()>
        <cfset result.errorNo = "0">
        <cfset result.errorMsg = "">
        <cfset result.result = "">

        <cftry>
            <cfquery datasource="mpds" name="qGetAgentConfigData">
                Select aKeyValue From mp_agent_config_data
                Where aid = '#arguments.configID#'
            </cfquery>
            <cfif qGetAgentConfigData.RecordCount GTE 1>
                <cfset confData = "">
                <cfoutput query="qGetAgentConfigData">
                    <cfset confData = confData & "#aKeyValue#">
                </cfoutput>

                <cfset result.result = Hash(confData,"MD5")>
            <cfelse>
                <cfset result.errorNo = "1">
                <cfset result.errorMsg = "No config data found.">
            </cfif>
            <cfcatch>
                <cfset result.errorNo = "1">
                <cfset result.errorMsg = "#cfcatch.Detail# #cfcatch.message#">
            </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="patchGroupConf" access="private" returntype="any">
        <cfargument name="action" required="true">

        <cfif arguments.action EQ "query">
            <cftry>
                <cfquery name="queryServer" datasource="mpds">
                    select *
                    from mp_patch_group
                    where name = 'Default'
                </cfquery>
                <cfif queryServer.recordcount == 0>
                    <cfreturn false>
                <cfelse>
                    <cfreturn true>
                </cfif>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
        <cfif arguments.action EQ "populate">
            <cftry>
                <cfset cID = CreateUuid()>
                <cfquery name="qAddGroupName" datasource="mpds">
                    Insert Into mp_patch_group ( name, id, type)
                    Values ('Default', '#cID#', '0')
                </cfquery>

                <cfquery name="qAddGroupOwner" datasource="mpds">
                    Insert Into mp_patch_group_members ( user_id, patch_group_id, is_owner)
                    Values ('mpadmin', '#cID#', '1')
                </cfquery>

                <cfreturn true>
                <cfcatch>
                    <cfreturn false>
                </cfcatch>
            </cftry>
        </cfif>
    </cffunction>

</cfcomponent>

