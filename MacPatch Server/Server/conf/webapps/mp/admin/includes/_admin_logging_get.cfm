<cfinclude template="#session.appBaseInc#/_js_includes.cfm">

<script type="text/javascript">	
	$(document).ready(function() { 
		$("#genit").tablesorter( {widgets: ['zebra']} ); 
	});	
</script>

<cfquery datasource="#session.dbsource#" name="qGetLogEvents">
    select Distinct event, event_type, date 
    from ws_log
    Where event_type like '#URL.type#'
    Order By Date Desc
</cfquery> 

<cfif qGetLogEvents.recordcount>
<table id="genit" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
    <thead>
    <tr>
        <th>Date</th>
        <th>Type</th>
        <th>Event</th>
    </tr>
    </thead>
    <tbody>
    <cfoutput query="qGetLogEvents">
    <tr>
        <td width="140">#date#</td>
        <td>#event_type#</td>
        <td>#event#</td>
    </tr>		
    </cfoutput>
    </tbody>
</table> 
</cfif>