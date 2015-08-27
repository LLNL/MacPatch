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

<title></title>
</head>
<body>
	<cfset rptOwner = "">
	<cfset displayActions = false>
	<cfset rptID = "0">
	<cfquery name="qGet" datasource="#session.dbsource#">
    	Select * from mp_adhoc_reports
        Where rid = <cfqueryparam value="#url.id#">
    </cfquery>
    <cfif qGet.Recordcount EQ 1>
    	<cfset rptOwner = qGet.owner>
    	<cfif qGet.owner EQ session.username OR session.IsAdmin EQ true>
        	<cfset displayActions = true>
        </cfif>
    	<cfif qGet.owner EQ session.username OR qGet.owner EQ "Global" OR qGet.rights EQ 0>
        	<cfset rptQry = ToString( ToBinary( qGet.reportData ) )>
            <cfset rptID = #qGet.rid#>
        <cfelse>
        <cfdump>
        	FAIL!!!!    
            <cfabort>
        </cfif>
    <cfelse>
    	FAIL!!!
    	<cfabort>
    </cfif>
	<!--- Run the query --->
    <cfset hasErr = false>
    <cfparam name="qRun.recordcount" default="0">
    <cfparam name="qRun.name" default="">
	<cftry>
		<CFQUERY NAME="qRun" DATASOURCE="#session.dbsource#">
			#PreserveSingleQuotes(rptQry)# 
		</CFQUERY>
        <cfset session.RptExportQuery = #qRun#>
		<cfcatch type = "Any">
        	<cfset hasErr = true>
        	<cfsavecontent variable="errMsg">
			<b>ERROR: There is an error in the query, please click on the back button and verify the query.</b>
			<p>Your Query:<br>
			<cfoutput><span class="query_error_small">#PreserveSingleQuotes(rptQry)#</span>
			</p>
			#cfcatch.Detail#
			</cfoutput>
            </cfsavecontent>
		</cfcatch>
	</cftry>
		
	<!--- Display the Query Results --->
    <div style="float: left;">
	<cfoutput>
	<div style="font-size:16px; font-weight:bold;">#qGet.name# Report</div><br /><div style="font-size:12px;">#qRun.recordcount# Records found. 
    <br />Report created by #rptOwner#.
    </div>
	</cfoutput>
    </div>
    <div style="float: right;font-size:12px;">
    <cfif displayActions EQ true>
    <cfform action="adhoc_report_edit.cfm" method="post">
    	<cfinput type="hidden" name="rptID" value="#rptID#">
		<cfinput type="submit" name="ReportAction" value="Edit">
        <cfinput type="submit" name="ReportAction" value="Delete">
	</cfform>
    </cfif>
    <br />
    <cfif hasErr EQ false>
    <img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('adhoc_report_export.cfm','Export2CSV');">Export (CSV)&nbsp;
    </cfif>
    </div>
    <br />
    <cfif hasErr EQ true>
    
    <table border="0" cellpadding="10" cellspacing="1" width="100%">
        <tr>
        	<td>
            <hr />
    <cfoutput>#errMsg#</cfoutput>
    		</td>
        </tr>
    </table>
    <cfabort>
    </cfif>
	<table id="rptTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
		<thead>
        <tr>
			<cfloop list="#qRun.columnlist#" index="i">
			<th><cfoutput>#i#</cfoutput></th>
			</cfloop>
		</tr>
        </thead>
        <tbody>
		<cfoutput query="qRun">
		<tr>				
			<cfloop list="#qRun.columnlist#" index="i">
				<td>#evaluate(i)#</td>
			</cfloop>
		</tr>
        </cfoutput>
        </tbody>
	</table>
	
    <div id="pager" class="pager">
    <br />
    <cfoutput>
    <form>
        <img src="/admin/js/tablesorter/pager/icons/first.png" class="first"/>
        <img src="/admin/js/tablesorter/pager/icons/prev.png" class="prev"/>
        <input type="text" class="pagedisplay"/>
        <img src="/admin/js/tablesorter/pager/icons/next.png" class="next"/>
        <img src="/admin/js/tablesorter/pager/icons/last.png" class="last"/>
        <select class="pagesize">
            <option value="10">10</option>
            <option value="20">20</option>
            <option selected="selected" value="25">25</option>
            <option value="30">30</option>
            <option value="40">40</option>
            <option value="50">50</option>
            <option value="5000">All (MAX 5,000)</option>
        </select>
    </form>
    </cfoutput>
    </div>

</body>
</html>
