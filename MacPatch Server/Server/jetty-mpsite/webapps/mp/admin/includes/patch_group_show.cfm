<script type="text/javascript">	
	function loadContent(param, id) {
		$("#dialog").load("includes/available_patches_apple_description.cfm?pid="+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 500,
			width: 700,
			modal: true
			}
		); 
		$("#dialog").dialog('open');
	}
</script>

<cfquery datasource="#session.dbsource#" name="qGetName">
    select a.name, b.user_id
    From mp_patch_group a 
    Left Join mp_patch_group_members b
    ON a.id = b.patch_group_id
    Where id = '#url.showpatchgroup#'
    AND b.is_owner = 1
</cfquery>
<cfquery datasource="#session.dbsource#" name="qGetData">
    select * 
	From mp_patch_group_patches a
	Left Join combined_patches_view b
	ON a.patch_id = b.id
	Where a.patch_group_id = '#url.showpatchgroup#'
</cfquery>

<H3>Detailed Patch Group Info</H3>
<cfoutput>
Patch Group Name: #qGetName.name#<br>
Created By: #qGetName.user_id#<br>
</cfoutput>
<hr>
<script type="text/javascript">
	$(document).ready(function()
		{
			var mygrid = $("#list").jqGrid(
			{
				url:'./includes/patch_group_show.cfc?method=getPatchGroupPatches&patchgroup=<cfoutput>#url.showpatchgroup#</cfoutput>', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['','Patch', 'Title', 'Type', 'PostDate'],
				colModel :[ 
				  {name:'rid', index:'rid', width:20, align:"center", sortable:false, search : false},
				  {name:'name', index:'name', width:140}, 
				  {name:'title', index:'title', width:200, sorttype:'float'},
				  {name:'type', index:'type', width:50, align:"center"}, 
				  {name:'postdate', index:'postdate', width:70, align:"center"}
				],
				emptyrecords: "No records to view",
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "postdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				//caption: 'Patch Group Patches', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				editurl:"includes/patch_group_show.cfc?method=addEditgetPatchGroupPatches",//Not used right now.
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						edit = "<input type='image' style='padding-left:4px;' onclick=loadContent('info','"+cl+"'); src='./_assets/images/jqGrid/info_16.png'>";
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
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
			   {}, // default settings for edit
			   {}, // default settings for add
			   {}, // delete
			   { sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
			   {}
			);
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true}); 
		}
	);
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="color:#000;"></div>

<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>


