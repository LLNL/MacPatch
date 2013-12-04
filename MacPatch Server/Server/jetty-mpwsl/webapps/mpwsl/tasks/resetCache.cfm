<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>MP Task worker...</title>
</head>
<body>
<cfif #CGI.HTTP_USER_AGENT# EQ "BlueDragon">
	<!--- Note this will get moved in the next version and will require a server key --->
    <cfobjectcache action="CLEAR">
<cfelse>
	Welcome to MacPatch
</cfif>
</body>
</html>