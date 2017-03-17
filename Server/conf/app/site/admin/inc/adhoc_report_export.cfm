<cfif isDefined("session.RptExportQuery")>
    <cfif session.RptExportQuery.RecordCount NEQ 0>
	<cfset csvBlock = Csvwrite( session.RptExportQuery, true )>
    <!--- Data to Export --->
    <cfheader name="Content-Disposition" value="inline; filename=ADHOC_REPORT.csv"> 
    <cfcontent type="application/csv">
    <cfoutput>#csvBlock#</cfoutput>
    <cfelse>
    	<cflocation url="#CGI.HTTP_REFERER#">
    </cfif>
<cfelse>
<cflocation url="#CGI.HTTP_REFERER#">
</cfif>