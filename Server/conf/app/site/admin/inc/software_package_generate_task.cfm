<cfif NOT isDefined("url.id")>
	<cflocation url="#session.cflocFix#/admin/inc/software_tasks.cfm">
</cfif>

<!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset cDate = #CreateODBCDateTime(now())#>
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">
<cfset tuuid=CreateUUID()>

<!--- Create Main Duplicate Record --->
<cftry>
    <cfquery name="qGetSWDist" datasource="#session.dbsource#">
        Select * From mp_software
        Where suuid = '#url.id#'
    </cfquery>
    <cfset new_name = "COPY_"&#qGetSWDist.sName#>
    <cfcatch type="any">
        <cflocation url="#session.cflocFix#/admin/inc/software_tasks.cfm">
    </cfcatch>    
</cftry>
<cftry>
	<cfquery name="qDupSWDist" datasource="#session.dbsource#">
		INSERT INTO mp_software_task (
			tuuid, name, primary_suuid, active, sw_task_type, sw_task_privs, sw_start_datetime, sw_end_datetime
	    )
	    Values (
	        '#tuuid#', '#qGetSWDist.sName# (#session.Username#)', '#qGetSWDist.suuid#', '0', 'o', 'Global', '#ts#', '#ts#'
	    )
	</cfquery>
	<cfcatch type="any">
		<cflocation url="#session.cflocFix#/admin/inc/software_tasks.cfm">
		<cfabort>
    </cfcatch>    
</cftry>
<cflocation url="#session.cflocFix#/admin/inc/software_tasks.cfm">
<cfabort>
