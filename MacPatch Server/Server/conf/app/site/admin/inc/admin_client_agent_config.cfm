<!---
<cfif isDefined("url.action")>
	<cfif url.action EQ "4">
    	<cfset form.fAction = "EditConfig">
        <cfset form.config = #url.config#>
    </cfif>
</cfif>


<cfif url.action EQ "0" OR url.action EQ "1" OR url.action EQ "2" OR url.action EQ "3">
    <cfinclude template="./includes/admin/_command.cfm">
<cfelse>
    <cfinclude template="./includes/admin/admin_agent_config.cfm">
</cfif>
--->
<cfif isDefined("form.fAction")>
	<cfif form.fAction EQ "NewConfig">
    	<cfset args = StructNew() />
    	<cfset args.action = 0>
    	<cfinclude template="_command.cfm">
    	<cfabort>
	</cfif>
    <cfif form.fAction EQ "EditConfig">
    	<cfset args = StructNew() />
    	<cfset args.action = 1>
    	<cfinclude template="_command.cfm">
    	<cfabort>
	</cfif>
    <cfif form.fAction EQ "EditConfig">
    	<cfset args = StructNew() />
    	<cfset args.action = 1>
    	<cfinclude template="_command.cfm">
    	<cfabort>
	</cfif>
</cfif>

<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
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
	width:500px;
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
	<cfquery name="getConfig" datasource="#session.dbsource#">
		Select * from mp_agent_config
	</cfquery>
</cfsilent>

<cfsilent>
<cfsavecontent variable="newConfig">
  <nocfml><cfoutput>
	<hr>
	<div style="font-size:16px; margin-top:20px;">New - Agent Config</div>
    <cfform action="#CGI.SCRIPT_NAME#&action=0" method="Post" name="AddNewAgentConfig">
		<fieldset>
    	<legend>Config Name:</legend>
			<table border="0" class="tbltask">
			<tr><td>Name:</td><td><input type="text" name="name" size="40" maxlength="50" value=""></td></tr>
			</table>
		</fieldset>
		<fieldset>
    	<legend>Config Properties:</legend>
			<table border="0" class="tbltask">
			<tr><td>AllowClient:</td><td><input type="text" name="p_AllowClient" size="40" maxlength="255" value="1"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Patch Mac OS X Client Software</td></tr>
			<tr><td>AllowServer:</td><td><input type="text" name="p_AllowServer" size="40" maxlength="255" value="0"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Patch Mac OS X Server Software</td></tr>
			<tr><td>Description:</td><td><input type="text" name="p_Description" size="40" maxlength="255" value="Default"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Description Text</td></tr>
			<tr><td>Domain:</td><td><input type="text" name="p_Domain" size="40" maxlength="255" value="Default"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Client Group Name</td></tr>
            <tr><td>CheckSignatures:</td><td><input type="text" name="p_CheckSignatures" size="40" maxlength="255" value="0"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">CheckSignatures</td></tr>
			<tr><td>PatchGroup:</td><td><input type="text" name="p_PatchGroup" size="40" maxlength="255" value="RecommendedPatches"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Patch Group Name</td></tr>
			<tr><td>Reboot:</td><td><input type="text" name="p_Reboot" size="40" maxlength="255" value="1"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Allow reboot with no users logged in.</td></tr>
			<tr><td>SWDistGroup:</td><td><input type="text" name="p_SWDistGroup" size="40" maxlength="255" value="Default"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Default Software Distirbution Group</td></tr>
			<tr><td>MPProxyEnabled:</td><td><input type="text" name="p_MPProxyEnabled" size="40" maxlength="255" value="1"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Enable MP Proxy Server Support</td></tr>
			<tr><td>MPProxyServerAddress:</td><td><input type="text" name="p_MPProxyServerAddress" size="40" maxlength="255" value="AUTOFILL" readonly></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">MPProxy Server Address</td></tr>
			<tr><td>MPProxyServerPort:</td><td><input type="text" name="p_MPProxyServerPort" size="40" maxlength="255" value="2600"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">MPProxy Server Port</td></tr>
			<tr><td>MPServerAddress:</td><td><input type="text" name="p_MPServerAddress" size="40" maxlength="255" value="AUTOFILL" readonly></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">MacPatch master server address</td></tr>
			<tr><td>MPServerPort:</td><td><input type="text" name="p_MPServerPort" size="40" maxlength="255" value="2600"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">MP Master Server Port</td></tr>
			<tr><td>MPServerSSL:</td><td><input type="text" name="p_MPServerSSL" size="40" maxlength="255" value="1"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Use SSL for client connection</td></tr>
			<tr><td>MPServerAllowSelfSigned:</td><td><input type="text" name="p_MPServerAllowSelfSigned" size="40" maxlength="255" value="0"></td><td>Enforced: <select name="enforced"><option value="1">Yes</option><option value="0" selected>No</option></select></td><td style="padding-left:60px;">Allow Self Signed Certificate. Use if server is IP based.</td></tr>
			</table>
		</fieldset>
		<fieldset>
			<table>
			<tr><td>
				<input type="hidden" name="fAction" value="NewConfig">
                <cfif session.IsAdmin IS true>
				<input class="button medium gray" type="button" value="Cancel" onclick="location.href='#CGI.SCRIPT_NAME#';return false;">
				<input class="button medium gray" type="button" value="Save" onclick="this.form.submit();">
                </cfif>
			</td></tr>
			</table>
		</fieldset>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>
