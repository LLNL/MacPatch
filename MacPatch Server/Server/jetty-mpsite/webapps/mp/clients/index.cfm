<html>
<head>
	<title>MacPatch Admin Login</title>
	<link href="../assets/css/main.css" rel="stylesheet" type="text/css">
<style type="text/css">
<!--
.style0 a {font-size: 12px; color:#000000;}
.style1 {font-size: 12px}
.style2 {font-size: 12px; font-weight: bold; }
.style3 {font-size: 12px; font-style: italic; }
.style4 {
	font-size: 16px;
	font-weight: bold;
}

#files table {
	font-family:Arial, Helvetica, sans-serif;
	font-size:12px;
}

#files th {
	font-size:14px;
	text-align:left;
	padding-left:8px;
}
#files td {
	font-size:12px;
	text-align:left;
	padding-left:8px;
}
-->
</style>
</head>
<body>
	<div id="headermain">
    	<div id="headerbanner">
    		<table cellpadding="0" cellspacing="0" width="1100">
                <tr>
                  <td width="10">
                    <img src="../assets/images/BannerLeftCorner.gif">
                  </td>
                  <td valign="top" bgcolor="#000000">
                    <img src="../assets/images/macpatchbanner.jpg">
                  </td>
                  <td align="right" bgcolor="#000000" valign="bottom">  
                    <a href="/">Admin Login</a>
                  </td>
                    <td width="10">
                    <img src="../assets/images/BannerRightCorner.gif">
                    </td>
                </tr>
            </table>
    	</div>
        <div id="headermenu">
        	<table cellpadding="0" cellspacing="0" width="1100" background="../assets/images/article-title-bg-apple.png">
                <tr height="30">
                	<td><a href="/clients" class="headermenuIndentFirst">Client Download</a>|<a href="http://<cfoutput>#CGI.SERVER_NAME#</cfoutput>/" class="headermenuIndentMiddle">Home</a></td>
                </tr>
            </table>
        </div>
        <div id="headerStatusBar">
            &nbsp;
        </div>
    </div>
	<!--- Main Body Section --->
    <div id="bodymain">
        <div id="bodycontainer" style="height:600px;">
		<br>
		<cfset BaseDir = #Expandpath(".")#>
		<cfdirectory action="list" sort="datelastmodified Desc" directory="/Library/MacPatch/Content/Web/clients" name="getdir" filter="*.zip">
        <span class="style4">Download Client Software...</span><br>
        <div id="normalize">
          <ul>
            
            <table id="files">
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
    	</div> <!--- bodycontainer --->
	</div> <!--- container --->
</body>

</html>
