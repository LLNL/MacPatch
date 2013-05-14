<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>MacPatch Proxy - Post Data</title>
</head>

<body>
<cfset currentPath = getCurrentTemplatePath()>
<cfset currentDirectory = getDirectoryFromPath(currentPath)>

<cfobject component="mpp_actions" name="mpp">
<cfinvoke component="#mpp#" method="postProxyData">
	<cfinvokeargument name="priKey" value="#currentDirectory#keys/mppri.pem">
    <cfinvokeargument name="pubKey" value="#currentDirectory#keys/mppub.pem">
    <cfinvokeargument name="proxyServerAddr" value="https://daywalker.llnl.gov">
    <cfinvokeargument name="proxyServerUsr" value="mppusrdev">
    <cfinvokeargument name="proxyServerPas" value="Apple2e">
</cfinvoke>

</body>
</html>