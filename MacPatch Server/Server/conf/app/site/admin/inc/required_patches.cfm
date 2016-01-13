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
			var mygrid = $("#list").jqGrid(
			{
				url:'required_patches.cfc?method=getRequiredPatches', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['', 'Patch', 'Description', 'HostName', 'IP Address', 'Client Group', 'Type', 'Days Needed', 'Date'],
				colModel :[ 
				  {name:'rNo', index:'patch', width:10, hidden:true},
				  {name:'patch', index:'patch', width:80},
				  {name:'description', index:'description', width:120},
				  {name:'hostname', index:'hostname', width:60},
				  {name:'ipaddr', index:'ipaddr', width:60}, 
				  {name:'ClientGroup', index:'ClientGroup', width:60}, 
				  {name:'type', index:'type', width:40},
				  {name:'DaysNeeded', index:'DaysNeeded', width:40},
				  {name:'date', index:'date', hidden: true}
				],
				emptyrecords: "No records to view",
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:30, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "date", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Detected Patches', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "Show {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				editurl:"required_patches.cfc?method=addEditRequiredPatches",//Not used right now.
				toppager:false,
				hidegrid:false,
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
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
			   {}, // default settings for edit
			   {}, // default settings for add
			   {}, // delete
			   { sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
			   {}
			);
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true, defaultSearch: 'cn'});
			
			$(window).bind('resize', function() {
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');
		}
	);
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="color:#000;"></div>


