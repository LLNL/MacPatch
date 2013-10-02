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
				url:'./includes/baseline/baseline_patches.cfc?method=getMPPatches', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Name', 'Description', 'Create Date', 'Mod Date', 'State'],
				colModel :[ 
				  {name:'baseline_id',index:'baseline_id', width:36, align:"center", sortable:false, resizable:false},	
				  {name:'name', index:'name', width:200, editable:true, edittype:'text'}, 
				  {name:'description', index:'description', width:200, editable:true, edittype:'text'}, 
				  {name:'cdate', index:'cdate', width:100, editable:true, edittype:'text',editoptions: {readonly: 'readonly'}, formatter: 'date', formatoptions: {srcformat:"F, d Y H:i:s", newformat: 'Y-m-d H:i' }},
				  {name:'mdate', index:'mdate', width:100, editable:true, edittype:'text',editoptions: {readonly: 'readonly'}, formatter: 'date', formatoptions: {srcformat:"F, d Y H:i:s", newformat: 'Y-m-d H:i' }}, 
				  {name:'state', index:'state', width:100, editable:true, edittype:'select', editoptions:{value:{1:'Production',2:'QA',0:'Inactive'}}}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "state", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Patch Baselines', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/baseline/baseline_patches.cfc?method=addEditMPBaseline",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						info = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?patch_baseline_info="+ids[i]+"'); src='./_assets/images/jqGrid/info_16.png'>";
						jQuery("#list").setRowData(ids[i],{baseline_id:info}) 
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
				
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:false,del:true})
			.navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-plus", 
			   title:"Add New Patch",
			   onClickButton: function(){ 
				 load('./index.cfm?adm_mp_patch_baseline_new');
			   }
			 })
			 .navButtonAdd('#pager',{
			   caption:"", 
			   buttonicon:"ui-icon-newwin", 
			   title:"New Baseline Using Current Production List",
			   onClickButton: function(){ 
				 load('./index.cfm?adm_mp_patch_baseline_duplicate');
			   },
			   position:"last"
			  } 
			);
			</cfif>
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
