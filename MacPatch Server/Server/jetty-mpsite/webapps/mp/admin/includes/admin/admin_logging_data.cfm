<script type="text/javascript">
	$(document).ready(function()
		{
			$("#list").jqGrid(
			{
				url:'./includes/admin/admin_logging_data.cfc?method=getMPLogData', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['ID','Date', 'Event Type', 'Event', 'Host', 'Script Name', 'Script Path', 'Server Host', 'Server Type'],
				colModel :[ 
				  {name:'rid',index:'rid',width:70, align:"left", hidden: true},
				  {name:'cdate', index:'cdate', width:100}, 
				  {name:'event_type', index:'event_type', width:70},
				  {name:'event', index:'event', width:400, align:"left"}, 
				  {name:'host', index:'host', width:70, align:"left", hidden: true},
				  {name:'scriptName', index:'scriptName',width:70, align:"left", hidden: true},
				  {name:'pathInfo', index:'pathInfo',width:70, align:"left", hidden: true},
				  {name:'serverName', index:'serverName',width:70, align:"left", hidden: true},
				  {name:'serverType', index:'serverType',width:70, align:"left", hidden: true}	
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:30, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "DESC", //Default sort order
				sortname: "cdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Log Data', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/admin/admin_logging_data.cfc?method=editMPLogData",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
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
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},{closeOnEscape:true});
			$('#list').jqGrid('navButtonAdd', '#pager',
			{   
				caption: "Columns",
				title: "Reorder Columns",
				onClickButton: function() { jQuery("#list").jqGrid('columnChooser') 
				} 
			});
		}
	);
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager"></div>



