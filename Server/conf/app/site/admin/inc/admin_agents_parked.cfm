<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">


<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			$("#list").jqGrid(
			{
				url:'admin_agents_parked.cfc?method=getAgents', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Client ID', 'HostName', 'Serial No', 'Enabled'],
				colModel :[
					{name:'rid',index:'rid', width:1, align:"center", sortable:false, hidden:true},
					{name:'cuuid', index:'cuuid', width:200, editable:false, editoptions:{size:150}},
					{name:'hostname', index:'hostname', width:200, editable:false, editoptions:{size:150}},
					{name:'serialno', index:'serialno', width:200, editable:false, editoptions:{size:150}},
					{name:'enabled', index:'enabled', width:40, editable:true, edittype:'select', editoptions:{value:{1:'Yes',0:'No'}}}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[5,10,20,30], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Parked Agents (Waiting Approval)', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"admin_agents_parked.cfc?method=editAgents",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i]
					}
				},
				onSelectRow: function(id)
				{
					if(id && id!==lastsel)
					{
					  lastsel=id;
					}
				},
				ondblClickRow: function(id) 
				{
				    <cfif session.IsAdmin IS true>
					$('#list').editRow(id, true, undefined, function(res) {
					    // res is the response object from the $.ajax call
					    $("#list").trigger("reloadGrid");
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
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:false,del:true},{closeOnEscape:true,reloadAfterSubmit:true,width:600, align:"left"},{reloadAfterSubmit:true,width:600},{});
			</cfif>
			
			$(window).bind('resize', function() {
				$("#regConfig").setGridWidth($(window).width()-20);
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');
		}
	);
</script>
<br>
<table id="list" class="scroll" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" class="scroll" style="display:block"></div>
<div id="dialog" title="Detailed Proxy Server Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
