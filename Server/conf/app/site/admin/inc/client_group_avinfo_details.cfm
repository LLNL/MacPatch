<cfquery datasource="#session.dbsource#" name="qGet">
    SELECT
        si.cuuid AS cuuid,
        si.defs_date,
        si.app_version,
        si.app_path,
        si.app_version,
        si.app_name,
        si.mdate AS mdate ,
        cci.hostname AS hostname ,
        cci.ipaddr AS ipaddr ,
        cci.osver AS osver ,
        cci.ostype AS ostype
    FROM
        av_info si
        JOIN mp_clients_view cci
        ON si.cuuid = cci.cuuid
    Where
        si.cuuid = '#url.cuuid#'
</cfquery> 

<html> 
<head> 
<title><cfoutput query="qGet">#hostname# AntiVirus Info...</cfoutput></title> 
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"> 

<style type="text/css">
    table.table1 {
        background-color:#000000;
        border-spacing: 1px;
    }

    table.table1 th {
        background-color: #CCCCCC;
        padding: 4px;
        text-align:left;
        font-size:13px;
        font-family: Arial, Helvetica, sans-serif;
        width: 36%;
    }

    table.table1 td {
        background-color: #FFF;
        padding: 4px;
        text-align:left;
        font-size:13px;
        font-family: Arial, Helvetica, sans-serif;
    }
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
        <table class="table1" border="0" cellpadding="0" cellspacing="0" width="100%">
            <tr><th>HostName</th><td>#hostname#</td></tr>
            <tr><th>IP Address</th><td>#ipaddr#</td></tr>
            <tr><th>OS Version</th><td>#osver#</td></tr>
            <tr><th>OS Type</th><td>#ostype#</td></tr>
            <tr><th>AV App Name</th><td>#app_name#</td></tr>
            <tr><th>AV App Path</th><td>#app_path#</td></tr>
            <tr><th>App Version</th><td>#app_version#</td></tr>
            <tr><th>AV Defs Date</th><td>#defs_date#</td></tr>
            <tr><th>Last Updated</th><td>#mdate#</td></tr>
        </table>  
        </cfoutput>
    </cfif>   
</cfif>
</body>
</html>