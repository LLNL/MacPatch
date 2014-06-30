<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="stylesheet" href="/admin/js/tablesorter/themes/blue/style.css" type="text/css"/>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />


<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<script type="text/javascript" src="/admin/js/tablesorter/jquery.tablesorter.js"></script>
<script type="text/javascript" src="/admin/js/tablesorter/pager/jquery.tablesorter.pager.js"></script>

<script type="text/javascript">	
    $(function() {
        $("#rptTable").tablesorter({
            widgets: ['zebra']
        }).tablesorterPager({
            container: $("#pager")
        });
    });	
</script>

<cfscript>
   function isEmpty(str) {
      if(NOT len(trim(str)))
         return false;
      else
         return true;
      } 
</cfscript>

<title></title>
</head>
<body>
<cfif ISDefined("form.ReportAction")>
	<cfif form.ReportAction EQ "Delete">
    	<cfquery name="qRptOwner" datasource="#session.dbsource#">
            Select owner From mp_adhoc_reports 
            Where rid = <cfqueryparam value="#form.RPTID#">
        </cfquery>
        <cfif qRptOwner.RecordCount EQ 1>
        	<cfif qRptOwner.owner NEQ "#session.username#" AND session.IsAdmin NEQ true>
            	<b>ERROR:</b> Only the owner of the report may delete it.
	            <cfabort>	
            </cfif>
        <cfelse>
        	<b>ERROR:</b> Report not found.
            <cfabort>    
        </cfif>
        
    	<cfquery name="qRptDisable" datasource="#session.dbsource#">
            UPDATE mp_adhoc_reports 
            Set disabled = <cfqueryparam value="1">
            ,disableddate = #CreateODBCDateTime(now())#
            Where rid = <cfqueryparam value="#form.RPTID#">
        </cfquery>
        <script type="text/javascript">
		var node = parent.$("#tree").fancytree("getActiveNode");
		node.remove();
        </script>
        <!--- <cflocation url="#session.cflocFix#/admin/inc/dashboard.cfm"> --->
        <cfabort>
    
	<cfelseif form.ReportAction EQ "Edit">
    	<cfquery name="qRptData" datasource="#session.dbsource#">
            Select * From mp_adhoc_reports 
            Where rid = <cfqueryparam value="#form.RPTID#">
        </cfquery>
        <cfif qRptData.RecordCount EQ 1>
        	<cfif qRptData.owner NEQ "#session.username#" AND session.IsAdmin NEQ true>
            	<b>ERROR:</b> Only the owner of the report may edit it.
	            <cfabort>	
            </cfif>
        <cfelse>
        	<b>ERROR:</b> Report not found.
            <cfabort>    
        </cfif>
    <cfelse>
    	<b>ERROR:</b> Action not defined.
        <cfabort>    
    </cfif>
</cfif>

<cfform action="adhoc_report_save.cfm" method="post">
	<table>
    	<tr><td>Report Name:</td><td><cfinput type="text" name="rName" value="#qRptData.name#" tooltip="Name of the Report/Query" label="Report Name"></td></tr>
        <tr><td>Owner:</td><td><cfinput type="text" name="rOwner" value="#qRptData.owner#" tooltip="Name of the Report owner" readonly="true"></td></tr>
        <tr><td>Scope:</td><td><cfselect name="rScope" required="yes">
        	<cfoutput>
			<option value="0" <cfif #qRptData.rights# EQ 0>selected="selected"</cfif>>Public</option>
			<option value="1" <cfif #qRptData.rights# EQ 1>selected="selected"</cfif>>Private</option>
			</cfoutput></cfselect></td></tr>
        <tr><td>Query: </td><td><textarea name="theQuery" cols="100" rows="20"><cfoutput>#ToString( ToBinary( qRptData.reportData ))#</cfoutput></textarea></td></tr>
        <tr><td></td><td><cfinput type="hidden" name="rptID" value="#form.rptID#"><cfinput type="submit" name="ReportAction" value="Update"></td></tr>
</cfform>
</body>
</html>
