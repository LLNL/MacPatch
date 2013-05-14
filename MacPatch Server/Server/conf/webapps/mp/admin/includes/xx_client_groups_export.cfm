<cfif isDefined("URL.clientgroup")>
    <cfsilent>
    <cfquery name="selGroupClients" datasource="#session.dbsource#" result="res">
   		SELECT DISTINCT cci.*, sav.defsDate
		FROM mp_clients_view cci
		LEFT JOIN savav_info sav 
		ON cci.cuuid = sav.cuuid 
		Where 
		cci.Domain = <cfqueryparam value="#URL.clientgroup#">        
	</cfquery>
    </cfsilent>
    <cfif selGroupClients.RecordCount NEQ 0>
    <!--- <cfset csvBlock = ToCSV( selGroupClients, true )> --->
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