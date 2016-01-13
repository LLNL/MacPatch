<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "software_group_edit" />

	<cffunction name="getCustomDataTasks" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false">
	    <cfargument name="filters" required="no" default="">
		
		<cfset var arrUsers = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = Arguments._search>
		<cfset var strSearch = "">
		
		<cfif Arguments.filters NEQ "" AND blnSearch>
			<cfset stcSearch = DeserializeJSON(Arguments.filters)>
            <cfif isDefined("stcSearch.groupOp")>
            	<cfset strSearch = buildSearch(stcSearch)>
            </cfif>            
        </cfif>
        
        <cftry>
            <cfquery name="qSelSW" datasource="#session.dbsource#" result="res">
				Select Distinct *, '0' as selected
				from mp_software_task
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
            	</cfif>

                ORDER BY #sidx# #sord#
            </cfquery>

            <cfcatch type="any">
                <cfset blnSearch = false>
                <cfset strMsgType = "Error">
                <cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">
            </cfcatch>
        </cftry>

		<cfset records = qSelSW>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="qSelSW" startrow="#start#" endrow="#end#">
			<cfset arrSW[i] = [#tuuid#, #getSelectedState(tuuid)#, #name#, #IIF(active EQ 0,DE('No'),DE('Yes'))#, #sw_task_type#, #sw_start_datetime#, #sw_end_datetime#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(records.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#records.RecordCount#,rows=#arrSW#}>
		<cfreturn stcReturn>
	</cffunction>

	<cffunction name="getSelectedState" access="private">
		<cfargument name="tid" required="yes">

		<cfset var stcReturn = "0">
		<cftry>
			<cfquery name="qSelSW" datasource="#session.dbsource#" result="res" Maxrows="1">
	                Select selected
					from mp_software_group_tasks
					Where sw_task_id = '#arguments.tid#'
					AND sw_group_id = '#session.mp_sw_gid#'
	        </cfquery>
	        <cfif qSelSW.RecordCount NEQ 0>
				<cfset stcReturn = qSelSW.selected>
			</cfif>
			<cfcatch type="any">
                <cfset strMsgType = "Error">
            </cfcatch>
        </cftry>

		<cfreturn stcReturn>
	</cffunction>

	<cffunction name="setTaskEnabled" access="remote" returnformat="json">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfquery name="selIt" datasource="#session.dbsource#">
			Select * From mp_software_group_tasks
			where sw_task_id = <cfqueryparam value="#Arguments.id#">
			AND sw_group_id = <cfqueryparam value="#session.mp_sw_gid#">
		</cfquery>
		<cfif selIt.RecordCount EQ 0>
			<cfquery name="selIt" datasource="#session.dbsource#">
				Insert Into mp_software_group_tasks (sw_task_id, selected, sw_group_id)
				Values(<cfqueryparam value="#Arguments.id#">, '1', <cfqueryparam value="#session.mp_sw_gid#">)
			</cfquery>
		<cfelse>
			<cfquery name="setIt" datasource="#session.dbsource#">
				Update mp_software_group_tasks
				Set selected = <cfqueryparam value="#IIF(selIt.selected EQ '1', DE('0'),DE('1'))#">
				where sw_task_id = <cfqueryparam value="#Arguments.id#">
				AND sw_group_id = <cfqueryparam value="#session.mp_sw_gid#">
			</cfquery>
		</cfif>
        <cfset _taskDataRes =  PopulateSoftwareGroupData(session.mp_sw_gid) />

		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>
    
    <cffunction name="PopulateSoftwareGroupData" access="public" returnType="any" output="false">
		<cfargument name="SWGroupID">

		<cfset l = logInfo("PopulateSoftwareGroupData","SWGroupID: #SWGroupID#") />

		<!--- Response Struct --->
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = {} />
		<cfset response.result[ "Tasks" ] = "" />
		<cfset tasksArray = ArrayNew(1) />

		<cfquery datasource="#session.dbsource#" name="qGetGroupTasksDataID">
			Select rid From mp_software_tasks_data
			Where gid = '#arguments.SWGroupID#'
		</cfquery>
        
        <cfquery datasource="#session.dbsource#" name="qGetGroupTasks">
			Select sw_task_id From mp_software_group_tasks
			Where sw_group_id = '#arguments.SWGroupID#'
			AND selected = '1'
		</cfquery>

		<cfif qGetGroupTasks.RecordCount GTE 1>
			<cfloop query="qGetGroupTasks">
				<cfset swTaskQuery = getSoftwareTaskFromID(qGetGroupTasks.sw_task_id)>

				<cfif swTaskQuery.RecordCount EQ 0>
					<!--- Log An Error, Maybe --->
					<cfcontinue>
				</cfif>
				<cfif swTaskQuery.active EQ "0">
					<!--- Log An Error, Maybe --->
					<cfcontinue>
				</cfif>

				<cfset task = {} />
				<cfset task[ "name" ] = "#Trim(swTaskQuery.name)#" />
                <cfset task[ "id" ] = "#Trim(swTaskQuery.tuuid)#" />
				<cfset task[ "sw_task_type" ] = "#Trim(swTaskQuery.sw_task_type)#" />
				<cfset task[ "sw_task_privs" ] = "#Trim(swTaskQuery.sw_task_privs)#" />
				<cfset task[ "sw_start_datetime" ] = "#DateFormat(swTaskQuery.sw_start_datetime,'yyyy-mm-dd')# #TimeFormat(swTaskQuery.sw_start_datetime,'HH:mm:ss')#" />
				<cfset task[ "sw_end_datetime" ] = "#DateFormat(swTaskQuery.sw_end_datetime,'yyyy-mm-dd')# #TimeFormat(swTaskQuery.sw_end_datetime,'HH:mm:ss')#" />
				<cfset task[ "active" ] = "#swTaskQuery.active#" />
				<!--- Get Software Info For SUUID --->

				<cfset swDataForSuuid = getSoftwareDistFromSUUID(swTaskQuery.primary_suuid)>
				<cfset task[ "Software" ] = {} />
					<cfset task.software[ "name" ] = "#Trim(swDataForSuuid.sName)#" />
					<cfset task.software[ "vendor" ] = "#Trim(swDataForSuuid.sVendor)#" />
					<cfset task.software[ "vendorUrl" ] = "#Trim(swDataForSuuid.sVendorURL)#" />
					<cfset task.software[ "version" ] = "#Trim(swDataForSuuid.sVersion)#" />
					<cfset task.software[ "description" ] = "#Trim(swDataForSuuid.sDescription)#" />
					<cfset task.software[ "reboot" ] = "#Trim(swDataForSuuid.sReboot)#" />
					<cfset task.software[ "sw_type" ] = "#Trim(swDataForSuuid.sw_type)#" />
					<cfset task.software[ "sw_url" ] = "#Trim(swDataForSuuid.sw_url)#" />
					<cfset task.software[ "sw_hash" ] = "#Trim(swDataForSuuid.sw_hash)#" />
                    <cfset task.software[ "sw_size" ] = "#Trim(swDataForSuuid.sw_size)#" />
					<cfset task.software[ "sw_pre_install" ] = "#ToBase64(Trim(swDataForSuuid.sw_pre_install_script))#" />
					<cfset task.software[ "sw_post_install" ] = "#ToBase64(Trim(swDataForSuuid.sw_post_install_script))#" />
					<cfset task.software[ "sw_uninstall" ] = "#ToBase64(Trim(swDataForSuuid.sw_uninstall_script))#" />
                    <cfset task.software[ "sw_env_var" ] = "#Trim(swDataForSuuid.sw_env_var)#" />
					<cfset task.software[ "auto_patch" ] = "#Trim(swDataForSuuid.auto_patch)#" />
					<cfset task.software[ "patch_bundle_id" ] = "#Trim(swDataForSuuid.patch_bundle_id)#" />
					<cfset task.software[ "state" ] = "#Trim(swDataForSuuid.sState)#" />
                    <cfset task.software[ "sid" ] = "#Trim(swTaskQuery.primary_suuid)#" />
				<cfset task[ "SoftwareCriteria" ] = {} />
					<cfset task.SoftwareCriteria = "#getSoftwareCriteriaFromSUUID(swTaskQuery.primary_suuid)#" />
				<cfset task[ "SoftwareRequisistsPre" ] = {} />
					<!--- <cfset reqs = ArrayNew(1) /> --->
					<cfset _preStruct = RequisistsForID("pre","ID")>
					<cfset task.SoftwareRequisistsPre = _preStruct />
				<cfset task[ "SoftwareRequisistsPost" ] = {} />
					<!--- <cfset reqs = ArrayNew(1) /> --->
					<cfset _postStruct = RequisistsForID("post","ID")>
					<cfset task.SoftwareRequisistsPost = _postStruct />

				<!--- Add Task To Array --->
				<cfset _addTask = Arrayappend(tasksArray,task)>
			</cfloop>
			<!--- Add the Tasks Array to the Struct --->
			<cfset response.result.Tasks = tasksArray>
		</cfif>

		<cfset _jsonData = SerializeJson(response)>
			
        <cfif qGetGroupTasksDataID.RecordCount EQ 0>
        	<cfquery datasource="#session.dbsource#" name="qAddTasksData">
            	Insert Into mp_software_tasks_data (gid, gDataHash, gData)
                Values ('#arguments.SWGroupID#', '#hash(_jsonData,"MD5")#', <cfqueryparam value="#_jsonData#">)
            </cfquery>
		<cfelse>
        	 <cfquery datasource="#session.dbsource#" name="qUpdateTasksData">
             	Update mp_software_tasks_data
                Set gDataHash = '#hash(_jsonData,"MD5")#',
                gData = <cfqueryparam value="#_jsonData#">
             	Where rid = '#qGetGroupTasksDataID.rid#'
            </cfquery>           
        </cfif>
	</cffunction>
    
    <cffunction name="getSoftwareGroupID" access="private" returntype="any" output="no">
		<cfargument name="GroupName">

		<cfquery datasource="#session.dbsource#" name="qGetID">
			Select gid from mp_software_groups
			Where gName = '#arguments.GroupName#'
		</cfquery>

		<cfif qGetID.RecordCount EQ 1>
			<cfreturn #qGetID.gid#>
		<cfelse>
			<cfreturn "0">
		</cfif>
	</cffunction>

	<cffunction name="getSoftwareTaskFromID" access="private" returntype="any" output="no">
		<cfargument name="TaskID">

		<cfquery datasource="#session.dbsource#" name="qGetTask">
			Select name, tuuid, primary_suuid, sw_task_type, sw_task_privs,
				sw_start_datetime, sw_end_datetime, active
			From mp_software_task
			Where tuuid = '#arguments.TaskID#'
		</cfquery>

		<cfif qGetTask.RecordCount EQ 1>
			<cfreturn #qGetTask#>
		<cfelse>
			<cfset myQuery = QueryNew("name, primary_suuid, sw_task_type, sw_task_privs, sw_start_datetime, sw_end_datetime, active")>
			<cfreturn #myQuery#>
		</cfif>
	</cffunction>

	<cffunction name="getSoftwareDistFromSUUID" access="private" returntype="query" output="no">
		<cfargument name="suuid">

		<cfquery datasource="#session.dbsource#" name="qGetTask">
			Select sName,sVendor,sVendorURL,sVersion,sDescription,sReboot,sw_type,sw_url,sw_hash,sw_size,sw_pre_install_script
				,sw_post_install_script,sw_uninstall_script,sw_env_var,auto_patch,patch_bundle_id,sState
			From mp_software
			Where suuid = '#arguments.suuid#'
		</cfquery>

		<cfif qGetTask.RecordCount EQ 1>
			<cfreturn #qGetTask#>
		<cfelse>
			<cfset myQuery = QueryNew("sName,sVendor,sVendorURL,sVersion,sDescription,sReboot,sw_type,sw_url,sw_hash,sw_size,sw_pre_install_script
				,sw_post_install_script,sw_uninstall_script,sw_env_var,auto_patch,patch_bundle_id,sState")>
			<cfreturn #myQuery#>
		</cfif>
	</cffunction>

	<cffunction name="getSoftwareCriteriaFromSUUID" access="private" returntype="struct" output="no">
		<cfargument name="suuid">

		<cfquery datasource="#session.dbsource#" name="qGetCrit">
			Select *
			From mp_software_criteria
			Where suuid = '#arguments.suuid#'
			Order By type_order Asc
		</cfquery>

		<cfset criteria = {} />
		<cfloop query="qGetCrit">
			<cfif qGetCrit.type EQ "OSType">
				<cfset criteria[ "os_type" ] = "#qGetCrit.type_data#" />
			</cfif>
			<cfif qGetCrit.type EQ "OSVersion">
				<cfset criteria[ "os_vers" ] = "#qGetCrit.type_data#" />
			</cfif>
			<cfif qGetCrit.type EQ "OSArch">
				<cfset criteria[ "arch_type" ] = "#qGetCrit.type_data#" />
			</cfif>
		</cfloop>

		<cfreturn criteria>
	</cffunction>

	<cffunction name="RequisistsForID" access="private" returntype="struct" output="no">
		<cfargument name="ReqType">
		<cfargument name="TaskID">

		<cfset criteria = {} />
		<cfreturn criteria>
	</cffunction>
</cfcomponent>