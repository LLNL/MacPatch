<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>

<cfsilent>
	<cfset hasEditRights = false>
</cfsilent>

<script type="text/javascript">	
	function loadContent(param, id, type) {
		$("#dialog").load("/admin/inc/patch_description.cfm?id="+id+"&type="+type);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 400,
			width: 600,
			modal: true
			}
		); 
		$("#dialog").dialog('open');
	}
</script>

<style type="text/css">
	#overlay {
		/*width:100%; float:center; */
		width:100%;
    	height:100%;
		background-color: black;

		position: fixed;
		top: 0; right: 0; bottom: 0; left: 0;
		/*
		position:fixed;
		left:50%;
		top:50%;
		margin:-50px 0 0 -50px;
		*/
		opacity: 0.7; /* also -moz-opacity, etc. */
		z-index: 10;
		display:none;
	}
</style>

<cfif isDefined("url.pgid")>
	<cfquery name="qInfo" datasource="#session.dbsource#">
        select id, name
        From mp_patch_group
        Where id = <cfqueryparam value="#url.pgid#">
    </cfquery>
    <cfif qInfo.RecordCount EQ 1>
    	<cfset pName = qInfo.name>
        <cfset pID = qInfo.id>
    <cfelse>
    	Error occured.
    	<cfabort>
    </cfif>

	<!--- Has Rights To Edit --->
	<cfquery name="qHasRights" datasource="#session.dbsource#">
		select is_owner from mp_patch_group_members
		Where user_id = '#session.Username#'
		AND patch_group_id = <cfqueryparam value="#pID#">
	</cfquery>
	
	<cfif qHasRights.RecordCount EQ 1 OR session.IsAdmin EQ True>
    	<cfset hasEditRights = true>
    </cfif>
</cfif>

