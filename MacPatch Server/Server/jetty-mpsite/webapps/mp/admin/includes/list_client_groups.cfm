<script type="text/javascript">	
	$(function() {
		
		$("#listClientGroups").tablesorter({
			widgets: ['zebra'],
			headers: { 0:{sorter: false} }
		});
		
		$("#listClientGroup").tablesorter({
			widgets: ['zebra'],
			headers: { 0:{sorter: false}, 1:{sorter: false}, 3:{sorter: 'ipAddress'}, 5:{sorter: 'ipAddress'}, 6:{sorter: 'ipAddress'}, 11:{sorter: 'isoDate'}, 12:{sorter: false} }
		})
			.tablesorterPager({
			container: $("#pager")
		});
	});	
</script>	
<script type="text/javascript">
function goTo()
{
	var url = document.searchForm.url.value;
	var field = document.searchForm.field.value;
	var data = document.searchForm.data.value;
	if (data != "") {
		window.location = url+'&QRYData='+escape(field+'|'+data);
		return false;
	} else {
		window.location = url;
		return false;
	}
}
function goToReset()
{
	var url = document.searchForm.url.value;
	window.location = url;
	return false;
}
</script>
<script type="text/javascript">	
	var popUpWin=0;
	function popUpWindow(URLStr, WindowName)
	{
	 popUpWin = window.open(URLStr, WindowName, 'width=560,height=760,menubar=no,resizable=yes,scrollbars=yes,toolbar=no,top=90,left=90');
	}
	var popUpInvWin=0;
	function popUpInvWindow(URLStr, WindowName)
	{
	 popUpInvWin = window.open(URLStr, WindowName, 'width=800,height=600,menubar=no,resizable=yes,scrollbars=yes,toolbar=no,top=90,left=90');
	}
</script>
<script type="text/javascript">
	function deleteUser(id){
		if(confirm('Delete Record : ' + id))
		{
			new Ajax.Request('list_client_groups_action.cfm', {
				parameters: $('cuuid'+id).serialize(true)
			});
		};
	}
</script>
<!--- --->
<cfform name="MyForm" method="POST" action="includes/remove_Client.cfm" onsubmit="return SubmitForm();">
	<input type="Hidden" name="ClientID" value="">
	<input type="Hidden" name="ReturnURL" value="<cfoutput>#CGI.SCRIPT_NAME#?#CGI.QUERY_STRING#</cfoutput>">
</cfform>

<script language="JavaScript">
	function SubmitForm(cuuid,hname){
		input_box=confirm("Are you sure you want to delete "+hname+"?\nNOTE: This can not be un-done.");
		if (input_box==true) {
			// Output when OK is clicked
			document.MyForm.ClientID.value = cuuid;
			document.MyForm.submit();
		}
	}
</script>

<cfif IsDefined("url.QRYData") AND NOT IsDefined("url.ClientGroupName")>
	<!---
	<cfquery datasource="#session.dbsource#" name="qGet">
        SELECT	*
        FROM	ClientCheckIn
        Where 	#ListGetAt(URL.QRYData,1,"|")# like '#ListGetAt(URL.QRYData,2,"|")#'
    </cfquery> 
	--->
	<cfquery datasource="#session.dbsource#" name="qGet">
        SELECT	*
        FROM	mp_clients_view
        Where 	#ListGetAt(URL.QRYData,1,"|")# like '#ListGetAt(URL.QRYData,2,"|")#'
    </cfquery> 
