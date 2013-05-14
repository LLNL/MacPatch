<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">
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
<cfloop index="p" list="#form.addPatch#" delimiters=",">
	<cfquery datasource="#session.dbsource#" name="qPut">
		Insert Into mp_patch_group_patches (patch_id, patch_group_id)
		Values ('#p#', '#uuid#') 
	</cfquery>
</cfloop>

<cflocation url="#CGI.HTTP_ORIGIN#/admin/index.cfm?listpatchgroups">