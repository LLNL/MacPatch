<!--- This File IS for displaying client with invalid patch groups --->
<script type="text/javascript">	
		$(function() {
			$("#listClients").tablesorter({
				widgets: ['zebra']
			});
		});	
</script>
<cfinvoke component="patch_group_data" method="showClientsForPatchGroup" returnvariable="invList">
	<cfinvokeargument name="aGroup" value="#url.group#">
</cfinvoke>
<table id="listClients" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
    <thead>
    <tr>
    	<th>HostName</th>
        <th>IP Address</th>
        <th>Client Group</th>
        <th>Last Checkin</th>
    </tr>
    </thead>
    <tbody>
    	<cfoutput query="invList">
    		<tr>
    			<td>#hostname#</td>
    			<td>#ipaddr#</td>
                <td>#domain#</td>
    			<td>#mdate#</td> 
    		</tr>	
    	</cfoutput>
    </tbody>
</table>