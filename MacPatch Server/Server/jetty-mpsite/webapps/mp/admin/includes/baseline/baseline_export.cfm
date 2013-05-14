<cfif isDefined("URL.baseline_id")>
    <cfsilent>
    <cfquery name="selGroupClients" datasource="#session.dbsource#" result="res">
        select *
        From mp_baseline_patches
        Where baseline_id = '#url.baseline_id#'
        ORDER BY p_postdate DESC
    </cfquery>
    </cfsilent>
    <cfif selGroupClients.RecordCount NEQ 0>
    <cfset csvBlock = Csvwrite( selGroupClients )>
    <!--- Data to Export --->
    <cfheader name="Content-Disposition" value="inline; filename=#URL.baseline_id#.csv"> 
    <cfcontent type="application/csv">
    <cfoutput>#csvBlock#</cfoutput>
    <cfelse>
    	<cflocation url="#CGI.HTTP_REFERER#">
    </cfif>
<cfelse>
<cflocation url="#CGI.HTTP_REFERER#">
</cfif>