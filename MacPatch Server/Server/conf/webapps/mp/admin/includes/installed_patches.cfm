<cfparam name="FilterPatches" default="Default">
<cfparam name="URL.OrderBy" default="idate">
<cfparam name="URL.OrderByType" default="DESC">
<cfparam name="URL.DrillDown" default="0|0">
<cfparam name="URL.StartRow" default="1">
<cfparam name="DisplayRows" default="50">
<cfset ToRow = StartRow + (DisplayRows - 1)>

<script type="text/javascript">	
	
	$(function() {
		// Used by build_patch_group.cfm, edit_patch_group.cfm
		$("#installedPatches").tablesorter({
			widgets: ['zebra'] 
		});
		
		$("#options").tablesorter({
				sortList: [[0,0]],  
				headers: { 0:{sorter: 'input'} }
		});
	});	
	
</script>
<script type="text/javascript">
function goTo()
{
	var url = document.forms[0].url.value;
	var field = document.forms[0].field.value;
	var data = document.forms[0].data.value;
	window.location = url+'&DrillDown='+escape(field+'|'+data);
	return false;
}
</script>


<cfif FilterPatches EQ "Filter">
    <cfquery datasource="#session.dbsource#" name="qGet2">
        Select hostname,idate, patch, domain
        From InstalledPatchListView
        Where 0=0
            <cfif #form.idate# NEQ "">
            AND
            CAST(FLOOR(CAST(idate AS float)) AS datetime) = '#trim(form.idate)#'
            </cfif>
            <cfif #form.patch# NEQ "">
            AND
            patch like '#trim(form.patch)#'
            </cfif>
            <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
                AND
                domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
            <cfelse>
                <cfif #form.domain# NEQ "">
                AND
                domain like '#trim(form.domain)#'
                </cfif>
            </cfif>    
        Order By idate DESC , patch DESC
    </cfquery>
<cfelse>           
    <cfquery datasource="#session.dbsource#" name="qGet2">
        Select hostname, idate, patch, domain
        From InstalledPatchListView
        Where 0=0
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        <cfif #ListGetAt(URL.DrillDown,1,"|")# EQ "domain">
            AND domain like '#ListGetAt(URL.DrillDown,2,"|")#'
        <cfelseif #ListGetAt(URL.DrillDown,1,"|")# EQ "hostname">
            AND hostname like '#ListGetAt(URL.DrillDown,2,"|")#'
        <cfelseif #ListGetAt(URL.DrillDown,1,"|")# EQ "patch">
            AND patch like '#ListGetAt(URL.DrillDown,2,"|")#'
        <cfelseif #ListGetAt(URL.DrillDown,1,"|")# EQ "idate">
            AND CAST(idate AS DATE) = '#ListGetAt(ListGetAt(URL.DrillDown,2,"|"),1," ")#'
        </cfif>
        <cfif #URL.OrderBy# NEQ "idate">
        Order By #URL.OrderBy# #URL.OrderByType#
        <cfelse>
        Order By #URL.OrderBy# #URL.OrderByType#
        </cfif>
    </cfquery>
</cfif>
<cfquery datasource="#session.dbsource#" name="qGetPatch">
    Select Distinct patch
    From InstalledPatchListView
    Order By patch DESC
</cfquery>
<cfquery datasource="#session.dbsource#" name="qGetDomain">
    Select Distinct domain
    From InstalledPatchListView
    Order By domain DESC
</cfquery>


<ct1>Installed Patches</ct1>
<table class="generictable" width="100%" cellspacing="0">
<tr>
    <td>
    <form action="" method="get" onsubmit="return goTo()">
    	Quick Search:
    	<select name="field">
        	<option value="hostname">Hostname</option>
            <option value="patch">Patch</option>
            <option value="domain">Client Group</option>
        </select>
        <input type="text" value="" name="data" />
        <input type="hidden" value="<cfoutput>#CGI.SCRIPT_NAME#?installedpatches=True</cfoutput>" name="url" />
        <input type="submit" value="Search">
    </form>
    </td>
    <td align="right"><cfoutput><a href="#CGI.SCRIPT_NAME#?installedpatches=True">Reset List</a></cfoutput></td>
</tr>
</table>
<table id="installedPatches" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
    <thead> 
    <tr>	
        <th>HostName</th>
        <th>Install Date</th>
        <th>Patch</th>
        <th>Client Group</th>   
    </tr>
	<thead>
    <tbody>
    
	<cfif ToRow gt qGet2.RecordCount>
        <cfset ToRow = qGet2.RecordCount>
    </cfif>
	<cfoutput query="qGet2" startrow="#StartRow#" maxrows="#DisplayRows#">
    <tr>
        <td><a href="#CGI.SCRIPT_NAME#?installedpatches=True&DrillDown=#UrlEncodedFormat("hostname|")##UrlEncodedFormat(hostname)#">#Hostname#</a></td>
        <td><a href="#CGI.SCRIPT_NAME#?installedpatches=True&DrillDown=#UrlEncodedFormat("idate|")##UrlEncodedFormat(idate)#">#idate#</a></td>
        <td><a href="#CGI.SCRIPT_NAME#?installedpatches=True&DrillDown=#UrlEncodedFormat("patch|")##UrlEncodedFormat(patch)#">#patch#</a></td>
        <td><a href="#CGI.SCRIPT_NAME#?installedpatches=True&DrillDown=#UrlEncodedFormat("domain|")##UrlEncodedFormat(domain)#">#domain#</a></td>
    </tr>		
    </cfoutput>
	</tbody>
</table>
<br />
<table class="generictable" cellspacing="0" width="100%" align="center">
<tr>
    <td style="font-size: 11px;">
    <cfset Next = #StartRow# + #DisplayRows#>
    <cfset Previous = #StartRow# - #DisplayRows#>
    <cfoutput>
        <cfif Previous GTE 1>
            <a href="#CGI.Script_Name#?installedpatches=True&StartRow=#Previous#&OrderBy=#URLEncodedFormat(URL.OrderBy)#&OrderByType=#URL.OrderByType#&DrillDown=#URL.DrillDown#"><b><< Previous #DisplayRows# Records</b></a>
        <cfelse>
            Previous Records
        </cfif>
        <b>|</b>
        <!--- Create a next records link if there are more records in the record set that haven't yet been displayed. --->
        <cfif Next lte qGet2.RecordCount>
        <a href="#CGI.Script_Name#?installedpatches=True&StartRow=#Next#&OrderBy=#URLEncodedFormat(URL.OrderBy)#&OrderByType=#URL.OrderByType#&DrillDown=#URL.DrillDown#"><b>Next
            <cfif (qGet2.RecordCount - Next) lt DisplayRows>
                #Evaluate((qGet2.RecordCount - Next)+1)#
            <cfelse>
                #DisplayRows#
            </cfif>
                Records >></b></a>
        <cfelse>
          Next Records
        </cfif>
        <br>
        <h4>Displaying records #StartRow# thru #ToRow# from the #qGet2.RecordCount# total records found.</h4>
        <br>
        (Number of rows to display at a time, #DisplayRows#.)
    </cfoutput>
    </td>
</tr>
</table>
