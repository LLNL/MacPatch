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
    .xAltRow { background-color: #F0F8FF; background-image: none; }
</style>
<script type="text/javascript">
	$(document).ready(function()
		{
			var lastsel=-1;
			var mygrid = $("#list").jqGrid(
			{
				url:'./includes/available_patches_mp.cfc?method=getMPPatches',
				datatype: 'json',
				colNames:['','','Patch Name', 'Version', 'Bundle ID', 'Severity', 'Reboot', 'State', 'Release Date'],
				colModel :[ 
				  {name:'puuid',index:'puuid', width:20, align:"center", sortable:false, resizable:false, search:false},
				  {name:'pkg_url',index:'pkg_url', width:20, align:"center", sortable:false, resizable:false, search:false},
				  {name:'patch_name', index:'patch_name', width:120,editable:true}, 
				  {name:'patch_ver', index:'patch_ver', width:40, sorttype:'float',editable:true},
				  {name:'bundle_id', index:'bundle_id', width:90, align:"left"},
				  {name:'patch_severity', index:'patch_severity', width:44, align:"center", editable:true, edittype:"select", editoptions:{value:"High:High; Medium:Medium; Low:Low; Unknown:Unknown"}}, 
				  {name:'patch_reboot', index:'patch_reboot', width:40, align:"center", editable:true, edittype:"select", editoptions:{value:"No:No;Yes:Yes"}}, 
				  {name:'patch_state', index:'patch_state', width:50, align:"center", editable:true, edittype:"select", editoptions:{value:"Production:Production;QA:QA;Create:Create;Disabled:Disabled"}},
				  {name:'mdate', index:'mdate', width:70, align:"center", formatter: 'date', formatoptions: {srcformat:"F, d Y H:i:s", newformat: 'Y-m-d' }}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#pager'),
				rowNum:20,
				rowList:[10,20,30,50,100],
				sortorder: "desc",
				sortname: "cdate",
				viewrecords: true,
				imgpath: '/',
				caption: 'Custom Patches',
				height:'auto',
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hidegrid:false,
				editurl:"includes/available_patches_mp.cfc?method=addEditMPPatch",
				toolbar:[false,"top"],
				loadComplete: function(){ 
					var ids = jQuery("#list").getDataIDs(); 
					for(var i=0;i<ids.length;i++){ 
						var cl = ids[i];
						var myCellData = encodeURI(jQuery("#list").getCell(cl,'pkg_url'));
						<cfif session.IsAdmin IS true>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?adm_mp_patch_edit="+ids[i]+"'); src='./_assets/images/jqGrid/edit_16.png'>";
						<cfelse>
						edit = "<input type='image' style='padding-left:4px;' onclick=load('./index.cfm?mp_patch_view="+ids[i]+"'); src='./_assets/images/jqGrid/info_16.png'>";
						</cfif>
						dl = "<input type='image' style='padding-left:0px;' onclick=downloadURL('/mp-content"+myCellData+"'); src='./_assets/images/icons/arrow_down.png'>";
						jQuery("#list").setRowData(ids[i],{puuid:edit,pkg_url:dl}) 
					} 
				}, 
				onSelectRow: function(id)
				{
					if(id && id!==lastsel)
					{
					  lastsel=id;
					}
				},
				ondblClickRow: function(id) 
				{
				    <cfif session.IsAdmin IS true>
					var patchID = $("#list").getDataIDs().indexOf(lastsel);
					var patchIDVal = jQuery("#list").getCell(patchID,2);
					$('#list').editRow(id, true, undefined, function(res) 
					{
					    $("#list").trigger("reloadGrid");
					});
					</cfif>
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
			<cfif session.IsAdmin IS true>	
			$("#list").jqGrid('navGrid',"#pager",{edit:true,add:false,del:true},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true}
				)
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
			<cfelse>
			$("#list").jqGrid('navGrid',"#pager",{edit:false,add:false,del:false},
				{}, // default settings for edit
				{}, // default settings for add
				{}, // delete
				{ sopt:['cn','bw','eq','ne','lt','gt','ew'], closeOnEscape: true, multipleSearch: true, closeAfterSearch: true }, // search options
				{closeOnEscape:true}
				);
			</cfif>
			$("#list").navButtonAdd("#pager",{caption:"",title:"Toggle Search Toolbar", buttonicon:'ui-icon-pin-s', onClickButton:function(){ mygrid[0].toggleToolbar() } });
			$("#list").jqGrid('filterToolbar',{stringResult: true, searchOnEnter: true, defaultSearch: 'cn'});
			mygrid[0].toggleToolbar();
		}
	);
</script>
<div align="center">
<table id="list" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="pager" style="text-align:center;font-size:11px;"></div>
</div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
