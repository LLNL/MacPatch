<cfparam name="mpDBSource" default="mpwsds">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>MP Task worker...</title>
</head>
<body>
<cfparam name="url.days" default="31">	
<cfif #CGI.HTTP_USER_AGENT# EQ "BlueDragon">

	<!--- Get DataBase Tables, and filter them --->
	<cffunction name="getDBTables" output="no" returntype="any">
        <cfargument name="tableNameFilter" default="None" required="no">

		<cfset tablesRaw = "">
		<cftry>
	        <cfquery datasource="mpds" name="qGet" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
	            SELECT DISTINCT TABLE_NAME 
	            FROM INFORMATION_SCHEMA.TABLES 
	            WHERE table_schema='MacPatchDB'
	            AND TABLE_TYPE = 'BASE TABLE' 
	            <cfif arguments.tableNameFilter NEQ "None">
				AND TABLE_NAME like '%#arguments.tableNameFilter#%'
				</cfif>
	        </cfquery>
	        <cfset tablesRaw = ValueList(qGet.TABLE_NAME)>
	        <cfcatch type="any">
	            <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[getDBTables]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#")>
	        </cfcatch>
        </cftry>
		
        <cfreturn #tablesRaw#>
    </cffunction>

	<cffunction name="getClientIDList" access="public" output="no">
	    <cfquery name="selIDs" datasource="mpds">
	        Select Distinct cuuid From mp_clients
		</cfquery>
		
		<cfreturn ValueList(selIDs.cuuid,",")>
	</cffunction>

    <cffunction name="deleteClient" access="public" output="no" returntype="void">
        <cfargument name="cuuid" required="yes">
        <cfargument	name="table" required="yes">
        <cftry>
            <cfquery datasource="mpds" name="qGetPatches">
                Delete
                FROM #arguments.table#
                Where cuuid = <cfqueryparam value="#arguments.cuuid#">
            </cfquery> 
            <cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[Delete][#arguments.table#][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
    </cffunction> 
	
	<cffunction name="tableContainsColumn" access="public" output="no" returntype="any">
        <cfargument	name="table" required="yes">
        <cftry>
            <cfquery datasource="mpds" name="qGetCol" cachedwithin="#CreateTimeSpan(2, 0, 0, 0)#">
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

	<cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aHost" required="no">
        <cfargument name="aEvent">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">
        
        <cfscript>
            try {
                inet = CreateObject("java", "java.net.InetAddress");
                inet = inet.getLocalHost();
            } catch (any e) {
                inet = "localhost";
            }
        </cfscript>
        <cftry>
            <cfquery datasource="mpds" name="qGet">
                Insert Into ws_log_jobs (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
                Values (#CreateODBCDateTime(now())#, '#aEventType#', '#aEvent#', '#CGI.REMOTE_HOST#', '#CGI.SCRIPT_NAME#', '#CGI.PATH_TRANSLATED#','#CGI.SERVER_NAME#','#CGI.SERVER_SOFTWARE#', '#inet#') 
            </cfquery>
            <cfcatch type="any">
                <cflog type="Error" file="MPDeleteClient" text="[Delete]:[logit] #cfcatch.Detail# -- #cfcatch.Message#">
            </cfcatch>
        </cftry>
	</cffunction>

<!--- Main --->
	<cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Starting inventory cleanup.")>
	
	<!--- Get All Inventory Tables, prefix is mpi --->
	<cfset tableList = #getDBTables("mpi_")#>
	<cfset tables = "mp_installed_patches,mp_client_patches_apple,mp_client_patches_third,patches,savav_info">
	<cfloop index="t" list="#tables#"> 
		<cfset tableList = listAppend(tableList, "#t#", ",")>
	</cfloop>
	
	<!--- Get A Distinct List Of All of the Client ID's --->
	<cfset _cuuidList = #getClientIDList()#> 
	
	<!---  Loop through all of the tables and remove all non-valid client ID's --->
	<cfloop index="table" list="#tableList#" delimiters=",">
		
		<!--- Get All of the Client ID's for the table --->
        <cftry>
            <cfquery name="selIDs" datasource="mpds">
                Select Distinct cuuid From #table#
            </cfquery>
            <cfcatch>
            	<cfset selIDs = QueryNew("cuuid")>
            </cfcatch>
		</cftry>		
		<cfif selIDs.RecordCount NEQ 0>
			<cfset idsToRemove = 0>
			<cfloop query="selIDs">
				<cfif ListFindNoCase(_cuuidList,selIDs.cuuid) EQ 0>
					<cfset idsToRemove = 0>
					<cfset _x = deleteClient(selIDs.cuuid,table)>
				</cfif>
				<cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Removed #idsToRemove# from #table#.")>
			</cfloop>
		</cfif>		
	</cfloop>

	<cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Inventory cleanup completed.")>
<cfelse>
	<cfset log = logit("Error",#CGI.REMOTE_HOST#,"(#CGI.HTTP_USER_AGENT#): Something tried to run Inventory cleanup script.")>
</cfif>
</body>
</html>