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
    <cftry>
        <cfquery datasource="#session.dbsource#" name="qGetName">
            select name
            From mp_patch_group
            Where id = '#url.pgid#'
        </cfquery>
        <cfcatch>
        	<cflog application="yes" text="#cfcatch.Detail#">
            <cfabort>
        </cfcatch>
    </cftry>
</cfsilent>
<script type="text/javascript">	
	function loadContent(param, id, type) {
		$("#dialog").load("/admin/inc/patch_description.cfm?id="+id+"&type="+type);
		$("#dialog").dialog( {
			bgiframe: false, height: 400, width: 600, modal: true 
		} ); 
		$("#dialog").dialog('open');
	}
</script>

<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'patch_group_view.cfc?method=getPatchGroupPatches&patchgroup=<cfoutput>#url.pgid#</cfoutput>',
				datatype: 'json',
				colNames:['','Patch', 'Title', 'Type', 'PostDate'],
				colModel :[ 
				  {name:'rid', index:'rid', width:20, align:"center", sortable:false, search : false},
				  {name:'name', index:'name', width:140}, 
				  {name:'title', index:'title', width:200, sorttype:'float'},
				  {name:'type', index:'type', width:50, align:"center"}, 
				  {name:'postdate', index:'postdate', width:70, align:"center"}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'),
				rowNum:20,
				rowList:[10,20,30,50,100],
				sortorder: "desc",
				sortname: "postdate",
				viewrecords: true,
				imgpath: '/',
				caption: 'View Patch Group - <cfoutput>#qGetName.name#</cfoutput>',
				height:'auto',
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"",
				toolbar:[false,"top"],
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						var pType = encodeURI(jQuery("#list").getCell(cl,'type'));
						info = "<input type='image' style='padding-left:4px;' onclick=loadContent('info','"+cl+"','"+pType+"'); src='/admin/images/info_16.png'>";
						jQuery("#list").setRowData(ids[i],{rid:info})
					} 
				}, 
				onSelectRow: function(id)
				{
					if(id && id!==lastsel)
					{
					  lastsel=id;
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
			});
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true});
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true, defaultSearch: 'cn'});
			mygrid[0].toggleToolbar();
			
			$(window).bind('resize', function() {
				$("#list").setGridWidth($(window).width()-20);
			}).trigger('resize');
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>