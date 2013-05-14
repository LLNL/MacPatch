<cfcomponent>
	<cffunction name="getSwTasksForGroup" access="remote" returnType="any" returnFormat="json" output="false">
		<cfargument name="groupName" required="true" />
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<cfset var sw_tasks = ArrayNew(1)>
		<cfset swObj = CreateObject( "component", "cfc.sw_dist_tasks" ) />
		<cfset _qTasks = swObj.getTasksForGroup(arguments.groupName)>

		<cfif _qTasks.RecordCount GTE 1>
			<cfloop query = "_qTasks">
				<cfset noErr = 0>
				<cfset asw_task = swObj.genNewSWTask()>
				<cfset _dataRes = swObj.getTaskDataForID(sw_task_id)>
				<cfif _dataRes.errorno EQ 0>
					<cfset asw_task.sw_task.task = _dataRes.data>
				<cfelse>
					<cfset noErr = 1>
					<cfset l = swObj.elog("[getTaskDataForID]Errorno:#_dataRes.errorno# ErrorMsg:#_dataRes.errormsg#")>
				</cfif>
				<cfset _infoRes = swObj.getTaskInfoForID(sw_task_id)>
				<cfif _infoRes.errorno EQ 0>
					<cfset asw_task.sw_task.info = _infoRes.data>
				<cfelse>
					<cfset noErr = 1>
					<cfset l = swObj.elog("[getTaskInfoForID]Errorno:#_dataRes.errorno# ErrorMsg:#_dataRes.errormsg#")>
				</cfif>
				<cfset _critRes = swObj.getTaskCriteriaForID(sw_task_id)>
				<cfif _critRes.errorno EQ 0>
					<cfset asw_task.sw_task.criteria = _critRes.data>
				<cfelse>
					<cfset noErr = 1>
					<cfset l = swObj.elog("[getTaskCriteriaForID]Errorno:#_dataRes.errorno# ErrorMsg:#_dataRes.errormsg#")>
				</cfif>

				<cfif noErr EQ 0>
					<cfset ArrayAppend(sw_tasks,asw_task)>
				<cfelse>
					<cfset l = swObj.elog("Task (#sw_task_id#) was not added due to error(s).")>
				</cfif>
			</cfloop>
		</cfif>
		<!--- Set the Result --->
		<cfset response.result = #sw_tasks#>

		<cfreturn #serializeJSON(response)#>
	</cffunction>
</cfcomponent>