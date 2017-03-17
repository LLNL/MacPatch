<!DOCTYPE html>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
	<title>MacPatch - Admin Console</title>    
	<link type="text/css" rel="stylesheet" href="layout-default-latest.css" />
	<style type="text/css">

	.ui-layout-pane {
		background:	#EEE;
	}
	.ui-layout-west {
		background:	#d9dee5;
	}
	.ui-layout-south {
		font-size: 10px;
	}
	.ui-layout-center {
		background:	#FFF;
		padding:	0; /* IMPORTANT - remove padding so pane can 'collapse' to 0-width */
		}
		.ui-layout-center > .wrapper {
			padding:	10px;
		}
		.ui-layout-pane			{ border-width:			0; }
		.ui-layout-north		{ border-bottom-width:	1px; padding:	4px;}
		.ui-layout-south		{ border-top-width:		1px; }
		.ui-layout-resizer-west { border-width:			0 1px; }
		
		.ui-layout-toggler-west { border-width:			0; }
		.ui-layout-toggler-west div {
		width:	4px;
		height:	10px; /* 3x 35 = 105 total height */
	}

	#image {
		float: left;
		display:inline-block;
   	 	width:60px;
   	 	height:60px;
	}
	#title {
		float: left;
  		line-height: 64px;
  		padding-left:12px;
  		font-size: 24px;
	}
	#loginInfo {
		margin-top: 8px;
		margin-right: 6px;
		float: right;
  		padding-left:12px;
  		font-size: 12px;
	}

	/* button 
	---------------------------------------------- */
	.button {
		display: inline-block;
		zoom: 1; /* zoom and *display = ie7 hack for display:inline-block */
		*display: inline;
		vertical-align: baseline;
		margin: 0 2px;
		outline: none;
		cursor: pointer;
		text-align: center;
		text-decoration: none;
		font: 14px/100% Arial, Helvetica, sans-serif;
		padding: .5em 2em .55em;
		text-shadow: 0 1px 1px rgba(0,0,0,.3);
		-webkit-border-radius: .5em; 
		-moz-border-radius: .5em;
		border-radius: .5em;
		-webkit-box-shadow: 0 1px 2px rgba(0,0,0,.2);
		-moz-box-shadow: 0 1px 2px rgba(0,0,0,.2);
		box-shadow: 0 1px 2px rgba(0,0,0,.2);
	}
	.button:hover {
		text-decoration: none;
	}
	.button:active {
		position: relative;
		top: 1px;
	}
	
	.bigrounded {
		-webkit-border-radius: 2em;
		-moz-border-radius: 2em;
		border-radius: 2em;
	}
	.medium {
		font-size: 12px;
		padding: .4em 1.5em .42em;
	}
	.small {
		font-size: 11px;
		padding: .2em 1em .275em;
	}
	
	/* color styles 
	---------------------------------------------- */
	
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


	</style>

	<script type="text/javascript" src="js/jquery-latest.js"></script>
	<script type="text/javascript" src="js/jquery-ui-latest.js"></script>
	<script type="text/javascript" src="js/layout/jquery.layout-latest.js"></script>

	<script type="text/javascript">

	$(document).ready(function(){

		// CREATE THE LAYOUT
		myLayout = $('body').layout({
			resizeWhileDragging: 			false
		,	sizable:						false
		,	west__size:						270
		,	west__minSize:					270
		,	west__maxSize:					500
		,	west__closable:					false
		,	west__resizable:				false
		,	spacing_open:					0
		,	spacing_closed:					0
		,	west__spacing_closed:			10
		,	west__spacing_open:				2
		,	west__togglerLength_closed:		0
		,	west__togglerLength_open:		0
		,	north__size:					70
		,	south__size:					30
		});

		$("a").click(function(e) {
			e.preventDefault();
			$("#bodyFrame").attr("src", $(this).attr("href"));
		})	
		
		$("lat").click(function(e) {
			e.preventDefault();
			$("body").attr("src", $(this).attr("href"));
		})	
	});

	// GENERIC HELPER FUNCTION
	function sizePane (pane, size) {
		myLayout.sizePane(pane, size);
		myLayout.open(pane); // open pane if not already
	};

    </script> 
    
    <script type="text/Javascript">
		function logout()
		{
			window.open('logout.cfm','_self') ;
		}
	</script>
</head>
<cfsilent>
	<cfset dbObj = CreateObject("component","cfc.db").init()>
	<cfif StructKeyExists( server, "mpsettings" )>
		<cfif StructKeyExists( server.mpsettings.settings, "dbSchema" )>
			<cfif StructKeyExists( server.mpsettings.settings.dbSchema, "schemaVersion" )>
				<cfset result = dbObj.checkSchemaVersion(server.mpsettings.settings.dbSchema.schemaVersion) />
			<cfelse>
				<cfset result = dbObj.checkSchemaVersion("0.0.0.0") />
			</cfif>
		</cfif>
	<cfelse>
		<cfset result = dbObj.checkSchemaVersion("0.0.0.0") />
	</cfif>

	<cfset session.myRes = result>
</cfsilent>
<body>
	<div class="ui-layout-north">
		<div id="image">
			<img src="images/MPLogo_60.png" alt="Logo">
		</div>  
		<div id="title">
			MacPatch - Admin Console
		</div> 
        <div id="loginInfo">
        	<cfoutput>Welcome, #session.RealName#</cfoutput>
            <br>
            <input class="button small gray" type="button" value="Logout" onclick="logout();return false;" style="float: right; margin-top:4px;">
		</div>
	</div> 
	<div class="ui-layout-west" style="padding:0px; margin:0px;">
    	<cfinclude template="menu.cfm">	
   	</div> 
	<div class="ui-layout-center">
		<div class="wrapper">
        	<cfset _checkSchema = false>
        	<cfif StructKeyExists( application.settings, "dbSchema" )>
        		<cfif StructKeyExists( application.settings.dbSchema, "checkSchema" )>
        			<cfset _checkSchema = application.settings.dbSchema.checkSchema>
        		</cfif>
        	</cfif>
        	<cfif _checkSchema EQ true>
	        	<cfif result.pass EQ false>
	        		<cfoutput>
	        		<iframe src="db_status.cfm?runningVersion=#result.runningVersion#&requiredVersion=#result.requiredVersion#" name="bodyFrame" id="bodyFrame" scrolling="yes" frameborder="0" style="overflow:auto;overflow-x:auto;overflow-y:auto;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px" height="100%" width="100%">
		            </iframe>
		            </cfoutput>
	        	<cfelse>
		        	<iframe src="inc/dashboard.cfm" name="bodyFrame" id="bodyFrame" scrolling="yes" frameborder="0" style="overflow:auto;overflow-x:auto;overflow-y:auto;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px" height="100%" width="100%">
		            </iframe>
	        	</cfif>
        	<cfelse>
        		<iframe src="inc/dashboard.cfm" name="bodyFrame" id="bodyFrame" scrolling="yes" frameborder="0" style="overflow:auto;overflow-x:auto;overflow-y:auto;height:100%;width:100%;position:absolute;top:0px;left:0px;right:0px;bottom:0px" height="100%" width="100%">
	            </iframe>
        	</cfif>
		</div>
	</div> 
	<div class="ui-layout-south">MacPatch Version 3.0.0</div>
</body>
</html>