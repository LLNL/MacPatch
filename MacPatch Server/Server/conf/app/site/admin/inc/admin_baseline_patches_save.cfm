<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">
<cfset dts = #DateFormat(Now(), "yyyymmdd")# & #TimeFormat(Now(), "HHmmss")#>
<cfset dtsName = #DateFormat(Now(), "mmmm yyyy")#>

<cftry>
<cfquery datasource="#session.dbsource#" name="qBaseline" result="iResult">
    INSERT INTO mp_baseline_patches (baseline_id, p_id, p_name, p_version, p_postdate, p_title, p_reboot, p_type, p_suname, p_active, p_severity, p_patch_state)
    select _latin1 '#dts#' AS `baseline_id`, id as p_id, name as p_name, version as p_version, postdate as p_postdate, title as p_title, reboot as p_reboot, type as p_type, suname as p_suname,
    active as p_active, severity as p_severity, patch_state as p_patch_state
    
    From combined_patches_view
    Where postdate
    Between (now() - interval 548 day) AND now()
    AND 
    suname NOT like '%firm%' 
    AND 
    title NOT like '%firm%' 
    AND
    suname NOT like '%NIL%' 
    AND 
    active = 1
    Order By postdate Desc
</cfquery>
<cfcatch type="Database">
	<!--- Cleanup --->
	<cfquery datasource="#session.dbsource#" name="qBaseline">
    	Delete from mp_baseline_patches
        Where baseline_id = '#dts#'
    </cfquery>
    <h1>Database Error</h1>
    <cfoutput>
    <ul>
        <li><b>Message:</b> #cfcatch.Message#
        <li><b>Native error code:</b> #cfcatch.NativeErrorCode#
        <li><b>SQLState:</b> #cfcatch.SQLState#
        <li><b>Detail:</b> #cfcatch.Detail#
    </ul>
    </cfoutput>
    <cfabort>
</cfcatch>
<cfcatch type="Any">
	<cfoutput>
    <hr>
    <h1>Other Error: #cfcatch.Type#</h1>
    <ul>
        <li><b>Message:</b> #cfcatch.Message#
        <li><b>Detail:</b> #cfcatch.Detail#
    </ul>
    </cfoutput>
    <cfabort>
</cfcatch>
</cftry>
<cftry>
<cfquery datasource="#session.dbsource#" name="qPut">
    Insert Into mp_baseline (baseline_id, name, cdate, mdate, state)
    Values ('#dts#', '#dtsName#', #CreateODBCDateTime(dt)#, #CreateODBCDateTime(dt)#, '0') 
</cfquery>
<cfcatch type="Database">
	<!--- Cleanup --->
	<cfquery datasource="#session.dbsource#" name="qBaseline">
    	Delete from mp_baseline_patches
        Where baseline_id = '#dts#'
    </cfquery>
    <h1>Database Error</h1>
    <cfoutput>
    <ul>
        <li><b>Message:</b> #cfcatch.Message#
        <li><b>Native error code:</b> #cfcatch.NativeErrorCode#
        <li><b>SQLState:</b> #cfcatch.SQLState#
        <li><b>Detail:</b> #cfcatch.Detail#
    </ul>
    </cfoutput>
    <cfabort>
</cfcatch>
<cfcatch type="Any">
	<cfoutput>
    <hr>
    <h1>Other Error: #cfcatch.Type#</h1>
    <ul>
        <li><b>Message:</b> #cfcatch.Message#
        <li><b>Detail:</b> #cfcatch.Detail#
    </ul>
    </cfoutput>
    <cfabort>
</cfcatch>
</cftry>


<cflocation url="#session.cflocFix#/admin/inc/admin_baseline_patches.cfm">
