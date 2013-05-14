<cfsetting showDebugOutput="No">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Detailed Info</title>
</head>
<body>
<cfsilent>
<!---
<cfquery datasource="#session.dbsource#" name="qGet">
    select description64
    From apple_patches
	Where supatchname = '#url.id#'
</cfquery>
--->
<cfquery datasource="#session.dbsource#" name="qGet">
    select description64
    From apple_patches
    <cfif isdefined("url.id")>
		Where supatchname = '#url.id#'
    <cfelseif isdefined("url.pid")>
    	Where akey = '#url.pid#'
    </cfif>
</cfquery>
</cfsilent>
<cfoutput query="qGet">
<cfset rawText = #ToString(ToBinary(description64))#>
<cfset text = ReplaceNoCase(rawText, Chr(226), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(230), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(194), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(128), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(162), "", "All")>
<cfset text = ReplaceNoCase(text, "<a href", "<a target='_blank' href", "All")>
#text#
</cfoutput>
</body>
</html>