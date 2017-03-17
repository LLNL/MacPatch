<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html>
<head>
	<title>MacPatch Client Downloads</title>
	<link href="/css/login.css" rel="stylesheet" type="text/css" />
</head>
<cfsilent>
    <cfset datasource = application.settings.database.prod.dsName />
    <cfset agent_pkg = "MPClientInstall" />
    <cfset agent_id = 0 />
    <cfquery name="qAgent" datasource="#datasource#" result="res">
        select puuid from mp_client_agents
        WHERE type = 'app' AND active = '1'
    </cfquery>
    <cfquery name="qUpdater" datasource="#datasource#" result="res">
        select puuid from mp_client_agents
        WHERE type = 'update' AND active = '1'
    </cfquery>
    <cfif qAgent.RecordCount EQ 1 AND qUpdater.RecordCount EQ 1>
        <cfif qAgent.puuid EQ qUpdater.puuid>
            <cfset agent_id = qAgent.puuid />
        </cfif>
    </cfif>
</cfsilent>
<body>
    <div id="layout" class="layout">
    	<div class="login_dialog">
    		<h1>MacPatch Client Downloads</h1>
    		<div class="icon">
            	<div class="img"></div>
            </div>
    		<p>&nbsp;</p>
    		<cfif agent_id NEQ 0>
        		<cfset mpClientDir = #server.mpsettings.settings.paths.content# & "/clients/" & agent_id />
        		<cfset mpClientDirAlt = #server.mpsettings.settings.paths.content# & "/clients/other" />
                <cfdirectory action="list" sort="datelastmodified Desc" directory="#mpClientDir#" name="getdir" filter="#agent_pkg#*.zip">
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
                        <td><a href="/mp-content/clients/#agent_id#/#name#">#Name#</a></td>
                        <td>#Round(Size/1024/1024)#MB</td>
                        <td>#DateFormat(dateLastModified,"yyyy-mm-dd")# #TimeFormat(dateLastModified,"HH:mm:ss")#</td>
                    </tr>
                    </cfoutput>
                    <cfif DirectoryExists(mpClientDirAlt)>
                    <cfdirectory action="list" sort="datelastmodified Desc" directory="#mpClientDirAlt#" name="getdirAlt" filter="*.zip">
                    <cfoutput query="getdirAlt">
                    <tr>
                        <td><a href="/mp-content/clients/other/#name#">#Name#</a></td>
                        <td>#Round(Size/1024/1024)#MB</td>
                        <td>#DateFormat(dateLastModified,"yyyy-mm-dd")# #TimeFormat(dateLastModified,"HH:mm:ss")#</td>
                    </tr>
                    </cfoutput>
                    </cfif>
                    </table>
                    </ul>
                </div>
            </cfif>

            <hr />
            <div style="margin-top:10px; margin-bottom:10px; text-align:center;">
            <a href="https://<cfoutput>#CGI.SERVER_NAME#</cfoutput>/admin" class="headermenuIndentMiddle">Admin Console Login</a>
            </div>
    	</div>
    </div>
</body>
</html>
