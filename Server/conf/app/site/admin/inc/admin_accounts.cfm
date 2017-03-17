<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>

<cfif NOT IsDefined("url.action")>
	<cfset uaction = "list">
<cfelse>
    <cfset uaction = "#decrypt(url.action,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">
</cfif>
<cfswitch expression="#uaction#"> 
    <cfcase value="list"> 
        <cfset session.adm_mp_accounts = "0">
    </cfcase> 
    <cfcase value="add"> 
        <cfset session.adm_mp_accounts = "1">
    </cfcase> 
    <cfcase value="submitAdd"> 
        <cfset session.adm_mp_accounts = "11">
    </cfcase> 
    <cfcase value="edit"> 
        <cfset editUserID = url.u>
        <cfset session.adm_mp_accounts = "2">
    </cfcase>
    <cfcase value="submitEdit"> 
        <cfset session.adm_mp_accounts = "21">
    </cfcase> 
    <cfcase value="delete"> 
        <cfset session.adm_mp_accounts = "3">
    </cfcase>
    <cfdefaultcase> 
        <cfset session.adm_mp_accounts = "0">
    </cfdefaultcase>
</cfswitch> 

<cfif IsDefined("session.adm_mp_account_msg")>
	<cfif session.adm_mp_account_msg NEQ "">
		<h4 style="color:red;">Error: <cfoutput>#session.adm_mp_account_msg#</cfoutput></h4>
		<cfset session.adm_mp_account_msg = "">
		<br>
	</cfif>
</cfif>
<script type="text/Javascript">
function checkPassword(form)
{
	if (document.forms[0] == document.forms["eusr"]) {
		form.submit();
	}
    else if (document.forms[0].user_pass1.value.length < 6 )
    {
        alert("Password must be at least 6 characters long!");
        document.forms[0].user_pass1.focus();
        return false;
    }
    else if (document.forms[0].user_pass2.value != document.forms[0].user_pass1.value)
    {
       alert("Passwords do not match! Please re-enter the password.");
       document.form[0].user_pass2.focus();
       return false;
    }
    else
    {
        form.submit();
    }
}
</script>

