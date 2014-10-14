<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title></title>
    <link rel="stylesheet" href="/admin/js/tablesorter/themes/blue/style.css" type="text/css"/>
    <link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
    
	<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
	<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
    <script type="text/javascript" src="/admin/js/tablesorter/jquery.tablesorter.js"></script>
    <script type="text/javascript" src="/admin/js/tablesorter/pager/jquery.tablesorter.pager.js"></script>
    
	<script type="text/javascript">
        $(function() {
            $("#dbSummary").tablesorter({
                widgets: ['zebra']
            });
        });
    </script>

<body>    
<h3>MacPatch Database Connection Infos:</h3>
<cfscript>
   s_db = StructNew();
</cfscript>
<cfset s_db = #Datasourceinfo("mpds")#>
<cfoutput>
<table class="tablesorter" id="dbSummary" border="0" cellpadding="0" cellspacing="1" width="100%">
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
</body>
</html>