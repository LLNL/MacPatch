<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">
<cfset xObj = CreateObject("component","update_patch_group").init()>

<!--- Add New Admin to Patch Group Members --->
<cfif form.UpdatePatchGroup EQ "Add">
	<cfquery datasource="#session.dbsource#" name="qAdd">
        Insert Into mp_patch_group_members (user_id, patch_group_id)
        Values ('#form.user_id#', '#form.group_id#') 
    </cfquery>

</cfif>
<cfif form.UpdatePatchGroup EQ "Delete">
	<cfquery datasource="#session.dbsource#" name="qDelete">
		Delete
		From mp_patch_group_members
		Where 
			user_id = '#form.user_id#'
		AND
			patch_group_id = '#form.group_id#'
	</cfquery>
    <cfset _d = RemovePatchGroupData(form.group_id)>
</cfif>

<!--- Change the Patch Group Contents --->
<cfif form.UpdatePatchGroup EQ "Update Group">
	<cfquery datasource="#session.dbsource#" name="qGet">
		Delete
		From mp_patch_group_patches
		Where patch_group_id = '#form.group_id#'
	</cfquery>
    
    <cfquery datasource="#session.dbsource#" name="qUpdate">
		Update
			mp_patch_group
        Set
        	type = '#form.type#'    
		Where id = '#form.group_id#'
	</cfquery>
	
	<cfloop index="patch_id" list="#form.addPatch#" delimiters=",">
		<cfoutput>
		<cfquery datasource="#session.dbsource#" name="qPut">
			Insert Into mp_patch_group_patches (patch_id, patch_group_id)
			Values ('#patch_id#', '#form.group_id#') 
		</cfquery>
		</cfoutput>
	</cfloop>
    
    <cfset _d = RemovePatchGroupData(form.group_id)>
    <!--- JSON 2.2.x --->
    <cfset _x = xObj.GetPatchGroupPatches(form.group_id)>
    <!--- SOAP < 2.1.1 --->
    <cfset _y = xObj.GetPatchGroupPatchesExtended(form.group_id)>
    <cfset _a = AddPatchGroupData(form.group_id,_x,'JSON')>
    <cfset _b = AddPatchGroupData(form.group_id,_y,'SOAP')>
</cfif>

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
    <cfargument name="PatchGroupDataType">

	<cftry>
    	<cfset _hash = hash(#arguments.PatchGroupData#, "MD5")>
		<cfquery datasource="#session.dbsource#" name="qPut">
			Insert Into mp_patch_group_data (pid, hash, data, data_type)
			Values ('#arguments.PatchGroupID#', '#_hash#', '#arguments.PatchGroupData#', '#arguments.PatchGroupDataType#') 
		</cfquery>
    <cfcatch></cfcatch>
    </cftry>
</cffunction>

