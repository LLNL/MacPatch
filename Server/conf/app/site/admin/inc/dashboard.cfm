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
			
			$("#tSorter").tablesorter({
				widgets: ['zebra'],
				headers: { 1:{sorter: 'ipAddress'}}
			})
				.tablesorterPager({
				container: $("#pager")
			});
			
			$("#avTable").tablesorter( {widgets: ['zebra'], headers: {0:{sorter: false}} } ); 
			$("#avInfoTable").tablesorter({widgets: ['zebra']}) .tablesorterPager({container: $("#pager")}); 
			$("#npTable").tablesorter({widgets: ['zebra']}); 
		});	
	</script>

<script type="text/javascript">	
	var popUpWin=0;
	function popUpWindow(URLStr, WindowName)
	{
	 popUpWin = window.open(URLStr, WindowName, 'width=600,height=600,menubar=no,resizable=yes,scrollbars=yes,toolbar=no,top=90,left=90');
	}
	
	function toggle() {
		//alert("called");
		for ( var i=0; i < arguments.length; i++ ) {
			//alert(i);
			if ( i == 0 ) {
				document.getElementById(arguments[i]).style.display = "inline";
			} else {
				document.getElementById(arguments[i]).style.display = "none";
			}
		}
	}	
</script>

<style type="text/css">

body {
	font-family: arial, helvetica;	
	padding: 0px;
	margin: 0px;
}

