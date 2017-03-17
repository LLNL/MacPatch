<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "software_tasks" />

	<cffunction name="getMPSoftwareTasks" access="remote" returnformat="json">
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
                select *
                From mp_software_task
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
			<cfset r = logInfo("getMPSoftwareTasks","Task: #name#")>
			<cfset arrSW[i] = [#rid#, #tuuid#, #name#, #primary_suuid#, #iif(active IS 1,DE("Yes"),DE("No"))#, #Ucase(sw_task_type)#, #DateTimeFormat( sw_start_datetime, "yyyy-MM-dd HH:mm:ss" )#, #DateTimeFormat( sw_end_datetime, "yyyy-MM-dd HH:mm:ss" )#, #DateTimeFormat( mdate, "yyyy-MM-dd HH:mm:ss" )#] >
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qSelSW.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qSelSW.recordcount#,rows=#arrSW#}>

		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="addEditMPSoftwareTask" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfif oper EQ "edit">
			<cftry>
				<cfquery name="editRecord" datasource="#session.dbsource#" result="res">
					UPDATE mp_software_task
					SET	 name = <cfqueryparam value="#Arguments.name#">,
	 					 active = <cfqueryparam value="#Arguments.active#">
					WHERE rid = <cfqueryparam value="#arguments.id#">
				</cfquery>
                <cfcatch type="any">			
					<cfset strMsgType = "Error">
					<cfset strMsg = "There was an issue with the Edit. An Error Report has been submitted to Support.">					
				</cfcatch>		
			</cftry>
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add.">
        <cfelseif oper EQ "del">
            <cfset strReturn = delMPSoftwareTask(Arguments.id)>
            <cfreturn strReturn>
		</cfif>

		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>

    <cffunction name="delMPSoftwareTask" access="private" hint="Delete Selected MP Software Task" returntype="struct">
		<cfargument name="id" required="yes" hint="id to delete">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
        <cfset var userdata = "">

		<cftry>
			<cfset strMsg = "Delete Software Task">
			<cfquery name="delTask" datasource="#session.dbsource#">
				DELETE FROM mp_software_task WHERE rid = <cfqueryparam value="#Arguments.id#">
			</cfquery>
		<cfcatch>
			<!--- Error, return message --->
			<cfset strMsgType = "Error">
			<cfset strMsg = "Error occured when Deleting MP patch. An error report has been submitted to support.">
		</cfcatch>
		</cftry>

		<cfset userdata  = {type='#strMsgType#', msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>

    <cffunction name="buildSearch" access="private" hint="Build our Search Parameters">
		<cfargument name="stcSearch" required="true">
		
		<!--- strOp will be either AND or OR based on user selection --->
		<cfset var strGrpOp = stcSearch.groupOp>
		<cfset var arrFilter = stcSearch.rules>
		<cfset var strSearch = "">
		<cfset var strSearchVal = "">
		
		<!--- Loop over array of passed in search filter rules to build our query string --->
		<cfloop array="#arrFilter#" index="arrIndex">
			<cfset strField = arrIndex["field"]>
			<cfset strOp = arrIndex["op"]>
			<cfset strValue = arrIndex["data"]>
			
			<cfset strSearchVal = buildSearchArgument(strField,strOp,strValue)>
			
			<cfif strSearchVal NEQ "">
				<cfif strSearch EQ "">
					<cfset strSearch = "HAVING (#PreserveSingleQuotes(strSearchVal)#)">
				<cfelse>
					<cfset strSearch = strSearch & "#strGrpOp# (#PreserveSingleQuotes(strSearchVal)#)">				
				</cfif>
			</cfif>
			
		</cfloop>
		
		<cfreturn strSearch>
	</cffunction>
	
    <cffunction name="buildSearchArgument" access="private" hint="Build our Search Argument based on parameters">
		<cfargument name="strField" required="true" hint="The Field which will be searched on">
		<cfargument name="strOp" required="true" hint="Operator for the search criteria">
		<cfargument name="strValue" required="true" hint="Value that will be searched for">
		
		<cfset var searchVal = "">
		
		<cfif Arguments.strValue EQ "">
			<cfreturn "">
		</cfif>
		
		<cfscript>
			switch(Arguments.strOp)
			{
				case "eq":
					//ID is numeric so we will check for that
					if(Arguments.strField EQ "id")
					{
						searchVal = "#Arguments.strField# = #Arguments.strValue#";
					}else{
						searchVal = "#Arguments.strField# = '#Arguments.strValue#'";
					}
					break;				
				case "lt":
					searchVal = "#Arguments.strField# < #Arguments.strValue#";
					break;
				case "le":
					searchVal = "#Arguments.strField# <= #Arguments.strValue#";
					break;
				case "gt":
					searchVal = "#Arguments.strField# > #Arguments.strValue#";
					break;
				case "ge":
					searchVal = "#Arguments.strField# >= #Arguments.strValue#";
					break;
				case "bw":
					searchVal = "#Arguments.strField# LIKE '#Arguments.strValue#%'";
					break;
				case "ew":					
					searchVal = "#Arguments.strField# LIKE '%#Arguments.strValue#'";
					break;
				case "cn":
					searchVal = "#Arguments.strField# LIKE '%#Arguments.strValue#%'";
					break;
			}			
		</cfscript>
		<cfreturn searchVal>
	</cffunction>

	<cffunction name="ExportTask" access="remote" returnformat="json">
		<cfargument name="taskID" required="no" default="1" hint="Task ID">

		<cfset var res = {} />

		<!--- Get Task Info --->
		<cfquery name="qSWTask" datasource="#session.dbsource#">
            select * From mp_software_task
            Where tuuid = <cfqueryparam value="#Arguments.taskID#">
        </cfquery>

        <cfset res['task']['tuuid'] = "#Arguments.taskID#" />
        <cfset res['task']['primary_suuid'] = "#qSWTask.primary_suuid#" />
        <cfset res['task']['active'] = "#qSWTask.active#" />
        <cfset res['task']['sw_task_type'] = "#qSWTask.sw_task_type#" />
        <cfset res['task']['sw_task_privs'] = "#qSWTask.sw_task_privs#" />
        <cfset res['task']['sw_task_privs'] = "#qSWTask.sw_task_privs#" />
        <cfset res['task']['sw_start_datetime'] = "#qSWTask.sw_start_datetime#" />
        <cfset res['task']['sw_end_datetime'] = "#qSWTask.sw_end_datetime#" />
        <cfset res['task']['mdate'] = "#qSWTask.mdate#" />
        <cfset res['task']['cdate'] = "#qSWTask.cdate#" />

        <!--- Get Software Info --->
        <cfquery name="qSWData" datasource="#session.dbsource#">
            select * From mp_software
            Where suuid = <cfqueryparam value="#qSWTask.primary_suuid#">
        </cfquery>

        <cfset res['sw']['suuid'] = "#qSWData.suuid#" />
        <cfset cols = ArrayToList( qSWData.getColumnNames() ) />
        
        <cfloop list="#cols#" index="col">
        	<cfoutput>
        		<cfset res['sw'][col] = Evaluate("qSWData." & col) />
        	</cfoutput>
        </cfloop>

        <!--- Get Software Criteria --->
        <cfquery name="qSWCri" datasource="#session.dbsource#">
            select * From mp_software_criteria
            Where suuid = <cfqueryparam value="#qSWTask.primary_suuid#">
        </cfquery>

        <cfset var criArray = ArrayNew(1) /> 
        <cfloop query="qSWCri">
        	<cfset x = StructNew() />
            <cfloop list="#ArrayToList(qSWCri.getColumnNames())#" index="col">
            	<cfset x[col] = qSWCri[col][currentrow] />
            </cfloop>
            <cfset arr = ArrayAppend(criArray,x) />
	    </cfloop>
	    <cfset res['sw']['criteria'] = criArray />

		<!--- Get Download Info --->
        <cfset res['file']['url'] = getMasterServerDLURL() & res['sw']['sw_url'] />
        <cfset res['file']['name'] = GetFileFromPath(res['sw']['sw_path']) />
		
		<cfset stcReturn = {taskID=#arguments.taskID#, result=#res#}>
		<cfreturn res>
	</cffunction>

	<cffunction name="getMasterServerDLURL" access="private">

		<cfquery name="qGet" datasource="#session.dbsource#">
            select * From mp_servers
            Where isMaster = 1
        </cfquery>
        <cfif qGet.useSSL EQ 1>
        	<cfset prefix = "https://" />
        <cfelse>
        	<cfset prefix = "http://" />
        </cfif>
        <cfset xURL = prefix & qGet.server & ":" & qGet.port & "/mp-content" />

		<cfreturn xURL>
	</cffunction>	
</cfcomponent>