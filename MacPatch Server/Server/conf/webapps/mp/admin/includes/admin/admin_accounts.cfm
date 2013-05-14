<style type="text/css">		
	table{
		/*border-collapse:separate;*/
	}
</style>			
<script type="text/javascript">	
	function loadContent(param, id) {
		$("#dialog").load("includes/available_patches_apple_description.cfm?id="+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 300,
			width: 600,
			modal: true
			}
		); 
		$("#dialog").dialog('open');
	}
</script>
<script type="text/Javascript">
	function load(url)
	{
		window.open(url,'_self') ;
	}
</script>
<script type="text/javascript">
	$(document).ready(function()
		{
			$("#list").jqGrid(
			{
				url:'./includes/admin/admin_accounts.cfc?method=getMPAccounts', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','User ID', 'Group ID', 'Last Login Date', 'Number of Logins'],
				colModel :[ 
				  {name:'rid',index:'rid', width:30, align:"center", sortable:false},
				  {name:'user_id', index:'user_id', width:100, editrules:{readonly:true}}, 
				  {name:'group_id', index:'group_id', width:70, sorttype:'float', editable:true,edittype:"text",editoptions:{size:30,maxlength:50},editrules:{required:true}},
				  {name:'last_login', index:'last_login', width:70, align:"center", editrules:{readonly:true}}, 
				  {name:'number_of_logins', index:'number_of_logins', width:70, align:"center", editrules:{readonly:true}}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'User Accounts', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/admin/admin_accounts.cfc?method=addEditMPAccounts",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i]
						edit = "<input type='image' style='padding-left:4px;' onclick=jQuery('#list').editGridRow('"+cl+"',{modal:true,closeAfterEdit:true}); src='./_assets/images/jqGrid/edit_16.png'>"
						jQuery("#list").setRowData(ids[i],{rid:edit}) 
					} 
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
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:false,del:true},{closeOnEscape:true});
			</cfif>
		}
	);
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager"></div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
