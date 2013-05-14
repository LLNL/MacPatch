<cfparam name="url.inname" default="0:0">
<cfparam name="pID" default="0">
<cfparam name="pName" default="0">
<cfif IsDefined("url.inname")>
	<cfset pName = ListGetAt(url.inname,1,":")>
</cfif>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Demo</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <SCRIPT LANGUAGE="JavaScript">
		function pick(pgid,pName) {
			if (window.opener && !window.opener.closed) {
				//window.opener.document.stepIt.tester.value = symbol;
				//window.opener.document.getElementById('<cfoutput>#URL.INName#</cfoutput>').value = pgid;
				window.opener.document.getElementById('<cfoutput>#pName#</cfoutput>').value = pgid;
				window.opener.document.getElementById('<cfoutput>#pName#</cfoutput>').value = pName;
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
<cfquery name="qGet" datasource="#session.dbsource#">
	Select Distinct suuid, sName, sVersion
    From mp_software
    Where sState IN ('1','2')
    Order By sName, sVersion Desc
</cfquery>
<body>

	<h1>Software Picker</h1>

    	<table border="1" cellpadding="2">
        	<tr>
            	<td>Name</td>
                <td>Version</td>
                <td>&nbsp;</td>
            </tr>
            <cfoutput query="qGet">
        	<tr>
            	<td>#sName#</td>
                <td>#sVersion#</td>
                <td><A HREF="javascript:pick('#sName#','#suuid#')">Select</A></td>
            </tr>
            </cfoutput>
        </table>
<div class="scroll">	        
</div>
</body>
</html>