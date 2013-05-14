<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8">
	<title>MacPatch v2.1.0 - Admin</title>
	<link type="text/css" href="./_assets/css/main/mp_base.css" rel="stylesheet" />
	
    <!-- Standard reset, fonts and grids -->
	<link rel="stylesheet" type="text/css" href="./_assets/js/yui/build/reset-fonts-grids/reset-fonts-grids.css">
    <!-- CSS for Menu -->
	<link rel="stylesheet" type="text/css" href="./_assets/js/yui/build/assets/skins/sam/menu.css">

	<style type="text/css">
		#custom-doc {
			width:76.92em;
			*width:75.07em;
			min-width:970px;
			margin:auto;
			text-align:left;
			height:100%;
			min-height:100%;
		}

		html{
		   height: 100%;
		   width: 100%;
		   margin: 0em;
		   padding: 0em;
		}

		body {
			background-color:#F7F7F7;
			height: 100%;
		}

		#hd {
			margin: 0;
			color: #FFF;
			background-color: #000;
			padding-top: 4px;
			padding-right: 4px;
			padding-bottom: 4px;
			padding-left: 10px;
			height:auto;
		}

		 #bd {
			margin: 0;
			color: #000;
			background-color: #FFF;
			min-height: 100%;
			height:auto;
			height: 100%;
		}

		#appData {
			margin: 8px;
		}

		#ft {
			height:auto;
			background-color: #FFF;
		}

		#mpservices {
			margin: 0 0 10px 0;
		}

		.yuimenu {
			width: 170px;
		}

		.yuimenuitemlabel, .yuimenubaritemlabel {
			font-size:12px;
		}
	</style>
	<!-- Dependency source files -->
	<script type="text/javascript" src="./_assets/js/yui/build/yahoo-dom-event/yahoo-dom-event.js"></script>
	<script type="text/javascript" src="./_assets/js/yui/build/container/container_core.js"></script>
	<!-- Menu source file -->
	<script type="text/javascript" src="./_assets/js/yui/build/menu/menu.js"></script>
	<!-- Page-specific script -->
	<script type="text/javascript">
        YAHOO.util.Event.onContentReady("mpservices", function () {
            var oMenuBar = new YAHOO.widget.MenuBar("mpservices", { 
                                                        autosubmenudisplay: true, 
                                                        hidedelay: 750, 
                                                        lazyload: true });

            oMenuBar.render();         
        });
    </script>	
</head>
<body class="yui-skin-sam" id="yahoo-com">
<div id="custom-doc" class="yui-t7">
<div id="hd" role="banner" align="right">
	<img src="./_assets/images/macpatchbanner.jpg" align="left">
	<cfoutput>v2.1.0 | <a href="../">Logout</a><br><div style="font-size:10px;">Welcome, #session.RealName#</div></cfoutput>
</div>
<div id="bd" role="main">
	<div class="yui-g" style="position:relative; z-index:2;">
	<!-- YOUR DATA GOES HERE -->
    <cfinclude template="_menu.cfm">
	</div>
	<div id="appData" role="application" class="yui-g"  style="position:relative; z-index:1;">