<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<cfsilent>
    <cfset agent_pkg = "MPClientInstall" />
    <cfset agent_id = 0 />
    <cfquery name="qAgent" datasource="#session.dbsource#" result="res">
        select puuid from mp_client_agents
        WHERE type = 'app' AND active = '1'
    </cfquery>
    <cfif qAgent.RecordCount EQ 1>
        <cfset agent_id = qAgent.puuid />
    </cfif>
</cfsilent>

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>

<style>
	fieldset {
		-moz-border-radius-bottomleft: 7px;
		-moz-border-radius-bottomright: 7px;
		-moz-border-radius-topleft: 5px;
		-moz-border-radius-topright: 7px;
		-webkit-border-radius: 7px;
		border-radius: 3px;
		border: solid 1px gray;
		padding: 4px;
		margin-bottom:10px;
		font-size: 12px;
		text-align:right;
		//line-height: 30px;
	}
	legend {
		color: black;
		padding: 4px;
		font-weight:bold;
	}
	#container {
		display: table;
		width: 100%;
		margin-bottom: 10px;
	}

	#row  {
		display: table-row;
	}

	#left {
		display: table-cell;
		font-size: 12px;
		text-align:left;
		margin-bottom:10px;
	}

	#right {
		display: table-cell;
		font-size: 12px;
		text-align:right;
		margin-bottom:10px;
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
  
	.btn 
	{
		padding: 6px 12px;
		color: #FFF;
		-webkit-border-radius: 4px;
		-moz-border-radius: 4px;
		border-radius: 4px;
		text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.4);
		-webkit-transition-duration: 0.2s;
		-moz-transition-duration: 0.2s;
		transition-duration: 0.2s;
		-webkit-user-select:none;
		-moz-user-select:none;
		-ms-user-select:none;
		user-select:none;
		display:inline-block;
		vertical-align:middle;
		margin-top: 6px;
	}
	.btn:hover {
		//background: #356094;
		//border: solid 1px #2A4E77;
		text-decoration: none;
	}
	.btn:active {
		position: relative;
		top: 1px;
	}
