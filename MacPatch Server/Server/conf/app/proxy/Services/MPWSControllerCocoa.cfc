<!--- **************************************************************************************** --->
<!---
		MPWSControllerCocoa - JSON Based Web Services
		Proxy File
	 	Database type is MySQL
		MacPatch Version 2.1.0
		Version 1.0
		Rev: 1
		Last Modified:	10/20/2012
--->
<!--- **************************************************************************************** --->
<cfcomponent>

	<cfparam name="mpDBSource" default="mpds">
	<cfparam name="logFile" default="MPWSControllerCocoa">
    <cfparam name="wsPort" default="2600">
	<cfparam name="wsURL" default="https://#server.mp.settings.proxyserver.primaryServer#:#server.mp.settings.proxyserver.primaryServerPort#/Services/MPWSControllerCocoa.cfc">
	
	<cffunction name="init" returntype="MPWSControllerCocoa" output="no">
		<cfreturn this>
	</cffunction>

<!--- ********************************************************************* --->
<!---  Methods																--->
<!--- ********************************************************************* --->
    
<!--- ********************************************************************* --->
<!--- Start --- Client Methods - for MacPatch 2.1.0							--->
<!--- ********************************************************************* ---> 

<!--- #################################################### --->
<!--- MPHostsListVersionIsCurrent	 		 			   --->
<!--- #################################################### --->
	<cffunction name="MPHostsListVersionIsCurrent" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="ListID" required="false" default="0" />
		<cfargument name="Version" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="MPHostsListVersionIsCurrent">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
                <cfhttpparam type="formfield" name="ListID" value="#arguments.ListID#">
				<cfhttpparam type="formfield" name="Version" value="#arguments.Version#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [MPHostsListVersionIsCurrent][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [MPHostsListVersionIsCurrent][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [MPHostsListVersionIsCurrent][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [MPHostsListVersionIsCurrent][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetMPHostsList		 		 					   --->
<!--- #################################################### --->
	<cffunction name="GetMPHostsList" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetMPHostsList">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetMPHostsList][#CGI.REMOTE_HOST#]: #cfhttp.FileContent#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetMPHostsList][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetMPHostsList][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetMPHostsList][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>	
	
<!--- #################################################### --->
<!--- GetSWDistGroups		 		 					   --->
<!--- #################################################### --->	
	<cffunction name="GetSWDistGroups" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetSWDistGroups">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSWDistGroups][#CGI.REMOTE_HOST#]: #cfhttp.FileContent#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSWDistGroups][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSWDistGroups][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSWDistGroups][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>	
	
<!--- #################################################### --->
<!--- GetScanList		 		 					   --->
<!--- #################################################### --->	
	<cffunction name="GetScanList" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="state" required="false" default="all" />
		<cfargument name="active" required="false" default="1" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetScanList">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
				<cfhttpparam type="formfield" name="state" value="#arguments.state#">
				<cfhttpparam type="formfield" name="active" value="#arguments.active#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetScanList][#CGI.REMOTE_HOST#]: #cfhttp.FileContent#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetScanList][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetScanList][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetScanList][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>	

<!--- #################################################### --->
<!--- GetPatchGroupPatches		 		 					   --->
<!--- #################################################### --->	
	<cffunction name="GetPatchGroupPatches" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="PatchGroup" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetPatchGroupPatches">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
				<cfhttpparam type="formfield" name="PatchGroup" value="#arguments.PatchGroup#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][#CGI.REMOTE_HOST#]: #cfhttp.FileContent#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>
	
<!--- #################################################### --->
<!--- getAsusCatalogs	 		 						   --->
<!--- #################################################### --->
	<cffunction name="getAsusCatalogs" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="osminor" required="yes" type="string">
		<cfargument name="clientKey" required="false" default="0" />
		
		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="getAsusCatalogs">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
                <cfhttpparam type="formfield" name="osminor" value="#arguments.osminor#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [getAsusCatalogs][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [getAsusCatalogs][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [getAsusCatalogs][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [getAsusCatalogs][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

