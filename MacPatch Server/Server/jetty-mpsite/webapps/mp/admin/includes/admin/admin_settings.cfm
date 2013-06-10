<style type="text/css">
/* <![CDATA[ */

table.servicesT {	
	border: 1px black solid;
	border-collapse: collapse;
	border-spacing: 0px;
	margin-top: 0px;
}


table.servicesT td {	
	border: 1px dotted #6699CC;
	border-collapse: collapse;
	border-spacing: 0px;
	background-color: white;
	text-align: left;
	padding: 4px;
} 

.servBodL { border-left: 1px dotted #CEDCEA; }

/* ]]> */
</style>
<script type="text/javascript">	
	
	$(function() {
		// Used by build_patch_group.cfm, edit_patch_group.cfm
		$("#hashTable").tablesorter({
			widgets: ['zebra'],
			headers: { 1:{sorter: 'ipAddress'} }
		});
		
		$("#genericTable").tablesorter({
			widgets: ['zebra'] 
		});
		
		$("#options").tablesorter({
			sortList: [[0,0]],  
			headers: { 0:{sorter: 'input'}, 1:{sorter: 'ipAddress'} }
		});
	});	
	
</script>


<!--- Create Client Update Package --->
<cfif IsDefined("form.ClientUpdatePackage") AND form.ClientUpdatePackage EQ "New Update">
<h3>New Client Agent Update</h3>
	<!--- Here we display the form to add the new app content --->

	<table cellspacing="1" cellpadding="4" class="servicesT">
		<cfform name="ClientUpdatePackage" action="./index.cfm?ApplicationHash" enctype="multipart/form-data">		
		<tr><td>Client Ver</td><td><cfinput type="text" name="clientVer" value=""></td></tr>
		<tr><td>SWUAD Ver</td><td><cfinput type="text" name="swuadVer" value=""></td></tr>
        <tr><td>PKG Name</td><td><cfinput type="text" name="pkg_name"></td></tr>
		<tr><td>PKG</td><td><cfinput type="file" name="pkg"></td></tr>
		<tr>
			<td>State</td>
			<td><cfselect name="state">
				<option value="install">Install</option>
				<option value="disabled">Disabled</option>
				</cfselect>
			</td>
		</tr>
		<tr><td>Description</td><td><cfinput type="text" name="description" value=""></td></tr>    
		<tr><td>&nbsp;</td><td><cfinput type="submit" name="ClientUpdatePackage" value="Add"></td></tr>
		</cfform>
	</table>
</cfif>

<cfif IsDefined("form.ClientUpdatePackage") AND form.ClientUpdatePackage EQ "Edit Update">
<cfquery datasource="#session.dbsource#" name="qGetAgentUpdate">
	Select * From SelfUpdates
	Where rid = <cfqueryparam value="#session.patchEdit#"> 
</cfquery>	
<h3>Edit Client Agent Update</h3>
	<!--- Here we display the form to add the new app content --->
	<table cellspacing="1" cellpadding="4" class="servicesT">
		<cfform name="ClientUpdatePackage" action="./index.cfm?ApplicationHash" enctype="multipart/form-data">		
		<tr><td>Client Ver</td><td><cfinput type="text" name="clientVer" value=""></td></tr>
		<tr><td>SWUAD Ver</td><td><cfinput type="text" name="swuadVer" value=""></td></tr>
        <tr><td>PKG Name</td><td><cfinput type="text" name="pkg_name"></td></tr>
		<tr><td>PKG</td><td><cfinput type="file" name="pkg"></td></tr>
		<tr>
			<td>State</td>
			<td><cfselect name="state">
				<option value="install">Install</option>
				<option value="disabled">Disabled</option>
				</cfselect>
			</td>
		</tr>
		<tr><td>Description</td><td><cfinput type="text" name="description" value=""></td></tr>    
		<tr><td>&nbsp;</td><td><cfinput type="submit" name="ClientUpdatePackage" value="Add"></td></tr>
		</cfform>
	</table>
</cfif>

<cfif IsDefined("form.ClientUpdatePackage") AND form.ClientUpdatePackage EQ "Add" >  
	<cfif #form.pkg# gt "">
    	<cfset pkgUUID = #CreateUUID()#>
    	<cfset thePath = expandPath("../clients/updates/"&#pkgUUID#)>
        <cfdirectory action="create" directory="#thePath#" >
        
        <cffile action = "upload"
        	fileField="form.pkg"
        	Destination="#thePath#"
        	nameConflict="MakeUnique"
            mode="644"
        	Accept="application/zip">
        <cfset pkg = cffile.serverdirectory & "/" & cffile.clientfile>
        <cfset pkg_URL = "#CGI.HTTP_ORIGIN#/clients/updates/#pkgUUID#/#cffile.clientfile#" >
    
        <!--- Genreate the Hash --->
        <cfexecute 
   			name = "/usr/bin/openssl"
   			arguments = "sha1 #pkg#"
   			variable = "sha1Result"
  			timeout = "5">
		</cfexecute>
		<cfset sha1 = #ListGetAt(sha1Result,2,"= ")#>
		<!--- cdate #DateFormat(Now())#, --->
		<cfquery datasource="#session.dbsource#" name="qGet">
			Insert INTO SelfUpdates (swuai_Ver,swuad_Ver,client_Ver, pkg_name, pkg_Hash, pkg_URL, pkg_id, state, description, type)
			Values('#form.swuaiVer#', '#form.swuadVer#', '#form.clientVer#', '#form.pkg_name#', '#sha1#', '#pkg_URL#', '#pkgUUID#', '#form.state#', '#form.description#','app')
		</cfquery>
    </cfif> 
    
	<cfform name="ClientUpdatePackage" action="./index.cfm?ApplicationHash">
    	<cfinput type="submit" name="ClientUpdatePackage" value="New Update">
    </cfform>
</cfif>




<!--- Create Swupd Update Package --->
<cfif IsDefined("form.SwupdUpdatePackage") AND form.SwupdUpdatePackage EQ "New Update">
<p>New Client Update</p>
	<!--- Here we display the form to add the new app content --->
	<table cellspacing="1">
		<cfform name="SwupdUpdatePackage" action="./index.cfm?ApplicationHash" enctype="multipart/form-data">
		<tr><td>SWUPD Ver</td><td><cfinput type="text" name="swupdVer" value=""></td></tr>
		<tr><td>PKG</td><td><cfinput type="file" name="swupd_pkg"></td></tr>
        <tr><td>PKG Name</td><td><cfinput type="text" name="pkg_name"></td></tr>
		<tr><td>State</td><td><cfinput type="text" name="state" value="install">(install,disabled)</td></tr>
		<tr><td>Description</td><td><cfinput type="text" name="description" value=""></td></tr>    
		<tr><td>&nbsp;</td><td><cfinput type="submit" name="SwupdUpdatePackage" value="Add"></td></tr>
		</cfform>
	</table>
</cfif>

<cfif IsDefined("form.SwupdUpdatePackage") AND form.SwupdUpdatePackage EQ "Add" >  
	<cfif #form.swupd_pkg# gt "">
    	<cfset pkgUUID = #CreateUUID()#>
    	<cfset thePath = expandPath("../clients/updates/"&#pkgUUID#)>
        <cfdirectory action="create" directory="#thePath#" mode="775" />

        <cffile action = "upload"
        	fileField="form.swupd_pkg"
        	Destination="#thePath#"
        	nameConflict="MakeUnique"
            mode="644"
        	Accept="application/zip">
        <cfset pkg = cffile.serverdirectory & "/" & cffile.clientfile>
        <cfset pkg_URL = "#CGI.HTTP_ORIGIN#/clients/updates/#pkgUUID#/#cffile.clientfile#" >
        <!--- Genreate the Hash --->
        <cfexecute 
   			name = "/usr/bin/openssl"
   			arguments = "sha1 #pkg#"
   			variable = "sha1Result"
  			timeout = "5">
		</cfexecute>
		<cfset sha1 = #ListGetAt(sha1Result,2,"= ")#>
		<!--- cdate #DateFormat(Now())#, --->
		<cfquery datasource="#session.dbsource#" name="qInsertSwupd">
			Insert INTO SelfUpdates (swupd_Ver,client_Ver,pkg_Name, pkg_Hash, pkg_URL, pkg_id, state, description,type)
			Values('#form.swupdVer#', '#form.swupdVer#', '#form.pkg_name#', '#sha1#', '#pkg_URL#', '#pkgUUID#', '#form.state#', '#form.description#','update')
		</cfquery>
    </cfif> 
    
	<cfform name="SwupdUpdatePackage" action="./index.cfm?ApplicationHash">
    	<cfinput type="submit" name="SwupdUpdatePackage" value="New Update">
    </cfform>
</cfif>

<cfform name="ClientUpdatePackage" action="./index.cfm?ApplicationHash">
	<cfinput type="submit" name="ClientUpdatePackage" value="New Update">
</cfform>

<cffunction name="isEmpty" access="public" returntype="boolean" output="yes">
	<cfargument name="theString" required="yes">
    
    <cfif Len(Trim(arguments.theString))>
    	<cfreturn false>
    <cfelse>
    	<cfreturn true>
    </cfif>
    
    <cfreturn false>
</cffunction>