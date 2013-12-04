<cfparam name="mpDBSource" default="mpwsds">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>MP Task worker...</title>
</head>
<body>
<cfparam name="url.days" default="180">
<cfparam name="url.archive" default="1">
<cfparam name="url.lrows" default="30000">	

<cfif #CGI.HTTP_USER_AGENT# EQ "BlueDragon">

	<cffunction name="addToHistory" output="no" returntype="boolean">
        <cfargument name="row" default="None" required="yes" type="struct">
		
		<cftry>
	        <cfquery datasource="mpds" name="qGet">
	            Insert Into mp_installed_patches_hst (cuuid,hostname,ipaddr,idate,patch,type,clientgroup,patchgroup)
	            VALUES (<cfqueryparam value="#row['cuuid']#">,<cfqueryparam value="#row['hostname']#">,<cfqueryparam value="#row['ipaddr']#">,
	            <cfqueryparam value="#row['idate']#" cfsqltype="cf_sql_timestamp">,<cfqueryparam value="#row['patch']#">,<cfqueryparam value="#row['type']#">,
	            <cfqueryparam value="#row['Domain']#">,<cfqueryparam value="#row['PatchGroup']#">)
	        </cfquery> 
	        <cfcatch type="any">
	            <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[addToHistory]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#")>
	            <cfreturn false>
	        </cfcatch>
        </cftry>
        <cfreturn true>
    </cffunction>

    <cffunction name="deleteFromTable" access="public" output="no" returntype="void">
        <cfargument name="rid" required="yes">
		
        <cftry>
            <cfquery datasource="mpds" name="qGetPatches">
                Delete
                FROM mp_installed_patches
                Where rid = <cfqueryparam value="#arguments.rid#">
            </cfquery> 
            <cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[Delete][mp_installed_patches][#arguments.rid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
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
	
	<cfscript>
	    function GetQueryRow(query, rowNumber) {
	        var i = 0;
	        var rowData = StructNew();
	        var cols    = ListToArray(query.columnList);
	        for (i = 1; i lte ArrayLen(cols); i = i + 1) {
	            rowData[cols[i]] = query[cols[i]][rowNumber];
	        }
	        return rowData;
	    }
	</cfscript>

<!--- Main --->
	<cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Starting install data cleanup.")>
    <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Purging data older than #url.days#.")>
    <cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Archiving is set to #url.archive#.")>

	<!--- Get All Records To Archive and Delete --->
	<cfset records = "">
	<cftry>
        <cfquery datasource="mpds" name="qGet">
			Select mip.rid, mip.cuuid as cuuid, mip.date as idate, mip.type, mcv.Domain, mcv.PatchGroup, mcv.hostname, mcv.ipaddr,
          	IF(UCASE(mip.type) = 'THIRD',  CONCAT(mpp.patch_name, '-', mpp.patch_ver), mip.patch) as patch
          	FROM mp_installed_patches mip
          	LEFT JOIN mp_clients_view mcv ON (mip.cuuid = mcv.cuuid)
          	LEFT JOIN mp_patches mpp ON (mip.patch = mpp.puuid)
			WHERE mip.date <= DATE_SUB(SYSDATE(), INTERVAL #url.days# DAY)
			Order By date desc
			Limit #url.lrows#
        </cfquery> 
		<cfset records = qGet>
        <cfcatch type="any">
            <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[getInstallDataQuery]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#")>
			<cfabort>
        </cfcatch>
	</cftry>
	
	<cfif qGet.RecordCount GTE 1>
		<cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Found #qGet.RecordCount# records to archive and purge.")>
		<cfloop query = "qGet"> 
			<!--- Archive Current Row --->
			<cfif url.archive EQ 1>
				<cfset rowData = #GetQueryRow(qGet,qGet.currentRow)#>
				<cfset y = addToHistory(rowData)>
				<!--- Delete Row --->
				<cfif y IS true>
					<cfset deleteFromTable(qGet.rid)>
				</cfif>
			<cfelse>	
				<!--- Delete Row --->
				<cfset deleteFromTable(qGet.rid)>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfset log = logit("TASK",#CGI.REMOTE_HOST#,"Install data cleanup completed.")>
<cfelse>
	<cfset log = logit("Error",#CGI.REMOTE_HOST#,"(#CGI.HTTP_USER_AGENT#): Something tried to run Inventory cleanup script.")>
</cfif>
</body>
</html>