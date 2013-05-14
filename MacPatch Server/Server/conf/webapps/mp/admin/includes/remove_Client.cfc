<cfcomponent>
	
	<cffunction name="getDBTables" output="no" returntype="any">
        <cftry>
	        <cfquery datasource="#session.dbsource#" name="qGet" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
	            SELECT DISTINCT TABLE_NAME 
	            FROM INFORMATION_SCHEMA.TABLES 
	            WHERE table_schema='MacPatchDB'
	            AND TABLE_TYPE = 'BASE TABLE' 
	        </cfquery> 
	        <cfcatch type="any">
	            <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[getDBTables]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#")>
	        </cfcatch>
        </cftry>
        <cfset tablesRaw = ValueList(qGet.TABLE_NAME)>
        
        <cfreturn #tablesRaw#>
    </cffunction>
    
    <cffunction name="deleteClient" access="public" output="no" returntype="void">
        <cfargument name="cuuid" required="yes">
        <cfargument	name="table" required="yes">
		
        <cftry>
            <cfquery datasource="#session.dbsource#" name="qGetPatches">
                Delete
                FROM #arguments.table#
                Where cuuid = '#arguments.cuuid#'
            </cfquery> 
            <cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[Delete][#arguments.table#][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
    </cffunction> 
	
	<cffunction name="tableContainsColumn" access="public" output="no" returntype="any">
        <cfargument	name="table" required="yes">
        <cftry>
            <cfquery datasource="#session.dbsource#" name="qGetCol" cachedwithin="#CreateTimeSpan(2, 0, 0, 0)#">
				SELECT * FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_SCHEMA = 'MacPatchDB' AND TABLE_NAME = <cfqueryparam value="#arguments.table#"> AND COLUMN_NAME = 'cuuid'
            </cfquery> 
				<cfif qGetCol.RecordCount EQ 1>
					<cfreturn true>
				<cfelse>
					<cfreturn false>
				</cfif>
            <cfcatch type="any">
                <cfreturn false>
            </cfcatch>
        </cftry>
		
		<cfreturn false>
    </cffunction> 
    
    <cffunction name="removeClient" access="public" returntype="any" output="no">
    	<cfargument name="id" required="yes">
	
		<cftry>
			<cfquery name="getClientInfo" datasource="#session.dbsource#">
	            Select * From mp_clients
	            Where cuuid = '#Arguments.id#'
	        </cfquery>
	        <cfif getClientInfo.RecordCount LTE 0>
	        	<!--- No Client, nothing to delete --->
	            <cfreturn true> 
	        </cfif>
			<cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"#Session.Username# removed client,(#getClientInfo.hostname#,#getClientInfo.ipaddr#,#Arguments.id#). #cfcatch.Message#")>
				<cfreturn false> 
            </cfcatch>
		</cftry>

        <!--- MacPatch Database Tables --->
        <cfset tableList = #getDBTables()#>
        <cfif ListLen(tableList,",") EQ 0>
        	<cfset log = logit("Warning",#CGI.REMOTE_HOST#,"[Delete]: No tables to remove client id from.")>
            <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"[Delete]: Client was not removed, #getClientInfo.hostname# (#Arguments.id#)")>
            <cfreturn false>
        </cfif>
        
        <!--- Delete the client --->
        <cfloop list="#tablesRaw#" index="table" delimiters=",">
			<cfif #tableContainsColumn(table)# EQ true>
				<cfset tmp = deleteClient(Arguments.id,table)>
				<cfset log = logit("Warning",#CGI.REMOTE_HOST#,"#Session.Username# removed client,(#getClientInfo.hostname#, #getClientInfo.ipaddr#, #Arguments.id#, #table#)")>
			</cfif>
        </cfloop>

		<cfreturn true>        
	</cffunction> 	
	
<!---	
	<cffunction name="removeClient" access="public" returntype="any" output="no">
	    	<cfargument name="id" required="yes">
	        
	        <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"One #application.settings.database.prod.databasename#")>
	        
	        <cfquery name="getClientInfo" datasource="#session.dbsource#">
	            Select * From mp_clients_view
	            Where cuuid = '#Arguments.id#'
	        </cfquery>
	        
	        <cfif getClientInfo.RecordCount LTE 0>
	        	<!--- No Client, nothing to delete --->
	            <cfreturn true> 
	        </cfif>
	        
	        <!--- MacPatch Database Tables --->
	        <cfset tableList = #getClientTables()#>
	        <cfif ListLen(tableList,",") EQ 0>
	        	<cfset log = logit("Warning",#CGI.REMOTE_HOST#,"[Delete]: No tables to remove client id from.")>
	            <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"[Delete]: Client was not removed, #getClientInfo.hostname# (#Arguments.id#)")>
	            <cfreturn false>
	        </cfif>
	        
	        <!--- Delete the client --->
	        <cfloop list="#tableList#" index="table" delimiters=",">
	            <cfset tmp = deleteClient(Arguments.id,table)>
	        </cfloop>
	        
	        <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"#Session.Username# removed client,(#getClientInfo.hostname#,#getClientInfo.ipaddr#,#Arguments.id#)")>
	
			<cfreturn true>        
	</cffunction>      
	
	<cffunction name="getClientTables" output="no" returntype="any">
		<cftry>
	        <cfquery datasource="#session.dbsource#" name="qGet">
	            Show FULL Tables
	            Where Table_type = 'BASE TABLE'
	        </cfquery> 
	        <cfcatch type="any">
	            <cflog type="Error" file="MPDeleteClient2" text="[getClientTables]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#">
	        </cfcatch>
	    </cftry>
		
		<cfif IsDefined("application.settings.database.prod.databasename")>
	    	<cfset tablesRaw = ValueList(evaluate("qGet.Tables_in_"&#application.settings.database.prod.databasename#))>
		<cfelse>
			<cfset tablesRaw = ValueList(qGet.Tables_in_MacPatchDB)>
		</cfif>
	    
	    <cfset protectedTables = "mp_proxy_conf,mp_proxy_key,mp_proxy_logs,mp_report_dev,mp_report_filter,mp_distribution_servers,mp_client_agent_updates,mp_apple_patch_criteria,mp_adm_users,dataMgrlogs,apple_patches_info,mp_reports,mp_selfupdate_filters,mp_servers,SAVAV_DEFS,SelfUpdates,profiles,proxy_config,proxy_keys,ws_log,mp_db_settings,mp_patch_group,mp_patch_group_dev,mp_patch_group_members,mp_patch_group_members_dev,mp_patch_group_patches,mp_patch_group_patches_dev,mp_patches,mp_patches_criteria,mp_patches_files,mp_patches_requisits,apple_patches,apple_patches_cve,apple_patches_real,mp_adm_group_users,mp_adm_groups,mp_asus_catalogs,mp_baseline,mp_baseline_patches">
	    
	    <cfloop list="#protectedTables#" index="table" delimiters=",">
	        <cfset whereItsAt = ListContainsnocase(tablesRaw,table,",")>
	        <cfif whereItsAt NEQ 0>
	            <cfset tablesRaw = ListDeleteat(tablesRaw,whereItsAt,",")>
	            <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"Table: #table#")>
	        </cfif>
	    </cfloop>
		
	    <cfreturn #tablesRaw#>
	</cffunction>
	
	<cffunction name="deleteClient" access="public" output="no" returntype="void">
		<cfargument name="cuuid" required="yes">
	    <cfargument	name="table" required="yes">
	    <cftry>
	    	<cfquery datasource="#session.dbsource#" name="qGetPatches">
	            Delete
	            FROM #arguments.table#
	            Where cuuid = '#arguments.cuuid#'
	        </cfquery> 
	        <cfcatch type="any">
	            <cflog type="Error" file="MPDeleteClient2" text="[Delete]:[#arguments.table#][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#">
	            <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[Delete][#arguments.table#][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
	        </cfcatch>
	    </cftry>
	</cffunction>  
	
--->	
	<cffunction name="logit" access="public" returntype="void" output="no">
	        <cfargument name="aEventType">
	        <cfargument name="aHost" required="no">
	        <cfargument name="aEvent">
	        <cfargument name="aScriptName" required="no">
	        <cfargument name="aPathInfo" required="no">
	        
	        <cflog type="Error" file="MPDeleteClient_DEV" text="[Delete]:[logit] #aEvent#">
	        
	        <cfscript> 
				inet = CreateObject("java", "java.net.InetAddress");
				inet = inet.getLocalHost();
			</cfscript> 
	        <cftry>
	    	<cfquery datasource="#session.dbsource#" name="qGet">
	            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
	            Values (#CreateODBCDateTime(now())#, '#aEventType#', '#aEvent#', '#CGI.REMOTE_HOST#', '#CGI.SCRIPT_NAME#', '#CGI.PATH_TRANSLATED#','#CGI.SERVER_NAME#','#CGI.SERVER_SOFTWARE#', '#inet#') 
	        </cfquery>
	        <cfcatch type="any">
	            <cflog type="Error" file="MPDeleteClient" text="[Delete]:[logit] #cfcatch.Detail# -- #cfcatch.Message#">
	        </cfcatch>
	    </cftry>
	</cffunction>
	
</cfcomponent>