.headerLabel {font-size:18px; font-weight:bold; padding: 6px;}
.style0 {border: 1px solid #000000;width:470px;padding:4px;}
.style1 {font-size: 12px}
.style2 {font-size: 12px; font-weight: bold; }
.style3 {font-size: 12px; font-style: italic; }
.style4 {font-size: 16px;font-weight: bold; }

p.solid {border-style: solid;}

.dashBox {width:470px; height:400px;}
.dashBox2 {width:470px; height:400px;}
.dashLink {
	margin-top:4px;
	margin-bottom:2px;
	border: 1px solid #000000;
	background-color:#999;
	border-color:#000;
	padding-left:4px;
	padding-right:4px;
	vertical-align:bottom;
}
.dashLink a {font-size: 11px;color:#FFF;}

.dashLink a:link { text-decoration: none;}
.dashLink a:visited { text-decoration: none;} 
.dashLink a:hover { color:#000; } 

</style>
<cfsilent>
<cfquery datasource="#session.dbsource#" name="qGetNewPatches">
    select name as patchname, title, version, postdate, reboot as restartaction 
	from combined_patches_view 
	where (postdate >= (now() - interval 14 day))
    AND active = '1'
	AND patch_state = 'Production'
    Order By postdate Desc
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetAVInfo">
   	SELECT	defs_date, Count(defs_date) As Count
    FROM	av_info
    LEFT 	JOIN mp_clients_view ci
	ON 		av_info.cuuid=ci.cuuid
    Where 0=0
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        ci.Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
    
    Group By defs_date
    Order By defs_date DESC
    LIMIT 0,10
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetTotalClient">
    SELECT	Count(*) As Total
    FROM	mp_clients_view
    Where 0=0
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetOSNumbers">
    SELECT	osver, Count(osver) As Count
    FROM	mp_clients_view
    Where 0=0
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
    Group By osver
    Order By Count Desc
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetOSNumbersMinorPre">
    SELECT  Left(osver,5) as OSMinorVer, Count(Left(osver,5)) As Count
    FROM    mp_clients_view
    Group By OSMinorVer
    Order By Count Desc
</cfquery>

<cfset qGetOSNumbersMinor = QueryNew("OSMinorVer, Count")> 
<cfset newRows = QueryAddRow(qGetOSNumbersMinor, qGetOSNumbersMinorPre.RecordCount)>

<cfset rowIDX = 1>  
<cfif  qGetOSNumbersMinorPre.RecordCount GTE 1>
    <cfoutput query="qGetOSNumbersMinorPre">
        <cfif Right(OSMinorVer, 1) is ".">
            <cfset OSMinorVerAlt = Left(OSMinorVer, Len(OSMinorVer)-1) />
        <cfelse>
            <cfset OSMinorVerAlt = OSMinorVer />
        </cfif>
        <cfset temp = QuerySetCell(qGetOSNumbersMinor, "OSMinorVer", OSMinorVerAlt, rowIDX)> 
        <cfset temp = QuerySetCell(qGetOSNumbersMinor, "Count", Count, rowIDX)> 
        <cfset rowIDX = rowIDX + 1>
    </cfoutput>
</cfif>

<cfquery datasource="#session.dbsource#" name="qGetModelNumbers" maxrows="10">
	SELECT
	hw.mpa_Model_Identifier AS ModelType, Count(hw.mpa_Model_Identifier) As Count
	FROM mp_clients mpc
	LEFT JOIN mpi_SPHardwareOverview hw ON hw.cuuid = mpc.cuuid
    Group By hw.mpa_Model_Identifier
    Order By Count Desc
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetRebootInfo">
    SELECT	CASE needsReboot
            WHEN '0' THEN 'False' 
            WHEN '1' THEN 'True' 
            ELSE needsReboot END AS needsReboot, Count(needsReboot) As Count
    FROM	mp_clients_view
    Where 0=0
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
    Group By needsReboot
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetClientPatchStatus" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
    Select 	patch, Count(*) As Clients  
    From 	client_patch_status_view
    LEFT 	JOIN mp_clients_view ci
	ON 		client_patch_status_view.cuuid=ci.cuuid
    Where 0=0
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        ci.Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
    Group By patch
    Order By Clients DESC
	LIMIT 0, 10
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGetClientDateStatus" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
    SELECT	mdate
    FROM	mp_clients_view
    Where 0=0
    <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
        AND
        Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
    </cfif>
</cfquery>

<cfset normal = 0>
<cfset warn = 0>
<cfset alert = 0>
<cfoutput query="qGetClientDateStatus">
	<cfif DateDiff("d",mdate,now()) GTE 7 and DateDiff("d",mdate,now()) LT 14>
		<cfset warn = warn + 1>
	<cfelseif DateDiff("d",mdate,now()) GTE 15>
		<cfset alert = alert + 1>
	<cfelse>
		<cfset normal = normal + 1>
	</cfif> 
</cfoutput>

<cfquery datasource="#session.dbsource#" name="qGetAgentVersionCount" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
    SELECT CONCAT(`client_version`, '.', `agent_build`) as client_ver, COUNT(*) as Total FROM `mp_clients`
    Group By client_ver
	Order By Total Desc
</cfquery>

<cfset tempColorList = "0099CC,00CCCC,CC9933,9999FF,FFCCFF,339933,66CCCC,FF6633,99CCFF,BDB76B,FFE4B5,FFE4E1">
<cfset myArrayColorList = ListToArray(tempColorList,",")>
<cfset CreateObject("java","java.util.Collections").Shuffle(myArrayColorList) />
<cfset myColorListArr = myArrayColorList>
<cfset CreateObject("java","java.util.Collections").Shuffle(myColorListArr) />
<cfset myColorList = ArrayToList(myColorListArr,",")>

<cfset objFile = createObject("java","java.io.File").init("/")>
<cfset disk = structNew()>
<cfset disk.freeSpace = NumberFormat(objFile.getFreeSpace()/1000000000.00,"0.00") & " GB">
<cfset disk.totalSpace = NumberFormat(objFile.getTotalSpace()/1000000000.00,"0.00") & " GB">

</cfsilent>
<body>
<table align="left">
	<tr>
        <td>
            <table align="center" width="960px">
                <cfoutput>
                <tr>
                    <td align="left">
                        <h3>Total Clients - #qGetTotalClient.Total#</h3>
                    </td>
                    <td align="right">
                        Server Disk Size: #disk.totalSpace#<br>Server Free Space: #disk.freeSpace#
                    </td>
                </tr>
                </cfoutput>
            </table>  
        </td>
    </tr>   
	<tr>
		<td>
            <table align="center"> 
                <tr>
                    <td class="style0" valign="top">
                    <div id="dashbox">
                            <div id="av1" style="display:inline;">
                            	<div align="center">
                            		<div style="margin-top:4px; margin-bottom:10px; border: 1px solid #000000; border-color:#000; font-size:12px; padding:10px; width:140px; text-align:center;">Antivirus Defs Distribution</div>
                                </div>
                                <table id="avTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
                                    <thead>
                                    <tr>
                                        <th width="26">&nbsp;</th>
                                        <th>AV Defs Date</th>
                                        <th>Count</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <cfoutput query="qGetAVInfo">
                                    <tr>
                                        <td><a href="dashboard.cfm?Series=AVInfo&Item=#defs_date#"><img src="/admin/images/info_16.png" height="16" width="16"></a></td>
                                        <td>#defs_date#</td>
                                        <td>#count#</td>
                                    </tr>		
                                    </cfoutput>
                                    </tbody>
                                </table>
                        	</div>
                            <div id="av2" style="display:none;">
                            	<cfquery datasource="#session.dbsource#" name="qGetAVVersionData">
                                    select app_version, count(*) as total 
                                    From    av_info
                                    LEFT 	JOIN mp_clients_view ci
                                    ON      av_info.cuuid=ci.cuuid
                                    Where 0 = 0 AND ci.cuuid IS NOT NULL
                                    Group By app_version
                                    Order By total Desc 
                                </cfquery>
                                <cfchart format="png" title="AV Client Version Break Down" showlegend="yes" showborder="no" chartheight="400" chartwidth="480" pieslicestyle="sliced"
                                url="dashboard.cfm?Series=AVVersionInfo&Item=$ITEMLABEL$" >
                                    <cfchartseries type="pie" serieslabel="AV Version Break Down">
                                    <cfoutput query="qGetAVVersionData">
                                        <cfchartdata item="#app_version#" value="#total#">
                                    </cfoutput>
                                    </cfchartseries>
                                </cfchart>
                            </div>
                            <div id="av3" style="display:none;">
                                <cfquery datasource="#session.dbsource#" name="qGet">
                                    select IF( av.app_version IS NULL, "no", "yes") as AVClient, count(*) total
                                    From mp_clients_view cci
                                    Left Join av_info av
                                    ON cci.cuuid = av.cuuid
                                    Where 0 = 0 AND cci.cuuid IS NOT NULL
                                    Group By AVClient
                                    Order By total Desc 
                                </cfquery>
                                <cfchart format="png" title="MacPatch Client With AV Installed" showlegend="yes" showborder="no" chartheight="400" chartwidth="480" pieslicestyle="sliced">
                                    <cfchartseries type="pie" serieslabel="Has AV Installed">
                                    <cfoutput query="qGet">
                                        <cfchartdata item="#AVClient#" value="#total#">
                                    </cfoutput>liced
                                    </cfchartseries>
                                </cfchart>
                            </div>    
                        <cfoutput>
                        <div class="dashLink">
                        	<a href="javascript:toggle('av1','av2','av3')">AV Defs Distribution</a>
                            &nbsp;|&nbsp;
                            <a href="javascript:toggle('av2','av1','av3')">AV Client Versions</a>
                            &nbsp;|&nbsp;
                            <a href="javascript:toggle('av3','av1','av2')">AV Client Installed</a>
                        </div>
                        </cfoutput>
                    </div>    
                	</td>
                    <td class="style0" valign="top">
                    		<div align="center">
                                <div style=" margin-top:4px; margin-bottom:10px; border: 1px solid #000000; border-color:#000; font-size:12px; padding:10px; width:240px; text-align:center;">Patches Released in the last 14 days</div>
                            </div>
                    		<table id="npTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
                            <thead>
                            <tr>
                                <th>Patch</th>
                                <th>Version</th>
                                <th>Release Date</th>
                            </tr>
                            </thead>
                            <tbody>
                            <cfoutput query="qGetNewPatches">
                            <tr>
                                <td>#patchname#</td>
                                <td>#version#</td>
                                <td>#DateFormat(postdate, "mm/dd/yyyy")#</td>
                            </tr>		
                            </cfoutput>
                            </tbody>
                        </table>
                        <br />
                	</td>
                </tr>
                <tr>
                    <td class="style0">
                    	<div id="dashbox">
                        	<div id="os1" style="display:none;">
                            <cfchart format="png" title="OS Break Down" showlegend="no" showborder="no" chartheight="400" chartwidth="480" xaxistitle="OS Versions" yaxistitle="Client Count" url="dashboard.cfm?Series=$SERIESLABEL$&Item=$ITEMLABEL$">
                                <cfchartseries type="bar" serieslabel="OSBreakDown">
                                <cfoutput query="qGetOSNumbers">
                                    <cfchartdata item="#osver#" value="#Count#">
                                </cfoutput>liced
                                </cfchartseries>
                            </cfchart>
                            </div>
                            <div id="os2" style="display:inline;">
                                <cfchart format="png" title="OS Break Down Minor" showlegend="no" chartheight="400" chartwidth="480" xaxistitle="Model Type" yaxistitle="Count" url="dashboard.cfm?Series=$SERIESLABEL$&Item=$ITEMLABEL$">
                                    <cfchartseries type="bar" serieslabel="OSBreakDownMinor">
                                    <cfoutput query="qGetOSNumbersMinor">
                                        <cfchartdata item="#OSMinorVer#" value="#Count#">
                                    </cfoutput>
                                    </cfchartseries>
                                </cfchart>
                            </div>
							<div id="os3" style="display:none;">
                                <cfchart format="png" title="Top 10 Model Types" showlegend="no" chartheight="400" chartwidth="480" xaxistitle="Model Type" yaxistitle="Count" url="dashboard.cfm?Series=$SERIESLABEL$&Item=$ITEMLABEL$">
                                    <cfchartseries type="bar" serieslabel="ModelTypeBreakDown">
                                    <cfoutput query="qGetModelNumbers">
                                        <cfchartdata item="#ModelType#" value="#Count#">
                                    </cfoutput>
                                    </cfchartseries>
                                </cfchart>
                            </div>
							<cfoutput>
                            <div class="dashLink">
                                <a href="javascript:toggle('os1','os2','os3','os4')">OS Breakdown</a>
                                &nbsp;|&nbsp;
								<a href="javascript:toggle('os2','os1','os3','os4')">OS Breakdown Minor</a>
                                &nbsp;|&nbsp;
                                <a href="javascript:toggle('os3','os1','os2','os4')">Model Types</a>
                            </div>
                            </cfoutput>    
                        </div>
                    </td>
                    <td class="style0">
                        <cfchart format="png" title="Top 10 Outstanding Patches" showlegend="no" showborder="no" chartheight="400" chartwidth="480" url="dashboard.cfm?Series=$SERIESLABEL$&Item=$ITEMLABEL$" yaxistitle="Patch Count">
                            <cfchartseries type="bar" serieslabel="OutstandingPatches" colorlist="#myColorList#">
                            <cfoutput query="qGetClientPatchStatus">
                                <cfchartdata item="#patch#" value="#Clients#">
                            </cfoutput>
                            </cfchartseries>
                        </cfchart>
                    </td>
                </tr>
             </table>  
			<table align="center">     
                <tr>
                    <td class="style0">	
                    <div id="dashbox">
                            <div id="cln1" style="display:inline;">
                            	<cfchart pieSliceStyle="sliced" show3d="yes"  format="png" title="Client Checkin Status" showlegend="no" showborder="no" chartheight="300" chartwidth="480" url="dashboard.cfm?Series=$SERIESLABEL$&Item=$ITEMLABEL$">
			                        <cfchartseries type="bar" serieslabel="ClientChekckInStatus" colorlist="green,yellow,red">
			                            <cfchartdata item="Normal" value="#normal#">
			                            <cfchartdata item="Warning" value="#warn#">
			                            <cfchartdata item="Alert" value="#alert#">
			                        </cfchartseries>
			                    </cfchart>
                            </div>
                            <div id="cln2" style="display:none;">
                                <cfchart pieSliceStyle="sliced" show3d="yes" format="png" title="Clients Needing Reboot" showlegend="no" showborder="no" chartheight="300" chartwidth="480" url="dashboard.cfm?Series=$SERIESLABEL$&Item=$ITEMLABEL$">
			                        <cfchartseries type="bar" serieslabel="NeedsReboot"  colorlist="##008000,##EE0000">
			                        <cfoutput query="qGetRebootInfo">
			                            <cfchartdata item="#needsReboot#" value="#Count#">
			                        </cfoutput>
			                        </cfchartseries>
			                    </cfchart>
                            </div>    
                        <cfoutput>
                        <div class="dashLink">
                        	<a href="javascript:toggle('cln1','cln2')">Checkin Status</a>
                            &nbsp;|&nbsp;
                            <a href="javascript:toggle('cln2','cln1')">Reboot Status</a>
                        </div>
                        </cfoutput>
                    </div>
                    </td>
                    <td class="style0">
					<cfchart format="png" title="MacPatch Agent Version Count" showlegend="yes" showborder="no" chartheight="300" chartwidth="480" pieslicestyle="sliced">
                       <cfchartseries type="pie" serieslabel="Agent Version Count">
                       <cfoutput query="qGetAgentVersionCount">
                           <cfchartdata item="#client_ver#" value="#total#">
                       </cfoutput>liced
                       </cfchartseries>
                   </cfchart>
                    </td>
                  </tr>
            </table>
        </td>
        <td>
            <table align="center" height="800">
                <tr>
                    <td><h3>&nbsp;</h3></td>
                </tr>    
                <tr>
                    
                </tr>
            </table>        
        </td>
	</tr>
    <tr>
    	<td colspan="2">      
<!---  Start Drill Down Data --->
<p>&nbsp;</p>   
<cfif IsDefined("url.Series") and url.Series EQ "AVInfo">
	<cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
		SELECT	av.defs_date, av.app_Version, av.app_name, av.mdate, ci.hostname, ci.mdate as cmdate, ci.Domain as ClientGroup, ci.ipaddr
		FROM	av_info av
		LEFT 	JOIN mp_clients_view ci
		ON      av.cuuid=ci.cuuid
		Where 0=0
		<cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            ci.Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        AND defs_date like '#Url.Item#'
        AND ci.cuuid IS NOT NULL
	</cfquery>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>AV Info - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>
	<table id="avInfoTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
		<thead>
        <tr>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Client Group</th>
            <th>Defs. Date</th>
            <th>AV App Name</th>
            <th>AV App Ver.</th>
            <th>Last AV CheckIn</th>
            <th>Last Client CheckIn</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
    	<tr>
            <td>#hostname#</td>
            <td>#ipaddr#</td>
            <td>#ClientGroup#</td>
            <td>#defs_date#</td>
            <td>#app_name#</td>
            <td>#app_version#</td>
            <td>#dateformat(mdate, "yyyy-mm-dd")# #TimeFormat(mdate, "HH:mm:ss")#</td>
            <td>#dateformat(cmdate, "yyyy-mm-dd")# #TimeFormat(cmdate, "HH:mm:ss")#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
</cfif>
<cfif IsDefined("url.Series") and url.Series EQ "AVVersionInfo">
	<cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
		SELECT	av.defs_date, av.app_version, av.app_name, av.mdate, ci.hostname, ci.mdate as cmdate, ci.Domain as ClientGroup, ci.ipaddr
		FROM	av_info av
		LEFT 	JOIN mp_clients_view ci
		ON      av.cuuid=ci.cuuid
		Where 0=0
		<cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            ci.Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        AND app_version like '#Url.Item#'
        AND ci.cuuid IS NOT NULL
	</cfquery>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>AV Info - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>
	<table id="avInfoTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
		<thead>
        <tr>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Client Group</th>
            <th>Defs. Date</th>
            <th>AV App Name</th>
            <th>AV App Ver.</th>
            <th>Last AV CheckIn</th>
            <th>Last Client CheckIn</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
    	<tr>
            <td>#hostname#</td>
            <td>#ipaddr#</td>
            <td>#ClientGroup#</td>
            <td>#defs_date#</td>
            <td>#app_name#</td>
            <td>#app_version#</td>
            <td>#dateformat(mdate, "yyyy-mm-dd")# #TimeFormat(mdate, "HH:mm:ss")#</td>
            <td>#dateformat(cmdate, "yyyy-mm-dd")# #TimeFormat(cmdate, "HH:mm:ss")#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
</cfif>

<cfif IsDefined("url.Series") and url.Series EQ "OSBreakDown">
    <cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        SELECT	*
        FROM	mp_clients_view
        Where 0=0
		<cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
         AND osver like '#Url.Item#'
    </cfquery>
     <cfquery datasource="#session.dbsource#" name="qOSBreakDownTotals" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        SELECT	Domain, Count(Domain) As Count
        FROM	mp_clients_view
        Where 0=0
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
         AND osver like '#Url.Item#'
         Group By Domain
         Order By count Desc
    </cfquery>
	<cfif ListLen(session.cgrp,",") GT 1>
    <table width="100%" align="center">
        <tr>
            <td align="center">
            <cfchart format="png" title="Client Group - OS Break Down (#Url.Item#)" showlegend="no" showborder="yes" chartheight="400" chartwidth="930">
                <cfchartseries type="bar" serieslabel="OutstandingPatches">
                <cfoutput query="qOSBreakDownTotals">
                    <cfchartdata item="#domain#" value="#count#">
                </cfoutput>
                </cfchartseries>
            </cfchart>
            </td>
        </tr>
    </table>
    </cfif>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>OS Break Down - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>
    <table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%" align="center">
		<thead>
        <tr>
        	<th>ClientID</th>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Client Group</th>
            <th>Patch Group</th>
            <th>OS Ver.</th>
            <th>OS Type</th>
            <th>Needs Reboot</th>
            <th>Last Check-in</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
		<cfset color = "normal">
        <cfif DateDiff("d",mdate,now()) GTE 7 and DateDiff("d",mdate,now()) LTE 14>
            <cfset color = "warn">
        <cfelseif DateDiff("d",mdate,now()) GTE 15>
            <cfset color = "alert">
        </cfif> 
    	<tr>
            <td>#cuuid#</td>
            <td>#hostname#</td>
            <td>#ipaddr#</td>
            <td>#Domain#</td>
            <td>#PatchGroup#</td>
            <td>#osver#</td>
            <td>#ostype#</td>
            <td>
                <cfif #needsreboot# EQ "True">
                    Yes
                <cfelseif #needsreboot# EQ "False">    
                    No
                <cfelse>
                    NA    
                </cfif>
            </td>
            <td class="#color#">#dateformat(mdate, "yyyy-mm-dd")# #TimeFormat(mdate, "HH:mm:ss")#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
<cfelseif IsDefined("url.Series") and url.Series EQ "OSBreakDownMinor">
    <cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        SELECT	*
        FROM	mp_clients_view
        Where 0=0
		<cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
         AND osver like '#Url.Item#.%'
    </cfquery>
     <cfquery datasource="#session.dbsource#" name="qOSBreakDownTotals" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        SELECT	Domain, Count(Domain) As Count
        FROM	mp_clients_view
        Where 0=0
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
         AND osver like '#Url.Item#.%'
         Group By Domain
         Order By count Desc
    </cfquery>
	<cfif ListLen(session.cgrp,",") GT 1>
    <table width="100%" align="center">
        <tr>
            <td align="center">
            <cfchart format="png" title="Client Group - OS Break Down (#Url.Item#)" showlegend="no" showborder="yes" chartheight="400" chartwidth="930">
                <cfchartseries type="bar" serieslabel="OutstandingPatches">
                <cfoutput query="qOSBreakDownTotals">
                    <cfchartdata item="#domain#" value="#count#">
                </cfoutput>
                </cfchartseries>
            </cfchart>
            </td>
        </tr>
    </table>
    </cfif>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>OS Break Down - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>
    <table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%" align="center">
		<thead>
        <tr>
        	<th>ClientID</th>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Client Group</th>
            <th>Patch Group</th>
            <th>OS Ver.</th>
            <th>OS Type</th>
            <th>Needs Reboot</th>
            <th>Last Check-in</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
		<cfset color = "normal">
        <cfif DateDiff("d",mdate,now()) GTE 7 and DateDiff("d",mdate,now()) LTE 14>
            <cfset color = "warn">
        <cfelseif DateDiff("d",mdate,now()) GTE 15>
            <cfset color = "alert">
        </cfif> 
    	<tr>
            <td>#cuuid#</td>
            <td>#hostname#</td>
            <td>#ipaddr#</td>
            <td>#Domain#</td>
            <td>#PatchGroup#</td>
            <td>#osver#</td>
            <td>#ostype#</td>
            <td>
                <cfif #needsreboot# EQ "True">
                    Yes
                <cfelseif #needsreboot# EQ "False">    
                    No
                <cfelse>
                    NA    
                </cfif>
            </td>
            <td class="#color#">#dateformat(mdate, "yyyy-mm-dd")# #TimeFormat(mdate, "HH:mm:ss")#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
<cfelseif IsDefined("url.Series") and url.Series EQ "ModelTypeBreakDown">
    <cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
    	SELECT	
        ci.cuuid, ci.hostname, ci.ipaddr, ci.Domain, ci.PatchGroup, ci.osver, ci.mdate,
        hw.mpa_Memory AS RAM,
        hw.mpa_Model_Identifier AS EQP_MODEL_ID,
        hw.mpa_Model_Name AS EQP_MODEL_NAM
    	FROM
        mp_clients_view ci
        LEFT JOIN mpi_SPHardwareOverview hw ON hw.cuuid = ci.cuuid
        Where 0=0
		<cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
         AND EQP_MODEL_ID like '#Url.Item#'
    </cfquery>
	<cfif ListLen(session.cgrp,",") GT 1>
    <table width="100%" align="center">
        <tr>
            <td align="center">
            <cfchart format="png" title="Client Group - OS Break Down (#Url.Item#)" showlegend="no" showborder="yes" chartheight="400" chartwidth="930">
                <cfchartseries type="bar" serieslabel="OutstandingPatches">
                <cfoutput query="qOSBreakDownTotals">
                    <cfchartdata item="#domain#" value="#count#">
                </cfoutput>
                </cfchartseries>
            </cfchart>
            </td>
        </tr>
    </table>
    </cfif>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>Model Type Break Down - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>
    <table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%" align="center">
		<thead>
        <tr>
        	<th>ClientID</th>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Client Group</th>
            <th>Patch Group</th>
            <th>Model Type</th>
            <th>CPU</th>
            <th>RAM</th>
            <th>OS Ver.</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
    	<tr>
            <td>#cuuid#</td>
            <td>#hostname#</td>
            <td>#ipaddr#</td>
            <td>#Domain#</td>
            <td>#PatchGroup#</td>
            <td>#EQP_MODEL_ID#</td>
            <td>#CPU#</td>
            <td>#RAM#</td>
            <td>#osver#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
    
<cfelseif IsDefined("url.Series") and url.Series EQ "OSTypeBreakDown">
    <cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        SELECT	
        ci.cuuid, ci.hostname, ci.ipaddr, ci.Domain, ci.PatchGroup, ci.osver, ci.mdate,
        hw.mpa_Model_Identifier AS EQP_MODEL_ID,
        hw.mpa_Model_Name AS EQP_MODEL_NAM,
        hw.mpa_Memory AS RAM,
        hw.mpa_Processor_Name AS CPU,
        hw.ostype AS OS_MAJ_VER_STD_NAM
    	FROM
        mp_clients_view ci
        LEFT JOIN mpi_SPHardwareOverview hw ON hw.cuuid = ci.cuuid
        
        Where 0=0
		<cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
         AND OS_MAJ_VER_STD_NAM like <cfqueryparam value="#Url.Item#">
    </cfquery>
	<cfif ListLen(session.cgrp,",") GT 1>
    <table width="100%" align="center">
        <tr>
            <td align="center">
            <cfchart format="png" title="Client Group - OS Break Down (#Url.Item#)" showlegend="no" showborder="yes" chartheight="400" chartwidth="930">
                <cfchartseries type="bar" serieslabel="OutstandingPatches">
                <cfoutput query="qOSBreakDownTotals">
                    <cfchartdata item="#domain#" value="#count#">
                </cfoutput>
                </cfchartseries>
            </cfchart>
            </td>
        </tr>
    </table>
    </cfif>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>Model Type Break Down - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>
    <table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%" align="center">
		<thead>
        <tr>
        	<th>ClientID</th>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Client Group</th>
            <th>Patch Group</th>
            <th>Model Type</th>
            <th>OS Ver.</th>
            <th>OS Type</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
    	<tr>
            <td>#cuuid#</td>
            <td>#hostname#</td>
            <td>#ipaddr#</td>
            <td>#Domain#</td>
            <td>#PatchGroup#</td>
            <td>#EQP_MODEL_ID#</td>
            <td>#osver#</td>
            <td>#OS_MAJ_VER_STD_NAM#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
    
<cfelseif IsDefined("url.Series") and url.Series EQ "OutstandingPatches">
	<cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
    	select cci.hostname, cci.ipaddr, cci.PatchGroup, cci.mdate, cpsv.patch, cpsv.description, cpsv.ClientGroup, cpsv.DaysNeeded,
		CASE WHEN EXISTS
		( SELECT 1
          FROM mp_patchgroup_patches_view v
          WHERE v.suname = cpsv.patch
		  AND v.patch_group = cci.PatchGroup)
        THEN "Yes" ELSE "No"
        END AS inPatchGroup
        From client_patch_status_view cpsv
        Join mp_clients_view cci on
            cpsv.cuuid = cci.cuuid
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            cci.Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        AND patch like '#Url.Item#'
        Order By CLIENTGROUP, Hostname
     </cfquery>
     <cfquery datasource="#session.dbsource#" name="qGetClientPatchStatusTotals" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
		Select cci.Domain as ClientGroup, Count(Domain) As Count
    	From client_patch_status_view cps join mp_clients_view cci on (cps.cuuid = cci.cuuid)
        Where 0=0
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            cci.Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        AND patch like '#Url.Item#'
        Group By ClientGroup
        Order By Count Desc
     </cfquery>
    <cfif ListLen(session.cgrp,",") GT 1>
    <table width="100%">
    <tr>
    	<td align="center">
        <cfchart format="png" title="Client Group - Outstanding Patches Break Down (#Url.Item#)" showlegend="no" showborder="yes" chartheight="400" chartwidth="930">
            <cfchartseries type="bar" serieslabel="OutstandingPatches">
            <cfoutput query="qGetClientPatchStatusTotals">
                <cfchartdata item="#ClientGroup#" value="#count#">
            </cfoutput>
            </cfchartseries>
        </cfchart>
    	</td>
    </tr>
    </table>    
    </cfif>
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>Outstanding Patches - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>	
   	<table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%" align="center">
		<thead>
        <tr>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Last Checkin</th>
            <th>Patch</th>
            <th>Patch Detail</th>
            <th>Client Group</th>
            <th>Patch Group</th>
            <th>Days Needed</th>
			<th>Assigned</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
        <tr>
            <td>#Hostname#</td>
            <td>#ipaddr#</td>
            <td>#DateFormat(mdate,"yyyy-mm-dd")# #timeformat(mdate,"HH:MM:SS")#</td>
            <td>#patch#</td>
            <td>#description#</td>
            <td>#ClientGroup#</td>
            <td>#PatchGroup#</td>
            <td>#DaysNeeded#</td>
			<td>#inPatchGroup#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
<cfelseif IsDefined("url.Series") and url.Series EQ "NeedsReboot">
    <h4>Clients Needing A Reboot - Drill Down</h4>
    <cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        select * 
        From mp_clients_view
        Where 0=0
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        AND needsReboot like '#Url.Item#'
        Order By Domain, Hostname
     </cfquery>
    
    <table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
		<thead>
        <tr>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Reboot</th>
            <th>Client Group</th>
            <th>Last CheckIn</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
        <tr>
            <td>#Hostname#</td>
            <td>#ipaddr#</td>
            <td>#needsReboot#</td>
            <td>#Domain#</td>
            <td>#DateFormat(mdate, "yyyy-mm-dd")# #TimeFormat(mdate, "hh:mm:ss")#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>
<cfelseif IsDefined("url.Series") and url.Series EQ "ClientChekckInStatus">
    <cfquery datasource="#session.dbsource#" name="qMoreInfo" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">
        select * 
        From mp_clients_view
        Where 0=0
        <cfif IsDefined("session.cgrp") and ListLen(session.cgrp,",") GTE 1>
            AND
            Domain IN (#ListQualify(session.cgrp,"'",",","CHAR")#)
        </cfif>
        <cfif #Url.Item# EQ "Normal">
            AND mdate >= DATE_SUB(curdate(),INTERVAL 6 day)
        <cfelseif #Url.Item# EQ "Warning">
            AND mdate between DATE_SUB(curdate(),INTERVAL 14 day) AND DATE_SUB(curdate(),INTERVAL 7 day)
        <cfelseif #Url.Item# EQ "Alert"> 
            AND mdate <= DATE_SUB(curdate(),INTERVAL 15 day)
        </cfif>
        Order By mdate
     </cfquery>
  
	<cfset session.DashboardExportQuery = qMoreInfo>
	<div style="float: left;"><h4>Client Checkin Status - Drill Down (<cfoutput>#Url.Item#</cfoutput>)</h4></div>
	<div style="float: right; padding-bottom:6px;">
		<img src="/admin/images/icons/table_save.png" title="Export to CSV" align="left" onClick="window.open('dashboard_export.cfm','Export2CSV');">Export (CSV)&nbsp;
	</div>	
    <table id="tSorter" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%" align="center">
		<thead>
        <tr>
            <th>HostName</th>
            <th>IP Address</th>
            <th>Reboot</th>
            <th>Client Group</th>
            <th>Last CheckIn</th>
        </tr>
        </thead>
        <tbody>
        <cfoutput query="qMoreInfo">
        <tr>
            <td>#Hostname#</td>
            <td>#ipaddr#</td>
            <td>#needsReboot#</td>
            <td>#Domain#</td>
            <td>#DateFormat(mdate, "yyyy-mm-dd")# #TimeFormat(mdate, "hh:mm:ss")#</td>
        </tr>		
        </cfoutput>
        </tbody>
    </table>     
</cfif>
<cfif IsDefined("url.Series")>
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
        <option value="<!---#qMoreInfo.RecordCount#--->1000">All</option>
    </select>
</form>
</cfoutput>
</div>
</cfif>  
<!--- END Drill Down Data --->
</td>
    </tr>
</table>    
</body>
</html>