<cfsavecontent variable="editConfig">
  <nocfml><cfoutput>
	<hr>
	<div style="font-size:16px; margin-top:20px;">Edit - Agent Config</div>
    <cfform action="#CGI.SCRIPT_NAME#&action=1" method="Post" name="EditAgentConfig">
		<fieldset>
    	<legend>Config Name:</legend>
			<table border="0" class="tbltask">
			<tr><td>Name:</td><td><input type="text" name="name" size="40" maxlength="50" value="#qReadConfig.name#" readonly></td></tr>
			</table>
		</fieldset>
		<fieldset>
    	<legend>Config Properties:</legend>
			<table border="0" class="tbltask">
			<tr><td>AllowClient:</td><td><input type="text" name="p_AllowClient" size="40" maxlength="255" value="#configData.AllowClient.value#"></td><td>Enforced: #SelectFormOption(configData.AllowClient.enforced)#</td><td style="padding-left:60px;">Patch Mac OS X Client Software</td></tr>
			<tr><td>AllowServer:</td><td><input type="text" name="p_AllowServer" size="40" maxlength="255" value="#configData.AllowServer.value#"></td><td>Enforced: #SelectFormOption(configData.AllowServer.enforced)#</td><td style="padding-left:60px;">Patch Mac OS X Server Software</td></tr>			
			<tr><td>Description:</td><td><input type="text" name="p_Description" size="40" maxlength="255" value="#configData.Description.value#"></td><td>Enforced: #SelectFormOption(configData.Description.enforced)#</td><td style="padding-left:60px;">Description Text</td></tr>
			<tr><td>Domain:</td><td><input type="text" name="p_Domain" size="40" maxlength="255" value="#configData.Domain.value#"></td><td>Enforced: #SelectFormOption(configData.Domain.enforced)#</td><td style="padding-left:60px;">Client Group Name</td></tr>
			<tr><td>CheckSignatures:</td><td><input type="text" name="p_CheckSignatures" size="40" maxlength="255" value="#IIF(IsDefined("configData.CheckSignatures"),Evaluate(DE("configData.CheckSignatures.value")),DE(''))#"></td><td>Enforced: #SelectFormOption(IIF(IsDefined("configData.CheckSignatures"),Evaluate(DE("configData.CheckSignatures.enforced")),DE('')))#</td><td style="padding-left:60px;">CheckSignatures</td></tr>
            <tr><td>PatchGroup:</td><td><input type="text" name="p_PatchGroup" size="40" maxlength="255" value="#configData.PatchGroup.value#"></td><td>Enforced: #SelectFormOption(configData.PatchGroup.enforced)#</td><td style="padding-left:60px;">Patch Group Name</td></tr>
			<tr><td>Reboot:</td><td><input type="text" name="p_Reboot" size="40" maxlength="255" value="#configData.Reboot.value#"></td><td>Enforced: #SelectFormOption(configData.Reboot.enforced)#</td><td style="padding-left:60px;">Allow reboot with no users logged in.</td></tr>
			<tr><td>SWDistGroup:</td><td><input type="text" name="p_SWDistGroup" size="40" maxlength="255" value="#configData.SWDistGroup.value#"></td><td>Enforced: #SelectFormOption(configData.SWDistGroup.enforced)#</td><td style="padding-left:60px;">Default Software Distirbution Group</td></tr>
			<tr><td>MPProxyEnabled:</td><td><input type="text" name="p_MPProxyEnabled" size="40" maxlength="255" value="#configData.MPProxyEnabled.value#"></td><td>Enforced: #SelectFormOption(configData.MPProxyEnabled.enforced)#</td><td style="padding-left:60px;">Enable MP Proxy Server Support</td></tr>
			<tr><td>MPProxyServerAddress:</td><td><input type="text" name="p_MPProxyServerAddress" size="40" maxlength="255" value="#configData.MPProxyServerAddress.value#" readonly></td><td>Enforced: #SelectFormOption(configData.MPProxyServerAddress.enforced)#</td><td style="padding-left:60px;">MPProxy Server Address</td></tr>
			<tr><td>MPProxyServerPort:</td><td><input type="text" name="p_MPProxyServerPort" size="40" maxlength="255" value="#configData.MPProxyServerPort.value#"></td><td>Enforced: #SelectFormOption(configData.MPProxyServerPort.enforced)#</td><td style="padding-left:60px;">MPProxy Server Port</td></tr>
			<tr><td>MPServerAddress:</td><td><input type="text" name="p_MPServerAddress" size="40" maxlength="255" value="#configData.MPServerAddress.value#" readonly></td><td>Enforced: #SelectFormOption(configData.MPServerAddress.enforced)#</td><td style="padding-left:60px;">MacPatch master server address</td></tr>
			<tr><td>MPServerPort:</td><td><input type="text" name="p_MPServerPort" size="40" maxlength="255" value="#configData.MPServerPort.value#"></td><td>Enforced: #SelectFormOption(configData.MPServerPort.enforced)#</td><td style="padding-left:60px;">MP Master Server Port</td></tr>
			<tr><td>MPServerSSL:</td><td><input type="text" name="p_MPServerSSL" size="40" maxlength="255" value="#configData.MPServerSSL.value#"></td><td>Enforced: #SelectFormOption(configData.MPServerSSL.enforced)#</td><td style="padding-left:60px;">Use SSL for client connection</td></tr>
			<tr><td>MPServerAllowSelfSigned:</td><td><input type="text" name="p_MPServerAllowSelfSigned" size="40" maxlength="255" value="#configData.MPServerAllowSelfSigned.value#"></td><td>Enforced: #SelectFormOption(configData.MPServerAllowSelfSigned.enforced)#</td><td style="padding-left:60px;">Allow Self Signed Certificate. Use if server is IP based.</td></tr>
			</table>
		</fieldset>
			<div style="margin-top:20px;">
			<table>
			<tr><td>
				<input type="hidden" name="fAction" value="EditConfig">
				<input type="hidden" name="config" value="#url.config#">
                <cfif session.IsAdmin IS true>
				<input class="button medium gray" type="button" value="Cancel" onclick="location.href='#CGI.SCRIPT_NAME#';return false;">
				<input class="button medium gray" type="button" value="Save" onclick="this.form.submit();">
                </cfif>
			</td></tr>
			</table>
			</div>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>
