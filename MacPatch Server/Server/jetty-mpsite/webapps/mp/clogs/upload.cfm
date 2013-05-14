<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title>MacPatch Client Log Upload</title>
</HEAD>
<body>
<h2>MacPatch Client Log Upload</h2>	
<h3>Max file size 15MB</h3>
<cfset _host = "#cgi.HTTP_HOST#">
<cfif isDefined("datafile")>
	<cfset strPath = ExpandPath( "./" ) />
	<cffile action="upload" fileField="datafile" destination="#strPath#" nameconflict="makeunique">
	<!--- FileSize is in Bytes, upload limit to 15MB --->
	<cfif CFFILE.FileSize GT (15 * (1024 * 1024))>
		<cftry>
			<cfset l_file = #strPath# & #CFFILE.ServerFile#>
			<cffile action="DELETE" file="#l_file#"/>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
	<cfmail to="macpatch-help@lists.llnl.gov" from="#_host#@llnl.gov" subject="Support - New Client Logs Upload " type="text">
	The following file "#CFFILE.ServerFile#" was just uploaded.
	</cfmail>
</cfif>
<form enctype="multipart/form-data" method="post">
	<input type="file" name="datafile" /><br />
	<input type="submit" value="Post" />
</form>
</body>
</html>