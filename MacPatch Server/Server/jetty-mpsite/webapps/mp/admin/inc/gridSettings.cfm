<cfset gObj = createObject("component", "gridSettings").init() />
<cfset jqGridInfoData = #url.data#>
<!---
<cfset jqGridInfoData = #Decrypt(url.data,session.usrKey)#>
--->
<cfset _xmlConfDir = #Expandpath("settings")#>
<cfset _xmlUsrConfFile = #Expandpath("settings/"&session.Username&"/"&jqGridInfoData&".xml")#>
<cfset _xmlConfFile = #Expandpath("settings/"&jqGridInfoData&".xml")#>

<cfif FileExists(_xmlUsrConfFile)>
	<cffile action="read" file="#_xmlUsrConfFile#" variable="_xmlConfData">
<cfelseif FileExists(_xmlConfFile)>
	<cffile action="read" file="#_xmlConfFile#" variable="_xmlConfData">
<cfelse>
	Error,<br>
	Unable to read config data.
	<cfabort>
</cfif>

<cfset columnsStruct = "#gObj.ConvertXmlToStruct(ToString(_xmlConfData), structnew())#">
<cfset sortedColsStruct = #gObj.arrayOfStructsSort(columnsStruct.Columns.Column,"order","asc","numeric")#>
<!---
<cfdump var="#Decrypt(DATA,session.usrKey)#">
<br>
<cfdump var="#sortedColsStruct#">
<cfdump>
--->
<!--- Example XML
<columns>
    <column>
        <align>left</align>
        <dname>Agent Version</dname>
        <hidden>false</hidden>
        <idx>2</idx>
        <name>agent_version</name> 
        <order>2</order>
        <width>100</width>
    </column>
    <column>
        <align>left</align>
        <dname>Allow Client</dname>
        <hidden>false</hidden>
        <idx>3</idx>
        <name>AllowClient</name> 
        <order>1</order>
        <width>100</width>
    </column>
</columns>
--->

<style type="text/css">
table.colGridEdit {
	border-width: 1px;
	border-spacing: 0px;
	border-style: none;
	border-color: black;
	border-collapse: collapse;
	background-color: white;
}
table.colGridEdit th {
	border-width: 1px;
	padding: 4px;
	border-style: inset;
	border-color: grey;
	background-color: #eee;
	font-weight:bold;
}
table.colGridEdit td {
	border-width: 1px;
	padding: 1px 4px 1px 6px;
	border-style: inset;
	border-color: grey;
}
</style>

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
<script src="/admin/js/tablednd/jquery.tablednd.js" type="text/javascript"></script>
<script type="text/javascript">
	$(document).ready(function() {
		// Initialise the table
		$("#table-1").tableDnD();
		$('#table-1 tr:odd').css({backgroundColor: '#EDF3FE'});
		
		$(function() {
			$("form input").keypress(function (e) {
				if ((e.which && e.which == 13) || (e.keyCode && e.keyCode == 13)) {
					$('button[type=submit].defaultBtn').click();
					return false;
				} else {
					return true;
				}
			});
		});	
	});
</script>

