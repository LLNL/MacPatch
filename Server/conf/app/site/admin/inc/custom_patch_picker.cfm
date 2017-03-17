<cfparam name="url.inname" default="0:0">
<cfparam name="pID" default="0">
<cfparam name="pName" default="0">
<cfif IsDefined("url.inname")>
	<cfset pName = ListGetAt(url.inname,1,":")>
	<cfset pID = ListGetAt(url.inname,2,":")>
</cfif>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Demo</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <SCRIPT LANGUAGE="JavaScript">
		function pick(pgid,pName) {
		  if (window.opener && !window.opener.closed)
			window.opener.document.getElementById('<cfoutput>#pName##pID#</cfoutput>').value = pgid;
			window.opener.document.getElementById('<cfoutput>pName#pName#:#pID#</cfoutput>').value = pName;
		  	window.close();
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
<cfquery name="qGet" datasource="#session.dbsource#">
	Select puuid, patch_name, patch_ver
    From mp_patches
    Order By patch_name, patch_ver Desc
</cfquery>
<body>

	<h1>Patch Picker</h1>
<div class="scroll">	
    	<table border="1" cellpadding="2">
        	<tr>
            	<td>Patch Name</td>
                <td>Patch Version</td>
                <td>&nbsp;</td>
            </tr>
            <cfoutput query="qGet">
        	<tr>
            	<td>#patch_name#</td>
                <td>#patch_ver#</td>
                <td><A HREF="javascript:pick('#puuid#','#patch_name# #patch_ver#')">Select</A></td>
            </tr>
            </cfoutput>
        </table>
</div>
</body>
</html>