<cfsetting showDebugOutput="No">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Detailed Info</title>

<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

<!-- Latest compiled and minified JavaScript -->
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>

</head>
<body>

<cfset arrTasks = ArrayNew(1)>
<cfquery name="qSWPkg" datasource="#session.dbsource#" result="res">
    select * From mp_software Where suuid = '#url.id#'
</cfquery>

<cfif qSWPkg.recordcount EQ 1>
    <cfquery name="qSWTasks" datasource="#session.dbsource#" result="res">
        select tuuid, name From mp_software_task Where primary_suuid = '#url.id#'
    </cfquery>

    <cfoutput query="qSWTasks">
        <cfset row = StructNew()>
        <cfset row['tuuid'] = #tuuid#>
        <cfset row['name'] = #name#>
        <cfset row['groups'] = GroupsForTask(tuuid)>
        <cfset arrayAppend(arrTasks, row)>
    </cfoutput>

    <cfset groups = GroupsForTask(qSWTasks.tuuid)>
</cfif>
<div class="container">
<div class="row">
    <div class="col-lg-6">
    <div class="panel panel-default">
        <div class="panel-heading"><h3>Software Package Assignments</h3></div>
        <div class="panel-body">
            <cfoutput>
                <h3>
                    #qSWPkg.sName#<br>
                    <small class="text-muted">#qSWPkg.suuid#</small>
                </h3>
                <h3>Tasks</h3> 

                <ul class="list-group">
                <cfloop array="#arrTasks#" index="task">
                    <li class="list-group-item">
                        <h4>
                            Task: #task['name']#<br>
                            <small class="text-muted">#task['tuuid']#</small>
                        </h4>
                        <h5>Assigned to Groups</h5>
                        <ul>
                        <cfloop list="#task['groups']#" index="group">
                            <cfset gData = GroupsInfoFromID(group)>
                            <li>#gData.gName#</li>
                        </cfloop>
                        </ul>
                    </li>
                </cfloop>
                </ul>
            </cfoutput>
        </div>
        </div>
    </div>
    </div>
</div>
</div>
</body>
</html>


<cffunction name="GroupsForTask" access="private" returntype="any">       
    <cfargument name="taskID" required="yes" hint="id to delete">

    <cfquery name="qSWGroupTasks" datasource="#session.dbsource#" result="res">
        select sw_group_id From mp_software_group_tasks
        Where sw_task_id = '#arguments.taskID#'
    </cfquery>

    <cfset myList = ValueList(qSWGroupTasks.sw_group_id)>

    <cfreturn myList>
</cffunction>

<cffunction name="GroupsInfoFromID" access="private" returntype="any">       
    <cfargument name="groupid" required="yes" hint="id to delete">

    <cfquery name="qSWGroupTasks" datasource="#session.dbsource#" result="res">
        select * From mp_software_groups
        Where gid = '#arguments.groupid#'
    </cfquery>

    <cfreturn qSWGroupTasks>
</cffunction>