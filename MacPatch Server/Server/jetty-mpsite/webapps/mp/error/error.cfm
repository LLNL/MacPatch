<!DOCTYPE html>
<html lang="en">
	<head>
	<title>MacPatch Admin Application</title>
	<meta charset="utf-8">
	<meta name="description" content="" />
	<meta name="keywords" content="" />
	<link href="/assets/css/mp_bootstrap.css" rel="stylesheet" />
	</head>
<body>
<div id="headermain">
	<div id="headerbanner">
		<table cellpadding="0" cellspacing="0" width="1100">
			<tr>
			<td width="10">
				<img src="/assets/images/BannerLeftCorner.gif">
			</td>
			<td valign="top" bgcolor="#000000">
				<img src="/assets/images/macpatchbanner.jpg">
			</td>
			<td width="10">
				<img src="/assets/images/BannerRightCorner.gif">
			</td>
			</tr>
		</table>
	</div>
	<div id="headermenu">	
		<table cellpadding="0" cellspacing="0" width="1100" background="/assets/images/article-title-bg-apple.png">
			<tr height="30">
			   <td>
               </td>
			</tr>
		</table>
	</div>	
	<div id="headerStatusBar">
		&nbsp;
	</div>
</div>
<div id="bodymain">
	<div id="bodycontainer">
		<cfoutput>
        <table>
        	<tr>
            	<td><img src="/assets/images/caution64.png"></td>
                <td><p>We are so sorry. Something went wrong. We are working on it now.</p>
        			<br>
       				 <p><b>Reason</b>: #error.message#</p>
                </td>
        	</tr>
        </table>
        </cfoutput>
	</div>
</div>
</body>
</html>        
<cfsilent>
    <cflog file="MP_SITE_ERRORS" text="#error.message# - #error.diagnostics#">
    
    <cfsavecontent variable="errortext">
    <cfoutput>
    An error occurred: http://#cgi.server_name##cgi.script_name#?#cgi.query_string#<br />
    Time: #dateFormat(now(), "short")# #timeFormat(now(), "short")#<br />
    
    <cfdump var="#error#" label="Error">
    <cfdump var="#form#" label="Form">
    <cfdump var="#url#" label="URL">
    
    </cfoutput>
    </cfsavecontent>
    
    
        <cfif #IsDefined("application.settings.mailserver.name")#>
            <cfset userName = #application.settings.mailserver.name#>
        <cfelse>    
            <cfset userName = "">
        </cfif>
        <cfif #IsDefined("application.settings.mailserver.pass")#>
            <cfset userPass = #application.settings.mailserver.pass#>
        <cfelse>    
            <cfset userPass = "">
        </cfif>  
      
    
    <cfmail to="heizer1@llnl.gov" from="heizer1@llnl.gov" subject="MacPatch Error: #error.message#" type="html" 
            server="#application.settings.mailserver.server#" 
            username="#userName#" password="#userPass#">
        #errortext#
    </cfmail>
</cfsilent>