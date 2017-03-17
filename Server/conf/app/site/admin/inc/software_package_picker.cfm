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
	<title></title>
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
#statusbar-display { display: none !important; }
#urlbar-container, #openLocation { display:none!important; }

div.scroll {
	height: 100%!important;
	width: auto;
	overflow: auto;
}
body {
	margin-bottom: 60px;
}
-->
</style>
<link rel="stylesheet" href="/admin/js/tablesort/css/tablesort.css" type="text/css" />
<script type="text/javascript" src="/admin/js/tablesort/tablesort.js"></script>
<cfquery name="qGet" datasource="#session.dbsource#">
	Select Distinct suuid, sName, sVersion
    From mp_software
    Where sState IN ('1','2')
    Order By sName, sVersion Desc
</cfquery>
<body>
<div class="scroll">
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
</div>
</body>
</html>