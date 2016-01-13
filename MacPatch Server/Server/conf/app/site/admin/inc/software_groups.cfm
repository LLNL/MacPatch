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
			$.jgrid.nav.addtitle = "Add New Group";
			$.jgrid.nav.edittitle = "Edit Group Info";
			
			var lastsel=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'software_groups.cfc?method=getMPSoftwareGroups', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['', 'Filter', 'Name', 'Description', 'Owner', 'State', 'Modify Date'],
				colModel :[
				  {name:'gid',index:'gid', width:22, align:"center", sortable:false, resizable:false, search:false},
				  {name:'gfid',index:'gfid', width:22, align:"center", sortable:false, resizable:false, search:false},
				  {name:'gName',index:'gName', width:120, align:"left", editable: true, edittype:'text'},
				  {name:'gDescription',index:'gDescription', width:180, align:"left", editable: true, edittype:'text'},
				  <cfif session.IsAdmin IS true>
				  {name:'owner', index:'owner', width:100, align:"left", editable: true, edittype:'text'},
				  <cfelse>
				  {name:'owner', index:'owner', width:100, align:"left", editable: true, edittype:'text', editoptions: {readonly: 'readonly'}},
				  </cfif>
				  {name:'state',index:'state', width:56, align:"left", editable: true, editable:true, edittype:"select", editoptions:{value:"1:Production;2:QA;0:Disabled"}},
				  {name:'mdate', index:'mdate', width:80, align:"left", editable: false, edittype:'text', editoptions: {readonly: 'readonly'}}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "mdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Software Distribution Groups', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"software_groups.cfc?method=editMPSoftwareGroups",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i];
						var xl = jQuery("#list").getCell(ids[i],'gid'); // get tuuid
						var el = jQuery("#list").getCell(ids[i],'gfid'); // get tuuid
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:0px;' onclick=load('software_group_edit.cfm?group="+xl+"'); src='/admin/images/edit_16.png'>";
						filter = "<input type='image' style='padding-left:0px;' onclick=load('software_groups_filter.cfm?group="+xl+"'); src='/admin/images/funnel-pencil-icon_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('software_group_edit.cfm?group="+xl+"'); src='/admin/images/info_16.png'>";
						filter = "<input type='image' style='padding-left:4px;' onclick=load('software_groups_filter.cfm?group="+xl+"'); src='/admin/images/16x16-filter.png'>";
						</cfif>
						jQuery("#list").setRowData(ids[i],{gid:edit,gfid:filter})
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
					var stateID = $("#list").getDataIDs().indexOf(lastsel);
					var stateIDVal = jQuery("#list").getCell(stateID,2);
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
				$("#list").jqGrid('navGrid',"#pager",{edit:true,add:true,del:true},
					{editCaption: "Edit Software Group"}, // default settings for edit
					{addCaption: "Add New Software Group"}, // default settings for add
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
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Task Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
