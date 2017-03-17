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
            $("#ldapSummary").tablesorter({});
            $("#ldapConfig").tablesorter({
                widgets: ['zebra']
            });
        });
    </script>

<body>    
<h3>MacPatch Datasources</h3>
<cfscript>
   s_db = StructNew();
</cfscript>
<cfset s_db = #Datasourceinfo("mpds")#>
<h5>Database</h5>
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

<cfif StructKeyExists(application.settings, 'ldap_filters')>
    <h5>LDAP Sources</h5>
    <cfif IsArray(application.settings.ldap_filters)>
        <cfif len(application.settings.ldap_filters) GTE 1>

            <cfset aArray = application.settings.ldap_filters>
            
            <cfoutput>
                <table class="tablesorter" id="ldapSummary" border="0" cellpadding="0" cellspacing="1" width="100%">
                    <thead>
                        <tr>
                            <th>Datasource</th>
                            <th>Properties</th>
                        </tr>
                    </thead>
                    <tbody>
                    <cfloop from="1" to="#arrayLen(aArray)#" index="i">
                        <cfif arrayIndexExists(aArray, i)>
                            <tr>
                                <td>#aArray[i]['config_name']#</td>
                                <td>
                                    <cfset _collection = #aArray[i]['config_ldap']# >
                                    <table class="tablesorter" id="ldapConfig" border="0" cellpadding="0" cellspacing="1" width="100%">
                                        <thead>
                                            <tr>
                                                <th>Key</th>
                                                <th>Property</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <cfloop collection="#_collection#" item="i">
                                                <cfif i EQ "userPas">
                                                    <tr><td>#i#</td><td>#hash(_collection[i],"SHA1")# (Hashed)</td></tr>
                                                <cfelse>
                                                    <tr><td>#i#</td><td>#_collection[i]#</td></tr>
                                                </cfif>
                                            </cfloop>
                                        </tbody>
                                    </table>
                                </td>
                            </tr>
                        </cfif>
                    </cfloop>
                    </tbody>
                </table>
            </cfoutput>
        </cfif>
    </cfif>
</cfif>
</body>
</html>