<cfscript>
Function setSelected(val1, val2){
    if (val1 EQ val2) {
        Return 'selected="selected"';
    } else {
        Return '';
    }
}
</cfscript>
<h3>Edit Columns for <cfoutput>#session.currentClientGroup#</cfoutput></h3>
<form name="gridSettings" method="post">
	<table width="100%" cellpadding="4">
    <tr>
    	<td>
            Edit Values for: 
            <cfoutput>
            <SELECT NAME="fType">
            <cfif session.IsAdmin EQ "1">
                <OPTION value="#Encrypt("Admin",session.usrKey)#">Admin (Global)</OPTION>
            </cfif>    
                <OPTION value="#Encrypt(session.Username,session.usrKey)#" selected="selected">User (#session.Username#)</OPTION>
            </SELECT>
            </cfoutput>
    	</td>
        <td align="right"><input name="submit" type="submit" value="Reset" />(Reset view to default view.)</td>
    </tr>
    </table>
	<table width="100%" class="colGridEdit" id="table-1">
    <thead>
	<tr>
		<th>Real Name</th>
		<th>Display Name</th>
		<th>Align Text</th>
		<th>Hide</th>
		<th>Column Width</th>
	</tr>
    </thead>
    <tbody>
	<cfloop index="x" array="#sortedColsStruct#">
	<tr>
	<cfoutput>
		<td>#x.name#<input type="hidden" name="name" value="#x.name#"></td>
		<td><input type="text" name="dname" size="50" value="<cfif Len(x.dname) EQ 0>&nbsp;<cfelse>#x.dname#</cfif>"></td>
		<td>
			<SELECT NAME="align">
				<OPTION value="left" #setSelected('left', x.align)#>Left</OPTION>
				<OPTION value="center" #setSelected('center', x.align)#>Center</OPTION>
				<OPTION value="right" #setSelected('right', x.align)#>Right</OPTION>
			</SELECT>
		</td>
		<td>
			<SELECT NAME="hidden">
				<OPTION value="true" #setSelected('true', x.hidden)#>True</OPTION>
				<OPTION value="false" #setSelected('false', x.hidden)#>False</OPTION>
			</SELECT>
		</td>
		<td>
			<input type="text" name="width" size="10" value="#x.width#">
			<input type="hidden" name="idx" value="#x.idx#">
		</td>
	</cfoutput>	
	</tr>
	</cfloop>
	</tbody>
    </table>
	<input name="submit" type="submit" value="Save" class="defaultBtn" />
	<a href="<cfoutput>client_group.cfm?gid=#session.currentClientGroup#</cfoutput>"><input type="button" name="cancel" value="Cancel" /></a>
</form>

<cfif IsDefined("form") AND StructIsempty(form) EQ false>
	<cfif form.submit EQ "Reset">
		<cfif IsDefined("form.fType")>
			<cfif #Decrypt(form.fType,session.usrKey)# EQ "Admin">
            	<cffile action="delete" file="#_xmlConfFile#">
            <cfelse>
                <cfif DirectoryExists(_xmlConfDir&"/"&session.Username)>
                    <cfset _xDir = #_xmlConfDir#&"/"&#session.Username#>
                   	<cffile action="delete" file="#_xmlUsrConfFile#">
                </cfif>
            </cfif>
        </cfif>
        <cflocation url="#session.cflocFix#/admin/inc/client_group.cfm?gid=#session.currentClientGroup#">
        <cfabort>
	</cfif>
    
	<cfset colList = form.FIELDNAMES>
	<cfset colList = ListDeleteat(colList,ListContainsnocase(form.FIELDNAMES,"SUBMIT",","),",")>
	<cfset colList = ListDeleteat(colList,ListContainsnocase(form.FIELDNAMES,"fType",","),",")>
    <cfset colList = ListDeleteat(colList,ListContainsnocase(form.FIELDNAMES,"SORT_ORDER",","),",")>
    <cfset colList = ListDeleteat(colList,ListContainsnocase(form.FIELDNAMES,"ORDER",","),",")>
	<cfset colLen = ListLen(evaluate("form."&ListGetAt(colList,1,",")),",")>
	<cfscript>
		xml = "";
		for (i = 1;  i LTE colLen; i++) {
			xml &= "<column><order>#i#</order>";
			for (x = 1; x LTE  listLen(colList); x++) {
				 xml &= "<#listGetAt(colList, x)#>#ListGetAt(evaluate("form."&listGetAt(colList, x)),i,",")#</#listGetAt(colList, x)#>";
			 }
			 xml &= "</column>";
		}
		xml = "<?xml version=""1.0"" encoding=""utf-8""?><settings><columns>#xml#</columns></settings>";
	</cfscript>

	<cfif IsDefined("form.fType")>
		<cfif #Decrypt(form.fType,session.usrKey)# EQ "Admin" AND session.IsAdmin EQ true>
        	<cftry>
            	<cffile action="write" file="#_xmlConfFile#" OUTPUT="#xml#" NAMECONFLICT="overwrite">
            <cfcatch>
            	<h3 style="color:red;">Error: settings could not be changed.<br /><cfoutput>#cfcatch.Detail#</cfoutput></h3>
                <cfabort>
            </cfcatch>
            </cftry>
		<cfelse>
        	<cfif NOT DirectoryExists(_xmlConfDir&"/"&session.Username)>
            	<cfset _xDir = #_xmlConfDir#&"/"&#session.Username#>
            	<cfdirectory action="create" directory="#_xDir#">
            </cfif>
            <cftry>
				<cffile action="write" file="#_xmlUsrConfFile#" OUTPUT="#xml#" NAMECONFLICT="overwrite">
            <cfcatch>
            	<h3 style="color:red;">Error: settings could not be changed.<br /><cfoutput>#cfcatch.Detail#</cfoutput></h3>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfif>
	</cfif>
    <!--- --->
	<cflocation url="#session.cflocFix#/admin/inc/client_group.cfm?gid=#session.currentClientGroup#">
</cfif>
