<script type="text/javascript">	
	$(function() {
		$("#cLogs").tablesorter({
			widgets: ['zebra']
		});
	});	
</script>
<cfset strPath = "#server.coldfusion.rootdir#/clogs" />
<h2 style="font-size:20px;">MacPatch Client Log Uploads</h2>

<cfif IsDefined("form.DeleteFile")>
	<cfif ListLen(form.dFile,",") GTE 1>
	<cfloop list="#form.dFile#" index="aFile">
		<cfset x_File = "#strPath#/#aFile#">
		<cftry>
		<cffile action="Delete" file="#x_File#">
		<cfcatch type="any">
		<div style="color:red;"><p>Error: <cfdump var="#cfcatch.Message#"><br><cfdump var="#cfcatch.detail#"></p></div>
		</cfcatch>
		</cftry> 
	</cfloop>
	</cfif>
</cfif>
<hr>
<cftry>
<cfdirectory directory="#strPath#" name="dirQuery" action="LIST" filter="*.zip" sort="datelastmodified DESC">
<!--- Get an array of directory names. --->
<cfform action="" method="post">
<table class="tablesorter" id="cLogs">
	<thead>
	<tr>
		<th>&nbsp;</th>
		<th>File</th>
		<th>Size</th>
		<th>Last Modified</th>
	</tr>
	</thead>
	<tbody>
<cfloop query="dirQuery">
<cfoutput>
<cfif dirQuery.type IS "file">
	<tr>
		<td><input Type="Checkbox" Name="dFile" Value="#dirQuery.name#"></td>
		<td><a href="/clogs/#dirQuery.name#">#dirQuery.name#</a></td>
		<td>#dirQuery.size#</td>
		<td>#dirQuery.datelastmodified# </td>
	</tr>
</cfif>
</cfoutput>
</cfloop>
	</tbody>
	<tr>
		<td colspan="4"><input type="submit" value="Delete" name="DeleteFile"></td>
	</tr>
</table>
</cfform>
<cfcatch>
	<div style="color:red;"><p>Error: <cfdump var="#cfcatch.Message#"><br><cfdump var="#cfcatch.detail#"></p></div>
    <cfdump var="#server#">
    <cfdump var="#strPath#">
    <cfdump var="#server.coldfusion.rootdir#">
    
</cfcatch>
</cftry>