<!--- #################################################### --->
<!--- GetLastCheckIn	 		 						   --->
<!--- #################################################### --->
	<cffunction name="getLastCheckIn" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="getLastCheckIn">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [getLastCheckIn][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [getLastCheckIn][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [getLastCheckIn][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [getLastCheckIn][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

<!--- #################################################### --->
<!--- getClientPatchStatusCount	 		 				   --->
<!--- #################################################### --->
    <cffunction name="getClientPatchStatusCount" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="getClientPatchStatusCount">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [getClientPatchStatusCount][#CGI.REMOTE_HOST#]: #cfhttp.responseheader.STATUS_CODE#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [getClientPatchStatusCount][#CGI.REMOTE_HOST#]: #cfhttp.responseheader.STATUS_CODE#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [getClientPatchStatusCount][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [getClientPatchStatusCount][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

<!--- #################################################### --->
<!--- PostPatchesFound		 		 					   --->
<!--- #################################################### --->	
	<cffunction name="PostPatchesFound" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="type" required="true" default="None" />
		<cfargument name="jsonData" required="true" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="PostPatchesFound">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
				<cfhttpparam type="formfield" name="type" value="#arguments.type#">
				<cfhttpparam type="formfield" name="jsonData" value="#arguments.jsonData#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [PostPatchesFound][#CGI.REMOTE_HOST#]: #cfhttp.FileContent#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [PostPatchesFound][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [PostPatchesFound][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [PostPatchesFound][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>
	
<!--- #################################################### --->
<!--- Installed Patches     	 		 				   --->
<!--- #################################################### --->
    <cffunction name="addInstalledPatch" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />
		<cfargument name="patch" required="false" default="0" />
		<cfargument name="patchType" required="false" default="0" />

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="addInstalledPatch">
                <cfhttpparam type="formfield" name="clientID" value="#arguments.clientID#">
                <cfhttpparam type="formfield" name="patch" value="#arguments.patch#">
				<cfhttpparam type="formfield" name="patchType" value="#arguments.patchType#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [addInstalledPatch][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [addInstalledPatch][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [addInstalledPatch][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [addInstalledPatch][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

<!--- #################################################### --->
<!--- GetSoftwareForGroup -> GetSoftwareTasksForGroup	   --->
<!--- #################################################### --->	
    <cffunction name="GetSoftwareForGroup" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="GroupName">

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetSoftwareForGroup">
                <cfhttpparam type="formfield" name="GroupName" value="#arguments.GroupName#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSoftwareForGroup][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSoftwareForGroup][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSoftwareForGroup][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSoftwareForGroup][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>
    
<!--- #################################################### --->
<!--- GetSoftwareTasksForGroup	   						   --->
<!--- #################################################### --->	    
    <cffunction name="GetSoftwareTasksForGroup" access="remote" returnType="any" returnFormat="plain" output="false">
    	<cfargument name="GroupName">
        
        <cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetSoftwareTasksForGroup">
                <cfhttpparam type="formfield" name="GroupName" value="#arguments.GroupName#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroup][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroup][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#cfhttp.fileContent#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroup][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroup][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
    </cffunction>
    
<!--- #################################################### --->
<!--- ValidateSoftwareGroupHash	   						   --->
<!--- #################################################### --->	 
	<cffunction name="ValidateSoftwareGroupHash" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="GroupName">
		<cfargument name="GroupHash">
		
        <cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="ValidateSoftwareGroupHash">
                <cfhttpparam type="formfield" name="GroupName" value="#arguments.GroupName#">
				<cfhttpparam type="formfield" name="GroupHash" value="#arguments.GroupHash#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ValidateSoftwareGroupHash][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [ValidateSoftwareGroupHash][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ValidateSoftwareGroupHash][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [ValidateSoftwareGroupHash][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetSoftwareTasksForGroupHash 						   --->
<!--- #################################################### --->	 
    <cffunction name="GetSoftwareTasksForGroupHash" access="remote" returnType="struct" returnFormat="json" output="false">
    	<cfargument name="GroupName">
    	
		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetSoftwareTasksForGroupHash">
                <cfhttpparam type="formfield" name="GroupName" value="#arguments.GroupName#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroupHash][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroupHash][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroupHash][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetSoftwareTasksForGroupHash][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
    </cffunction>
    
<!--- #################################################### --->
<!--- PostSoftwareInstallResults 						   --->
<!--- #################################################### --->	    
    <cffunction name="PostSoftwareInstallResults" access="remote" returnType="struct" returnFormat="json" output="false">
    	<cfargument name="ClientID">
        <cfargument name="SWTaskID">
        <cfargument name="SWDistID">
        <cfargument name="ResultNo">
        <cfargument name="ResultString">
		<cfargument name="Action">
        
		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="PostSoftwareInstallResults">
                <cfhttpparam type="formfield" name="ClientID" value="#arguments.ClientID#">
				<cfhttpparam type="formfield" name="SWTaskID" value="#arguments.SWTaskID#">
				<cfhttpparam type="formfield" name="SWDistID" value="#arguments.SWDistID#">
				<cfhttpparam type="formfield" name="ResultNo" value="#arguments.ResultNo#">
				<cfhttpparam type="formfield" name="ResultString" value="#arguments.ResultString#">
				<cfhttpparam type="formfield" name="Action" value="#arguments.Action#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [PostSoftwareInstallResults][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [PostSoftwareInstallResults][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [PostSoftwareInstallResults][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [PostSoftwareInstallResults][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
    </cffunction>
 
<!--- ********************************************************************* --->
<!--- End --- Client Methods - for MacPatch 2.1.0							--->
<!--- ********************************************************************* ---> 

<!--- ********************************************************************* --->
<!--- Start --- Agent Update Methods - for MacPatch 2.1.0					--->
<!--- ********************************************************************* ---> 

	<cffunction name="CheckForAgentUpdates" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="cuuid" required="no">
		<cfargument name="agentVersion">
		<cfargument name="agentBuild">
		<cfargument name="agentFramework">
		
		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "Not Supported Via Proxy" />
        <cfset response[ "result" ] = {} />
		
		<cfreturn #response#>
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="CheckForAgentUpdates">
                <cfhttpparam type="formfield" name="cuuid" value="#arguments.cuuid#">
				<cfhttpparam type="formfield" name="agentVersion" value="#arguments.agentVersion#">
				<cfhttpparam type="formfield" name="agentBuild" value="#arguments.agentBuild#">
				<cfhttpparam type="formfield" name="agentFramework" value="#arguments.agentFramework#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [CheckForAgentUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [CheckForAgentUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [CheckForAgentUpdates][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [CheckForAgentUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

    <cffunction name="GetAgentUpdaterUpdates" access="remote" returntype="any" output="no">
    	<!--- New MacPatch 2.0 --->
		<cfargument name="agentUp2DateVer">
        <cfargument name="cuuid">

		<cfset var result = "" />
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "1" />
        <cfset response[ "errorMsg" ] = "Not Supported Via Proxy" />
        <cfset response[ "result" ] = {} />
		
		<cfreturn #response#>
		
		<cftry>
           	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                <cfhttpparam type="header" name="charset" value="utf-8">
                <cfhttpparam type="formfield" name="method" value="GetAgentUpdaterUpdates">
                <cfhttpparam type="formfield" name="cuuid" value="#arguments.cuuid#">
				<cfhttpparam type="formfield" name="agentUp2DateVer" value="#arguments.agentUp2DateVer#">
            </cfhttp>
               
			<cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
			   <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAgentUpdaterUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			   <cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetAgentUpdaterUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
			   <cfset result = response>
			</cfif>
	        <cfset result = "#deserializejson(cfhttp.fileContent)#">	
			
			<cfcatch>
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAgentUpdaterUpdates][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
				<cfset response[ "errorMsg" ] = "#CreateODBCDateTime(now())# -- [GetAgentUpdaterUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#" />
				<cfset result = response>
			</cfcatch>
		</cftry>

		<cfreturn #result#>
	</cffunction>

<!--- ********************************************************************* --->
<!--- End --- Agent Update Methods - for MacPatch 2.1.0					    --->
<!--- ********************************************************************* ---> 
</cfcomponent>