</cfsilent>

<script type="text/Javascript">
	function defaultConfig(id)
	{
		var retVal = confirm("Are you sure you want to make this config the default?");
		if( retVal == true ) {
			//window.location = 'admin_client_agent_config.cfm?action=3&config='+id;
			window.location = '_command.cfm?action=3&config='+id;
		}
	}
	function editIt(id)
	{
		window.location = 'admin_client_agent_config.cfm?action=4&config='+id;
	}
	function delIt(id)
	{
		var retVal = confirm("Are you sure you want to delete this config?");
		if( retVal == true ) {
			window.location = '_command.cfm?action=2&config='+id;
		}
	}
</script>

<div style="font-size:18px;">MacPatch Agent Configuration</div>

<br>
<form action="" method="Post" name="AddConfig">
	<cfif session.IsAdmin IS true>
	<input type="hidden" name="fAction" value="AddConfig">
	<input type="button" name="btnAddConfig" id="btnAddConfig" value="Create New Agent Config" onclick="this.form.submit();" />
    </cfif>
</form>
<hr>
<table class="genTable">
<THEAD>
<tr>
	<th>Name</th>
	<th>Default</th>
	<th>Edit</th>
    <th>Remove</th>
</tr>
</THEAD>
<TBODY>
<cfoutput query="getConfig">
<tr>
	<td>#name#</td>
	<td align="center">
		<cfif isDefault EQ 0>
        	<img <cfif session.IsAdmin IS false>class='dimImg'</cfif> src="/admin/images/icons/table_gear.png" <cfif session.IsAdmin IS true>onclick="defaultConfig('#aid#');"</cfif> title="Make Default Config" />
        <cfelse>
        	<img src="/admin/images/icons/bullet_green.png" title="Config is Default">
        </cfif>
    </td>
    <td align="center"><img src="/admin/images/<cfif session.IsAdmin IS false>info_16<cfelse>icons/cog_edit</cfif>.png" onclick="editIt('#aid#');"  title="Edit Config" /></td>
    <td align="center"><img <cfif session.IsAdmin IS false>class='dimImg'</cfif> src="/admin/images/icons/cog_delete.png" <cfif session.IsAdmin IS true>onclick="delIt('#aid#');"</cfif> title="Delete Config" /></td>
