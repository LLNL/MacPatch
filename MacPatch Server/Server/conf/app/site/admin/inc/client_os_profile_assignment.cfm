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
	<cfquery name="getGrpInfo" datasource="#session.dbsource#" result="res">
		select Distinct domain from mp_clients_plist
	</cfquery>
    <cfset grps = "">
	<cfset grps = ListAppend(grps,'Global:Global',';')>
    <cfoutput query="getGrpInfo">
    	<cfset gName = "#domain#:#domain#">
    	<cfset grps = ListAppend(grps,gName,';')>
    </cfoutput>
    <cfquery name="getProInfo" datasource="#session.dbsource#" result="res">
		select profileID,profileName from mp_os_config_profiles
	</cfquery>
    <cfset profiles = "">
    <cfoutput query="getProInfo">
    	<cfset pName = "#profileID#:#profileName#">
    	<cfset profiles = ListAppend(profiles,pName,';')>
    </cfoutput>
</cfsilent>

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'client_os_profile_assignment.cfc?method=getOSProfileAssignments',
				datatype: 'json',
				colNames:['','Assigned To Group', 'Profile', 'Profile Description', 'Profile is Enabled'],
				colModel :[ 
				  {name:'id',index:'id', width:20, align:"center", sortable:false, resizable:false, search:false, hidden:true},
				  {name:'assignment', index:'assignment', width:100, editable:true, edittype:"select", editoptions:{value:"<cfoutput>#grps#</cfoutput>"}},
				  {name:'profileID', index:'profileID', width:100, editable:true, edittype:"select", editoptions:{value:"<cfoutput>#profiles#</cfoutput>"}},
				  {name:'profileDescription', index:'profileDescription', width:120,editable:false},
				  {name:'enabled', index:'enabled', width:30, align:"left", sorttype:'float',editable:false}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'),
				rowNum:20,
				rowList:[10,20,30,50,100],
				sortorder: "desc",
				sortname: "rid",
				viewrecords: true,
				imgpath: '/',
				caption: 'OS Profiles',
				height:'auto',
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"client_os_profile_assignment.cfc?method=addEditOSProfileAssignments",
				toolbar:[false,"top"],
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						/*
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('client_os_profile_wizard_edit.cfm?profileID="+ids[i]+"'); src='/admin/images/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('client_os_profile_wizard_edit.cfm?profileID="+ids[i]+"'); src='/admin/images/info_16.png'>";
						</cfif>
						jQuery("#list").setRowData(ids[i],{profileID:edit}) 
						*/
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
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:true,del:true},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true}
				);
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
