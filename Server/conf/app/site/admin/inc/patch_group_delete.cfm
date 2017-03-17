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
			var mygrid = $("#list").jqGrid(
			{
				url:'patch_groups.cfc?method=getPatchGroups',
				datatype: 'json',
				colNames:['ID','Name','Owner', 'Is Owner', 'Type', 'Rights', 'Total Clients', 'Release Date'],
				colModel :[ 
				  {name:'patch_group_id',index:'patch_group_id', width:30, align:"center", sortable:false, resizable:false, search:false, hidden: false},				  
				  {name:'name', index:'name', width:120,editable:true}, 
				  {name:'user_id', index:'user_id', width:90, editable:true},
				  {name:'is_owner', index:'is_owner', width:90, align:"left", hidden: true},
				  {name:'type', index:'type', width:50, align:"center",editable:true,edittype:"select", editoptions:{value:"2:Production;1:QA;0:Dev"}},
				  {name:'rights', index:'rights', width:90, align:"left", hidden: true},
				  {name:'cTotal', index:'cTotal', width:30, align:"center"},
				  {name:'mdate', index:'mdate', width:70, align:"center", hidden: true}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'),
				rowNum:20,
				rowList:[10,20,30,50,100],
				sortorder: "desc",
				sortname: "cdate",
				viewrecords: true,
				imgpath: '/',
				caption: 'Patch Groups',
				height:'auto',
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"",
				toolbar:[false,"top"],
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						var myCellData = encodeURI(jQuery("#list").getCell(cl,'rights'));
						edit = "<input type=\'image\' style=\'padding-left:4px;\' onclick=load(\'view_patch_group.cfm?pgid="+ids[i]+"\') src=\'/admin/images/info_16.png\'>";
						if (myCellData >= 1) {
							edit += "<input type=\'image\' style=\'padding-left:4px;\' onclick=load(\'edit_patch_group.cfm?pgid="+ids[i]+"\') src=\'/admin/images/edit_16.png\'>";
						} else {
							edit += "<img class=\'dimImg\' style=\'padding-left:4px;\') src=\'/admin/images/edit_16.png\'>";
						}
						if (myCellData >= 2) {
							edit += "<input type=\'image\' style=\'padding-left:4px;\' onclick=load(\'remove_patch_group.cfm?pgid="+ids[i]+"\') src=\'/admin/images/delete_16.png\'>";
						} else {
							//edit += "<input class=\'dimImg\' type=\'image\' style=\'padding-left:4px;\') src=\'/admin/images/delete_16.png\'>";
							edit += "<img class=\'dimImg\' style=\'padding-left:4px;\') src=\'/admin/images/delete_16.png\'>";
						}
						jQuery("#list").setRowData(ids[i],{patch_group_id:edit})
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
					var patchID = $("#list").getDataIDs().indexOf(lastsel);
					var patchIDVal = jQuery("#list").getCell(patchID,2);
					$('#list').editRow(id, true, undefined, function(res) 
					{
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
			});
			<cfif session.IsAdmin IS true>	
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true}
				)
			.navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-plus", 
			   title:"Add New Patch",
			   onClickButton: function(){ 
				 load('./index.cfm?adm_mp_patch_wizard');
			   }
			});
			<cfelse>
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true}
				);
			</cfif>
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true, defaultSearch: 'cn'});
			mygrid[0].toggleToolbar();
			
			$(window).bind('resize', function() {
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>