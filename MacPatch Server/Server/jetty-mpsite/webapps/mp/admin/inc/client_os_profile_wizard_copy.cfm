<cfif NOT isDefined("url.profileID")>
	<cflocation url="#session.cflocFix#/admin/inc/client_os_profiles.cfm">
</cfif>

<!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset new_profileID=CreateUUID()>

<!--- Create Main Duplicate Record --->
<cfquery name="qGetProfile" datasource="#session.dbsource#">
	Select * From mp_os_config_profiles
    Where profileID = '#url.profileID#'
</cfquery>
<cfset nid = "COPY_"&#qGetProfile.profileName#>
<cftry>
<cfquery name="qDupPatch" datasource="#session.dbsource#">
	INSERT INTO mp_os_config_profiles (
		profileID, profileIdentifier, profileName, profileDescription, profileRev, profileData, uninstallOnRemove, enabled, profileHash
    )
    Values (
        '#new_profileID#', '#qGetProfile.profileIdentifier#', '#nid#', '#qGetProfile.profileDescription#', 1, <cfqueryparam value="#qGetProfile.profileData#" cfsqltype="cf_sql_blob">, '#qGetProfile.uninstallOnRemove#', 0,
        '#qGetProfile.profileHash#'
    )
</cfquery>
<cfcatch>
	<cfoutput>#cfcatch.Message#<br />#cfcatch.Detail#</cfoutput>
    <cfabort>
</cfcatch>
</cftry>
<cflocation url="#session.cflocFix#/admin/inc/client_os_profiles.cfm">
<cfabort>

