<cfset SCRIPT_NAME = #Replace(SCRIPT_NAME,"//","/","All")#>

<cffunction name="encodeBase64" access="public" returntype="any" output="no">
    <cfargument name="aString">
    <cfreturn Tobase64(arguments.aString)>
</cffunction>
<cffunction name="decodeBase64" access="public" returntype="any" output="no">
    <cfargument name="aString">
    <cfreturn ToString( ToBinary( arguments.aString ) )>
</cffunction>

<script type="text/javascript">	
	$(function() {
		
		$("#listSummary").tablesorter({
			widgets: ['zebra']
		})
		.tablesorterPager({
			container: $("#pager")
		});
		
	});	
</script>
<script type="text/javascript">	
	$(function() {
		// Used by build_patch_group.cfm, edit_patch_group.cfm
		$("#listClients").tablesorter({
			widgets: ['zebra'] 
		});
		
		$("#options").tablesorter({
			sortList: [[0,0]]
		});
	});	
</script>
<script language="javascript">

	imageX1='minus';
	imageX2='plus';
	imageX3='plus';
	
	function toggleDisplay(e){
	imgX="imagePM"+e;
	tableX="table"+e;
	imageX="imageX"+e;
	tableLink="tableHref"+e;
	imageXval=eval("imageX"+e);
	element = document.getElementById(tableX).style;
	
	if (element.display=='none') {
		 element.display='block';
	} else {
		element.display='none';
	}
	if (imageXval=='plus') {
		 document.getElementById(imgX).src='./_assets/images/minus.jpg';
		 eval("imageX"+e+"='minus';");
		 document.getElementById(tableLink).title='Hide Table #'+e+'a';
	} else if (imageXval=='minus') {
		document.getElementById(imgX).src='./_assets/images/plus.jpg';
		eval("imageX"+e+"='plus';");
		document.getElementById(tableLink).title='Show Table #'+e+'a';}
	}
</script>
<script type="text/javascript">
function goTo()
{
	var url = document.forms[0].url.value;
	var field = document.forms[0].field.value;
	var data = document.forms[0].data.value;
	if (document.forms[0].data.value != "") {
		window.location = url+'&DrillDown='+escape(field+'|')+btoa(data)+'&TableState=Table&DrillDownQry=1';
		return false;
	} else {
		return false;
	}	
	
}
</script>

<cfparam name="URL.OrderBy" default="hostname">
<cfparam name="URL.OrderByType" default="ASC">
<cfparam name="URL.TableState" default="none">
<cfparam name="URL.DrillDown" default="">

<cftry>
<cfquery datasource="#session.dbsource#" name="qGet2" result="res">
	select * from mp_client_patch_status_view
    Where (hostname IS NOT NULL
    OR ipaddr IS NOT NULL)
    <cfif IsDefined("URL.DrillDown") AND URL.DrillDown NEQ "">
    AND
    #ListGetAt(URL.DrillDown,1,"|")# like '#decodeBase64(ListGetAt(URL.DrillDown,2,"|"))#%'
    </cfif>
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        ClientGroup IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
    Order By #URL.OrderBy# #URL.OrderByType#
</cfquery>

<cfcatch type="any">
<cfoutput>#cfcatch.Detail#</cfoutput>
</cfcatch>
</cftry>

<cfquery name="rSet1" datasource="#session.dbsource#">
	Select 	cps.cuuid as cuuid, cps.patch as patch, ci.hostname as hostname, ci.ipaddr as ipaddr, 
    		cps.description as description, ci.Domain as ClientGroup, cps.type as type
    FROM mp_client_patches_full_view cps
    LEFT 	JOIN mp_clients_view ci
	ON 		cps.cuuid=ci.cuuid
</cfquery>

<cfquery name="rset2" dbtype="query">
	Select 	patch, Count(*) As Clients  
    FROM 	rSet1
    Where 0=0
    <cfif IsDefined("URL.DrillDown") AND URL.DrillDown NEQ "">
    	AND
    	#ListGetAt(URL.DrillDown,1,"|")# like '#decodeBase64(ListGetAt(URL.DrillDown,2,"|"))#%'
    </cfif>
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        ClientGroup IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
    Group By patch
    Order BY Clients Desc
</cfquery>

<cfquery name="qGet3" dbtype="query">
	Select 	patch, Clients
    FROM 	rset2
	Order BY Clients Desc
