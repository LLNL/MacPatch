<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title></title>
    <link rel="stylesheet" href="/admin/js/tablesorter/themes/blue/style.css" type="text/css"/>
    <link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />    
	<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
	<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
</head>
<body>
<h3>WARNING</h3>
<cfoutput>
    The current database schema (#url.runningVersion#) does not match the required version (#url.requiredVersion#).<br>
    Please upgrade the database to the latest version of the database schema.
</cfoutput>
<cfabort>
</body>
</html>