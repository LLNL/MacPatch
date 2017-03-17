<cfsetting showDebugOutput="No">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Detailed Info</title>
</head>
<body>
<cfsilent>
<cflog application="yes" type="error" text="Type: #url.type#">
<cfif url.type EQ "Apple">
	<cflog application="yes" type="error" text="Type id: #url.id#">
    <cfquery datasource="#session.dbsource#" name="qGet">
        select description64
        From apple_patches
        <cfif isdefined("url.id")>
            Where akey = '#url.id#'
        <cfelse>
        	<cfabort>
        </cfif>
    </cfquery>
<cfelse>
	<cfquery datasource="#session.dbsource#" name="qGet">
        select description
        From mp_patches
        <cfif isdefined("url.id")>
            Where puuid = '#url.id#'
        <cfelse>
        	<cfabort>
        </cfif>
    </cfquery>
</cfif>
</cfsilent>
<cfoutput query="qGet">
<cfif url.type EQ "Apple">
<cfset rawText = #ToString(ToBinary(description64))#>
<cfset text = ReplaceNoCase(rawText, Chr(226), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(230), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(194), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(128), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(162), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(13), "", "All")>
<cfset text = ReplaceNoCase(text, Chr(10), "", "All")>
<cfset text = ReplaceNoCase(text, "Data('", "", "All")>
<cfset text = ReplaceNoCase(text, "\n')", "", "All")>
<cfset text = ReplaceNoCase(text, "\n", "", "All")>
<cfset text = ReplaceNoCase(text, "\r", "", "All")>
<cfset text = ReplaceNoCase(text, "\t", "", "All")>
<cfset text = ReplaceNoCase(text, "<a href", "<a target='_blank' href", "All")>
#text#
<cfelse>
#description#
</cfif>
</cfoutput>
</body>
</html>