<cfif isDefined("URL.clientgroup")>
    <cfsilent>
    	<cftry>
            <cfquery name="selGroupClients" datasource="#session.dbsource#" result="res">
                SELECT DISTINCT cci.*, sav.defsDate
                FROM mp_clients_view cci
                LEFT JOIN savav_info sav 
                ON cci.cuuid = sav.cuuid 
                <cfif URL.clientgroup NEQ "All">
                    Where 
                    cci.Domain = <cfqueryparam value="#URL.clientgroup#">  
                </cfif>      
            </cfquery>
            <cfcatch>
                <cflocation url="#session.cflocFix#/admin/inc/client_group.cfm">
            </cfcatch>
		</cftry>
    </cfsilent>
    
    <cfif selGroupClients.RecordCount NEQ 0>
		<cfset csvBlock = Csvwrite( selGroupClients, true )>
    	
		<!--- Data to Export --->
    	<cfheader name="Content-Disposition" value="inline; filename=#URL.clientgroup#.csv"> 
    	<cfcontent type="application/csv">
    	<cfoutput>#csvBlock#</cfoutput>
    
    <cfelse>
    	<cflocation url="#session.cflocFix#/admin/inc/client_group.cfm">
    </cfif>
<cfelse>
	<cfabort>
	<cflocation url="#session.cflocFix#/admin/inc/client_group.cfm">
</cfif>