<p>Query Results for (<cfoutput>#ListGetAt(URL.QRYData,1,"|")# like #ListGetAt(URL.QRYData,2,"|")#</cfoutput>)</p>
<table class="generictable" width="100%" cellspacing="0">
<tr>
    <td>
    Quick Search (<font size="-4">Use % as wildcard</font>)
	<form action="" method="get" onsubmit="return goTo()" name="searchForm">
    	<select name="field">
        	<option value="hostname">Hostname</option>
            <option value="computername">Computername</option>
            <option value="ipaddr">IP Address</option>
            <option value="consoleUser">Console User</option>
            <option value="serialNo">Serial No</option>
            <option value="macaddr">MAC Address (e.g. 00:25:4b:c6:3b:46)</option>
            <option value="cci.cuuid">Client ID</option>
        </select>
        <input type="text" value="" name="data" />
        <input type="hidden" value="<cfoutput>#CGI.SCRIPT_NAME#?clientgroups=0</cfoutput>" name="url" />
        <input type="submit" value="Search">
        <input type="button" value="Show All" onclick="return goToReset()">
    </form>
    </td>
    <td align="right">&nbsp;</td>
</tr>
</table>

<table id="listClientGroup" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
	<thead>
    <tr>
        <th>&nbsp;&nbsp;</th>
        <th>AV</th>
        <th>HostName&nbsp;&nbsp;</th>
        <th>IP Address&nbsp;&nbsp;</th>
        <th>OS&nbsp;&nbsp;</th>
        <th width="60">SWUAD&nbsp;&nbsp;</th>
        <th width="60">SWUAI&nbsp;&nbsp;</th>
        <th>SWUPD&nbsp;&nbsp;</th>
        <th width="100">Checkin Interval(sec)</th>
        <th width="80">Needs Reboot&nbsp;&nbsp;</th>
        <th>Patch Group</th>
        <th>Client Group</th>
        <th>Last Checkin Date</th>
    </tr>
	</thead>
    <tbody>
    <cfoutput query="qGet">
    <cfset color = "normal">
    <cfif DateDiff("d",sdate,now()) GTE 7 and DateDiff("d",sdate,now()) LTE 14>
		<cfset color = "warn">
    <cfelseif DateDiff("d",sdate,now()) GTE 15>
        <cfset color = "alert">
    </cfif>           
    <tr>
    	<td>
        <a href="javascript:popUpWindow('#Session.appBase#/includes/list_client_group_client_info.cfm?cuuid=#cuuid#','Client Info')"><img src="./_assets/images/info.png" height="16" width="16" align="texttop"></a>
        </td>
        <td>
        <a href="javascript:popUpWindow('#Session.appBase#/includes/list_client_group_client_avinfo.cfm?cuuid=#cuuid#','AV Info')"><img src="./_assets/images/av_icon.png" height="16" width="16" align="texttop"></a>
        </td>
        <td>#hostname#</td>
        <td>#ipaddr#</td>
        <td>#osver#</td>
        <td>#swuad_ver#</td>
        <td>#swuai_ver#</td>
        <td>#swupd_ver#</td>
        <td>#p_ClientScanInterval#</td>
        <td>
            <cfif #needsreboot# EQ "True">
                Yes
            <cfelseif #needsreboot# EQ "False">    
                No
            <cfelse>
                NA    
            </cfif>
        </td>
        <td>#p_PatchGroup#</td>
        <td>#p_Domain#</td>
        <td class="#color#">#DateFormat(sdate, "mm/dd/yyyy")# #TimeFormat(sdate, "HH:mm:ss")#</td>
    </tr>		
    </cfoutput>
    </tbody>
</table>
<div id="pager" class="pager">
<br />
<cfoutput>
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
        <option value="#qGet.RecordCount#">All</option>
    </select>
</form>
</cfoutput>
</div>

<p>&nbsp;</p>
<table class="generictable" width="330">
	<tr>
    	<td align="center">Client Check-in Status</td>
    </tr>
</table>    
<table class="resultsListTable" width="330">
	<tr>
    <td class="normal" width="110"><b>Normal</b></td>
    <td class="warn" width="110"><b>Warning</b></td>
    <td class="alert" width="110"><b>Alert</b></td>
    </tr>
    <tr>
    <td class="normal">0 - 7 Days</td>
    <td class="warn">7 - 14 Days</td>
    <td class="alert">15 or more Days</td>
    </tr>
</table>   
<cfelse>
	<!--- List the Client Groups to drill down in to --->      
	<cfquery datasource="#session.dbsource#" name="qGet">
        SELECT	Domain, COUNT(hostname) AS Clients
        FROM	mp_clients_view
        GROUP BY Domain
    </cfquery>
    <h3>Client Groups</h3>
    <table class="generictable" width="100%" cellspacing="0">
    <tr>
        <td>
        Quick Search
        <form action="./index.cfm?ClientGroupsInfo=0" method="post" name="searchForm">
            <select name="field">
                <option value="hostname">Hostname</option>
                <option value="computername">Computername</option>
                <option value="ipaddr">IP Address</option>
                <option value="consoleUser">Console User</option>
                <option value="serialNo">Serial No</option>
                <option value="macaddr">MAC Address (e.g. 00:25:4b:c6:3b:46)</option>
                <option value="cci.cuuid">Client ID</option>
            </select>
            <input type="text" value="" name="data" />
            <input type="hidden" value="1" name="isSearch" />
            <input type="submit" value="Search">
        </form>
        </td>
        <td align="right">&nbsp;</td>
    </tr>
    </table>
    <br />
    <table> 
        <tr>
            <td valign="top">
            <table id="listClientGroups" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="500"> 
                <thead>
                <tr>
                    <th>&nbsp;</th>
                    <th>Group</th>
                    <th>Clients</th>
                </tr>
                </thead>
                <tbody>
                <cfoutput query="qGet">
                <tr>
                    <td align="center" width="18">
                    	<a href="./index.cfm?ClientGroupsInfo=0&ClientGroupName=#URLEncodedFormat(Domain)#">
						<img src="./_assets/images/info.png" height="16" width="16" align="texttop"></a>
                    </td>
                    <td>#Domain#</td>
                    <td>#Clients#</td>
                </tr>		
                </cfoutput>
                </tbody>
            </table>
            </td>
         </tr>
     </table>       		       
</cfif>