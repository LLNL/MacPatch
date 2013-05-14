<!--- Logging Info --->
<cflog type="information" file="MP_WSL_files" text="getLLNLSwUpdates.cfm">
    
<cfsetting showDebugOutput="No">
<cfif isDefined("url.os")>
	<cfif url.os EQ "10.4">
		<cfinclude template="getTigerUpdates.cfm">
	<cfelseif url.os EQ "10.3">
		<cfinclude template="getPantherUpdates.cfm">
	</cfif>
</cfif>
<cfif isDefined("url.PatchGroup")>
	<cfquery datasource="ld02" name="qGetUpdates">
		Select Distinct patch
		From patch_groups
		Where name like '#url.PatchGroup#'
	</cfquery>
<cfxml variable="root">
<root>
	<AppleUpdates>
	<cfoutput query="qGetUpdates">
		<cfif #Right(Trim(patch),1)# NEQ "-">
			<update>#Trim(patch)#</update>
		</cfif>
	</cfoutput>
	</AppleUpdates>
</root>
</cfxml>
<cfoutput>#root#</cfoutput>
</cfif>