<script type="text/javascript">
	$(document).ready(function()
		{
			function getLink() {
				var rowid = $("#list").getGridParam('selrow');
				var MyCellData = $("#list").jqGrid('getCell', rowid, 'p_name');
				return MyCellData;
			}

			var selMe = 0;
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
			var mygrid = $("#list").jqGrid(
			{
				sortable: true,
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				ajaxGridOptions:{
					type: "POST",
					url: "patch_group_edit.cfc?method=getPatchGroupPatches&patchgroup=<cfoutput>#pID#</cfoutput>",
				},
				<cfif isDefined("fDD")>
				postData: {
					/* method: '', */
					searchType:true,
					searchField: function() { return "baseline_id"; },
					searchString: function() { return "<cfoutput>#fDD#</cfoutput>"; },
					searchOper: function() { return "cn"; }
				},
				</cfif>
				colNames:['','', '', 'Patch', 'Description', 'Reboot', 'Type', 'Patch State', 'Release Date'],
				colModel :[
				  {name:'rid',index:'rid', width:36, align:"center", sortable:false, resizable:false, hidden:true, search : false},
				  {name:'info',index:'info', width:36, align:"center", sortable:false, resizable:false, hidden:false, search : false},
				  {name:'enbl', index:'enbl', width: 30, align:'center', search : false, sortable:true, sorttype:'int', formatter:'checkbox', editoptions:{value:'1:0'},
				  formatoptions:{disabled:<cfif session.IsAdmin IS true>false<cfelseif hasEditRights IS true>false<cfelse>true</cfif>}},
				  {name:'name', index:'name', width:200},
				  {name:'title', index:'title', width:300},
				  {name:'reboot', index:'reboot', width:40, align:"center"},
				  {name:'type', index:'type', width:40, align:"center"},
				  {name:'patch_state', index:'patch_state', width:40},
				  {name:'postdate', index:'postdate', width:100}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:20, //Number of records we want to show per page
				rowList:[10,20,30,50,100], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "desc", //Default sort order
				sortname: "postdate", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Edit Patch Group - <cfoutput>#pName#</cfoutput>', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				multiselect: false,
				multiboxonly: false,
				editurl:"patch_group_edit.cfc?method=addEditPatchGroupPatches",//Not used right now.
				toolbar:[false,"top"],
				loadComplete: function(){
					var ids = jQuery("#list").getDataIDs();
					for(var i=0;i<ids.length;i++){
						var cl = ids[i];
						
						var pType = encodeURI(jQuery("#list").getCell(cl,'type'));
						infoOpt = "<input type='image' style='padding-left:4px;' onclick=loadContent('info','"+cl+"','"+pType+"'); src='/admin/images/info_16.png'>";
						jQuery("#list").setRowData(ids[i],{info:infoOpt})
						
					}
					// Auto Enable Disable on Checkbox
                    var iCol = getColumnIndexByName ($(this), 'enbl'), rows = this.rows, i, c = rows.length;
                    for (i = 0; i < c; i += 1) {
                        $(rows[i].cells[iCol]).click(function (e) {
                            var id = $(e.target).closest('tr')[0].id,
                                isChecked = $(e.target).is(':checked');
                            <cfif hasEditRights IS true>
                            $.ajax({
							    url: "patch_group_edit.cfc"
							  , type: "get"
							  , dataType: "json"
							  , data: {
							      method: "togglePatch",
							  	  id: id,
								  gid: "<cfoutput>#pID#</cfoutput>"
							  }
							  // this runs if an error
							  , error: function (xhr, textStatus, errorThrown){
							    // show error
							    alert(errorThrown);
							  }
							});
							</cfif>
                        });
                    }
				},
				onSelectRow: function(id){
					/* This section of code fixes the highlight issues, with altRows */
					selMe = id;
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


			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true});
			$("#list").navButtonAdd("#pager",
				{	caption:"",
					title:"Toggle Search Toolbar", 
					buttonicon:'ui-icon-pin-s', 
					onClickButton:function(){ mygrid[0].toggleToolbar() 
				} 
			});

			<cfif hasEditRights IS true>
			$("#list").navButtonAdd("#pager",
				{	caption:"",
					title:"Save Patch Data",
			   		buttonicon:'ui-icon-disk',
					onClickButton: function()
					{
						$.ajax({
						 	url: "patch_group_edit.cfc",
							type: "get",
							dataType: "json",
							data: {
							      method: "savePatchGroupData",
							  	  id: "<cfoutput>#pID#</cfoutput>"
							},
							// this runs if an error
							error: function (xhr, textStatus, errorThrown) {
							    // show error
								$('#overlay').hide();
							    alert(errorThrown);
							},
							beforeSend: function() {
								$('#overlay').show();    /*showing  a div with spinning image */
							},
							/* after success  */
							success: function(response) {
							   /*  simply hide the image */
							   $('#overlay').hide();
							   /*  your code here   */
							}
						});
					}
			});
			$("#list").navButtonAdd('#pager',{
				caption:"Select All",
				buttonicon:"ui-icon-gear",
				title:"Select All Patches",
				onClickButton: function() {
					$.ajax({
						url: "patch_group_edit.cfc",
						type: "get",
						dataType: "json",
						data: {
							  method: "SelectAll",
							  patchgroup: "<cfoutput>#pID#</cfoutput>"
						},
						// this runs if an error
						error: function (xhr, textStatus, errorThrown) {
							// show error
							$('#overlay').hide();
							alert(errorThrown);
						},
						beforeSend: function() {
							$('#overlay').show();    /*showing  a div with spinning image */
						},
						/* after success  */
						success: function(response) {
						   /*  simply hide the image */
						   $('#overlay').hide();
						   $("#list").trigger("reloadGrid");
						   /*  your code here   */
						}
					});
				}
			});
			$("#list").navButtonAdd('#pager',{
				caption:"Select (Apple)",
			   	buttonicon:"ui-icon-gear",
			   	title:"Select Only Apple Patches",
				onClickButton: function() {
					$.ajax({
						url: "patch_group_edit.cfc",
						type: "get",
						dataType: "json",
						data: {
							  method: "SelectApple",
							  patchgroup: "<cfoutput>#pID#</cfoutput>"
						},
						// this runs if an error
						error: function (xhr, textStatus, errorThrown) {
							// show error
							$('#overlay').hide();
							alert(errorThrown);
						},
						beforeSend: function() {
							$('#overlay').show();    /*showing  a div with spinning image */
						},
						/* after success  */
						success: function(response) {
						   /*  simply hide the image */
						   $('#overlay').hide();
						   $("#list").trigger("reloadGrid");
						   /*  your code here   */
						}
					});
				},
			   	position:"last"
			});
			$("#list").navButtonAdd('#pager',{
				caption:"Select (Custom)",
			   	buttonicon:"ui-icon-gear",
			   	title:"Select Only Custom Patches",
				onClickButton: function() {
					$.ajax({
						url: "patch_group_edit.cfc",
						type: "get",
						dataType: "json",
						data: {
							  method: "SelectCustom",
							  patchgroup: "<cfoutput>#pID#</cfoutput>"
						},
						// this runs if an error
						error: function (xhr, textStatus, errorThrown) {
							// show error
							$('#overlay').hide();
							alert(errorThrown);
						},
						beforeSend: function() {
							$('#overlay').show();    /*showing  a div with spinning image */
						},
						/* after success  */
						success: function(response) {
						   /*  simply hide the image */
						   $('#overlay').hide();
						   $("#list").trigger("reloadGrid");
						   /*  your code here   */
						}
					});
				},
			   	position:"last"
			});
			</cfif>

			$("#list").navButtonAdd('#pager',{
				caption:"History",
			   	buttonicon:"ui-icon-calculator",
			   	title:"Patch History",
				onClickButton: function() 
				{
					load('patch_group_history.cfm?pgid=<cfoutput>#pID#</cfoutput>')
				},
			   	position:"last"
			});



			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true, defaultSearch: 'cn'});
			mygrid[0].toggleToolbar();

			$(window).bind('resize', function() {
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');

		}
	);

	function deleteGridRow(){
		var id = jQuery("#list").jqGrid('getGridParam','selrow');
		var pName = $('#list').jqGrid('getCell', id, 1);
		if( id != null ) {
			jQuery("#list").jqGrid('delGridRow',id,
			{
				height: 150,
				width: 300,
				msg: "<div align=\"left\" style=\"white-space: normal; font-size:11px;\">Are you sure you want to delete the patch "+pName+", from this baseline?</div>",
				modal: true
			});
		} else {
			alert("Please Select Row to delete!");
		}

	}
</script>

<div align="center">
<table id="list" cellpadding="0" cellspacing="0"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
<div id="overlay"><img src="/admin/images/loading.gif" style="display:block;margin:auto;padding-top:10%;" /></div>
