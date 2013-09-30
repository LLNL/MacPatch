<script type="text/javascript">
	function loadContent(param, id) {
		$("#dialog").load("./includes/available_patches_apple_description.cfm?pid="+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 400,
			width: 700,
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
			var lastsel = -1;
			$("#list").jqGrid(
			{
				url:'./includes/available_patches_apple.cfc?method=getMPApplePatches', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['', '', 'Patch', 'Version', 'Title', 'Reboot', 'Supported OS', 'Criteria', 'Patch State', 'Release Date'],
				colModel :[
				  {name:'akeyE',index:'akeyE', width:18, align:"center", sortable:false, resizable:false},
				  {name:'akey',index:'akey', width:18, align:"center", sortable:false, resizable:false},
				  {name:'supatchname', index:'supatchname', width:160},
				  {name:'version', index:'version', width:50, sorttype:'float'},
				  {name:'title', index:'title', width:160, align:"left"},
				  {name:'restartaction', index:'restartaction', width:40, align:"center"},
				  {name:'osver_support', index:'osver_support', width:80, align:"left", hidden: true},
				  {name:'hasCriteria', index:'hasCriteria', width:40, align:"center"},
				  {name:'patch_state', index:'patch_state', width:50, align:"left", editable:true, edittype:"select", editoptions:{value:"Production:Production;QA:QA;Create:Create;Disabled:Disabled"}},
				  {name:'postdate', index:'postdate', width:70, align:"center", formatter: 'date', formatoptions: {srcformat:"F, d Y H:i:s", newformat: 'Y-m-d' }}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:30, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "postdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Apple Patches', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0}-{1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"./includes/available_patches_apple.cfc?method=addEditMPApplePatches",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i];
						var aps = jQuery("#list").getCell(cl,1);
						var suname = jQuery("#list").getCell(cl,2);
						info = "<input type='image' style='padding-left:2px;' onclick=loadContent('info','"+cl+"'); src='./_assets/images/jqGrid/info_16.png'>";
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:2px;' onclick=load('./index.cfm?adm_apple_patch_edit="+ids[i]+"&adm_apple_patch_edit_name="+suname+"'); src='./_assets/images/jqGrid/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:2px;' onclick=load('./index.cfm?adm_apple_patch_view="+ids[i]+"&adm_apple_patch_name="+suname+"'); src='./_assets/images/jqGrid/info.png'>";
						</cfif>
						jQuery("#list").setRowData(ids[i],{akeyE:edit,akey:info})
					}
				},
				onSelectRow: function(id){
					if(id && id!==lastsel){
						var xyz = $("#list").getDataIDs().indexOf(lastsel);
						if (xyz%2 != 0)
						{
						  $('#'+lastsel).addClass('ui-priority-secondary');
						}

					  $('#list').jqGrid('restoreRow',lastsel);

					}
					$('#'+id).removeClass('ui-priority-secondary');

					<cfif session.IsAdmin IS true>
					var suPatchNameID = $("#list").getDataIDs().indexOf(lastsel);
					var suPatchNameIDVal = jQuery("#list").getCell(suPatchNameID,2);
					$('#list').editRow(id, true, undefined, function(res) {
					    // res is the response object from the $.ajax call
					    $("#list").trigger("reloadGrid");
					});
					</cfif>
					
					lastsel = id;
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
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false});
		}
	);
</script>
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
