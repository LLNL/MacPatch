<style type="text/css">
	table{
		/*border-collapse:separate;*/
	}
</style>

<link rel="stylesheet" href="./_assets/css/tablesorter/themes/blue/style.css" type="text/css" />
<script type="text/javascript" src="./_assets/js/jquery/jquery.tablesorter.js"></script>

<script type="text/javascript">
	function loadContent(param, id) {
		$("#dialog").load("includes/admin/admin_proxy_info.cfm?id="+id);
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
<script type="text/javascript">
	function syncContent(id) {
		$("#dialog").load("includes/admin/admin_proxy_sync.cfm?id="+id);
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
<script type="text/javascript">
	function checkProxyStatus(id) {
		$("#dialog").load("includes/admin/admin_proxy_sync.cfm?id="+id+"&isTest=1");
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
<script type="text/javascript">
	function showLogData(id) {
		$("#dialog").load("includes/admin/admin_proxy_logs.cfm?id="+id.value);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 600,
			width: 980,
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

<!---
<script type=text/javascript>
  function refresh()
  {
	$("#modalIframeId").attr("src","https://mpproxy.llnl.gov:2600/mplogs/cf_logs/MPProxy.log");
  }
  window.setInterval("refresh()",5000);
</script>
--->
<script type="text/javascript">
	function showLog() {
		$("#divId").dialog(
			{
			autoOpen: false,
			modal: true,
			height: 600,
			width: 980,
			buttons:
				{
					"Refresh": function() {
						$("#modalIframeId").attr("src","https://mpproxy.llnl.gov/mplogs/cf_logs/MPProxy.log");
					},
					"Close": function() {
						$( this ).dialog( "close" );
					}
				}
			}
		);

		$("#divId").html('<iframe id="modalIframeId" width="100%" height="100%" marginWidth="0" marginHeight="0" frameBorder="0" scrolling="auto" />').dialog("open");
		$("#modalIframeId").attr("src","https://mpproxy.llnl.gov:2600/mplogs/cf_logs/MPProxy.log");
   		return false;
	}
</script>
<script type="text/javascript">
	function showLogFor(item) {
		$("#divId").dialog(
			{
			autoOpen: false,
			modal: true,
			height: 600,
			width: 980,
			buttons:
				{
					"Refresh": function() {
						/* $("#modalIframeId").attr("src","https://mpproxy.llnl.gov/mplogs/cf_logs/"+item.value+".log");
						$("#modalIframeId").attr("src","https://mpproxy.llnl.gov:2600/MPProxyLogs.cfc?method=ReadLogFile&logFile="+item.value+".log"); */
					},
					"Close": function() {
						$( this ).dialog( "close" );
					}
				}
			}
		);

		$("#divId").html('<iframe id="modalIframeId" width="100%" height="100%" marginWidth="0" marginHeight="0" frameBorder="0" scrolling="auto" />').dialog("open");
		$("#modalIframeId").attr("src","https://mpproxy.llnl.gov:2600/mplogs/cf_logs/"+item.value+".log");
   		return false;
	}
</script>


<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			$("#list").jqGrid(
			{
				url:'./includes/admin/admin_proxy.cfc?method=getProxyServer', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['Sync Content','Address', 'Port', 'Description', 'Modify Date'],
				colModel :[
				  {name:'rid',index:'rid', width:70, align:"center", sortable:false},
				  {name:'address', index:'address', width:200, editable:true},
				  {name:'port', index:'port', width:120, editable:true},
				  {name:'description', index:'description', width:200, editable:true},
				  {name:'mdate', index:'mdate', width:200, editrules:{readonly:true}}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Proxy Server', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/admin/admin_proxy.cfc?method=editProxyServer",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i]
						sync = "<input type='image' style='padding-left:4px;' onclick=syncContent('"+cl+"'); src='./_assets/images/jqGrid/sync_16.png'>"
						jQuery("#list").setRowData(ids[i],{rid:sync})
					}
				},
				onSelectRow: function(id){
					/* This section of code fixes the highlight issues, with altRows */
					if(id && id!==lastsel){
						var xyz = $("#list").getDataIDs().indexOf(lastsel);
						if (xyz%2 != 0)
						{
						  $('#'+lastsel).addClass('ui-priority-secondary');
						}

					  $('#list').jqGrid('restoreRow',lastsel);
					  lastsel=id;
					}
					$('#'+id).removeClass('ui-priority-secondary');
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
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:true,del:true},{closeOnEscape:true})
			.navButtonAdd('#pager',{
			   caption:"",
			   buttonicon:"ui-icon-info",
			   title:"Get Proxy Server ID",
			   onClickButton: function(){
				 loadContent('info',lastsel);
			   }
			  })
			   .navButtonAdd('#pager',{
			   caption:"",
			   buttonicon:"ui-icon-transfer-e-w",
			   title:"Proxy Server Test",
			   onClickButton: function(){
				 checkProxyStatus(lastsel);
			   }
			});
			</cfif>
		}
	);
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager"></div>
<hr>
Proxy Server Logs:
<select onchange="showLogData(this);" onclick="showLogData(this);">
  <option>MPProxy</option>
  <option>MPWSController</option>
  <option>MPWSControllerCocoa</option>
</select>
<div id="dialog" title="Detailed Proxy Server Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
<div id="divId" title="Proxy Server Log" style="text-align:left;" class="ui-dialog-titlebar" />
