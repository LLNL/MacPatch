<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">


<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>
<script src="/admin/js/jquery.fileDownload.js" type="text/javascript"></script>

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
			var lastsel=-1;
			var selTUUID=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'software_tasks.cfc?method=getMPSoftwareTasks', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','TaskID', 'Name','', 'Active', 'Task Type', 'Valid From', 'Valid To', 'Modify Date'],
				colModel :[
				  {name:'rid',index:'rid', width:30, align:"center", sortable:false, resizable:false, search: false},
				  {name:'tuuid',index:'tuuid', width:30, align:"center", hidden: true},
				  {name:'name',index:'name', width:120, align:"left",editable:true},
				  {name:'primary_suuid',index:'primary_suuid', width:30, align:"center", hidden: true},
				  {name:'active', index:'active', width:50, align:"left",editable:true, edittype:"select", editoptions:{value:"0:No;1:Yes"}},
				  {name:'sw_task_type', index:'sw_task_type', width:60, align:"left"},
				  {name:'sw_start_datetime', index:'sw_start_datetime', width:90, align:"left"},
				  {name:'sw_end_datetime', index:'sw_end_datetime', width:90, align:"left"},
				  {name:'mdate', index:'mdate', width:90, align:"left"}
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
				caption: 'Software Distribution Tasks', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"software_tasks.cfc?method=addEditMPSoftwareTask",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i];
						var xl = jQuery("#list").getCell(ids[i],'tuuid'); // get tuuid
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:0px;' onclick=load('software_task_wizard_edit.cfm?taskID="+xl+"'); src='/admin/images/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:0px;' onclick=load('software_task_wizard_edit.cfm?taskID="+xl+"'); src='/admin/images/info_16.png'>";
						</cfif>
						jQuery("#list").setRowData(ids[i],{rid:edit})
					}
				},
				onSelectRow: function(id)
				{
					if(id && id!==lastsel)
					{
					  lastsel=id;
					}

					selTUUID = jQuery("#list").getCell(id[i],'tuuid'); // get tuuid
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
				$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:true},
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
					 load('software_task_wizard_new.cfm');
				   }
				}).navButtonAdd('#pager',{
					caption:"",
					buttonicon:"ui-icon-arrowstop-1-s",
					title:"Export Software Task",
					onClickButton: function() {
					   	window.location.href = "software_task_export.cfm?taskID="+jQuery("#list").getCell(lastsel,'tuuid');
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

<div id="container">
    <div id="row">
        <div id="left">
        	<a class="btn medium gray" href="software_task_import.cfm">Import Task</a>
        </div>
        <div id="right">
        </div>
    </div>
</div>

<div align="center">
<table id="list" cellpadding="0" cellspacing="0"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Task Information" style="text-align:left;" class="ui-dialog-titlebar"></div>

