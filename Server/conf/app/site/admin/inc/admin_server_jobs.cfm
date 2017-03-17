<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />

<cfparam name="url.action" default="-1">
<cfif IsDefined("url.task")>
	<cfset taskName = #url.task#>
<cfelse>
	<cfset taskName = "">
</cfif>

<cfif IsDefined("url.action")>
	<cfif url.action EQ "1" OR url.action EQ "2">
        <cfinclude template="admin_server_jobs_cmd.cfm">
    </cfif>
</cfif>

<cfparam name="application.settings.server.tasksHost" default="127.0.0.1">
<cfparam name="application.settings.server.tasksPort" default="8080">
<cfparam name="application.settings.server.tasksHTTP" default="http">
<cfset tasksURL = application.settings.server.tasksHTTP & "://" & application.settings.server.tasksHost & ":" & application.settings.server.tasksPort>

<style type="text/css"> 
fieldset {   
	margin-top:10px;
	border:1px solid black;
	-moz-border-radius:5px;  
	border-radius: 5px;  
	-webkit-border-radius: 5px;
	padding:6px;
}

legend {
	padding:4px;
	margin-left: 20px;
	color:black;
}
table.tbltask {}
table.tbltask th {}
table.tbltask td {
	padding-bottom: 4px;
	padding-left: 4px;
	padding-right: 4px;
}

