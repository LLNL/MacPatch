<cfquery datasource="#session.dbsource#" name="qGet">
    SELECT	*
    FROM	savav_client_info
    Where cuuid = '#url.cuuid#'
</cfquery> 

<html> 
<head> 
<title><cfoutput query="qGet">#hostname# AntiVirus Info...</cfoutput></title> 
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"> 

<style type="text/css">
<!--
table {
	background-color:#000000;
	border-spacing: 1px;
}

th {
	background-color: #CCCCCC;
	padding: 4px;
	text-align:left;
	font-size:13px;
	font-family: Arial, Helvetica, sans-serif;
	width: 36%;
}

td {
	background-color: #FFF;
	padding: 4px;
	text-align:left;
	font-size:13px;
	font-family: Arial, Helvetica, sans-serif;
}

-->
</style>
</head>

<body>
<cfif IsDefined("url.cuuid")>
    <h3>Client AntiVirus Information</h3>
    <cfif qGet.RecordCount EQ 0>
    <hr>
    <h4>No Client AntiVirus data available.</h4>
    <cfelse>
		<cfoutput query="qGet">
        <table border="0" cellpadding="0" cellspacing="0" width="100%"> 
            <tr><th>HostName</th><td>#hostname#</td></tr>
            <tr><th>IP Address</th><td>#ipaddr#</td></tr>
            <tr><th>OS Version</th><td>#osver#</td></tr>
            <tr><th>OS Type</th><td>#ostype#</td></tr>
            <tr><th>AV App Name</th><td>#savAppName#</td></tr>
            <tr><th>AV App Path</th><td>#appPath#</td></tr>
            <tr><th>App Version</th><td>#savShortVersion#</td></tr>
            <tr><th>App Build Version</th><td>#savBundleVersion#</td></tr>
            <tr><th>AV Defs Date</th><td>#defsDate#</td></tr>
            <tr><th>Last Updated</th><td>#mdate#</td></tr>
        </table>  
        </cfoutput>
    </cfif>   
</cfif>
</body>
</html>