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
	function load(url,id)
	{
		window.open(url,'_self') ;
	}
</script>
<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			$("#list").jqGrid(
			{
				url:'./includes/available_patches_mp.cfc?method=getMPPatches', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Patch Name', 'Version', 'Bundle ID', 'Severity', 'Reboot', 'State', 'Release Date', 'Create Date'],
				colModel :[ 
				  {name:'puuid',index:'puuid', width:30, align:"center", sortable:false, resizable:false},
				  {name:'patch_name', index:'patch_name', width:160}, 
				  {name:'patch_ver', index:'patch_ver', width:70, sorttype:'float'},
				  {name:'bundle_id', index:'bundle_id', width:110, align:"left"},
				  {name:'patch_severity', index:'patch_severity', width:70, align:"center"}, 
				  {name:'patch_reboot', index:'patch_reboot', width:70, align:"center"}, 
				  {name:'patch_state', index:'patch_state', width:70, align:"center"},
				  {name:'mdate', index:'mdate', width:100, align:"center"},
				  {name:'cdate', index:'cdate', width:100, align:"center", hidden: true}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "cdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Custom Patches', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/available_patches_mp.cfc?method=addEditMPPatch",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?adm_mp_patch_edit="+ids[i]+"'); src='./_assets/images/jqGrid/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?mp_patch_view="+ids[i]+"'); src='./_assets/images/jqGrid/info_16.png'>";
						</cfif>
						jQuery("#list").setRowData(ids[i],{puuid:edit}) 
					} 
				}, 
				onSelectRow: function(id){
					/* This section of code fixes the highlight issues, with altRows */
					if(id && id!==lastsel){
						var xyz = $("#list").getDataIDs().indexOf(lastsel);
						if (xyz%2 != 0)
						{
						  $('#'+lastsel).addClass('ui-priority-secondary');	
						} 							 

					  $('#list').jqGrid('restoreRow',lastsel);
					  lastsel=id;
					}
					$('#'+id).removeClass('ui-priority-secondary');
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
			   title:"Add New Patch",
			   onClickButton: function(){ 
				 load('./index.cfm?adm_mp_patch_wizard');
			   }
			})
			.navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-copy", 
			   title:"Duplicate Patch",
			   onClickButton: function(){ 
				 load("./includes/pb/duplicate.cfm?id="+ lastsel);
			   }, 
			   position:"last"
			});
			</cfif>
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
