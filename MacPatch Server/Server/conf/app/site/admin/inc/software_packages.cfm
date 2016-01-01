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
				url:'software_packages.cfc?method=getMPSoftware', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','','Name', 'Version', 'Reboot', 'State', 'Dist Type', 'Modified Date', 'Create Date'],
				colModel :[ 
				  {name:'suuid',index:'suuid', width:20, align:"center", sortable:false, resizable:false},
				  {name:'sw_url',index:'sw_url', width:20, align:"center", sortable:false},
				  {name:'sName', index:'sName', width:100, editable:true}, 
				  {name:'sVersion', index:'sVersion', width:30, sorttype:'float', editable:true},
				  {name:'sReboot', index:'sReboot', width:20, align:"left", editable:true, edittype:"select", editoptions:{value:"0:No;1:Yes"}},
				  {name:'sState', index:'sState', width:40, align:"left", editable:true, edittype:"select", editoptions:{value:"2:Production;1:QA;0:Create;3:Disabled"}}, 
				  {name:'sw_Type', index:'sw_Type', width:40, align:"left"}, 
				  {name:'mdate', index:'mdate', width:60, align:"center"},
				  {name:'cdate', index:'cdate', width:60, align:"center"}
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
				caption: 'Software Distribution Packages', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"software_packages.cfc?method=addEditMPSoftware",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						var pkgURLPATH = encodeURI(jQuery("#list").getCell(cl,'sw_url'));
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:0px;' onclick=load('software_package_wizard_edit.cfm?packageID="+ids[i]+"'); src='/admin/images/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:0px;' onclick=load('software_package_wizard_edit.cfm?packageID="+ids[i]+"'); src='/admin/images/info_16.png'>";
						</cfif>
						dl = "<input type='image' style='padding-left:0px;' onclick=downloadURL('/mp-content"+pkgURLPATH+"'); src='/admin/images/icons/arrow_down.png'>";
						jQuery("#list").setRowData(ids[i],{suuid:edit,sw_url:dl}) 
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
				$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:true})
				.navButtonAdd('#pager',{
				   caption:"", 
				   buttonicon:"ui-icon-plus", 
				   title:"Add New Software Package",
				   onClickButton: function(){ 
					 load('software_package_wizard_new.cfm');
				   }
				})
				.navButtonAdd('#pager',{
				   caption:"", 
				   buttonicon:"ui-icon-copy", 
				   title:"Duplicate Software Package",
				   onClickButton: function(){ 
					 load("software_package_copy.cfm?id="+ lastsel);
				   }, 
				   position:"last"
				})
				.navButtonAdd('#pager',{
				   caption:"", 
				   buttonicon:"ui-icon-gear", 
				   title:"Generate Task",
				   onClickButton: function(){ 
					 load("software_package_generate_task.cfm?id="+ lastsel);
				   }, 
				   position:"last"
				});
			<cfelse>
				$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},{closeOnEscape:true});
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
