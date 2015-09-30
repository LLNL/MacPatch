<cfparam name="mpDBSource" default="mpwsds">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>MP Task worker...</title>
</head>
<body>
<!---
    This task, cleanup.cfm will delete aged out clients and all of their respective data.
    This task is triggered by the server job "delete expired clients" where a date 
    threshold is set. If no date is set 31 day is used. 15 days is the lowest number 
    which can be used. If a user sets days below 15 it will revert to 15 in code only.
--->    
<cfparam name="url.days" default="31">  
<cfif #CGI.HTTP_USER_AGENT# EQ "BlueDragon">

    <!--- Get DataBase Tables, and filter them --->
    <cffunction name="getDBTables" output="no" returntype="any">
        
        <cfset var tablesRaw = "">
        <cftry>
            <cfquery datasource="mpds" name="qGet" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
                SELECT DISTINCT TABLE_NAME 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE table_schema='MacPatchDB'
                AND TABLE_TYPE = 'BASE TABLE' 
            </cfquery> 
            <cfset tablesRaw = ValueList(qGet.TABLE_NAME)>
            <cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[getDBTables]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#")>
            </cfcatch>
        </cftry>

        <cfreturn #tablesRaw#>
    </cffunction>
    
    <cffunction name="deleteClient" access="public" output="no" returntype="void">
        <cfargument name="cuuid" required="yes">
        <cfargument name="table" required="yes">
        <cftry>
            <cfquery datasource="mpds" name="qGetPatches">
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
        <cfargument name="table" required="yes">
        <cftry>
            <cfquery datasource="mpds" name="qGetCol" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
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
    
    <cffunction name="removeClient" access="public" returntype="any" output="yes">
        <cfargument name="id" required="yes">

        <cfset log = logit("Error",#CGI.REMOTE_HOST#,"Removing #arguments.id#")>
        <cftry>
            <cfquery name="getClientInfo" datasource="mpds">
                Select cuuid,hostname,ipaddr From mp_clients
                Where cuuid = '#arguments.id#'
            </cfquery>

            <cfif getClientInfo.RecordCount LTE 0>
                <!--- No Client, nothing to delete --->
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"No client was found for ID #arguments.id#.")>
                <cfreturn true> 
            </cfif>
            <cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"#CGI.HTTP_USER_AGENT# removed client,(#getClientInfo.hostname#,#getClientInfo.ipaddr#,#Arguments.id#). #cfcatch.Message#")>
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
        <cfloop list="#tableList#" index="table" delimiters=",">
            <cfif #tableContainsColumn(table)# EQ true>
                <cfset tmp = deleteClient(Arguments.id,table)>
                <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"#CGI.HTTP_USER_AGENT# removed client,(#getClientInfo.hostname#, #getClientInfo.ipaddr#, #Arguments.id#, #table#)")>
            </cfif>
        </cfloop>

        <cfreturn true>        
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
    <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Starting Client Clean up.")>
    <cfif IsDefined("url.days")>
        <cfif IsNumeric(url.days)>
            <cfif url.days LT "15">
                <cfset url.days = "15"> 
            </cfif> 
        <cfelse>
            <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Error, days was not properly set.")>
            <cfabort>
        </cfif>
    </cfif>
    <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Setting days to #url.days#")>
    <cfquery name="getClientInfo" datasource="mpds">
        Select cuuid, mdate, hostname From mp_clients
        Where  mdate <= (now() - interval #url.days# day)
    </cfquery>
    
    <cfset rmListID = ValueList(getClientInfo.cuuid)>
    <cfset rmListNM = ValueList(getClientInfo.hostname)>
    <cfset rmListDT = ValueList(getClientInfo.mdate)>
    <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Need to remove #ListLen(rmListID)# client, to old.")>
    
    <cfloop From = "1" TO = "#ListLen(rmListID)#" INDEX = "Counter">
        <cfset cid = #ListGetAt(rmListID, Counter)#>
        <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"#CGI.HTTP_USER_AGENT# removed client,(#ListGetAt(rmListNM, Counter)#,#cid#)")>
        <cfset rm = #removeClient(cid)#>
    </cfloop>
    
    <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Client Clean up finished.")>
<cfelse>
    <cfset log = logit("Error",#CGI.REMOTE_HOST#,"(#CGI.HTTP_USER_AGENT#): Something tried to run remove client script.")>
</cfif>
</body>
</html>