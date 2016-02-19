<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<cfsilent>
	<cfparam name="groupName" type="string" default="NA" />
	<cfparam name="hasGroup" type="boolean" default="false" />
	<cfif IsDefined("url.group")>
		<cftry>
			<cfquery name="qGroup" datasource="#session.dbsource#">
				select gName
				From mp_software_groups
				Where gid = <cfqueryparam value="#url.group#">
			</cfquery>
			<cfif qGroup.recordcount NEQ 1>
				<cflocation url="#GetFileFromPath(CGI.HTTP_REFERER)#" addtoken="false">
			<cfelse>
				<cfset groupName = qGroup.gName />
				<cfset hasGroup = true />
			</cfif>
			<cfcatch type="any">
                <cflocation url="#GetFileFromPath(CGI.HTTP_REFERER)#" addtoken="false">
            </cfcatch>
		</cftry>
	<cfelse>
		<cflocation url="#GetFileFromPath(CGI.HTTP_REFERER)#" addtoken="false">
	</cfif>
</cfsilent>

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/jqGrid/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/admin/css/mp.css" />
<script src="/admin/js/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script src="/admin/js/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
<script src="/admin/js/mp-jqgrid-common.js" type="text/javascript"></script>

<style>
  fieldset
  {
    -moz-border-radius-bottomleft: 7px;
    -moz-border-radius-bottomright: 7px;
    -moz-border-radius-topleft: 5px;
    -moz-border-radius-topright: 7px;
    -webkit-border-radius: 7px;
    border-radius: 3px;
	border: solid 1px gray;
	padding: 4px;
	margin-bottom:10px;
	font-size: 12px;
	text-align:right;
	//line-height: 30px;
	
  }
  legend
  {
    color: black;
	padding: 4px;
	font-weight:bold;
  }
  
	.dlTitle {
		font-size: 12px;
		text-align:right;
		margin-bottom:10px;
	}
	
	/* gray */
	.gray {
		color: #e9e9e9;
		border: solid 1px #555;
		background: #6e6e6e;
		background: -webkit-gradient(linear, left top, left bottom, from(#888), to(#575757));
		background: -moz-linear-gradient(top,  #888,  #575757);
		filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#888888', endColorstr='#575757');
	}
	.gray:hover {
		background: #616161;
		background: -webkit-gradient(linear, left top, left bottom, from(#757575), to(#4b4b4b));
		background: -moz-linear-gradient(top,  #757575,  #4b4b4b);
		filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#757575', endColorstr='#4b4b4b');
	}
	.gray:active {
		color: #afafaf;
		background: -webkit-gradient(linear, left top, left bottom, from(#575757), to(#888));
		background: -moz-linear-gradient(top,  #575757,  #888);
		filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#575757', endColorstr='#888888');
	}
  
	.btn 
	{
		padding: 6px 12px;
		color: #FFF;
		-webkit-border-radius: 4px;
		-moz-border-radius: 4px;
		border-radius: 4px;
		text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.4);
		-webkit-transition-duration: 0.2s;
		-moz-transition-duration: 0.2s;
		transition-duration: 0.2s;
		-webkit-user-select:none;
		-moz-user-select:none;
		-ms-user-select:none;
		user-select:none;
		display:inline-block;
		vertical-align:middle;
		margin-top: 6px;
	}
	.btn:hover {
		//background: #356094;
		//border: solid 1px #2A4E77;
		text-decoration: none;
	}
	.btn:active {
		/*
		-webkit-box-shadow: inset 0 1px 4px rgba(0, 0, 0, 0.6);
		-moz-box-shadow: inset 0 1px 4px rgba(0, 0, 0, 0.6);
		box-shadow: inset 0 1px 4px rgba(0, 0, 0, 0.6);
		background: #2E5481;
		border: solid 1px #203E5F;
		*/
		position: relative;
		top: 1px;
	}
	div.centered {
	    position: fixed;
	    top: 50%;
	    left: 50%;
	    margin-top: -250px;
	    margin-left: -200px;
	}
</style>

<script type="text/javascript">
	$(document).ready(function()
		{

			$(window).bind('resize', function() {
				$("#swGrpFilter").setGridWidth($(window).width()-20);
			}).trigger('resize');
			
			var lastCFilterSel
			$("#swGrpFilter").jqGrid(
			{
				url:'software_groups.cfc?method=getGroupFilters&gid=<cfoutput>#url.group#</cfoutput>', //CFC that will return the users
				datatype: 'json', //We specify that the datatype we will be using will be JSON
				colNames:['', 'Type', 'DataSource', 'Operator', 'Filter Value', 'Condition'],
				colModel :[ 
				  {name:'rid',index:'rid', width:20, align:"center", sortable:true, hidden:true},
				  {name:'attribute', index:'attribute', width:60, editable:true, edittype:"select", 
				  editoptions:{value:"ldap:LDAP Query; cuuid:Client ID;ipaddr:IP Address;Domain:Client Group;agent_version:Agent Version;client_version:Client Version;osver:OS Version;Model_Identifier:Model Identifier;Model_Name:Model Name"}},
				  {name:'datasource', index:'datasource', width:60,editable:true, edittype:"select", editoptions:{value:"Database:Database"}},
				  {name:'attribute_oper', index:'attribute_oper', width:60,editable:true, edittype:"select", editoptions:{value:"In:In;EQ:Equal;NEQ:Not Equal;Contains:Contains"}},
				  {name:'attribute_filter', index:'attribute_filter', width:200, editable:true}, 
				  {name:'attribute_condition', index:'attribute_condition', width:60, editable:true, edittype:"select", editoptions:{value:"AND:AND;OR:OR;None:None"}}
				],
				altRows:true,
				altclass:'xAltRow',
				pager: jQuery('#agentFilterPager'), //The div we have specified, tells jqGrid where to put the pager
				rowNum:10, //Number of records we want to show per page
				rowList:[5,10,15,20,25], //Row List, to allow user to select how many rows they want to see per page
				sortorder: "asc", //Default sort order
				sortname: "rid", //Default sort column
				viewrecords: true, //Shows the nice message on the pager
				imgpath: '/', //Image path for prev/next etc images
				caption: 'Software Group Filter - <cfoutput>#groupName#</cfoutput>', //Grid Name
				height:'auto', //I like auto, so there is no blank space between. Using a fixed height can mean either a scrollbar or a blank space before the pager
				recordtext: "View {0} - {1} of {2} Records",
				pgtext: "Page {0} of {1}",
				pginput:true,
				width:980,
				hiddengrid:false,
				hidegrid:true,
				editurl:"software_groups.cfc?method=editGroupFilters&gid=<cfoutput>#url.group#</cfoutput>",//Not used right now.
				toolbar:[false,"top"],//Shows the toolbar at the top. I will decide if I need to put anything in there later.
				//The JSON reader. This defines what the JSON data returned from the CFC should look like
				onSelectRow: function(id)
				{
					if(id && id!==lastCFilterSel)
					{
					  lastCFilterSel=id;
					}
				},
				ondblClickRow: function(id) 
				{
				    <cfif session.IsAdmin IS true>
					$('#swGrpFilter').editRow(id, true, undefined, function(res) {
					    // res is the response object from the $.ajax call
					    $("#swGrpFilter").trigger("reloadGrid");
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
				}
			);
			<cfif session.IsAdmin IS true>
			$("#swGrpFilter").jqGrid('navGrid',"#agentFilterPager",
				{edit:true,add:true,del:true},
				{ 
					beforeShowForm: function(form) 
					{
						var dlgDiv = $("#editmodswGrpFilter");
						var parentDiv = dlgDiv.parent();
						var dlgWidth = dlgDiv.width();
						var parentWidth = $(window).width();
						var dlgHeight = dlgDiv.height();
						var parentHeight = $(window).height()-dlgDiv.height();
						// TODO: change parentWidth and parentHeight in case of the grid
						//       is larger as the browser window
						dlgDiv[0].style.top = Math.round((parentHeight-dlgHeight)/2) + "px";
						dlgDiv[0].style.left = Math.round((parentWidth-dlgWidth)/2) + "px";
                    }
            	});
			</cfif>
			$(window).bind('resize', function() {
				$("#agentFilter").setGridWidth($(window).width()-20);
			}).trigger('resize');
		} 	
	);
</script>
<div id="btn"></div>
<table id="swGrpFilter" cellpadding="0" cellspacing="0" style="font-size:11px;"></table>
<div id="agentFilterPager"></div>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>
