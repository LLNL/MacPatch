<!--- First Validate that the User removing the group is the owner --->
<cfquery datasource="#session.dbsource#" name="qGet1">
    Select Distinct user_id
    From mp_patch_group_members
    Where user_id = '#session.username#' AND is_owner = 1
</cfquery>

<cfif qGet1.RecordCount EQ 1>
    <cfquery datasource="#session.dbsource#" name="qRM1">
        Delete
        From mp_patch_group
        Where id = '#form.group_id#'
    </cfquery>
	<cfquery datasource="#session.dbsource#" name="qRM2">
        Delete
        From mp_patch_group_members
        Where patch_group_id = '#form.group_id#'
    </cfquery>
    <cfquery datasource="#session.dbsource#" name="qRM3">
        Delete
        From mp_patch_group_patches
        Where patch_group_id = '#form.group_id#'
    </cfquery>
<cfelse>
	<img src="../_assets/images/Warning-256x256.png" height="32" width="32" />You do not have rights to delete this group. Only the owner can remove it.
    <cfabort>
</cfif>        