<cfparam name="url.inname" default="0:0">
<cfparam name="suuid" default="0">
<cfparam name="sName" default="0">
<cfif IsDefined("url.inname")>
	<cfset suuid = ListGetAt(url.inname,1,":")>
	<cfset sName = ListGetAt(url.inname,2,":")>
</cfif>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Demo</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <SCRIPT LANGUAGE="JavaScript">
		function pick(pgid,pName) {
			if (window.opener && !window.opener.closed) {
				window.opener.document.getElementById('<cfoutput>#suuid#</cfoutput>').value = pgid;
				window.opener.document.getElementById('<cfoutput>#sName#</cfoutput>').value = pName;
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
<cfquery name="qGet" datasource="#session.dbsource#">
	Select Distinct suuid, sName, sVersion
    From mp_software
    Where sState IN ('1','2')
    Order By sName, sVersion Desc
</cfquery>
<body>
<h1>Software Picker</h1>
<table id="swTable" width="400px" cellpadding="0" cellspacing="0" border="0" class="sortable-onload rowstyle-alt colstyle-alt no-arrow">
	<thead>
 	<tr>
		<th class="sortable">Name</th>
		<th class="sortable">Version</th>
		<th>&nbsp;</th>
	</tr>
	</thead>
	<tbody>
	<cfoutput query="qGet">
	<cfif (currentRow MOD 2 EQ 0)><tr class="alt"><cfelse><tr></cfif>
		<td>#sName#</td>
		<td>#sVersion#</td>
		<td><A HREF="javascript:pick('#suuid#','#sName# v.#sVersion#')">Select</A></td>
	</tr>
	</cfoutput>
	</tbody>
</table>
<div class="scroll">
</div>
</body>
</html>