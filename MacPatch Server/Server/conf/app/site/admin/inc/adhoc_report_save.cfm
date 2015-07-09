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
	<cfif form.ReportAction EQ "Save">
    	<cfif ISDefined("form.rName") AND isEmpty(form.rName)>
        	<cfif Hash(form.theQuery,'MD5') EQ session.qHash>
            	<cfset qb64 = ToBase64(form.theQuery)>
            	<cfquery name="qRptInsert" datasource="#session.dbsource#" result="result">
                	Insert Into mp_adhoc_reports (name,reportData,owner,rights)
                    Values (<cfqueryparam value="#form.rName#">,<cfqueryparam value="#qb64#">,<cfqueryparam value="#form.rOwner#">,<cfqueryparam value="#form.rScope#">)
                </cfquery>
                <cfset rid = result.generated_key>
                
                <script type="text/javascript">
				//var node = parent.$("#tree").fancytree("getActiveNode");
				var node = parent.$("#tree").fancytree("getTree").getNodeByKey("mainReports");
				//var rootNode = parent.$("#tree").fancytree("getRootNode");
				node.addChildren({title: "<cfoutput>#form.rName#</cfoutput>", icon: "text-list.png", href: "/admin/inc/adhoc_report_run.cfm?id=<cfoutput>#rid#</cfoutput>"});
				</script>
                <!---
                <cflocation url="#session.cflocFix#/admin/inc/dashboard.cfm">
				--->
                <cfabort>
            </cfif> 
        </cfif>
    <cfelseif form.ReportAction EQ "Update">
    	<cfif ISDefined("form.RPTID") AND isEmpty(form.RPTID)>
            <cfquery name="qRptOwner" datasource="#session.dbsource#">
                Select owner From mp_adhoc_reports 
                Where rid = <cfqueryparam value="#form.RPTID#">
            </cfquery>
            <cfif qRptOwner.RecordCount EQ 1>
                <cfif qRptOwner.owner NEQ "#session.username#">
                    FAIL, not the owner!!!
                    <cfabort>	
                </cfif>
            <cfelse>
                FAIL, not found!!!
                <cfabort>    
            </cfif>
            
            <cfquery name="qRptUpdate" datasource="#session.dbsource#">
                UPDATE mp_adhoc_reports 
                Set name = <cfqueryparam value="#form.rName#">
                ,reportData = <cfqueryparam value="#ToBase64(form.theQuery)#">
                ,rights = <cfqueryparam value="#form.rScope#">
                Where rid = <cfqueryparam value="#form.RPTID#">
            </cfquery>
            
            Report was updated!
            <cfabort>
		</cfif>
    </cfif>
</cfif>
<cfform action="adhoc_report_save.cfm" method="post">
	<table>
    	<tr><td>Report Name:</td><td><cfinput type="text" name="rName" value="" tooltip="Name of the Report/Query" label="Report Name"></td></tr>
        <tr><td>Owner:</td><td><cfinput type="text" name="rOwner" value="#session.username#" tooltip="Name of the Report owner" readonly="true"></td></tr>
        <tr><td>Scope:</td><td><cfselect name="rScope" required="yes">
		   <option value="0">Public</option>
           <option value="1">Private</option>
           </cfselect></td></tr>
        <tr><td>Query: </td><td><textarea name="theQuery" cols="100" rows="20"><cfoutput>#theQuery#</cfoutput></textarea></td></tr>
        <tr><td></td><td><cfinput type="submit" name="ReportAction" value="Save"></td></tr>
</cfform>
</body>
</html>