.dimImg {
	filter: url(filters.svg#grayscale); /* Firefox 3.5+ */
	filter: gray; /* IE6-9 */
	-webkit-filter: grayscale(1); /* Google Chrome & Safari 6+ */
}

/* button 
---------------------------------------------- */
.button {
	display: inline-block;
	zoom: 1; /* zoom and *display = ie7 hack for display:inline-block */
	*display: inline;
	vertical-align: baseline;
	margin: 0 2px;
	outline: none;
	cursor: pointer;
	text-align: center;
	text-decoration: none;
	font: 14px/100% Arial, Helvetica, sans-serif;
	padding: .5em 2em .55em;
	text-shadow: 0 1px 1px rgba(0,0,0,.3);
	-webkit-border-radius: .5em; 
	-moz-border-radius: .5em;
	border-radius: .5em;
	-webkit-box-shadow: 0 1px 2px rgba(0,0,0,.2);
	-moz-box-shadow: 0 1px 2px rgba(0,0,0,.2);
	box-shadow: 0 1px 2px rgba(0,0,0,.2);
}
.button:hover {
	text-decoration: none;
}
.button:active {
	position: relative;
	top: 1px;
}

.bigrounded {
	-webkit-border-radius: 2em;
	-moz-border-radius: 2em;
	border-radius: 2em;
}
.medium {
	font-size: 12px;
	padding: .4em 1.5em .42em;
}
.small {
	font-size: 11px;
	padding: .2em 1em .275em;
}

/* color styles 
---------------------------------------------- */

/* black */
.black {
	color: #d7d7d7;
	border: solid 1px #333;
	background: #333;
	background: -webkit-gradient(linear, left top, left bottom, from(#666), to(#000));
	background: -moz-linear-gradient(top,  #666,  #000);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#666666', endColorstr='#000000');
}
.black:hover {
	background: #000;
	background: -webkit-gradient(linear, left top, left bottom, from(#444), to(#000));
	background: -moz-linear-gradient(top,  #444,  #000);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#444444', endColorstr='#000000');
}
.black:active {
	color: #666;
	background: -webkit-gradient(linear, left top, left bottom, from(#000), to(#444));
	background: -moz-linear-gradient(top,  #000,  #444);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#000000', endColorstr='#666666');
}

/* gray */
.gray {
	color: #e9e9e9;
	border: solid 1px #555;
	background: #6e6e6e;
	background: -webkit-gradient(linear, left top, left bottom, from(#888), to(#575757));
	background: -moz-linear-gradient(top,  #888,  #575757);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#888888', endColorstr='#575757');
}
.gray:hover {
	background: #616161;
	background: -webkit-gradient(linear, left top, left bottom, from(#757575), to(#4b4b4b));
	background: -moz-linear-gradient(top,  #757575,  #4b4b4b);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#757575', endColorstr='#4b4b4b');
}
.gray:active {
	color: #afafaf;
	background: -webkit-gradient(linear, left top, left bottom, from(#575757), to(#888));
	background: -moz-linear-gradient(top,  #575757,  #888);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#575757', endColorstr='#888888');
}

/* white */
.white {
	color: #606060;
	border: solid 1px #b7b7b7;
	background: #fff;
	background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#ededed));
	background: -moz-linear-gradient(top,  #fff,  #ededed);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#ededed');
}
.white:hover {
	background: #ededed;
	background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#dcdcdc));
	background: -moz-linear-gradient(top,  #fff,  #dcdcdc);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#dcdcdc');
}
.white:active {
	color: #999;
	background: -webkit-gradient(linear, left top, left bottom, from(#ededed), to(#fff));
	background: -moz-linear-gradient(top,  #ededed,  #fff);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ededed', endColorstr='#ffffff');
}

/* orange */
.orange {
	color: #fef4e9;
	border: solid 1px #da7c0c;
	background: #f78d1d;
	background: -webkit-gradient(linear, left top, left bottom, from(#faa51a), to(#f47a20));
	background: -moz-linear-gradient(top,  #faa51a,  #f47a20);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#faa51a', endColorstr='#f47a20');
}
.orange:hover {
	background: #f47c20;
	background: -webkit-gradient(linear, left top, left bottom, from(#f88e11), to(#f06015));
	background: -moz-linear-gradient(top,  #f88e11,  #f06015);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#f88e11', endColorstr='#f06015');
}
.orange:active {
	color: #fcd3a5;
	background: -webkit-gradient(linear, left top, left bottom, from(#f47a20), to(#faa51a));
	background: -moz-linear-gradient(top,  #f47a20,  #faa51a);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#f47a20', endColorstr='#faa51a');
}

/* red */
.red {
	color: #faddde;
	border: solid 1px #980c10;
	background: #d81b21;
	background: -webkit-gradient(linear, left top, left bottom, from(#ed1c24), to(#aa1317));
	background: -moz-linear-gradient(top,  #ed1c24,  #aa1317);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ed1c24', endColorstr='#aa1317');
}
.red:hover {
	background: #b61318;
	background: -webkit-gradient(linear, left top, left bottom, from(#c9151b), to(#a11115));
	background: -moz-linear-gradient(top,  #c9151b,  #a11115);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#c9151b', endColorstr='#a11115');
}
.red:active {
	color: #de898c;
	background: -webkit-gradient(linear, left top, left bottom, from(#aa1317), to(#ed1c24));
	background: -moz-linear-gradient(top,  #aa1317,  #ed1c24);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#aa1317', endColorstr='#ed1c24');
}

/* blue */
.blue {
	color: #d9eef7;
	border: solid 1px #0076a3;
	background: #0095cd;
	background: -webkit-gradient(linear, left top, left bottom, from(#00adee), to(#0078a5));
	background: -moz-linear-gradient(top,  #00adee,  #0078a5);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#00adee', endColorstr='#0078a5');
}
.blue:hover {
	background: #007ead;
	background: -webkit-gradient(linear, left top, left bottom, from(#0095cc), to(#00678e));
	background: -moz-linear-gradient(top,  #0095cc,  #00678e);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#0095cc', endColorstr='#00678e');
}
.blue:active {
	color: #80bed6;
	background: -webkit-gradient(linear, left top, left bottom, from(#0078a5), to(#00adee));
	background: -moz-linear-gradient(top,  #0078a5,  #00adee);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#0078a5', endColorstr='#00adee');
}

/* rosy */
.rosy {
	color: #fae7e9;
	border: solid 1px #b73948;
	background: #da5867;
	background: -webkit-gradient(linear, left top, left bottom, from(#f16c7c), to(#bf404f));
	background: -moz-linear-gradient(top,  #f16c7c,  #bf404f);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#f16c7c', endColorstr='#bf404f');
}
.rosy:hover {
	background: #ba4b58;
	background: -webkit-gradient(linear, left top, left bottom, from(#cf5d6a), to(#a53845));
	background: -moz-linear-gradient(top,  #cf5d6a,  #a53845);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#cf5d6a', endColorstr='#a53845');
}
.rosy:active {
	color: #dca4ab;
	background: -webkit-gradient(linear, left top, left bottom, from(#bf404f), to(#f16c7c));
	background: -moz-linear-gradient(top,  #bf404f,  #f16c7c);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#bf404f', endColorstr='#f16c7c');
}

/* green */
.green {
	color: #e8f0de;
	border: solid 1px #538312;
	background: #64991e;
	background: -webkit-gradient(linear, left top, left bottom, from(#7db72f), to(#4e7d0e));
	background: -moz-linear-gradient(top,  #7db72f,  #4e7d0e);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#7db72f', endColorstr='#4e7d0e');
}
.green:hover {
	background: #538018;
	background: -webkit-gradient(linear, left top, left bottom, from(#6b9d28), to(#436b0c));
	background: -moz-linear-gradient(top,  #6b9d28,  #436b0c);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#6b9d28', endColorstr='#436b0c');
}
.green:active {
	color: #a9c08c;
	background: -webkit-gradient(linear, left top, left bottom, from(#4e7d0e), to(#7db72f));
	background: -moz-linear-gradient(top,  #4e7d0e,  #7db72f);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#4e7d0e', endColorstr='#7db72f');
}

/* pink */
.pink {
	color: #feeef5;
	border: solid 1px #d2729e;
	background: #f895c2;
	background: -webkit-gradient(linear, left top, left bottom, from(#feb1d3), to(#f171ab));
	background: -moz-linear-gradient(top,  #feb1d3,  #f171ab);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#feb1d3', endColorstr='#f171ab');
}
.pink:hover {
	background: #d57ea5;
	background: -webkit-gradient(linear, left top, left bottom, from(#f4aacb), to(#e86ca4));
	background: -moz-linear-gradient(top,  #f4aacb,  #e86ca4);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#f4aacb', endColorstr='#e86ca4');
}
.pink:active {
	color: #f3c3d9;
	background: -webkit-gradient(linear, left top, left bottom, from(#f171ab), to(#feb1d3));
	background: -moz-linear-gradient(top,  #f171ab,  #feb1d3);
	filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#f171ab', endColorstr='#feb1d3');
}
	
select {
	-webkit-background-size: 1600px 16px;
}	

table.genTable
{ 
	font-family:arial;
	border-collapse:collapse;
	font-size:10pt;
	background-color:black;
	width:100%;
	border-style:solid;
	border-color:black;
	border-width:1px;
}

table.genTable th
{
	font-size:12pt;
	background-color:grey;
	color:white;
	border-style:solid;
	border-width:1px;
	border-color:black;
	text-align:center;
	padding: 4px;
}

table.genTable td
{  
	font-size:10pt;
	background-color:white;
	color:black;
	border-style:solid;
	border-width:1px;
	padding: 4px;
}
</style>
<cfsilent>
<cfparam name="jobType" default="Delete Expired Clients,Purge Old Client Data,Purge and Archive Install Data">
<cfparam name="jobtaskType" default="ONCE,DAILY,INTERVAL">
<cfsavecontent variable="deleteTypeTask">
  <nocfml><cfoutput>
	<hr>
	<div style="font-size:16px; margin-top:20px;">Add - Server Task</div>
    <cfform action="admin_server_jobs.cfm" method="Post" name="AddNewTask">
		<fieldset>
    	<legend>Server Task Schedule:</legend>
			<table border="0" class="tbltask">
			<tr><td>Task Name:</td><td><input type="text" name="taskName" size="40" maxlength="50" value="#form.TYPE#"></td></tr>
			<tr><td>Interval:</td>
			<td><input type="radio" name="runinterval" value="once"> One Time @ <input type="text" name="starttime_once" size="5" maxlength="5" value=""> (Time 24hs.)<br>
			<input type="radio" name="runinterval" value="recurring"> Recurring <select name="tasktype">
			<option value="" selected="true">- select -</option>
			<option value="DAILY">daily</option>
			<option value="WEEKLY">weekly</option>
			<option value="MONTHLY">monthly</option>
			</select> @ <input type="text" name="starttime_recurring" size="5" maxlength="5" value=""> (Time 24hs.)<br>
			<input type="radio" name="runinterval" value="daily"> Daily every <input type="text" name="interval" size="5" maxlength="5" value="" id="datepicker"> seconds from <input type="text" name="starttime_daily" id="starttime_daily" size="5" maxlength="5"  value=""> to <input type="text" name="endtime_daily" id="endtime_daily" size="5" maxlength="5" value=""> (Time 24hs.) (Note: Must Contain Start Time)
			<br>
			</td></tr>
			<tr><td>Duration:</td><td>Start Date: <input type="text" name="taskStartDateTime" size="12" maxlength="12" value=""> End Date: <input type="text" name="taskEndDateTime" size="12" maxlength="12" value=""> (Date Format DD/MM/YYYY)</td></tr>
			</table>
		</fieldset>
		<fieldset>
    	<legend>Server Task Action:</legend>
			Remove clients after <input type="text" name="actionVar" value="30" size="3"> days of inactivity.
		</fieldset>
		<fieldset>
			<table>
			<tr><td>
            	<input type="hidden" name="url" value="<cfoutput>#tasksURL#</cfoutput>/tasks/cleanup.cfm">
				<input type="hidden" name="actionVarName" value="days">
            	<input type="hidden" name="fAction" value="AddNewTask">
            </td></tr>
            <cfif session.IsAdmin IS true>
			<tr><td><input class="button medium gray" type="button" value="Cancel" onclick="window.location='admin_server_jobs.cfm'">
			<input class="button medium gray" type="button" value="Save" onclick="this.form.submit();"></td></tr>
            </cfif>
			</table>
		</fieldset>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>
<cfsavecontent variable="purgeTypeTask">
  <nocfml><cfoutput>
	<hr>
	<div style="font-size:16px; margin-top:20px;">Add - Server Task</div>
    <cfform action="admin_server_jobs.cfm" method="Post" name="AddNewTask">
		<fieldset>
    	<legend>Server Task Schedule:</legend>
			<table border="0" class="tbltask">
			<tr><td>Task Name:</td><td><input type="text" name="taskName" size="40" maxlength="50" value="#form.TYPE#" readonly></td></tr>
			<tr><td>Interval:</td>
			<td><input type="radio" name="runinterval" value="once"> One Time @ <input type="text" name="starttime_once" size="5" maxlength="5" value=""> (Time 24hs.)<br>
			<input type="radio" name="runinterval" value="recurring"> Recurring <select name="tasktype">
			<option value="" selected="true">- select -</option>
			<option value="DAILY">daily</option>
			<option value="WEEKLY">weekly</option>
			<option value="MONTHLY">monthly</option>
			</select> @ <input type="text" name="starttime_recurring" size="5" maxlength="5" value=""> (Time 24hs.)<br>
			<input type="radio" name="runinterval" value="daily"> Daily every <input type="text" name="interval" size="5" maxlength="5" value="" id="datepicker"> seconds from <input type="text" name="starttime_daily" id="starttime_daily" size="5" maxlength="5"  value=""> to <input type="text" name="endtime_daily" id="endtime_daily" size="5" maxlength="5" value=""> (Time 24hs.) (Note: Must Contain Start Time)
			<br>
			</td></tr>
			<tr><td>Duration:</td><td>Start Date: <input type="text" name="taskStartDateTime" size="12" maxlength="12" value=""> End Date: <input type="text" name="taskEndDateTime" size="12" maxlength="12" value=""> (Date Format DD/MM/YYYY)</td></tr>
			</table>
		</fieldset>
		<fieldset>
			<table>
			<tr><td>
            	<input type="hidden" name="url" value="<cfoutput>#tasksURL#</cfoutput>/tasks/cleanupInventoryData.cfm">
            	<input type="hidden" name="fAction" value="AddNewTask">
            </td></tr>
            <cfif session.IsAdmin IS true>
			<tr><td><input class="button medium gray" type="button" value="Cancel" onclick="window.location='admin_server_jobs.cfm'">
			<input class="button medium gray" type="button" value="Save" onclick="this.form.submit();"></td></tr>
            </cfif>
			</table>
		</fieldset>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>
<cfsavecontent variable="deleteInstallTypeTask">
  <nocfml><cfoutput>
	<hr>
	<div style="font-size:16px; margin-top:20px;">Add - Server Task</div>
    <cfform action="admin_server_jobs.cfm" method="Post" name="AddNewTask">
		<fieldset>
    	<legend>Server Task Schedule:</legend>
			<table border="0" class="tbltask">
			<tr><td>Task Name:</td><td><input type="text" name="taskName" size="40" maxlength="50" value="#form.TYPE#"></td></tr>
			<tr><td>Interval:</td>
			<td><input type="radio" name="runinterval" value="once"> One Time @ <input type="text" name="starttime_once" size="5" maxlength="5" value=""> (Time 24hs.)<br>
			<input type="radio" name="runinterval" value="recurring"> Recurring <select name="tasktype">
			<option value="" selected="true">- select -</option>
			<option value="DAILY">daily</option>
			<option value="WEEKLY">weekly</option>
			<option value="MONTHLY">monthly</option>
			</select> @ <input type="text" name="starttime_recurring" size="5" maxlength="5" value=""> (Time 24hs.)<br>
			<input type="radio" name="runinterval" value="daily"> Daily every <input type="text" name="interval" size="5" maxlength="5" value="" id="datepicker"> seconds from <input type="text" name="starttime_daily" id="starttime_daily" size="5" maxlength="5"  value=""> to <input type="text" name="endtime_daily" id="endtime_daily" size="5" maxlength="5" value=""> (Time 24hs.) (Note: Must Contain Start Time)
			<br>
			</td></tr>
			<tr><td>Duration:</td><td>Start Date: <input type="text" name="taskStartDateTime" size="12" maxlength="12" value=""> End Date: <input type="text" name="taskEndDateTime" size="12" maxlength="12" value=""> (Date Format DD/MM/YYYY)</td></tr>
			</table>
		</fieldset>
		<fieldset>
    	<legend>Server Task Action:</legend>
			Remove Installed Patches Data After <input type="text" name="actionVar" value="180" size="3"> days.<br>
			Archive Before Purge <input type="radio" name="actionVar" value="1" checked> Yes <input type="radio" name="actionVar" value="0"> No.
			<input type="hidden" name="actionVarName" value="days">
			<input type="hidden" name="actionVarName" value="archive">
		</fieldset>
		<fieldset>
			<table>
			<tr><td>
            	<input type="hidden" name="url" value="<cfoutput>#tasksURL#</cfoutput>/tasks/cleanupInstallData.cfm">
            	<input type="hidden" name="fAction" value="AddNewTask">
            </td></tr>
            <cfif session.IsAdmin IS true>
			<tr><td><input class="button medium gray" type="button" value="Cancel" onclick="window.location='admin_server_jobs.cfm'">
			<input class="button medium gray" type="button" value="Save" onclick="this.form.submit();"></td></tr>
            </cfif>
			</table>
		</fieldset>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>
</cfsilent>

<cfif #IsDefined("form.faction")#>
	<cfif form.faction EQ "AddNewTask" OR form.faction EQ "EditTask">
		<cfif ISDefined("form.actionVarName")>
			<cfif ListLen(form.actionVarName,",") GT 1>
				<cfset xURL = ListGetAt(form.actionVarName,1) &"="& ListGetAt(form.actionVar,1)>
				<cfloop index="x" from="2" to="#ListLen(form.actionVarName,",")#">
					<cfset xURL = "#xURL#&#ListGetAt(form.actionVarName,x)#=#ListGetAt(form.actionVar,x)#">
				</cfloop>
			<cfelseif ListLen(form.actionVarName,",") EQ 1>
				<cfset xURL = ListGetAt(form.actionVarName,1) &"="& ListGetAt(form.actionVar,1)>
			<cfelse>
				<cfset xURL = "">
			</cfif>
			<cfset theURL = "#ListGetAt(form.URL,1,'?')#?#xURL#">
		<cfelse>
			<cfset theURL = "#ListGetAt(form.URL,1,'?')#">
		</cfif>		
		<cfschedule
			action="UPDATE"
			task="#form.TASKNAME#"
			URL="#theURL#"
			interval="#form.TASKTYPE#"
			StartDate="#DateFormat(form.TASKSTARTDATETIME,"mm/dd/yyyy")#"
			StartTime="#TimeFormat(form.STARTTIME_RECURRING)#"
			ENDDATE="#DateFormat(form.TASKENDDATETIME,"mm/dd/yyyy")#"
			ENDTIME="#TimeFormat(form.STARTTIME_RECURRING)#"
			publish="NO"
			path=""
			file=""
			REQUESTTIMEOUT="1200"
			operation="HTTPRequest">
	</cfif>	
</cfif>

<div style="font-size:18px;">MacPatch Server Jobs</div>
<br>
<cfif session.IsAdmin IS true>
<form action="admin_server_jobs.cfm" method="Post" name="AddJob">
	Add New Task: <select name="Type" onchange="this.form.submit();">
		<option value="NA">...</option>
	    <cfloop list="#jobType#" delimiters="," index="_type">
	        <cfoutput>
		    <option value="#_type#">#_type#</option>
		    </cfoutput>
	    </cfloop>
	</select>
</form>
</cfif>
<hr>
<cfschedule action="listall" result="tasks"/>
<table class="genTable">
<THEAD>
<tr>
	<th>Task</th>
	<th>Interval</th>
	<th>Start Date/Time</th>
	<th>End Date/Time</th>
	<th>Edit</th>
    <th>Remove</th>
	<th>Run</th>
</tr>
</THEAD>
<TBODY>
<cfloop array="#tasks#" index="task">
<cfset tData = readTask(task)>
<tr>
	<td><cfoutput>#task#</cfoutput></td>
	<td><cfoutput>#tData["tasktype"]#@#TimeFormat(tData["starttime"],"HH:mm:ss")#</cfoutput></td>
	<td><cfoutput>#dateformat(tData["starttime"], "yyyy-mm-dd")# #TimeFormat(tData["starttime"], "HH:mm:ss")#</cfoutput></td>
	<td><cfoutput>#dateformat(tData["enddate"], "yyyy-mm-dd")#</cfoutput></td>
    <td align="center">
    	<a href="admin_server_jobs.cfm?task=<cfoutput>#URLEncodedFormat(task)#</cfoutput>&action=0" alt="Edit Task" title="Edit Task"><img src="/admin/images/<cfif session.IsAdmin IS true>icons/cog_edit<cfelse>info_16</cfif>.png"></a>
    </td>
    <td align="center">
		<cfif session.IsAdmin IS true>
        	<a href="admin_server_jobs.cfm?task=<cfoutput>#URLEncodedFormat(task)#</cfoutput>&action=1" alt="Remove Task" title="Remove Task"><img src="/admin/images/icons/cog_delete.png"></a>
        <cfelse>
        	<img class="dimImg" src="/admin/images/icons/cog_delete.png">
        </cfif>
    </td>
	<td align="center">
		<cfif session.IsAdmin IS true>
        	<a href="admin_server_jobs.cfm?task=<cfoutput>#URLEncodedFormat(task)#</cfoutput>&action=2" alt="Run Task" title="Run Task"><img src="/admin/images/icons/control_play_blue.png" border="0" width="16" height="16" /></a>
        <cfelse>
        	<img class="dimImg" src="/admin/images/icons/control_play_blue.png" border="0" width="16" height="16" />
        </cfif>
    </td>
</tr>
</cfloop>
</TBODY>
</table>
<!--- ArrayLen(tasks) GTE 1 AND --->
<cfif isDefined("taskName") AND Len(taskName) GT 1>
	<cfsilent>
    <cfschedule action="read" task="#taskName#" result="taskdata"/>
    <cfsavecontent variable="editTypeTask">
      <nocfml><cfoutput>
      	<cfif #taskdata["tasktype"]# EQ "ONCE">
      		<cfset _type = 1>
        <cfelseif #taskdata["tasktype"]# EQ "DAILY">
        	<cfset _type = 2>
        <cfelseif #taskdata["tasktype"]# EQ "WEEKLY">
        	<cfset _type = 2>   
        <cfelseif #taskdata["tasktype"]# EQ "MONTHLY">
        	<cfset _type = 2>       
        <cfelse>
        	<cfset _type = 3>    
        </cfif>    
        <hr>
        <div style="font-size:16px; margin-top:20px;">Add - Server Task</div>
        <cfform action="admin_server_jobs.cfm" method="Post" name="EditNewTask">
            <fieldset>
            <legend>Server Task Schedule:</legend>
                <table border="0" class="tbltask">
                <tr><td>Task Name:</td><td><input type="text" name="taskName" size="40" maxlength="50" value="#taskdata["task"]#"></td></tr>
                <tr><td>Interval:</td>
                <td><input type="radio" name="runinterval" value="once" #IIF(_type EQ 1, DE("checked='checked'"), DE(""))#> One Time @ <input type="text" name="starttime_once" size="5" maxlength="5" value="#IIF(_type EQ 1, DE(TimeFormat(taskdata["starttime"], "HH:mm:ss")), DE(""))#"> (Time 24hs.)<br>
                <input type="radio" name="runinterval" value="recurring" #IIF(_type EQ 2, DE("checked='checked'"), DE(""))#> Recurring <select name="tasktype">
                <option value="DAILY" #IIF(taskdata["tasktype"] EQ "DAILY", DE("selected='true'"), DE(""))#>daily</option>
                <option value="WEEKLY" #IIF(taskdata["tasktype"] EQ "WEEKLY", DE("selected='true'"), DE(""))#>weekly</option>
                <option value="MONTHLY" #IIF(taskdata["tasktype"] EQ "MONTHLY", DE("selected='true'"), DE(""))#>monthly</option>
                </select> @ <input type="text" name="starttime_recurring" size="5" maxlength="5" value="#IIF(_type EQ 2, DE(TimeFormat(taskdata["starttime"], "HH:mm:ss")), DE(""))#"> (Time 24hs.)<br>
                <input type="radio" name="runinterval" value="daily" #IIF(_type EQ 3, DE("checked='checked'"), DE(""))#> Daily every <input type="text" name="interval" size="5" maxlength="5" value="#IIF(taskdata["tasktype"] EQ "INTERVAL",DE(taskdata["interval"]),DE(""))#"> seconds from <input type="text" name="starttime_daily" id="starttime_daily" size="5" maxlength="5"  value="#IIF(taskdata["tasktype"] EQ "INTERVAL",DE(TimeFormat(taskdata["starttime"], "HH:mm")),DE(""))#"> to <input type="text" name="endtime_daily" id="endtime_daily" size="5" maxlength="5" value="<cfif StructKeyExists(taskdata, "endtime")>#IIF(taskdata["tasktype"] EQ "INTERVAL",DE(TimeFormat(taskdata["endtime"], "HH:mm")),DE(""))#</cfif>"> (Time 24hs.) (Note: Must Contain Start Time)
                <br>
                </td></tr>
                <tr><td>Duration:</td><td>Start Date: <input type="text" name="taskStartDateTime" size="12" maxlength="12" value="#DateFormat(taskdata["startdate"], "mm/dd/yyyy")#"> End Date: <input type="text" name="taskEndDateTime" size="12" maxlength="12" value="#DateFormat(taskdata["enddate"], "mm/dd/yyyy")#"> (Date Format DD/MM/YYYY)</td></tr>
                </table>
            </fieldset>
			<cfif taskName EQ "delete expired clients">	
            <fieldset>
            <legend>Server Task Action:</legend>
                Remove clients after <input type="text" name="actionVar" value="#getParamsFromUrlString(taskdata["url"])["days"]#" size="3"> days of inactivity.
				<input type="hidden" name="actionVarName" value="days">
            </fieldset>
			</cfif>
			<cfif taskName EQ "Purge and Archive Install Data">	
            <fieldset>
            <legend>Server Task Action:</legend>
				<cftry>
				Remove Installed Patches Data After <input type="text" name="actionVar" value="#getParamsFromUrlString(taskdata["url"])["days"]#" size="3"><input type="hidden" name="actionVarName" value="days"> days.<br>
				Archive Before Purge <input type="radio" name="actionVar" value="1" #IIF(getParamsFromUrlString(taskdata["url"])["archive"] EQ 1, DE("checked='checked'"), DE(""))#> Yes 
				<input type="radio" name="actionVar" value="0" #IIF(getParamsFromUrlString(taskdata["url"])["archive"] EQ 0, DE("checked='checked'"), DE(""))#> No.
				<input type="hidden" name="actionVarName" value="archive">
				<cfcatch></cfcatch>
				</cftry>
            </fieldset>
			</cfif>
            <cfif session.IsAdmin IS true>
            <fieldset>
                <table>
                <tr><td>
                    <input type="hidden" name="url" value="#taskdata["url"]#">
					<input type="hidden" name="fAction" value="EditTask">
                </td></tr>
                <tr><td><input class="button medium gray" type="button" value="Cancel" onclick="window.location='admin_server_jobs.cfm'">
                <input class="button medium gray" type="button" value="Save" onclick="this.form.submit();"></td></tr>
                </table>
            </fieldset>
            </cfif>
        </cfform>
      </cfoutput></nocfml>	
    </cfsavecontent>
    </cfsilent>
	<cfoutput>#render(editTypeTask)#</cfoutput>

</cfif>

<cfif isDefined("Type")>
<cfif Type EQ "Delete Expired Clients">
<cfoutput>#render(deleteTypeTask)#</cfoutput>
</cfif>
<cfif Type EQ "Purge Old Client Data">
<cfoutput>#render(purgeTypeTask)#</cfoutput>
</cfif>
<cfif Type EQ "Purge and Archive Install Data">
<cfoutput>#render(deleteInstallTypeTask)#</cfoutput>
</cfif>
</cfif>

<cffunction name="readTask" access="public" returntype="any" output="yes">
	<cfargument name="taskName">
	<cfschedule action="read" task="#arguments.taskName#" result="taskdata"/>
	<cfreturn taskdata>
</cffunction>

<cffunction name="getParamsFromUrlString" returntype="Struct" output="no">
    <cfargument name="UrlString" type="String" required />
    <cfargument name="Separator" type="String" default="?" />
    <cfargument name="Delimiter" type="String" default="&" />
    <cfargument name="AssignOp"  type="String" default="=" />
    <cfargument name="EmptyVars" type="String" default="" />

    <cfset var QueryString = ListRest( ListFirst( Arguments.UrlString , '##' ) , Arguments.Separator ) />
    <cfset var Result = {} />

    <cfloop index="QueryPiece" list="#QueryString#" delimiters="#Arguments.Delimiter#">

        <cfif NOT find(Arguments.AssignOp,QueryPiece)>
            <cfset Result[ UrlDecode( QueryPiece ) ] = Arguments.EmptyVars />
        <cfelse>
            <cfset Result[ UrlDecode( ListFirst(QueryPiece, Arguments.AssignOp) )] = UrlDecode( ListRest(QueryPiece,Arguments.AssignOp) ) />
        </cfif>
    </cfloop>

    <cfreturn Result />
</cffunction>
