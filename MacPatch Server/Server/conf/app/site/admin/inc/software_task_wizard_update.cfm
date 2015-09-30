<cfscript>
   function isEmpty(str) {
      if(NOT len(trim(str)))
         return false;
      else
         return true;
      }
</cfscript>

<!--- Update the Main Record --->
<cfquery name="qUpdate" datasource="#session.dbsource#" result="res">
	Update mp_software_task
    Set
		name = <cfqueryparam value="#form.name#">
        <cfif IsDefined("Form.primary_suuid") AND isEmpty(Form.primary_suuid)>
        	,primary_suuid = <cfqueryparam value="#form.primary_suuid#">
        </cfif>
        <cfif IsDefined("Form.active") AND isEmpty(Form.active)>
        	,active = <cfqueryparam value="#form.active#">
        </cfif>
		<cfif IsDefined("Form.sw_task_type") AND isEmpty(Form.sw_task_type)>
        	,sw_task_type = <cfqueryparam value="#form.sw_task_type#">
        </cfif>
        <cfif IsDefined("Form.sw_start_datetime") AND isEmpty(Form.sw_start_datetime)>
        	,sw_start_datetime = <cfqueryparam value="#form.sw_start_datetime#">
        </cfif>
		<cfif IsDefined("Form.sw_end_datetime") AND isEmpty(Form.sw_end_datetime)>
        	,sw_end_datetime = <cfqueryparam value="#form.sw_end_datetime#">
        </cfif>
    Where tuuid = <cfqueryparam value="#form.tuuid#">
</cfquery>

<!--- Update the group data with the updated task info --->
<cftry>
	<cfquery datasource="#session.dbsource#" name="qGetGroupsToUpdate">
		select sw_group_id from mp_software_group_tasks
		Where sw_task_id = '#form.tuuid#'
	</cfquery>
	<cfcatch>
	</cfcatch>
</cftry>
<cfset obj = CreateObject("component","software_group_edit")>
<cfloop query="qGetGroupsToUpdate">
	<cfset res = obj.PopulateSoftwareGroupData(sw_group_id)>
</cfloop>

<cflocation url="#session.cflocFix#/admin/inc/software_tasks.cfm">

