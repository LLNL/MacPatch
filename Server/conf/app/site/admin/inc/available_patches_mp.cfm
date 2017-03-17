<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>

<cfsilent>
	<cfquery name="getSrvInfo" datasource="#session.dbsource#" result="res">
		select server, useSSL from mp_servers
		Where isMaster = '1' and active = '1'
	</cfquery>
	<cfif getSrvInfo.RecordCount GTE 1>
		<cfset mpServer = IIF(getSrvInfo.useSSL EQ 1,DE('https://'),DE('http://')) & getSrvInfo.server >
	<cfelse>	
		<cfset mpServer = "https://localhost" >
	</cfif>
</cfsilent>

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'available_patches_mp.cfc?method=getMPPatches',
				datatype: 'json',
				colNames:['','','Patch Name', 'Version', 'Bundle ID', 'Severity', 'Reboot', 'State', 'Active', 'Release Date'],
				colModel :[ 
				  {name:'puuid',index:'puuid', width:20, align:"center", sortable:false, resizable:false, search:false},
				  {name:'pkg_url',index:'pkg_url', width:20, align:"center", sortable:false, resizable:false, search:false},
				  {name:'patch_name', index:'patch_name', width:120,editable:true}, 
				  {name:'patch_ver', index:'patch_ver', width:40, sorttype:'float',editable:true},
				  {name:'bundle_id', index:'bundle_id', width:90, align:"left"},
				  {name:'patch_severity', index:'patch_severity', width:44, align:"center", editable:true, edittype:"select", editoptions:{value:"High:High; Medium:Medium; Low:Low; Unknown:Unknown"}}, 
				  {name:'patch_reboot', index:'patch_reboot', width:40, align:"center", editable:true, edittype:"select", editoptions:{value:"No:No;Yes:Yes"}}, 
				  {name:'patch_state', index:'patch_state', width:50, align:"center", editable:true, edittype:"select", editoptions:{value:"Production:Production;QA:QA;Create:Create;Disabled:Disabled"}},
				  {name:'active', index:'active', width:40, align:"center", editable:true, edittype:"select", editoptions:{value:"0:No;1:Yes"}},
				  {name:'mdate', index:'mdate', width:70, align:"center"}
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
				caption: 'Custom Patches',
				height:'auto',
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"available_patches_mp.cfc?method=addEditMPPatch",
				toolbar:[false,"top"],
				multiselect: true,
				multiboxonly: true,
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						var myCellData = encodeURI(jQuery("#list").getCell(cl,'pkg_url'));
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('custom_patch_builder_wizard_edit.cfm?patchID="+ids[i]+"'); src='/admin/images/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('custom_patch_builder_wizard_edit.cfm?patchID="+ids[i]+"'); src='/admin/images/info_16.png'>";
						</cfif>
						dl = "<input type='image' style='padding-left:0px;' onclick=window.open('<cfoutput>#mpServer#</cfoutput>/mp-content"+myCellData+"','_blank'); src='/admin/images/arrow_down.png'>";
						jQuery("#list").setRowData(ids[i],{puuid:edit,pkg_url:dl}) 
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
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:false,del:true},
				{}, // default settings for edit
				{}, // default settings for add
				{
					beforeShowForm: function ($form) {
						var dlgDiv = $("#delmodlist");
						var parentDiv = dlgDiv.parent(); // div#gbox_list
						var dlgWidth = dlgDiv.width();
						var parentWidth = parentDiv.width();
						var dlgHeight = dlgDiv.height();
						var parentHeight = parentDiv.height();
						dlgDiv[0].style.top = Math.round((parentHeight-dlgHeight)/2) + "px";
						dlgDiv[0].style.left = Math.round((parentWidth-dlgWidth)/2) + "px";
						
						$("td.delmsg", $form[0]).html("Are you sure you want to delete the <br>selected patches?<br><br>This can not be undone!");
					}
                }, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true}
				)
			.navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-plus", 
			   title:"Add New Patch",
			   onClickButton: function(){ 
				 load('custom_patch_builder_wizard_new.cfm');
			   }
			})
			.navButtonAdd('#pager',{
				caption:"", 
				buttonicon:"ui-icon-copy", 
				title:"Duplicate Patch",
				onClickButton: function(){ 
					var selr = jQuery('#list').jqGrid('getGridParam','selrow');
					if (selr) {
						load("custom_patch_builder_wizard_copy.cfm?id="+ lastsel);
					} else {
						alert("You must select a patch first.");	
					}
				}, 
				position:"last"
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
<table id="list" cellpadding="0" cellspacing="0"></table>
<div id="pager" style="text-align:center;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