<cfif session.adm_mp_accounts EQ "0">

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'admin_accounts.cfc?method=getMPAccounts', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','User ID', 'User Type', 'Group', 'Last Login Date', 'Number of Logins', 'Enabled', 'Email', 'Email Notify'],
				colModel :[ 
				  {name:'rid',index:'rid', width:30, align:"center", sortable:false, hidden:true},
				  {name:'user_id', index:'user_id', width:100}, 
				  {name:'user_type', index:'user_type', width:40},
				  {name:'group_id', index:'group_id', width:40, sorttype:'float'},
				  {name:'last_login', index:'last_login', width:70, align:"center"}, 
				  {name:'number_of_logins', index:'number_of_logins', width:70, align:"center"},
				  {name:'enabled', index:'enabled', width:70, align:"center"},
				  {name:'email', index:'email', width:70, align:"center"},
				  {name:'notify', index:'notify', width:70, align:"center"}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'User Accounts', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"admin_accounts.cfc?method=addEditMPAccounts",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				jsonReader: {
					total: "total",
					page: "page",
					records:"records",
					root: "rows",
					userdata: "userdata",
					cell: "",
					id: "0"
					}
				}
			);
			<cfif session.IsAdmin IS true>
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:true})
			
			.navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-plus", 
			   title:"New Account",
			   onClickButton: function(){ 
				 load('admin_accounts.cfm?adm_mp_accounts&action=<cfoutput>#encrypt('add',session.usrKey,'AES/CBC/PKCS5Padding','base64')#</cfoutput>');
			   }
			})
			.navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-pencil", 
			   title:"Edit Account",
			   onClickButton: function(){ 
			   	var grid = $("#list");
          		var rowid = grid.jqGrid('getGridParam', 'selrow');
          		if (rowid) { 
					load('admin_accounts.cfm?adm_mp_accounts&action=<cfoutput>#encrypt('edit',session.usrKey,'AES/CBC/PKCS5Padding','base64')#</cfoutput>&u='+rowid);
          		}
			   }, 
			   position:"last"
			});
			<cfelse>
				$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false});
			</cfif>
			
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true, defaultSearch: 'cn'});
			mygrid[0].toggleToolbar();
			
			$(window).bind('resize', function() {
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');
		});
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager"></div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
</cfif>
<cfif session.adm_mp_accounts GTE "1">
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
<cfsavecontent variable="newConfig">
  <nocfml><cfoutput>
	<div style="font-size:16px; margin-top:20px;">Create Account</div>
    <cfform action="admin_accounts.cfm?adm_mp_accounts&action=#encrypt('submitAdd',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" method="Post" name="AddNewUser">
		<fieldset>
    	<legend>New Account (Local Account):</legend>
			<table border="0" class="tbltask">
			<tr><td>User ID (Login ID):</td><td><input type="text" name="user_id" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>User Name:</td><td><input type="text" name="user_RealName" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>Email Address:</td><td><input type="text" name="user_email" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>Password:</td><td><input type="password" name="user_pass1" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>Password:</td><td><input type="password" name="user_pass2" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>Group:</td><td><select name="group">
				<option value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" selected>User</option>
				</select></td></tr>
			<tr>
				<td>Rights</td>
				<td>
					<table width="500">
    					<tr>
    						<th>Autopkg</th><th>Admin</th><th>Agent Upload</th><th>API Access</th>
    					</tr>
    					<tr>
    						<td>
    							<input type="radio" name="rautopkg" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"> Yes
    							<input type="radio" name="rautopkg" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" checked> No
    						</td>
    						<td>
    							<input type="radio" name="radmin" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"> Yes
    							<input type="radio" name="radmin" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" checked> No
    						</td>
    						<td>
    							<input type="radio" name="ragentupload" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"> Yes
    							<input type="radio" name="ragentupload" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" checked> No
    						</td>
    						<td>
    							<input type="radio" name="rapi" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"> Yes
    							<input type="radio" name="rapi" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" checked> No
    						</td>
    					</tr>
    				</table>
    			</td>
    		</tr>
			<tr><td>Enabled:</td><td><select name="enabled">
				<option value="1">Yes</option>
				<option value="0" selected>No</option>
				</select></td></tr>	
			<tr><td>Email Notifications:</td><td><select name="email_notification">
				<option value="1">Yes</option>
				<option value="0" selected>No</option>
				</select></td></tr>	
			</table>
		</fieldset>
		<fieldset>
			<table>
			<tr><td>
				<input class="button medium gray" type="button" value="Cancel" onclick="load('admin_accounts.cfm');">
				<input class="button medium gray" type="button" value="Save" onclick="return checkPassword(this.form);">
			</td></tr>
			</table>
		</fieldset>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>

