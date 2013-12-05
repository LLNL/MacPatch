<cfset session.mp_sw_gid = l_gid>
<cffunction name="getGroupName" access="private">
	<cfargument name="gid" required="yes">

	<cfset var stcReturn = "NA">
	<cftry>
		<cfquery name="qSelSW" datasource="#session.dbsource#" result="res" Maxrows="1">
                Select gName
				from mp_software_groups
				Where gid = '#arguments.gid#'
        </cfquery>
        <cfif qSelSW.RecordCount NEQ 0>
			<cfset stcReturn = qSelSW.gName>
		</cfif>
		<cfcatch type="any">
               <cfset strMsgType = "Error">
           </cfcatch>
       </cftry>

	<cfreturn stcReturn>
</cffunction>
<script type="text/javascript">
	function taskInfo(id) {
		$("#TaskInfoDialog").load("./includes/sw_group_tasks_info.cfm?id="+id);
		$("#TaskInfoDialog").dialog(
		 	{
			bgiframe: false,
			height: 400,
			width: 700,
			modal: true
			}
		);
		$("#TaskInfoDialog").dialog('open');
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
			var getColumnIndexByName = function(grid, columnName) {
                    var cm = grid.jqGrid('getGridParam', 'colModel'), i, l;
                    for (i = 0, l = cm.length; i < l; i += 1) {
                        if (cm[i].name === columnName) {
                            return i; // return the index
                        }
                    }
                    return -1;
            };
			$("#list").jqGrid(
			{
				url:'./includes/sw_group_list.cfc?method=getCustomDataTasks', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['', 'Enable', 'Name', 'Active', 'Type', 'Start Date', 'End/Mandatory Date'],
				colModel :[
				  {name:'tuuid',index:'tuuid', width:30, align:"center", sortable:false, resizable:false},
				  {name:'enbl', index:'enbl', width: 60, align:'center', sortable:true, sorttype:'int', 
				  formatter:'checkbox', editoptions:{value:'1:0'}, 
				  formatoptions:{disabled:<cfif session.IsAdmin IS true>false<cfelse>true</cfif>}},
				  {name:'name',index:'name', width:200, align:"left"},
				  {name:'active',index:'active', width:100, align:"left"},
				  {name:'sw_task_type', index:'sw_task_type', width:100, align:"left"},
				  {name:'sw_start_datetime', index:'sw_start_datetime', width:120, align:"left"},
				  {name:'sw_end_datetime', index:'sw_end_datetime', width:120, align:"left"}
				],
				altRows:true,
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "mdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Software Distribution Group Tasks <cfoutput>(#getGroupName(l_gid)#)</cfoutput>', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/sw_group_list.cfc?method=editMPSoftwareGroupTasks",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				loadComplete: function () {
					// Set Info Button For Task Data
					var ids = jQuery("#list").getDataIDs();
					for(var x=0;x<ids.length;x++){
						var cl = ids[x];
						edit = "<input type='image' style='padding-left:2px;' onclick=taskInfo('"+cl+"'); src='./_assets/images/jqGrid/info.png'>";
						jQuery("#list").setRowData(ids[x],{tuuid:edit})
					}
					// Auto Enable Disable on Checkbox
                    var iCol = getColumnIndexByName ($(this), 'enbl'), rows = this.rows, i, c = rows.length;
                    for (i = 0; i < c; i += 1) {
                        $(rows[i].cells[iCol]).click(function (e) {
                            var id = $(e.target).closest('tr')[0].id,
                                isChecked = $(e.target).is(':checked');
                            /*
                            alert('clicked on the checkbox in the row with id=' + id +
                                  '\nNow the checkbox is ' +
                                  (isChecked? 'checked': 'not checked'));
							*/
                            $.ajax({
							    url: "./includes/sw_group_list.cfc"
							  , type: "get"
							  , dataType: "json"
							  , data: {
							      method: "setTaskEnabled",
							  	  id: id
							  }
							  // this runs if an error
							  , error: function (xhr, textStatus, errorThrown){
							    // show error
							    alert(errorThrown);
							  }
							});
                        });
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
					 load('./index.cfm?adm_sw_task_new');
				   }
				})
				.navButtonAdd('#pager',{
				   caption:"",
				   buttonicon:"ui-icon-copy",
				   title:"Duplicate Patch",
				   onClickButton: function(){
					 load("./index.cfm?adm_sw_task_dup="+ lastsel);
				   },
				   position:"last"
				});
			<cfelse>
				$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false});
			</cfif>
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="TaskInfoDialog" title="Detailed Task Information" style="text-align:left;" class="ui-dialog-titlebar"></div>

