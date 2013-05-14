<cfif isDefined("session.clientPatchStateExportQuery")>
    <cfif session.clientPatchStateExportQuery.RecordCount NEQ 0>
	<cfset csvBlock = Csvwrite( session.clientPatchStateExportQuery, true )>
    <!--- Data to Export --->
    <cfheader name="Content-Disposition" value="inline; filename=client_patch_state.csv"> 
    <cfcontent type="application/csv">
    <cfoutput>#csvBlock#</cfoutput>
    <cfelse>
    	<cflocation url="#CGI.HTTP_REFERER#">
    </cfif>
<cfelse>
<cflocation url="#CGI.HTTP_REFERER#">
</cfif>