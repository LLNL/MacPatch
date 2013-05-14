<cfsetting showDebugOutput="No">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Detailed Info</title>
</head>
<body>
<cfsilent>
<cfquery name="getProxyServerID" datasource="#session.dbsource#">
	Select * From mp_proxy_key
	Where type = <cfqueryparam value="1">
</cfquery>
</cfsilent>
<cfoutput>
<b>MacPatch Proxy Server ID Key:</b> #getProxyServerID.proxy_key#<br />
<br />
Note: Please copy this key exactly as when adding it to the proxy server.
</cfoutput>
</body>
</html>