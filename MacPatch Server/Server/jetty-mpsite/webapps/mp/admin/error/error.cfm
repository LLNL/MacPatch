<html>
<head>
<title>Oops! An error has occurred.</title>
</head>

<body>
<p align="center"><strong>We're Sorry! An error has occurred.</strong><br>
The details of this error have been emailed to the web application administrator.<br>
Please <a href="<cfoutput>#CGI.HTTP_REFERER#</cfoutput>">click here</a> to return to the previuse page.</p>
</body>
<cfdump var="#application#">
</html>

<cflog file="MPADMINAPP" text="#error.message# - #error.diagnostics#">

<cfsavecontent variable="errortext">
<cfoutput>
An error occurred: http://#cgi.server_name##cgi.script_name#?#cgi.query_string#<br />
Time: #dateFormat(now(), "short")# #timeFormat(now(), "short")#<br />

<cfdump var="#error#" label="Error">
<cfdump var="#form#" label="Form">
<cfdump var="#url#" label="URL">

</cfoutput>
</cfsavecontent>


<cfmail to="heizer1@llnl.gov" from="heizer1@llnl.gov" subject="Error: #error.message#" type="html" server="#application.settings.mailserver.server#">
    #errortext#
</cfmail>

<cfabort>