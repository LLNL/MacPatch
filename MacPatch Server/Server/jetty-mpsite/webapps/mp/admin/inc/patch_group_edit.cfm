<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">


<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>

<cfsilent>
	<cfquery name="getSrvInfo" datasource="#session.dbsource#" result="res">
		select server, useSSL from mp_servers
		Where isMaster = '1' and active = '1'
	</cfquery>
	<cfif getSrvInfo.RecordCount GTE 1>
		<cfset mpServer = IIF(getSrvInfo.useSSL EQ 1,DE('https://'),DE('http://')) & getSrvInfo.server >
	<cfelse>	
		<cfset mpServer = "https://localhost" >
	</cfif>
</cfsilent>
<script type="text/javascript">	
	function loadContent(param, id) {
		$("#dialog").load("available_patches_apple_description.cfm?id="+id);
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
	function downloadURL(url)
	{
	  var iframe;
	  iframe = document.getElementById("hiddenDownloader");
	  if (iframe === null)
	  {
		iframe = document.createElement('iframe');  
		iframe.id = "hiddenDownloader";
		iframe.style.visibility = 'hidden';
		document.body.appendChild(iframe);
	  }
	  iframe.src = "<cfoutput>#mpServer#</cfoutput>" + url;   
	}
</script>
<script type="text/Javascript">
	function load(url,id)
	{
		window.open(url,'_self') ;
	}
</script>
<style type="text/css">
	.ui-jqgrid {font-size:12px;}
	.ui-jqgrid .ui-jqgrid-titlebar {font-size:18px; font-weight:bold; font-style:italic;}
	.ui-jqgrid .ui-jqgrid-htable th {font-size:12px; font-weight:bold; vertical-align:bottom;}
	.ui-jqgrid .ui-jqgrid-pager { font-size: 12px; vertical-align:center;}
	.ui-jqgrid-btable .ui-state-highlight { background: yellow; }
	
	.dimImg {
		filter: url(filters.svg#grayscale); /* Firefox 3.5+ */
		filter: gray; /* IE6-9 */
		-webkit-filter: grayscale(1); /* Google Chrome & Safari 6+ */
	}
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
<style type="text/css">
    .xAltRow { background-color: #F0F8FF; background-image: none; }
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
				colNames:['','', 'Patch', 'Description', 'Reboot', 'Type', 'Patch State', 'Baseline', 'Release Date'],
				colModel :[ 
				  {name:'rid',index:'rid', width:36, align:"center", sortable:false, resizable:false, hidden:true, search : false},
				  {name:'enbl', index:'enbl', width: 30, align:'center', search : false, sortable:true, sorttype:'int', formatter:'checkbox', editoptions:{value:'1:0'}, 
				  formatoptions:{disabled:<cfif session.IsAdmin IS true>false<cfelse>true</cfif>}},		
				  {name:'name', index:'name', width:200}, 
				  {name:'title', index:'title', width:300},
				  {name:'reboot', index:'reboot', width:40, align:"center"},
				  {name:'type', index:'type', width:40, align:"center"},
				  {name:'patch_state', index:'patch_state', width:40},
				  {name:'baseline_enabled', index:'baseline_enabled', width:40},
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
					}
					// Auto Enable Disable on Checkbox
                    var iCol = getColumnIndexByName ($(this), 'enbl'), rows = this.rows, i, c = rows.length;
                    for (i = 0; i < c; i += 1) {
                        $(rows[i].cells[iCol]).click(function (e) {
                            var id = $(e.target).closest('tr')[0].id,
                                isChecked = $(e.target).is(':checked');
								
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
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").navButtonAdd("#pager",
				{	caption:"",
					title:"Save Patch Data", 
			   		buttonicon:'ui-icon-disk', 
					onClickButton: function() 
					{
						/*
						load("patch_group_data_save.cfm?pID="+ <cfoutput>#pID#</cfoutput>);
						*/
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