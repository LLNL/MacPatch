<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html>
<head>
	<title>MacPatch Client Downloads</title>
	<link href="/css/login.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <div id="layout" class="layout">
    	<div class="login_dialog">
    		<h1>MacPatch Client Downloads</h1>
    		<div class="icon">
            	<div class="img"></div>
            </div>
    		<p>&nbsp;</p>
    		<cfset BaseDir = #Expandpath(".")#>
    		<cfdirectory action="list" sort="datelastmodified Desc" directory="/Library/MacPatch/Content/Web/clients" name="getdir" filter="*.zip">
            <div id="normalize">
                <ul>
                <table id="files" cellpadding="4px">
                <tr>
                	<th>Name</th>
                	<th>Size</th>
                	<th>Mod date</th>
                </tr>
                <cfoutput query="getdir">
                <tr>
                    <td><a href="/mp-content/clients/#name#">#Name#</a></td>
                    <td>#Round(Size/1024/1024)#MB</td>
                    <td>#DateFormat(dateLastModified,"yyyy-mm-dd")# #TimeFormat(dateLastModified,"HH:mm:ss")#</td>
                </tr>
                </cfoutput>
                </table>
                </ul>
    		</div>
            <hr />
            <div style="margin-top:10px; margin-bottom:10px; text-align:center;">
            <a href="https://<cfoutput>#CGI.SERVER_NAME#</cfoutput>/admin" class="headermenuIndentMiddle">Admin Console Login</a>
            </div>
    	</div>
    </div>
</body>
</html>
