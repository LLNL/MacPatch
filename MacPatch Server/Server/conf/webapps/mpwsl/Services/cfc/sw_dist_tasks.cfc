<cfcomponent name="sw_dist_tasks" extends="_mpbase">

	<cfparam name="mpDBSource" default="mpds">

	<cffunction name="getTasksForGroup" access="public" returntype="query" output="no">
		<cfargument name="groupName" required="true" />

		<cfset qGet = QueryNew("sw_group_id, sw_task_id, selected")>

		<cftry>
			<cfquery datasource="#mpDBSource#" name="qGet">
				Select sw_group_id, sw_task_id, selected
				from mp_software_group_tasks
				Where sw_group_id = <cfqueryparam value="#getGroupID(arguments.groupName)#">
				AND selected = '1'
			</cfquery>
			<cfcatch>
				<!--- Log Error --->
				<cfset elog("[getTasksForGroup][#cfcatch.ErrorCode#]: #cfcatch.Message# #cfcatch.Detail#")>
			</cfcatch>
		</cftry>

		<cfreturn qGet>
	</cffunction>

	<cffunction name="getGroupID" access="public" returntype="any" output="no">
		<cfargument name="groupName" required="true" />

		<cftry>
			<cfquery datasource="#mpDBSource#" name="qGet" maxrows="1">
				Select * from mp_software_groups
				Where gName = <cfqueryparam value="#arguments.groupName#">
			</cfquery>
			<cfif qGet.RecordCount EQ 1>
				<cfreturn qGet.gid>
			</cfif>
		<cfcatch>
				<!--- Log Error --->
				<cfset elog("[getGroupID][#cfcatch.ErrorCode#]: #cfcatch.Message# #cfcatch.Detail#")>
			</cfcatch>
		</cftry>

		<cfreturn "NA">
	</cffunction>

	<cffunction name="getTaskDataForID" access="public" returntype="struct" output="no">
		<cfargument name="taskID" required="true" />

		<cfset result = {} />
		<cfset result[ "errorno" ] = "0" />
		<cfset result[ "errormsg" ] = "" />
		<cfset result[ "data" ] = {} />

		<cfset result.data[ "name" ] = "" />
		<cfset result.data[ "active" ] = "" />
		<cfset result.data[ "task_type" ] = "" />
		<cfset result.data[ "task_start_datetime" ] = "" />
		<cfset result.data[ "task_end_datetime" ] = "" />
		<cfset result.data[ "tuuid" ] = "#arguments.taskID#" />
		<cfset result.data[ "suuid" ] = "" />

		<cftry>
			<cfquery datasource="#mpDBSource#" name="qGet" maxrows="1">
				Select * from mp_software_task
				Where tuuid = <cfqueryparam value="#arguments.taskID#">
			</cfquery>

			<cfif qGet.RecordCount NEQ 1>
				<cfset result.errorno = "1">
				<cfset result.errormsg = "No task for for ID #arguments.taskID#">
				<cfset elog("[getTaskDataForID][#cfcatch.ErrorCode#]: Find task data for (#arguments.taskID#). #cfcatch.Message# #cfcatch.Detail#")>
			<cfelse>
				<cfoutput query="qGet">
					<cfset result.data.name = #name#>
					<cfset result.data.active = #active#>
					<cfset result.data.task_type = #sw_task_type#>
					<cfset result.data.task_start_datetime = "#DateFormat(sw_start_datetime, 'mm/dd/yyyy')# #TimeFormat(sw_start_datetime, 'HH:mm:ss')#">
					<cfset result.data.task_end_datetime = "#DateFormat(sw_end_datetime, 'mm/dd/yyyy')# #TimeFormat(sw_end_datetime, 'HH:mm:ss')#">
					<cfset result.data.suuid = #primary_suuid#>
				</cfoutput>
			</cfif>
			<cfcatch>
				<!--- Log Error --->
				<cfset result.errorno = "#cfcatch.ErrorCode#">
				<cfset result.errormsg = "#cfcatch.Message# #cfcatch.Detail#">
				<cfset elog("[getTaskDataForID][#cfcatch.ErrorCode#]: #cfcatch.Message# #cfcatch.Detail#")>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

	<cffunction name="getTaskCriteriaForID" access="public" returntype="struct" output="no">
		<cfargument name="taskID" required="true" />

		<cfset result = {} />
		<cfset result[ "errorno" ] = "0" />
		<cfset result[ "errormsg" ] = "" />
		<cfset result[ "data" ] = {} />

		<cfset result.data[ "os_type" ] = "0" />
		<cfset result.data[ "os_ver" ] = "0" />
		<cfset result.data[ "arch_type" ] = "" />

		<cftry>
			<cfquery datasource="#mpDBSource#" name="qGet" maxrows="1">
				Select primary_suuid from mp_software_task
				Where tuuid = <cfqueryparam value="#arguments.taskID#">
			</cfquery>

			<cfif qGet.RecordCount NEQ 1>
				<cfset result.errorno = "1">
				<cfset result.errormsg = "No task for for ID #arguments.taskID#">
				<cfset elog("[getTaskDataForID][#cfcatch.ErrorCode#]: Find task (#arguments.taskID#). #cfcatch.Message# #cfcatch.Detail#")>
			<cfelse>
				<cfset _suuid =  qGet.primary_suuid>
				<cfquery datasource="#mpDBSource#" name="qGetCriteria">
					Select * from mp_software_criteria
					Where suuid = <cfqueryparam value="#_suuid#">
					Order By type_order ASC
				</cfquery>
				<cfif qGet.RecordCount EQ 0>
					<cfset result.errorno = "2">
					<cfset result.errormsg = "No sw criteria for for ID #_suuid#">
					<cfset elog("[getTaskDataForID][#cfcatch.ErrorCode#]: Find criteria for (#arguments.taskID#). #cfcatch.Message# #cfcatch.Detail#")>
				<cfelse>
					<cfoutput query="qGetCriteria">
						<cfif type EQ "OSType">
							<cfset result.data.os_type = #type_data#>
						</cfif>
						<cfif type EQ "OSVersion">
							<cfset result.data.os_ver = #type_data#>
						</cfif>
						<cfif type EQ "OSArch">
							<cfset result.data.arch_type = #type_data#>
						</cfif>
					</cfoutput>
				</cfif>
			</cfif>
			<cfcatch>
				<!--- Log Error --->
				<cfset result.errorno = "#cfcatch.ErrorCode#">
				<cfset result.errormsg = "#cfcatch.Message# #cfcatch.Detail#">
				<cfset elog("[getTaskCriteriaForID][#cfcatch.ErrorCode#]: #cfcatch.Message# #cfcatch.Detail#")>
			</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>

	<cffunction name="getTaskInfoForID" access="public" returntype="struct" output="no">
		<cfargument name="taskID" required="true" />

		<cfset result = {} />
		<cfset result[ "errorno" ] = "0" />
		<cfset result[ "errormsg" ] = "" />
		<cfset result[ "data" ] = {} />

		<cfset result.data[ "size" ] = "0" />
		<cfset result.data[ "reboot" ] = "0" />
		<cfset result.data[ "autopatch" ] = "" />

		<cftry>
			<cfquery datasource="#mpDBSource#" name="qGet" maxrows="1">
				Select primary_suuid from mp_software_task
				Where tuuid = <cfqueryparam value="#arguments.taskID#">
			</cfquery>

			<cfif qGet.RecordCount NEQ 1>
				<cfset result.errorno = "1">
				<cfset result.errormsg = "No task for for ID #arguments.taskID#">
				<cfset elog("[getTaskInfoForID][#cfcatch.ErrorCode#]: Find task (#arguments.taskID#). #cfcatch.Message# #cfcatch.Detail#")>
			<cfelse>
				<cfset _suuid =  qGet.primary_suuid>
				<cfquery datasource="#mpDBSource#" name="qGetInfo" maxrows="1">
					Select * from mp_software
					Where suuid = <cfqueryparam value="#_suuid#">
				</cfquery>
				<cfif qGet.RecordCount NEQ 1>
					<cfset result.errorno = "2">
					<cfset result.errormsg = "No sw id for for ID #_suuid#">
					<cfset elog("[getTaskInfoForID][#cfcatch.ErrorCode#]: Find sw ID for (#arguments.taskID#). #cfcatch.Message# #cfcatch.Detail#")>
				<cfelse>
					<cfoutput query="qGetInfo">
						<cfset result.data.size = #sw_size#>
						<cfset result.data.reboot = #sReboot#>
						<cfset result.data.autopatch = #auto_patch#>
					</cfoutput>
				</cfif>
			</cfif>
			<cfcatch>
				<!--- Log Error --->
				<cfset result.errorno = "#cfcatch.ErrorCode#">
				<cfset result.errormsg = "#cfcatch.Message# #cfcatch.Detail#">
				<cfset elog("[getTaskInfoForID][#cfcatch.ErrorCode#]: #cfcatch.Message# #cfcatch.Detail#")>
			</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>

	<cffunction name="genNewSWTask" access="public" returntype="struct" output="no">
		<!--- Create SW_TASK Struct --->
		<cfset asw_task = {} />
		<cfset asw_task[ "sw_task" ] = {} />
		<cfset asw_task.sw_task[ "task" ] = {} />
		<cfset asw_task.sw_task[ "criteria" ] = {} />
		<cfset asw_task.sw_task[ "info" ] = {} />

		<!--- Task --->
		<cfset asw_task.sw_task.task[ "name" ] = "" />
		<cfset asw_task.sw_task.task[ "active" ] = "" />
		<cfset asw_task.sw_task.task[ "task_type" ] = "" />
		<cfset asw_task.sw_task.task[ "task_start_datetime" ] = "" />
		<cfset asw_task.sw_task.task[ "task_end_datetime" ] = "" />
		<cfset asw_task.sw_task.task[ "tuuid" ] = "" />
		<cfset asw_task.sw_task.task[ "suuid" ] = "" />
		<!--- criteria --->
		<cfset asw_task.sw_task.criteria[ "os_type" ] = "" />
		<cfset asw_task.sw_task.criteria[ "os_ver" ] = "" />
		<cfset asw_task.sw_task.criteria[ "arch_type" ] = "" />
		<!--- Info --->
		<cfset asw_task.sw_task.info[ "size" ] = "" />
		<cfset asw_task.sw_task.info[ "reboot" ] = "" />
		<cfset asw_task.sw_task.info[ "autopatch" ] = "" />

		<cfreturn asw_task>
	</cffunction>


</cfcomponent>