</style>

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel0 = -1;
			$("#agent").jqGrid(
			{		
				url:'admin_client_agents.cfc?method=getClientAgents', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Agent Ver', 'OS Ver', 'App Ver', 'Build', 'PKG Name', 'PKG Path', 'PKG Hash (SHA1)', 'State', 'Active', 'CDate', 'MDate'],
				colModel :[ 
				  {name:'rid',index:'rid', width:20, align:"center", sortable:true, hidden:true},
				  {name:'agent_ver', index:'agent_ver', width:40, editable:true,edittype:"text"}, 
				  {name:'osver', index:'osver', width:40, editable:true,edittype:"text"},
				  {name:'version', index:'version', width:40, sorttype:'float', editable:true,edittype:"text",editoptions:{size:30,maxlength:50}},
				  {name:'build', index:'build', width:30, sorttype:'float', editable:true,edittype:"text",editoptions:{size:30,maxlength:50}},
				  {name:'pkg_name', index:'pkg_name', width:50},
				  {name:'pkg_url', index:'pkg_url', width:100, editable:true,edittype:"text"},
				  {name:'pkg_hash', index:'pkg_hash', width:100, editrules:{readonly:true}},
				  {name:'state', index:'state', width:40, editrules:{readonly:true}, hidden: true },
				  {name:'active', index:'active', width:30, editable:true, edittype:"select", editoptions:{value:"0:No;1:Yes"}},
				  {name:'cdate', index:'cdate', width:70, editrules:{readonly:true}, formatter: 'date', formatoptions: {srcformat:"F, d Y H:i:s", newformat: 'Y-m-d H:i:s' }},
				  {name:'mdate', index:'mdate', width:70, editrules:{readonly:true}, formatter: 'date', formatoptions: {srcformat:"F, d Y H:i:s", newformat: 'Y-m-d H:i:s' }}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#agent_pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:10, //Number of records we want to show per page
				rowList:[5,10,15,20,25], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Client Agents', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:true,
				editurl:"admin_client_agents.cfc?method=editClientAgents",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){ 
					var ids = jQuery("#agent").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i]
					} 
				},
				onSelectRow: function(id)
				{
					if(id && id!==lastsel0)
					{
					  lastsel0=id;
					}
				},
				ondblClickRow: function(id) 
				{
				    <cfif session.IsAdmin IS true>
					$('#agent').editRow(id, true, undefined, function(res) {
					    // res is the response object from the $.ajax call
					    $("#agent").trigger("reloadGrid");
					});
					</cfif>
				},
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
			$("#agent").jqGrid('navGrid',"#agent_pager",{edit:true,add:false,del:true},
			{},
			{},
			{
				beforeShowForm: function ($form) {
					$("td.delmsg", $form[0]).html("<div align='left'>Selecting delete will remove both the <br> Agent & Updater packages.</div>");
				},
			}
			);
			</cfif>
			
			$(window).bind('resize', function() {
				$("#agent").setGridWidth($(window).width()-20);
			}).trigger('resize');
			
			var lastCFilterSel
			$("#agentFilter").jqGrid(
			{
				url:'admin_client_agents.cfc?method=getClientAgentFilters', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Attribute', 'Operator', 'Filter Value', 'Condition'],
				colModel :[ 
				  {name:'rid',index:'rid', width:20, align:"center", sortable:true, hidden:true},
				  {name:'attribute', index:'attribute', width:60, editable:true, edittype:"select", 
				  editoptions:{value:"cuuid:Client ID;ipaddr:IP Address;hostname:HostName;Domain:Client Group;agent_version:Agent Version;agent_build:Agent Build;client_version:Client Version;All:All"}},
				  {name:'attribute_oper', index:'attribute_oper', width:60,editable:true, edittype:"select", editoptions:{value:"EQ:Equal;NEQ:Not Equal"}},
				  {name:'attribute_filter', index:'attribute_filter', width:100, editable:true}, 
				  {name:'attribute_condition', index:'attribute_condition', width:60, editable:true, edittype:"select", editoptions:{value:"AND:AND;OR:OR;None:None"}}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#agentFilterPager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:10, //Number of records we want to show per page
				rowList:[5,10,15,20,25], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Client Agent Update Filter', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hiddengrid:false,
				hidegrid:true,
				editurl:"admin_client_agents.cfc?method=editClientAgentFilters",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				onSelectRow: function(id)
				{
					if(id && id!==lastCFilterSel)
					{
					  lastCFilterSel=id;
					}
				},
				ondblClickRow: function(id) 
				{
				    <cfif session.IsAdmin IS true>
					$('#agentFilter').editRow(id, true, undefined, function(res) {
					    // res is the response object from the $.ajax call
					    $("#agentFilter").trigger("reloadGrid");
					});
					</cfif>
				},
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
			$("#agentFilter").jqGrid('navGrid',"#agentFilterPager",{edit:true,add:true,del:true});
			</cfif>
			$(window).bind('resize', function() {
				$("#agentFilter").setGridWidth($(window).width()-20);
			}).trigger('resize');
		} 	
	);
</script>

<div id="container">
    <div id="row">
        <div id="left">
        &nbsp;<br>
        <a class="btn medium gray" href="/mp-content/clients/<cfoutput>#agent_id#</cfoutput>/MPClientInstall.pkg.zip" target="_new">Client Download</a>
        </div>
        <div id="right">
        To upload a new version of the MacPatch agent please download the MacPatch Agent Uploader.<br>
        <a class="btn medium gray" href="/mp-content/tools/MPAgentUploader.zip" target="_new">Download</a>
        </div>
    </div>
</div>

<table id="agent" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="agent_pager"></div>
<br />
<hr>
<br />
<table id="agentFilter" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="agentFilterPager"></div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
