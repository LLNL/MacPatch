<cfparam name="url.inname" default="0:0">
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Demo</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <SCRIPT LANGUAGE="JavaScript">
		function pick(pgid,pName) {
			if (window.opener && !window.opener.closed) {
				window.opener.document.getElementById('patch_bundle_id').value = pgid;
		  		window.close();
		  	}
		}
	</SCRIPT>
</head>
<style type="text/css">
<!--
div.scroll {
	height: 500px;
	width: 360px;
	overflow: auto;
}
-->
</style>
<link rel="stylesheet" href="/admin/js/tablesort/css/tablesort.css" type="text/css" />
<script type="text/javascript" src="/admin/js/tablesort/tablesort.js"></script>
<cfquery name="qGet" datasource="#session.dbsource#">
	Select Distinct patch_name, bundle_id
    From mp_patches
    Where active = '1'
</cfquery>
<body>
<table id="swTable" width="90%" cellpadding="0" cellspacing="0" border="0" class="sortable-onload rowstyle-alt colstyle-alt no-arrow">
	<thead>
 	<tr>
		<th class="sortable">Name</th>
		<th class="sortable">Bundle ID</th>
		<th>&nbsp;</th>
	</tr>
	</thead>
	<tbody>
	<cfoutput query="qGet">
	<cfif (currentRow MOD 2 EQ 0)><tr class="alt"><cfelse><tr></cfif>
		<td>#patch_name#</td>
		<td>#bundle_id#</td>
		<td><A HREF="javascript:pick('#bundle_id#','#patch_name#')">Select</A></td>
	</tr>
	</cfoutput>
	</tbody>
</table>
<div class="scroll">
</div>
</body>
</html>