</tr>
</cfoutput>
</TBODY>
</table>

<cfif isDefined("form.fAction")>
	<cfif form.fAction EQ "AddConfig">
		<cfoutput>#render(newConfig)#</cfoutput>
	</cfif>
	<cfif form.fAction EQ "EditConfig">
		<cfquery datasource="#session.dbsource#" name="qReadConfig">
			Select * from mp_agent_config
			Where aid = '#form.config#'
		</cfquery>
		<cfquery datasource="#session.dbsource#" name="qReadConfigData">
			Select * from mp_agent_config_data
			Where aid = '#form.config#'
		</cfquery>
		<cfoutput>#render(editConfig)#</cfoutput>
	</cfif>
</cfif>

<cfif isDefined("url.action")>
	<cfif url.action eq "4">
		<cfquery datasource="#session.dbsource#" name="qReadConfig">
			Select * from mp_agent_config
			Where aid = '#url.config#'
		</cfquery>
		<cfquery datasource="#session.dbsource#" name="qReadConfigData">
			Select aKey, aKeyValue, enforced from mp_agent_config_data
			Where aid = '#url.config#'
		</cfquery>
		<cfset configData = #QueryToStruct(qReadConfigData)#>
		<cfoutput>#render(editConfig)#</cfoutput>
	</cfif>
</cfif>

<cffunction name="QueryToStruct" access="public" returntype="any" output="true">
	<!--- Define arguments. --->
	<cfargument name="Query" type="query" required="true" />

	<cfset local = StructNew()>
	<cfloop query="qReadConfigData">
		<cfset row = StructNew()>
		<cfset row["value"] = aKeyValue>
		<cfset row["enforced"] = enforced>
		<cfset local[akey] = row>
	</cfloop>
	<cfreturn local>
</cffunction>

<cffunction name="SelectFormOption" access="public" returntype="any" output="false">
	<!--- Define arguments. --->
	<cfargument name="fieldName" type="string" required="true" />
	
	<cftry>
		<cfsavecontent variable="editConfigSelect">
			<cfoutput>
			<select name="enforced">
					<option value="1" #IIF(arguments.fieldName EQ 1 ,DE('selected'),DE(''))#>Yes</option>
					<option value="0" #IIF(arguments.fieldName EQ 0 ,DE('selected'),DE(''))#>No</option>
			</select>
			</cfoutput>
		</cfsavecontent>
	<cfcatch>
		<cfsavecontent variable="editConfigSelect">
			<cfoutput>
			<select name="enforced">
					<option value="1" >Yes</option>
					<option value="0" selected>No</option>
			</select>
			</cfoutput>
		</cfsavecontent>
	</cfcatch>
	</cftry>
	<cfreturn editConfigSelect>
</cffunction>