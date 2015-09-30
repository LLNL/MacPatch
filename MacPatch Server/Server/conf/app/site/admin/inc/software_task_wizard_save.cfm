<!--- Setup Variables that make this entry unique --->
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">
<cfset new_tuuid=CreateUUID()>

<!--- Check to see if the patch id is unique first, if not bail --->
<cfif CheckForDuplicateID(new_tuuid) NEQ 0>
	<h1>Error: Duplicate task ID.</h1>
	<cfabort />
</cfif>

<!--- Insert the new Record --->
<!--- Insert the Main Record --->
<cfquery name="qInsert1" datasource="#session.dbsource#">
	Insert Into mp_software_task (
		tuuid, name, primary_suuid, active, sw_task_type, sw_start_datetime, sw_end_datetime, mdate, cdate
    )
    Values (
        '#new_tuuid#', <cfqueryparam value="#name#">, <cfqueryparam value="#primary_suuid#">, <cfqueryparam value="#active#">,
		<cfqueryparam value="#sw_task_type#">, <cfqueryparam value="#sw_start_datetime#">, <cfqueryparam value="#sw_end_datetime#">,
		<cfqueryparam value="#ts#">, <cfqueryparam value="#ts#">
    )
</cfquery>

<cflocation url="#session.cflocFix#/admin/inc/software_tasks.cfm">

<cffunction name="CheckForDuplicateID" returntype="any">
	<cfargument name="uid" type="string" required="true">
	<cftry>
        <cfquery name="qCheck" datasource="#session.dbsource#">
            Select tuuid From mp_software_task
            Where tuuid = <cfqueryparam value="#arguments.uid#">
        </cfquery>
        <cfif qCheck.RecordCount EQ 0>
        	<cfreturn "0">
        <cfelse>
        	<cfreturn "1">
        </cfif>
        <cfcatch type="any">
        	<cfreturn "-1">
        </cfcatch>
    </cftry>
    	<cfreturn "-1">
</cffunction>

