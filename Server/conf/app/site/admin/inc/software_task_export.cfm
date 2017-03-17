<cfif isDefined("URL.taskID")>
    <cfsilent>
    	<cfset data = ExportTask(URL.taskID)>
    </cfsilent>
    
	<!--- Data to Export --->
	<cfheader name="Content-Disposition" value="inline; filename=sw_task_#URL.taskID#.json"> 
	<cfcontent type="application/csv">
	<cfoutput>#SerializeJSON(data)#</cfoutput>
<cfelse>
	<cfabort>
</cfif>

<cffunction name="ExportTask" access="private">
    <cfargument name="taskID" required="no" default="1" hint="Task ID">

    <cfset var res = {} />

    <!--- Get Task Info --->
    <cfquery name="qSWTask" datasource="#session.dbsource#">
        select * From mp_software_task
        Where tuuid = <cfqueryparam value="#Arguments.taskID#">
    </cfquery>

    <cfset res['task']['tuuid'] = "#Arguments.taskID#" />
    <cfset res['task']['name'] = "#qSWTask.name#" />
    <cfset res['task']['primary_suuid'] = "#qSWTask.primary_suuid#" />
    <cfset res['task']['active'] = "#qSWTask.active#" />
    <cfset res['task']['sw_task_type'] = "#qSWTask.sw_task_type#" />
    <cfset res['task']['sw_task_privs'] = "#qSWTask.sw_task_privs#" />
    <cfset res['task']['sw_start_datetime'] = "#dateTimeString(qSWTask.sw_start_datetime)#" />
    <cfset res['task']['sw_end_datetime'] = "#dateTimeString(qSWTask.sw_end_datetime)#" />

    <!--- Get Software Info --->
    <cfquery name="qSWData" datasource="#session.dbsource#">
        select * From mp_software
        Where suuid = <cfqueryparam value="#qSWTask.primary_suuid#">
    </cfquery>
    <cfif qSWData.RecordCount EQ 1>
        <cfset res['sw']['suuid'] = "#qSWData.suuid#" />
        <cfset cols = ArrayToList( qSWData.getColumnNames() ) />
        
        <cfloop list="#cols#" index="col">
            <cfoutput>
                <cfset res['sw'][col] = Evaluate("qSWData." & col) />    
            </cfoutput>
        </cfloop>
        
        <cfset rc = structDelete(res['sw'], "rid") />
        <cfset rc = structDelete(res['sw'], "cdate") />
        <cfset rc = structDelete(res['sw'], "mdate") />

        <!--- Get Software Criteria --->
        <cfquery name="qSWCri" datasource="#session.dbsource#">
            select * From mp_software_criteria
            Where suuid = <cfqueryparam value="#qSWTask.primary_suuid#">
        </cfquery>

        <cfset var criArray = ArrayNew(1) /> 
        <cfloop query="qSWCri">
            <cfset x = StructNew() />
            <cfloop list="#ArrayToList(qSWCri.getColumnNames())#" index="col">
                <cfif col NEQ "rid">
                    <cfset x[col] = qSWCri[col][currentrow] />
                </cfif>
            </cfloop>
            <cfset arr = ArrayAppend(criArray,x) />
        </cfloop>
        <cfset res['sw']['criteria'] = criArray />

        <!--- Get Download Info --->
        <cfset res['file']['url'] = getMasterServerDLURL() & res['sw']['sw_url'] />
        <cfset res['file']['name'] = GetFileFromPath(res['sw']['sw_path']) />
    </cfif>
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

<cffunction name="dateTimeString" access="private">
    <cfargument name="dtObj" required="yes">

    <cfset var dtStr = dateformat(arguments.dtObj, "yyyy-mm-dd") & " " & TimeFormat(arguments.dtObj, "HH:mm:ss") />

    <cfreturn dtStr>
</cffunction>
