<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">
<cfset xObj = CreateObject("component","update_patch_group").init()>
<cfset uuid = #CreateUUID()#>

<!--- Create the New PatchGroup Entry --->
<cfquery datasource="#session.dbsource#" name="qCreateGroup">
	Insert Into mp_patch_group (name, id, type)
	Values ('#form.groupname#', '#uuid#', '#form.type#') 
</cfquery>
<!--- Create the Owner Record for the Patch Group --->
<cfquery datasource="#session.dbsource#" name="qCreateGroupMember">
	Insert Into mp_patch_group_members (user_id, patch_group_id, is_owner)
	Values ('#session.username#', '#uuid#', 1) 
</cfquery>
<!--- Add the Patches --->
<cfif IsDefined('form.addPatch')>
    <cfloop index="p" list="#form.addPatch#" delimiters=",">
        <cfquery datasource="#session.dbsource#" name="qPut">
            Insert Into mp_patch_group_patches (patch_id, patch_group_id)
            Values ('#p#', '#uuid#') 
        </cfquery>
    </cfloop>
    <!--- Create the JSON Data --->
    <cfset _x = xObj.GetPatchGroupPatches(uuid)>
    <cfset _a = AddPatchGroupData(uuid,_x)>
</cfif>
<cflocation url="#session.cflocFix#/admin/index.cfm?listpatchgroups">

<cffunction name="AddPatchGroupData" returntype="any" output="no">
	<cfargument name="PatchGroupID">
    <cfargument name="PatchGroupData">

	<cftry>
    	<cfset _hash = hash(#arguments.PatchGroupData#, "MD5")>
		<cfquery datasource="#session.dbsource#" name="qPut">
			Insert Into mp_patch_group_data (pid, hash, data, data_type)
			Values ('#arguments.PatchGroupID#', '#_hash#', '#arguments.PatchGroupData#', 'JSON') 
		</cfquery>
    <cfcatch></cfcatch>
    </cftry>
</cffunction>