<cfsavecontent variable="editConfig">
  <nocfml><cfoutput>
  <cfswitch expression="#accountData.user_type#">
		<cfcase value="0">
			<cfset _usrType = "Global Admin" />
			<cfset _usrNo = "0" />
		</cfcase>
		<cfcase value="1">
			<cfset _usrType = "Local Account" />
			<cfset _usrNo = "1" />
		</cfcase>
		<cfcase value="2">
			<cfset _usrType = "Directory Account" />
			<cfset _usrNo = "2" />
		</cfcase>
		<cfdefaultcase>
			<cfset _usrType = "Local Account" />
			<cfset _usrNo = "1" />
		</cfdefaultcase>
	</cfswitch>
	<div style="font-size:16px; margin-top:20px;">Edit Accounts</div>
    <cfform action="admin_accounts.cfm?adm_mp_accounts&action=#encrypt('submitEdit',session.usrKey,'AES/CBC/PKCS5Padding','base64')#" method="Post" name="eusr">
		<fieldset>
    	<legend>Account (#_usrType#):</legend>
			<table border="0" class="tbltask">
			<tr><td>User ID (Login ID):</td><td><input type="text" name="user_id" size="40" maxlength="255" value="#accountData.user_id#" readonly></td></tr>
			<tr><td>User Name:</td><td><input type="text" name="user_RealName" size="40" maxlength="255" value="#accountData.user_RealName#" autocomplete="off"></td></tr>
			<tr><td>Email Address:</td><td><input type="text" name="user_email" size="40" maxlength="255" value="#accountData.user_email#" autocomplete="off"></td></tr>
			<cfif _usrNo EQ 1>
			<tr><td>Old Password:</td><td><input type="password" name="user_pass0" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>Password:</td><td><input type="password" name="user_pass1" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			<tr><td>Password:</td><td><input type="password" name="user_pass2" size="40" maxlength="255" value="" autocomplete="off"></td></tr>
			</cfif>
			<tr><td>Group:</td><td>
				<select name="group">
					<option value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountData.group_id EQ "1"> selected</cfif>>User</option>
				</select></td></tr>
			<tr>
				<td>Rights</td>
				<td>
    				<table width="500">
    					<tr>
    						<th>Autopkg</th><th>Admin</th><th>Agent Upload</th><th>API Access</th>
    					</tr>
    					<tr>
    						<td>
    							<input type="radio" name="rautopkg" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.autopkg EQ "1"> checked</cfif>> Yes
    							<input type="radio" name="rautopkg" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.autopkg NEQ "1"> checked</cfif>> No
    						</td>
    						<td>
    							<input type="radio" name="radmin" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.admin EQ "1"> checked</cfif>> Yes
    							<input type="radio" name="radmin" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.admin NEQ "1"> checked</cfif>> No
    						</td>
    						<td>
    							<input type="radio" name="ragentupload" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.agentUpload EQ "1"> checked</cfif>> Yes
    							<input type="radio" name="ragentupload" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.agentUpload NEQ "1"> checked</cfif>> No
    						</td>
    						<td>
    							<input type="radio" name="rapi" value="#encrypt('1',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.apiAccess EQ "1"> checked</cfif>> Yes
    							<input type="radio" name="rapi" value="#encrypt('0',session.usrKey,'AES/CBC/PKCS5Padding','base64')#"<cfif accountDataAlt.apiAccess NEQ "1"> checked</cfif>> No
    						</td>
    					</tr>
    				</table>
    			</td>
    		</tr>
			<tr><td>Enabled:</td><td><select name="enabled">
				<option value="1"<cfif accountData.enabled EQ "1"> selected</cfif>>Yes</option>
				<option value="0"<cfif accountData.enabled EQ "0"> selected</cfif>>No</option>
				</select></td></tr>	
			<tr><td>Email Notification:</td><td><select name="email_notification">
				<option value="1"<cfif accountData.email_notification EQ "1"> selected</cfif>>Yes</option>
				<option value="0"<cfif accountData.email_notification EQ "0"> selected</cfif>>No</option>
				</select></td></tr>	
			</table>
		</fieldset>
		<fieldset>
			<table>
			<tr><td>
				<input type="hidden" name="rid" value="#editUserID#">
				<input class="button medium gray" type="button" value="Cancel" onclick="load('admin_accounts.cfm');">
				<input class="button medium gray" type="button" value="Save" onclick="return checkPassword(this.form);">
			</td></tr>
			</table>
		</fieldset>
	</cfform>
  </cfoutput></nocfml>	
</cfsavecontent>
</cfsilent>
</cfif>

<cfif session.adm_mp_accounts EQ "1">
	<cfoutput>#render(newConfig)#</cfoutput>
</cfif>	

<cfif session.adm_mp_accounts EQ "2">
	<cfsilent>
		<cfquery name="accountData" datasource="#session.dbsource#">
			Select b.rid, b.group_id, b.user_id, b.user_type, a.user_RealName, b.enabled, b.user_email, b.email_notification
			from mp_adm_group_users b
			LEFT Join mp_adm_users a ON a.user_id = b.user_id
			Where b.rid = '#editUserID#'
		</cfquery>

		<cfquery name="accountDataAlt" datasource="#session.dbsource#">
			Select a.admin, a.autopkg, a.agentUpload, a.apiAccess 
			from mp_adm_users_info a
			LEFT Join mp_adm_group_users b ON a.user_id = b.user_id
			Where b.rid = <cfqueryparam value="#editUserID#">
		</cfquery>

	</cfsilent>
	<cfif accountData.RecordCount EQ "1">
		<cfif accountData.user_type EQ "0">
			<cfset session.adm_mp_account_msg = "Can not edit ""Local"" user type.">
			<cflocation url="#session.cflocFix#/admin/inc/admin_accounts.cfm">
			<cfabort>
		</cfif>
	</cfif>
	<cfoutput>#render(editConfig)#</cfoutput>
</cfif>	

<cfif session.adm_mp_accounts EQ "11">
	<cftry>
		<cfquery datasource="#session.dbsource#" name="addAccount">
			Insert Into mp_adm_users (user_id, user_RealName, user_pass, enabled)
			Values (<cfqueryparam value="#form.USER_ID#">,<cfqueryparam value="#form.USER_REALNAME#">,<cfqueryparam value="#hash(form.USER_PASS1,'MD5')#">,<cfqueryparam value="#form.Enabled#">)
		</cfquery>	
		<cfquery datasource="#session.dbsource#" name="addAccountGroup">
			Insert Into mp_adm_group_users (group_id, user_id, user_type, number_of_logins, enabled, user_email, email_notification)
			Values (<cfqueryparam value="#decrypt(form.GROUP,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,<cfqueryparam value="#form.USER_ID#">,'1','0',<cfqueryparam value="#form.Enabled#">,
				<cfqueryparam value="#form.user_email#">, <cfqueryparam value="#form.email_notification#">)
		</cfquery>
		<cfquery datasource="#session.dbsource#" name="addAccountGroup">
			Insert Into mp_adm_users_info (user_id, user_type, number_of_logins, enabled, user_email, email_notification, admin, autopkg, agentUpload, apiAccess)
			Values (<cfqueryparam value="#form.USER_ID#">,'1','0',<cfqueryparam value="#form.Enabled#">,
				<cfqueryparam value="#form.user_email#">, <cfqueryparam value="#form.email_notification#">,
				<cfqueryparam value="#decrypt(form.radmin,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
				<cfqueryparam value="#decrypt(form.rautopkg,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
				<cfqueryparam value="#decrypt(form.ragentupload,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
				<cfqueryparam value="#decrypt(form.rapi,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">)
		</cfquery>
		<cfcatch type="any">
			<cfset session.adm_mp_account_msg = #cfcatch.Message#>
		</cfcatch>
	</cftry>
	<cflocation url="#session.cflocFix#/admin/inc/admin_accounts.cfm">
</cfif>
<!--- Edit Data --->
<cfif session.adm_mp_accounts EQ "21">
	<cfset session.adm_mp_account_msg = "">
	<cfset updatePass = "0">
	<cfset updateType = "0">
	
	<cfquery name="accountData" datasource="#session.dbsource#">
		Select a.user_pass, b.user_type, b.user_email, b.email_notification from mp_adm_users a
		LEFT Join mp_adm_group_users b ON a.user_id = b.user_id
		Where b.rid = <cfqueryparam value="#form.rid#">
	</cfquery>

	<cfquery name="accountDataAlt" datasource="#session.dbsource#">
		Select b.user_id, b.user_type, a.admin, a.autopkg, a.agentUpload, a.apiAccess from mp_adm_users_info a
		LEFT Join mp_adm_group_users b ON a.user_id = b.user_id
		Where b.rid = <cfqueryparam value="#form.rid#">
	</cfquery>
	
	<cfif accountData.RecordCount EQ "1">
		<cfif accountData.user_type EQ "1">
			<cfset updateType = "1">
		</cfif>
	</cfif>
	<cfif StructKeyExists(form, "USER_PASS0")>
		<cfif form.USER_PASS0 NEQ "">
			<cfif accountData.RecordCount EQ "1">
				<cfif accountData.user_pass NEQ #hash(form.USER_PASS0,'MD5')#>
					<cfset session.adm_mp_account_msg = "Origional password was incorrect. Password will not be updated.">
					<cflocation url="#session.cflocFix#/admin/inc/admin_accounts.cfm?adm_mp_accounts&action=#encrypt('edit',session.usrKey,'AES/CBC/PKCS5Padding','base64')#&u=#form.rid#">
				<cfelse>
					<cfset updatePass = "1">	
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	<cftry>
		<cfif updateType EQ "1">
			<!--- Only Update DB User Data --->
			<cfquery name="editUser1" datasource="#session.dbsource#">
				UPDATE mp_adm_users
				SET
					user_RealName = <cfqueryparam value="#form.USER_REALNAME#">,
					enabled = <cfqueryparam value="#form.Enabled#">
					<cfif updatePass EQ "1">
					,user_pass = <cfqueryparam value="#hash(form.USER_PASS1,'MD5')#">
					</cfif>
				WHERE user_id = <cfqueryparam value="#form.USER_ID#">
			</cfquery>
		</cfif>
		<cfquery name="editUser2" datasource="#session.dbsource#">
			UPDATE mp_adm_group_users
			SET
				enabled = <cfqueryparam value="#form.Enabled#">,
				user_email = <cfqueryparam value="#form.user_email#">,
				email_notification = <cfqueryparam value="#form.email_notification#">
				<cfif session.IsAdmin IS true>
					,group_id = <cfqueryparam value="#decrypt(form.GROUP,session.usrKey,'AES/CBC/PKCS5Padding','base64')#" cfsqltype="cf_sql_integer">
				</cfif>
			WHERE rid = #Val(form.rid)#
		</cfquery>
		<cfquery name="editUser3" datasource="#session.dbsource#">
			<cfif hasUserInfoRecord(form.USER_ID)>

				UPDATE mp_adm_users_info
				SET
					enabled = <cfqueryparam value="#form.Enabled#">,
					user_email = <cfqueryparam value="#form.user_email#">,
					email_notification = <cfqueryparam value="#form.email_notification#">
					<cfif session.IsAdmin IS true>
						,admin = <cfqueryparam value="#decrypt(form.radmin,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
						autopkg = <cfqueryparam value="#decrypt(form.rautopkg,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
						agentUpload = <cfqueryparam value="#decrypt(form.ragentupload,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
						apiAccess = <cfqueryparam value="#decrypt(form.rapi,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">
					</cfif>
				WHERE user_id = <cfqueryparam value="#form.user_id#">

			<cfelse>

				Insert Into mp_adm_users_info (user_id, user_type, number_of_logins, enabled, user_email, email_notification, admin, autopkg, agentUpload, apiAccess)
				Values (<cfqueryparam value="#form.USER_ID#">,'1','0',<cfqueryparam value="#form.Enabled#">,
					<cfqueryparam value="#form.user_email#">, <cfqueryparam value="#form.email_notification#">,
					<cfqueryparam value="#decrypt(form.radmin,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
					<cfqueryparam value="#decrypt(form.rautopkg,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
					<cfqueryparam value="#decrypt(form.ragentupload,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">,
					<cfqueryparam value="#decrypt(form.rapi,session.usrKey,'AES/CBC/PKCS5Padding','base64')#">)

			</cfif>
		</cfquery>
	<cfcatch type="any">
		<cfset session.adm_mp_account_msg = #cfcatch.Message# & #cfcatch.detail#>
	</cfcatch>
	</cftry>
	<cflocation url="#session.cflocFix#/admin/inc/admin_accounts.cfm">
</cfif>

<cffunction name="hasUserInfoRecord" access="private" returntype="any">
	<cfargument name="user_id" required="yes">

	<CFQUERY NAME="q_usr" DATASOURCE="#session.dbsource#">
        SELECT user_id from mp_adm_users_info
        Where user_id = <cfqueryparam value="#arguments.user_id#">
    </CFQUERY>

    <cfif q_usr.RecordCount EQ "1">
    	<cfreturn true>
    <cfelseif q_usr.RecordCount GT "1">
    	<cfreturn false>
    <cfelse>
    	<cfreturn false>
    </cfif>
</cffunction>

