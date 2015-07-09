<cfif NOT isDefined("url.id")>
	<cflocation url="#session.cflocFix#/admin/inc/available_patches_mp.cfm">
</cfif>

<!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset cDate = #CreateODBCDateTime(now())#>
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">
<cfset new_puuid=CreateUUID()>

<!--- Create Main Duplicate Record --->
<cfquery name="qGetPatch" datasource="#session.dbsource#">
	Select * From mp_patches
    Where puuid = '#url.id#'
</cfquery>
<cfset nid = "COPY_"&#qGetPatch.patch_name#>
<cfquery name="qDupPatch" datasource="#session.dbsource#">
	INSERT INTO mp_patches (
		puuid, bundle_id, patch_name, patch_ver, patch_vendor, description,
        description_url, patch_severity, patch_state, cve_id, cdate, mdate, active,
        pkg_name, pkg_hash, pkg_path, pkg_url, patch_reboot, pkg_preinstall, pkg_postinstall,
		pkg_size, pkg_env_var, patch_install_weight
    )
    Values (
        '#new_puuid#', '#qGetPatch.bundle_id#', '#nid#', '#qGetPatch.patch_ver#', '#qGetPatch.patch_vendor#', '#qGetPatch.description#',
        '#qGetPatch.description_url#', '#qGetPatch.patch_severity#', 'Create', '#qGetPatch.cve_id#',
        #cDate#, #cDate#, '0', '#qGetPatch.pkg_name#', '#qGetPatch.pkg_hash#', 
        '#qGetPatch.pkg_path#', '#qGetPatch.pkg_url#', '#qGetPatch.patch_reboot#', '#qGetPatch.pkg_preinstall#',
		'#qGetPatch.pkg_postinstall#', '#qGetPatch.pkg_size#', '#qGetPatch.pkg_env_var#', '#qGetPatch.patch_install_weight#'
    )
</cfquery>

<cfquery name="qGetPatchCrit" datasource="#session.dbsource#">
	Select * From mp_patches_criteria
    Where puuid = '#url.id#'
</cfquery>
<cfif #qGetPatchCrit.RecordCount# GTE 1>
	<cfoutput query="qGetPatchCrit">
		<cfquery name="qInsertCrit" datasource="#session.dbsource#">
			Insert Into mp_patches_criteria (
				puuid, type, type_data, type_order
			)
			Values (
				'#new_puuid#', <cfqueryparam value="#qGetPatchCrit.type#"/>, <cfqueryparam value="#qGetPatchCrit.type_data#"/>, <cfqueryparam value="#qGetPatchCrit.type_order#"/>
			)
		</cfquery>	
	</cfoutput>
</cfif>

<cfquery name="qGetPrePatch" datasource="#session.dbsource#">
	Select * From mp_patches_requisits
    Where puuid = '#url.id#'
    AND type = '0'
</cfquery>
<cfif #qGetPrePatch.RecordCount# GTE 1>
	<cfoutput query="qGetPrePatch">
		<cfquery name="qInsertPre" datasource="#session.dbsource#">
			Insert IGNORE Into mp_patches_requisits (
				puuid, type, type_txt, type_order, puuid_ref
			)
			Values (
				'#new_puuid#', '0', <cfqueryparam value="#qGetPrePatch.type_txt#"/>, <cfqueryparam value="#qGetPrePatch.type_order#"/>, <cfqueryparam value="#qGetPrePatch.puuid_ref#"/>
			)
		</cfquery>
	</cfoutput>
</cfif>

<cfquery name="qGetPostPatch" datasource="#session.dbsource#">
	Select * From mp_patches_requisits
    Where puuid = '#url.id#'
    AND type = '1'
</cfquery>
<cfif #qGetPostPatch.RecordCount# GTE 1>
	<cfoutput query="qGetPostPatch">
		<cfquery name="qInsertPost" datasource="#session.dbsource#">
			Insert IGNORE Into mp_patches_requisits (
				puuid, type, type_txt, type_order, puuid_ref
			)
			Values (
				'#new_puuid#', '1', <cfqueryparam value="#qGetPostPatch.type_txt#"/>, <cfqueryparam value="#qGetPostPatch.type_order#"/>, <cfqueryparam value="#qGetPostPatch.puuid_ref#"/>
			)
		</cfquery>
	</cfoutput>
</cfif>

<cflocation url="#session.cflocFix#/admin/inc/available_patches_mp.cfm">
<cfabort>

