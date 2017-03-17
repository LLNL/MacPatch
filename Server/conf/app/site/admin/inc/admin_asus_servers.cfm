<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			$("#list").jqGrid(
			{
				url:'admin_asus_servers.cfc?method=getAsusServers',
				datatype: 'json',
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
				altclass:'xAltRow',
				pager: jQuery('#pager'),
				rowNum:30,
				rowList:[5,10,20,30],
				sortorder: "asc",
				sortname: "catalog_group_name",
				viewrecords: true,
				imgpath: '/',
				caption: 'Apple Software Update Servers',
				height:'auto',
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"admin_asus_servers.cfc?method=editAsusServers",
				toolbar:[false,"top"],
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
			
			$(window).bind('resize', function() {
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');
		}
	);
</script>
<table id="list" class="scroll" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" class="scroll" style="display:block"></div>
<div id="dialog" title="Detailed Proxy Server Information" style="text-align:left;" class="ui-dialog-titlebar"></div>

