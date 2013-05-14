<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Untitled Document</title>
</head>

<body>
<cfset xObj = CreateObject("component","update_patch_group").init()>

<cfquery datasource="#session.dbsource#" name="qSelect">
    Select id From mp_patch_group
</cfquery>

<cfloop query="qSelect">
	<cfoutput>
	<cfset _d = RemovePatchGroupData(id)>
    <cfset _x = xObj.GetPatchGroupPatchesExtended(id)>
    <cfset _a = AddPatchGroupData(id,_x)>
	</cfoutput>
</cfloop> 

<cflocation url="/admin/index.cfm?listpatchgroups">
</body>
</html>

<cffunction name="RemovePatchGroupData" returntype="any" output="no">
	<cfargument name="PatchGroupID">

	<cftry>
	<cfquery datasource="#session.dbsource#" name="qDelete">
		Delete
		From mp_patch_group_data
		Where 
			pid = '#arguments.PatchGroupID#'
	</cfquery>
    <cfcatch></cfcatch>
    </cftry>
</cffunction>

<cffunction name="AddPatchGroupData" returntype="any" output="no">
	<cfargument name="PatchGroupID">
    <cfargument name="PatchGroupData">

	<cftry>
    	<cfset _hash = hash(#arguments.PatchGroupData#, "MD5")>
		<cfquery datasource="#session.dbsource#" name="qPut">
			Insert Into mp_patch_group_data (pid, hash, data)
			Values ('#arguments.PatchGroupID#', '#_hash#', '#arguments.PatchGroupData#') 
		</cfquery>
    <cfcatch></cfcatch>
    </cftry>
</cffunction>