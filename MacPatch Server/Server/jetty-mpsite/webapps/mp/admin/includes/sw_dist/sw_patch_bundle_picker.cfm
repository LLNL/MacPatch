<cfparam name="url.inname" default="0:0">
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Patch BundleID Picker</title>
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
<link rel="stylesheet" href="/admin/_assets/css/main/tablesort.css" type="text/css" />
<script type="text/javascript" src="/admin/_assets/js/other/tablesort.js"></script>
<cfsilent>
	<cfquery name="qGet" datasource="#session.dbsource#">
		Select patch_name, bundle_id
	    From mp_patches
	    Where active = '1'
		Order by bundle_id, rid ASC
	</cfquery>
	
	<cfset temp = structNew()>
	<cfoutput query="qGet">
		<cfset temp[bundle_id] = patch_name>
	</cfoutput>
	<cfset distinctList = structKeyList(temp)>
	<cfset currow = 0>
</cfsilent>
<body>
<h2>Patch Bunlde Picker</h2>
<table id="swTable" width="90%" cellpadding="0" cellspacing="0" border="0" class="sortable-onload rowstyle-alt colstyle-alt no-arrow">
	<thead>
 	<tr>
		<th class="sortable">Name</th>
		<th class="sortable">Bundle ID</th>
		<th>&nbsp;</th>
	</tr>
	</thead>
	<tbody>
	<cfloop collection="#temp#" item="p">
	    <cfoutput>
		<cfif (currow MOD 2 EQ 0)><tr class="alt"><cfelse><tr></cfif>
	        <td>#StructFind(temp, p)#</td>
	        <td>#p#</td>
	        <td><A HREF="javascript:pick('#StructFind(temp, p)#','#p#')">Select</A></td>
		</tr>
		<cfset currow++>
		</cfoutput>
	</cfloop>
	</tbody>
</table>
<div class="scroll">
</div>
</body>
</html>