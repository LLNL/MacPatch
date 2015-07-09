<cfif NOT isDefined("url.id")>
	<cflocation url="#session.cflocFix#/admin/inc/software_packages.cfm">
</cfif>

<!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset cDate = #CreateODBCDateTime(now())#>
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">
<cfset new_suuid=CreateUUID()>

<!--- Create Main Duplicate Record --->
<cftry>
    <cfquery name="qGetSWDist" datasource="#session.dbsource#">
        Select * From mp_software
        Where suuid = '#url.id#'
    </cfquery>
    <cfset new_name = "COPY_"&#qGetSWDist.sName#>
    <cfcatch type="any">
        <cflocation url="#session.cflocFix#/admin/inc/software_packages.cfm">
    </cfcatch>    
</cftry>

<cfquery name="qDupSWDist" datasource="#session.dbsource#">
	INSERT INTO mp_software (
    	suuid, sw_path, sw_url, sw_size, sw_hash, 
        sName, sVersion, sVendor, sDescription, sVendorURL, sState,
        patch_bundle_id, auto_patch, sw_pre_install_script, sw_post_install_script, sw_type, sw_env_var, sReboot,
        sw_uninstall_script
    )
    Values (
        '#new_suuid#', '#qGetSWDist.sw_path#', '#qGetSWDist.sw_url#', '#qGetSWDist.sw_size#', '#qGetSWDist.sw_hash#', 
        '#new_name#', '#qGetSWDist.sVersion#', '#qGetSWDist.sVendor#', '#qGetSWDist.sDescription#', '#qGetSWDist.sVendorURL#', '0',
       '#qGetSWDist.patch_bundle_id#', '#qGetSWDist.auto_patch#', '#qGetSWDist.sw_pre_install_script#', '#qGetSWDist.sw_post_install_script#', '#qGetSWDist.sw_type#', '#qGetSWDist.sw_env_var#', '#qGetSWDist.sReboot#',
        '#qGetSWDist.sw_uninstall_script#'
    )
</cfquery>

<cfquery name="qGetSWCrit" datasource="#session.dbsource#">
	Select * From mp_software_criteria
    Where suuid = '#url.id#'
</cfquery>
<cfif #qGetSWCrit.RecordCount# GTE 1>
	<cfoutput query="qGetSWCrit">
		<cfquery name="qInsertCrit" datasource="#session.dbsource#">
			Insert Into mp_software_criteria (
				suuid, type, type_data, type_order
			)
			Values (
				'#new_suuid#', <cfqueryparam value="#qGetSWCrit.type#"/>, <cfqueryparam value="#qGetSWCrit.type_data#"/>, <cfqueryparam value="#qGetSWCrit.type_order#"/>
			)
		</cfquery>	
	</cfoutput>
</cfif>

<cfquery name="qGetPreSW" datasource="#session.dbsource#">
	Select * From mp_software_requisits
    Where suuid = '#url.id#'
    AND type = '0'
</cfquery>
<cfif #qGetPreSW.RecordCount# GTE 1>
	<cfoutput query="qGetPreSW">
		<cfquery name="qInsertPre" datasource="#session.dbsource#">
			Insert IGNORE Into mp_software_requisits (
				suuid, type, type_txt, type_order, suuid_ref
			)
			Values (
				'#new_suuid#', '0', <cfqueryparam value="#qGetPreSW.type_txt#"/>, <cfqueryparam value="#qGetPreSW.type_order#"/>, <cfqueryparam value="#qGetPreSW.suuid_ref#"/>
			)
		</cfquery>
	</cfoutput>
</cfif>

<cfquery name="qGetPostSW" datasource="#session.dbsource#">
	Select * From mp_software_requisits
    Where suuid = '#url.id#'
    AND type = '1'
</cfquery>
<cfif #qGetPostSW.RecordCount# GTE 1>
	<cfoutput query="qGetPostSW">
		<cfquery name="qInsertPost" datasource="#session.dbsource#">
			Insert IGNORE Into mp_software_requisits (
				suuid, type, type_txt, type_order, suuid_ref
			)
			Values (
				'#new_suuid#', '1', <cfqueryparam value="#qGetPostSW.type_txt#"/>, <cfqueryparam value="#qGetPostSW.type_order#"/>, <cfqueryparam value="#qGetPostSW.suuid_ref#"/>
			)
		</cfquery>
	</cfoutput>
</cfif>

<cflocation url="#session.cflocFix#/admin/inc/software_packages.cfm">
<cfabort>

