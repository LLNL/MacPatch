<cfif isDefined("URL.clientgroup")>
    <cfsilent>
    <cfquery name="selGroupClients" datasource="#session.dbsource#" result="res">
   		SELECT DISTINCT cci.*, av.defs_date
		FROM mp_clients_view cci
		LEFT JOIN av_info av 
		ON cci.cuuid = av.cuuid 
		Where 
		cci.Domain = <cfqueryparam value="#URL.clientgroup#">        
	</cfquery>
    </cfsilent>
    <cfif selGroupClients.RecordCount NEQ 0>
	<cfset csvBlock = Csvwrite( selGroupClients, true )>
    <!--- Data to Export --->
    <cfheader name="Content-Disposition" value="inline; filename=#URL.clientgroup#.csv"> 
    <cfcontent type="application/csv">
    <cfoutput>#csvBlock#</cfoutput>
    <cfelse>
    	<cflocation url="#CGI.HTTP_REFERER#">
    </cfif>
<cfelse>
<cflocation url="#CGI.HTTP_REFERER#">
</cfif>