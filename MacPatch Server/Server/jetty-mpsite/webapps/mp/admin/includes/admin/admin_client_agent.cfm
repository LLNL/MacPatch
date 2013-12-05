<style>
  fieldset
  {
    -moz-border-radius-bottomleft: 7px;
    -moz-border-radius-bottomright: 7px;
    -moz-border-radius-topleft: 5px;
    -moz-border-radius-topright: 7px;
    -webkit-border-radius: 7px;
    border-radius: 3px;
	border: solid 1px gray;
	padding: 4px;
	margin-bottom:10px;
  }
  legend
  {
    color: black;
	padding: 4px;
	font-weight:bold;
  }
</style>
	
<script type="text/javascript">	
	function loadContent(param, id) {
		$("#dialog").load("includes/available_patches_apple_description.cfm?id="+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 300,
			width: 600,
			modal: true
			}
		); 
		$("#dialog").dialog('open');
	}
</script>
<script type="text/Javascript">
	function load(url)
	{
		window.open(url,'_self') ;
	}
</script>
<style type="text/css">
    .xAltRow { background-color: #F0F8FF; background-image: none; }
</style>
<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel0 = -1;
			$("#agent").jqGrid(
			{		
				url:'./includes/admin/admin_client_agent.cfc?method=getClientAgents', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Agent Ver', 'OS Ver', 'App Ver', 'Build', 'Framework', 'PKG Name', 'PKG Path', 'PKG Hash (SHA1)', 'State', 'Active', 'CDate', 'MDate'],
				colModel :[ 
				  {name:'rid',index:'rid', width:20, align:"center", sortable:true, hidden:false},
				  {name:'agent_ver', index:'agent_ver', width:60, editable:true,edittype:"text"}, 
				  {name:'osver', index:'osver', width:60, editable:true,edittype:"text"},
				  {name:'version', index:'version', width:50, sorttype:'float', editable:true,edittype:"text",editoptions:{size:30,maxlength:50}},
				  {name:'build', index:'build', width:40, sorttype:'float', editable:true,edittype:"text",editoptions:{size:30,maxlength:50}}, 
				  {name:'framework', index:'framework', width:60, sorttype:'float', hidden:true}, 
				  {name:'pkg_name', index:'pkg_name', width:100},
				  {name:'pkg_url', index:'pkg_url', width:100, editable:true,edittype:"text"},
				  {name:'pkg_hash', index:'pkg_hash', width:100, editrules:{readonly:true}},
				  {name:'state', index:'state', width:40, editrules:{readonly:true}, hidden: true },
				  {name:'active', index:'active', width:50, editable:true, edittype:"select", editoptions:{value:"0:No;1:Yes"}},
				  {name:'cdate', index:'cdate', width:70, editrules:{readonly:true}},
				  {name:'mdate', index:'mdate', width:70, editrules:{readonly:true}}
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
				editurl:"includes/admin/admin_client_agent.cfc?method=editClientAgents",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){ 
					var ids = jQuery("#agent").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i]
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?adm_mp_agents_client="+ids[i]+"'); src='./_assets/images/jqGrid/edit_16.png'>"
						jQuery("#agent").setRowData(ids[i],{rid:edit}) 
						</cfif>
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
			$("#agent").jqGrid('navGrid',"#agent_pager",{edit:false,add:false,del:true},
			{},
			{},
			{
				beforeShowForm: function ($form) {
					$("td.delmsg", $form[0]).html("<div align='left'>Selecting delete will remove both the <br> Agent & Updater packages.</div>");
				},
			}
			);
			</cfif>
			var lastCFilterSel
			$("#agentFilter").jqGrid(
			{
				url:'./includes/admin/admin_client_agent.cfc?method=getClientAgentFilters', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Attribute', 'Operator', 'Filter Value', 'Condition'],
				colModel :[ 
				  {name:'rid',index:'rid', width:20, align:"center", sortable:true, hidden:true},
				  {name:'attribute', index:'attribute', width:60, editable:true, edittype:"select", editoptions:{value:"cuuid:Client ID;ipaddr:IP Address;hostname:HostName;Domain:Client Group;All:All"}},
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
				editurl:"includes/admin/admin_client_agent.cfc?method=editClientAgentFilters",//Not used right now.
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
			$("#agentFilter").jqGrid('navGrid',"#agentFilterPager",{edit:true,add:true,del:true});
		} 	
	);
</script>
<cfif StructKeyexists(session,"lastErrorNo")>
<cfif session.lastErrorNo NEQ "0">
<cfoutput>
<h3 style="color: red">Error No. #session.lastErrorNo#<br>#session.lastErrorMsg#</h3>
</cfoutput>
<cfset session.lastErrorNo = "0">
</cfif>
</cfif>
<form action="./includes/admin/_agent_upload.cfm" enctype="multipart/form-data" method="post">
<fieldset>
	<legend>New Agent Upload</legend>
	<cfform name="ClientUpdatePackage" action="index.cfm" enctype="multipart/form-data">
	Agent PKG (ZIP): <cfinput type="file" name="pkg"> <cfinput type="submit" name="AgentPackage" value="Upload">
    </cfform>
</fieldset>
</form>

<table id="agent" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="agent_pager"></div>
<p>&nbsp;</p>
<hr>
<p>&nbsp;</p>
<table id="agentFilter" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="agentFilterPager"></div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
