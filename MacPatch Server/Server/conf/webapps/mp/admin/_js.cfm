<style type="text/css">
	h3 {
		font-size:16px;
		font-weight:bold;
		padding-top:10px;
		padding-bottom:10px;
	}
</style>
<cfoutput>
<link rel="stylesheet" href="/admin/_assets/css/main/main.css" type="text/css" />
<link rel="stylesheet" href="/admin/_assets/css/main/main2.css" type="text/css" />

<cfif IsDefined("ISjqGrid") and ISjqGrid IS true>
<!--- OLD JQuery 1.4.x
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-1.4.2.min.js"></script>
    <link type="text/css" href="/admin/_assets/js/jquery/jquery-ui/themes/macpatch/jquery-ui-1.8.1.macpatch.css" rel="stylesheet" />

    <!--- jqGrid - jquery --->
    <link rel="stylesheet" type="text/css" href="/admin/_assets/js/jquery/jqGrid/css/ui.jqgrid.css">
    <link rel="stylesheet" type="text/css" media="screen" href="/admin/_assets/js/jquery/jqGrid/src/css/jquery.searchFilter.css" />

    <script src="/admin/_assets/js/jquery/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
    <script src="/admin/_assets/js/jquery/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
    <script src="/admin/_assets/js/jquery/jqGrid/src/grid.jqueryui.js" type="text/javascript"></script>


    <!--- Modal Dialog - jquery --->
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-ui/ui/ui.core.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-ui/ui/ui.draggable.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-ui/ui/ui.resizable.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-ui/ui/ui.dialog.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-ui/external/bgiframe/jquery.bgiframe.js"></script>

	<!--- Over rides --->
    <style type="text/css">
		.ui-jqgrid {font-size:10px;}
		.ui-jqgrid .ui-jqgrid-titlebar {font-size:16px; font-weight:bold; font-style:italic;}
		.ui-jqgrid .ui-jqgrid-htable th {font-size:11px; font-weight:bold; color:##000; vertical-align:bottom;}
	</style>
--->
	<!--- Base Theme and JQuery Script --->
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/jquery-1.7.1.min.js"></script>
    <link type="text/css" href="/admin/_assets/js/jquery_1.8.18/themes/macpatch/jquery-ui-1.8.1.macpatch.css" rel="stylesheet" />

	<!--- jqGrid - jquery --->
    <link rel="stylesheet" type="text/css" href="/admin/_assets/js/jquery_1.8.18/addons/jqGrid/css/ui.jqgrid.css">
    <link rel="stylesheet" type="text/css" media="screen" href="/admin/_assets/js/jquery_1.8.18/addons/jqGrid/src/css/jquery.searchFilter.css" />

	<script src="/admin/_assets/js/jquery_1.8.18/addons/jqGrid/js/i18n/grid.locale-en.js" type="text/javascript"></script>
    <script src="/admin/_assets/js/jquery_1.8.18/addons/jqGrid/js/jquery.jqGrid.min.js" type="text/javascript"></script>
    <script src="/admin/_assets/js/jquery_1.8.18/addons/jqGrid/src/grid.jqueryui.js" type="text/javascript"></script>

	<!--- Modal Dialog - jquery --->
    <script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.core.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.widget.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.button.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.mouse.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.draggable.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.position.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.resizable.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.dialog.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/external/jquery.bgiframe-2.1.2.js"></script>

	<!--- Over rides --->
    <style type="text/css">
		.ui-jqgrid {font-size:10px;}
		.ui-jqgrid .ui-jqgrid-titlebar {font-size:16px; font-weight:bold; font-style:italic;}
		.ui-jqgrid .ui-jqgrid-htable th {font-size:11px; font-weight:bold; color:##000; vertical-align:bottom;}
	</style>

<cfelseif IsDefined("ISPBWizard") and ISPBWizard IS true>
    <link href="/admin/_assets/css/patchBuilder/bp_main.css" rel="stylesheet" type="text/css">
	<link href="/admin/_assets/css/patchBuilder/style_wizard.css" rel="stylesheet" type="text/css">
	<link href="/admin/_assets/css/autofill/jquery.autocomplete.css" rel="stylesheet" type="text/css">
	<link type="text/css" href="/admin/_assets/js/jquery_1.8.18/themes/macpatch/jquery-ui-1.8.1.macpatch.css" rel="stylesheet" />
<!--- Old JQuery
	<script type="text/javascript" src="/admin/_assets/js/jquery/jquery-1.4.2.min.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery/SmartWizard.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery/jquery.autocomplete.js"></script>
--->
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/jquery-1.7.1.min.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.core.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.widget.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.mouse.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.slider.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/addons/SmartWizard/SmartWizard.js"></script>
	<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.autocomplete.js"></script>

<cfelse>
    <link rel="stylesheet" href="/admin/_assets/css/tablesorter/themes/blue/style.css" type="text/css" />
    <link rel="stylesheet" href="/admin/_assets/js/jquery/jquery-ui/themes/macpatch/jquery-ui-1.8.1.macpatch.css" type="text/css" />
    <link rel="stylesheet" href="/admin/_assets/js/jquery/jquery-contextmenu/jquery.contextmenu.css" type="text/css" />

    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery/jquery.tablesorter.js"></script>
    <script type="text/javascript" src="/admin/_assets/js/jquery/addons/pager/jquery.tablesorter.pager.js"></script>
    <script src="/admin/_assets/js/jquery/jquery-contextmenu/jquery.contextmenu.js" type="text/javascript"></script>

</cfif>
</cfoutput>