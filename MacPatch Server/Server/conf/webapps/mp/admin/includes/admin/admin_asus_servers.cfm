<style type="text/css">
	table{
		/*border-collapse:separate;*/
	}
	.EditTable td {
	    align: left;
	}
</style>
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
<script type="text/Javascript">
	function load(url)
	{
		window.open(url,'_self') ;
	}
</script>
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
						$("#modalIframeId").attr("src","https://mpproxy.llnl.gov/mplogs/cf_logs/"+item.value+".log");
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
				url:'./includes/admin/admin_asus_servers.cfc?method=getAsusServers', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','CatalogURL', 'OS Major', 'OS Minor', 'Order', 'Is Proxy', 'Group Name'],
				colModel :[
				  {name:'rid',index:'rid', width:70, align:"center", sortable:false, hidden:true},
				  {name:'catalog_url', index:'catalog_url', width:300, editable:true, editoptions:{size:70}},
				  {name:'os_major', index:'os_major', width:40, editable:true, formoptions:{align: 'left'}},
				  {name:'os_minor', index:'os_minor', width:40, editable:true},
				  {name:'c_order', index:'c_order', width:40, editable:true, editoptions:{alt:'Set the search order for OS Minor. Search starts with "0".'}},
				  {name:'proxy', index:'proxy', width:40, editable:true, edittype:'select', editoptions:{value:{1:'Yes',0:'No'}}},
				  {name:'catalog_group_name', index:'catalog_group_name', width:140, editable:true, editoptions:{size:70}}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[5,10,20,30], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "catalog_group_name", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Apple Software Update Servers', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/admin/admin_asus_servers.cfc?method=editAsusServers",//Not used right now.
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
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:true,del:true},{closeOnEscape:true,reloadAfterSubmit:true,width:600, align:"left"},{reloadAfterSubmit:true,width:600},{});
			</cfif>
		}
	);
</script>
<table id="list" class="scroll" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" class="scroll" style="display:block"></div>
<div id="dialog" title="Detailed Proxy Server Information" style="text-align:left;" class="ui-dialog-titlebar"></div>