</cfquery> 
<ct1>Patching State</ct1>
<table class="generictable" width="100%" cellspacing="0">
<tr>
    <td>
    <form action="" method="get" onsubmit="return goTo()">
    	Quick Search:
    	<select name="field">
        	<option value="hostname">Hostname</option>
            <option value="patch">Patch</option>
            <option value="ClientGroup">Client Group</option>
        </select>
        <input type="text" value="" name="data" />
        <input type="hidden" value="<cfoutput>#SCRIPT_NAME#</cfoutput>?clientstatus=True" name="url" />
        <input type="submit" value="Search">
    </form>
    </td>
    <td align="right"><cfoutput><a href="#SCRIPT_NAME#?clientstatus=True">Reset List</a></cfoutput></td>
</tr>
</table>
<hr />
<p>
    <a title="Show Summary Table" href="javascript:toggleDisplay('1')" id=tableHref1><img border="0" src="./_assets/images/minus.jpg" id=imagePM1></a>&nbsp;Summary...
</p>
<div style="display:table;" id=table1>
	<cfoutput>
	<div id="pager" class="pager">
        <br />
        <form>
            <img src="./_assets/js/jquery/addons/pager/icons/first.png" class="first"/>
            <img src="./_assets/js/jquery/addons/pager/icons/prev.png" class="prev"/>
            <input type="text" class="pagedisplay"/>
            <img src="./_assets/js/jquery/addons/pager/icons/next.png" class="next"/>
            <img src="./_assets/js/jquery/addons/pager/icons/last.png" class="last"/>
            <select class="pagesize">
                <option value="10">10</option>
                <option value="20">20</option>
                <option selected="selected" value="25">25</option>
                <option value="30">30</option>
                <option value="40">40</option>
                <option value="50">50</option>
                <option value="#qGet3.RecordCount#">All</option>
            </select>
        </form>
    </div>
    </cfoutput>
    <br />
    <table id="listSummary" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="500">
        <thead> 
        <tr>
            <th>Patch</th>
            <th>No of Clients Affected</th>
        </tr>
        </thead>
        <tbody>  
        <cfoutput query="qGet3"> 
        <tr>
            <td><a href="#SCRIPT_NAME#?clientstatus=True&DrillDown=#UrlEncodedFormat("patch|")##encodeBase64(patch)#&TableState=Table">#patch#</a></td>
            <td>#Clients#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
</div>
<br />
<img border="0" src="./_assets/images/plus.jpg" id="imagePM2" onclick="javascript:toggleDisplay('2')">&nbsp;Client(s)...
<br />
<div style="display:<cfoutput>#URL.TableState#</cfoutput>;" id=table2>
<cfset session.clientPatchStateExportQuery = qGet2>
<div style="float: left;"> </div>
<div style="float: right;">
	<img src="./_assets/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('includes/client_patch_state_export.cfm','Export2CSV');">Export (CSV)&nbsp;
</div>
<br />
<table id="listClients" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="980" align="center">
    <thead> 
    <tr>
        <th>HostName</th>
        <th>IP Address</th>
        <th>Patch</th>
        <th>Patch Detail</th>
        <th>Client Group&nbsp;&nbsp;&nbsp;</th>
		<th>Client Patch Group&nbsp;&nbsp;&nbsp;</th>
        <th>Days Needed&nbsp;&nbsp;&nbsp;</th>
    </tr>
	</thead>
    <tbody>
    <cfoutput query="qGet2">
    <tr>
        <td width="140"><a href="#SCRIPT_NAME#?clientstatus=True&DrillDown=#UrlEncodedFormat('hostname|')##encodeBase64(Hostname)#&TableState=Table">#Hostname#</td>
        <td><a href="#SCRIPT_NAME#?clientstatus=True&DrillDown=#UrlEncodedFormat('ipaddr|')##encodeBase64(ipaddr)#&TableState=Table">#ipaddr#</td>
        <td><a href="#SCRIPT_NAME#?clientstatus=True&DrillDown=#UrlEncodedFormat('patch|')##encodeBase64(patch)#&TableState=Table">#patch#</td>
        <td><a href="#SCRIPT_NAME#?clientstatus=True&DrillDown=#UrlEncodedFormat('description|')##encodeBase64(description)#&TableState=Table">#description#</td>
        <td><a href="#SCRIPT_NAME#?clientstatus=True&DrillDown=#UrlEncodedFormat('ClientGroup|')##encodeBase64(ClientGroup)#&TableState=Table">#ClientGroup#</a></td>
        <td>#patchgroup#</td>
		<td>#IIf(Len(Trim(DaysNeeded)) EQ 0, DE("NA"), DE(DaysNeeded))#</td>
    </tr>		
    </cfoutput>
    </tbody>
</table>
</div>