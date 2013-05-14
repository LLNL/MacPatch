<script type="text/javascript">
	$(function() {
		$("#dbSummary").tablesorter({
			widgets: ['zebra']
		});
		$("#dbInfo").tablesorter({
			widgets: ['zebra']
		});
	});
</script>
<h1>MacPatch Database Connection Info:</h1>
<cfscript>
   s_db = StructNew();
</cfscript>
<cfset s_db = #Datasourceinfo("mpds")#>
<cfoutput>
<table class="tablesorter" id="dbSummary">
<thead>
	<tr>
		<th>DB Param</th>
		<th>Value</th>
	</tr>
</thead>
<tbody>
<cfloop collection="#s_db#" item="key">
	<tr>
		<td>#key#</td>
		<td>#s_db[key]#</td>
	</tr>
</cfloop>
	<tr>
		<td>Datasource Is Valid</td>
		<td>#DatasourceIsValid("mpds")#</td>
	</tr>
</tbody>
</table>
</cfoutput>
<cfquery name="gGetDBInfo" datasource="mpds">
	SHOW VARIABLES LIKE "%version%";
</cfquery>
<br />
<h1>MacPatch Database Info:</h1>
<table class="tablesorter" id="dbInfo">
<thead>
	<tr>
		<th>DB Param</th>
		<th>Value</th>
	</tr>
</thead>
<tbody>
<cfoutput query="gGetDBInfo">
	<tr>
		<td>#Variable_name#</td>
		<td>#Value#</td>
	</tr>
</cfoutput>
</tbody>
</table>
