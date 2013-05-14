<cfif isDefined("session.DashboardExportQuery")>
    <cfif session.DashboardExportQuery.RecordCount NEQ 0>
	<cfset csvBlock = Csvwrite( session.DashboardExportQuery, true )>
    <!--- Data to Export --->
    <cfheader name="Content-Disposition" value="inline; filename=Dashboard.csv"> 
    <cfcontent type="application/csv">
    <cfoutput>#csvBlock#</cfoutput>
    <cfelse>
    	<cflocation url="#CGI.HTTP_REFERER#">
    </cfif>
<cfelse>
<cflocation url="#CGI.HTTP_REFERER#">
</cfif>