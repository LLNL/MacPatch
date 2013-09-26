<cfparam name="mainZipFileName" default="MPClientInstall.pkg.zip">
<cfparam name="infoFileName" default="mpInfo.ini">

<cfif IsDefined("form.AgentPackage") AND form.AgentPackage EQ "Upload">
	<cfif #form.pkg# gt "">
    	<cfset pkgUUID = #CreateUUID()#>
		<cfset ulTmpPath = #GetTempdirectory()# & #pkgUUID#>
		<cfif directoryexists(ulTmpPath) EQ False>
        	<cfdirectory action="create" directory="#ulTmpPath#" recurse="true">
		</cfif>
		
        <cffile action = "upload"
        	fileField="form.pkg"
        	Destination="#ulTmpPath#"
        	nameConflict="overwrite"
            mode="644"
        	Accept="application/zip">
		
		<cfif #mainZipFileName# NEQ #clientfile#>
			<cfoutput>The uploaded file is not a proper MacPatch updater.</cfoutput>
			<cfdirectory action="delete" directory="#ulTmpPath#" recurse="true">
			<cfabort>
		</cfif>
        
        <cfset pkgName = #clientfilename# />
		
		<!--- Unzip the Main Client Installer --->
		<cfexecute 
   			name = "/usr/bin/ditto"
   			arguments = "-x -k #serverfileuri# #ulTmpPath#"
   			variable = "unzipResult"
  			timeout = "15">
		</cfexecute>
        
        <!--- Extract Flat Package --->
        <cfexecute 
			name = "/usr/sbin/pkgutil"
			arguments = "--expand #ulTmpPath#/#pkgName# #ulTmpPath#/MPClientInstall"
			variable = "pkgExpanded"
			timeout = "15">
		</cfexecute>
        
		<cfset iniFile = "#ulTmpPath#/MPClientInstall/Resources/#infoFileName#">
		<cfset sections = GetProfilesections(iniFile)>
		<cfset data = structNew()>
		<cfset pkgs = arrayNew(1)>
		
		<!--- Add the Main Client Installer First, to the pks array --->
		<cfset _a = #Arrayappend(pkgs,mainZipFileName)#>
		
		<!--- Create a Struct of the ini file --->
		<cfloop collection="#sections#" item="akey">
			<cfif structKeyExists(sections, akey)>				
			<cfset aStruct = structNew()>
			<cfloop index="key" list="#Evaluate("sections." & akey)#">
				<cfif key EQ "pkg">
					<cfset _a = #Arrayappend(pkgs,GetFilefrompath(getProfileString(iniFile, akey, key)) & ".zip")#>
				</cfif>	
				<cfset aStruct[key] = getProfileString(iniFile, akey, key)>
			</cfloop>
			<cfset data[akey] = aStruct>
			</cfif>
		</cfloop>

		<cfset agentPlist = {}>
		<cfset agentPlist = createAgentConfig()>
		<cfif agentPlist.errorNo NEQ "0">
			<cfset session.lastErrorNo = agentPlist.errorNo>
			<cfset session.lastErrorMsg = agentPlist.errorMsg>
			<cflog type="Error" application="yes" text="Error[#agentPlist.errorNo#]: #agentPlist.errorMsg#">
			<cflocation url="#session.cflocFix#/admin/index.cfm?#session.curRef#">
			<cfabort>
		</cfif>
		
        
		<!--- Configure Packages for update mechanisim --->
		<cfset results = 0>
		<cfloop collection="#data#" item="key">
			<cftry>
				<cfset _i = processPackage(pkgUUID,pkgName,data[key],key,agentPlist.result)>
				<cfif _i.errorNo NEQ "0">
					<cfdump var="Error[#_i.errorNo#]:#_i#">
				</cfif>
				<cfset results = #results# + #_i.errorNo#>
				<cfcatch type="any">
					<cfset results = #results# + "1">
					<cfset session.lastErrorNo = "#cfcatch.ErrorCode#">
					<cfset session.lastErrorMsg = "#cfcatch.detail# #cfcatch.Message#">
				</cfcatch>
			</cftry>
		</cfloop>
		<cfif results NEQ "0">
			<cflocation url="#session.cflocFix#/admin/index.cfm?#session.curRef#">
			<cfabort>
		</cfif>
        
		<!--- Write Config to Main Package --->
		<cffile action="delete" file="#ulTmpPath#/#clientfilename#.zip">	
        <cffile action="delete" file="#ulTmpPath#/#pkgName#">    
        <cfexecute 
			name = "/usr/sbin/pkgutil"
			arguments = "--flatten #ulTmpPath#/MPClientInstall #ulTmpPath#/#pkgName#"
			variable = "flattenResult"
			timeout = "15">
		</cfexecute>
		<cfexecute 
			name = "/usr/bin/ditto"
			arguments = "-c -k #ulTmpPath#/#pkgName# #ulTmpPath#/#pkgName#.zip"
			variable = "aZipResult"
			timeout = "15">
		</cfexecute>
		
		<!--- Move Packages To New Location --->
		<cfset baseLoc = "/Library/MacPatch/Content/Web/clients/updates">
		<cfset new_pkgBaseDir = #baseLoc# & "/" & pkgUUID>
		<cfif directoryexists(new_pkgBaseDir) EQ False>
        	<cftry>
        	<cfdirectory action="create" directory="#new_pkgBaseDir#" recurse="true">
            <cfcatch>
            	<cfoutput>Error: #cfcatch.Detail#</cfoutput>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfif>

		<cfloop array="#pkgs#" index="i" from="1" to="#arraylen(pkgs)#">
			<cfset pkg_source = ulTmpPath & "/" & #pkgs[i]#>
            <cfset pkg_source = #Replace(pkg_source,"//","/","All")#>
            <cftry>
				<cffile action="move" source="#pkg_source#" destination="#new_pkgBaseDir#">
            <cfcatch>
            	<cfoutput>Error: #cfcatch.Detail#</cfoutput>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfloop>
	
    	<!--- Clean up the temp Dir --->
		<cfset rm_File = "#ulTmpPath#">
		<cfdirectory action="delete" directory="#rm_File#" recurse="true">
    </cfif>

    <cflocation url="#session.cflocFix#/admin/index.cfm?#session.curRef#">
</cfif>	

<cffunction name="processPackage" access="public" output="no" returntype="any">
    <cfargument name="gCUUID">
	<cfargument name="mainPkg">
	<cfargument name="pkgStruct" type="struct">
    <cfargument name="pType">
	<cfargument name="agentConfigPlist">
	
    <cfset var pkg = "0">
	<cfset var pkgName = "">
	<cfset var pkgHash = "">
	<cfset var version = "0">
	<cfset var agent_version = "0">
	<cfset var build = "0">
	<cfset var framework = "0">
	<cfset var osVerSupport = "*">
	
	<cfset tmpDir = #GetTempdirectory()# & #arguments.gCUUID#>
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	
	<cfif StructKeyExists(arguments.pkgStruct,"agent_version")>
		<cfset agent_version = Replace(arguments.pkgStruct["agent_version"],"""","","All")>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: agent version attribute was missing.">	
		<cfreturn result>	
	</cfif>	
	
	<cfif StructKeyExists(arguments.pkgStruct,"pkg")>
		<cfset pkg = Replace(arguments.pkgStruct["pkg"],"""","","All")>
		<cfset pkgName = GetFilefrompath(pkg)>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: pkg attribute was missing.">	
		<cfreturn result>	
	</cfif>	
	
	<cfif StructKeyExists(arguments.pkgStruct,"version")>
		<cfset version = Replace(arguments.pkgStruct["version"],"""","","All")>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: version attribute was missing.">	
		<cfreturn result>	
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"build")>
		<cfset build = Replace(arguments.pkgStruct["build"],"""","","All")>
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"framework")>
		<cfset framework = Replace(arguments.pkgStruct["framework"],"""","","All")>
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"osver")>
		<cfset osVerSupport = Replace(arguments.pkgStruct["osver"],"""","","All")>
	</cfif>
    
    <cfsavecontent variable="mpVerPlist">
	<cfoutput>	
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
    <dict>
        <key>bug</key>
        <string>#ListGetAt(version,3,".")#</string>
        <key>build</key>
        <string>#build#</string>
        <key>framework</key>
        <string>#framework#</string>
        <key>major</key>
        <string>#ListGetAt(version,1,".")#</string>
        <key>minor</key>
        <string>#ListGetAt(version,2,".")#</string>
        <key>version</key>
        <string>#version#</string>
    </dict>
	</plist>
	</cfoutput>
	</cfsavecontent>
	<cfset mpVersion = htmlCompressFormat(mpVerPlist, 2)>
	
	<!--- Create Paths --->
	<cfset pkgPath = tmpDir & "/MPClientInstall/" & pkg>
	<cfset pkgPathZip = tmpDir & "/" & pkgName & ".zip">
	<cfset pkgURLPath = "/mp-content/clients/updates/#arguments.gCUUID#/"& GetFilefrompath(pkgPathZip)>
	
	<!--- Add Agent Config To Package --->
	<cffile action = "write" 
    		file = "#pkgPath#/Scripts/gov.llnl.mpagent.plist" 
    		output = "#arguments.agentConfigPlist#">
    <cffile action = "write" 
    		file = "#pkgPath#/Scripts/.mpVersion.plist" 
    		output = "#mpVersion#">        
	<cfexecute 
        name = "/usr/sbin/pkgutil"
        arguments = "--flatten #pkgPath# #tmpDir#/#pkg#"
        variable = "flattenResult"
        timeout = "15">
    </cfexecute>
	<!--- Compress the inner pkg --->	
	<cfexecute 
		name = "/usr/bin/ditto"
		arguments = "-c -k #pkgPath# #pkgPathZip#"
		variable = "aBaseZipResult"
		timeout = "15">
	</cfexecute>
	
	<cfset pkgHash = getSHA1Hash(pkgPathZip)>
	
	<cfif arguments.ptype EQ "agent">
		<cfset ptype = "app">
    <cfelseif arguments.ptype EQ "updater">    
    	<cfset ptype = "update">
	<cfelse>
		<cfset ptype = "NA">
	</cfif>
	<cftry>
		<cfquery datasource="mpds" name="qAddUpdate">
			Insert INTO mp_client_agents (puuid, type, agent_ver, version, build, framework, pkg_name, pkg_url, pkg_hash, osver)
			Values('#arguments.gCUUID#', '#ptype#', '#agent_version#', '#version#', '#build#', '#framework#', '#pkgName#', '#pkgURLPath#', '#pkgHash#', '#osVerSupport#')
		</cfquery>
	<cfcatch>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
	</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="processPackageOrig" access="public" output="no" returntype="any">
    <cfargument name="gCUUID">
	<cfargument name="mainPkg">
	<cfargument name="pkgStruct" type="struct">
    <cfargument name="pType">
	<cfargument name="agentConfigPlist">
	
    <cfset var pkg = "0">
	<cfset var pkgName = "">
	<cfset var pkgHash = "">
	<cfset var version = "0">
	<cfset var agent_version = "0">
	<cfset var build = "0">
	<cfset var framework = "0">
	<cfset var osVerSupport = "*">
	
	<cfset tmpDir = #GetTempdirectory()# & #arguments.gCUUID#>
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	
	<cfif StructKeyExists(arguments.pkgStruct,"agent_version")>
		<cfset agent_version = arguments.pkgStruct["agent_version"]>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: agent version attribute was missing.">	
		<cfreturn result>	
	</cfif>	
	
	<cfif StructKeyExists(arguments.pkgStruct,"pkg")>
		<cfset pkg = arguments.pkgStruct["pkg"]>
		<cfset pkgName = GetFilefrompath(pkg)>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: pkg attribute was missing.">	
		<cfreturn result>	
	</cfif>	
	
	<cfif StructKeyExists(arguments.pkgStruct,"version")>
		<cfset version = arguments.pkgStruct["version"]>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: version attribute was missing.">	
		<cfreturn result>	
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"build")>
		<cfset build = arguments.pkgStruct["build"]>
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"framework")>
		<cfset framework = arguments.pkgStruct["framework"]>
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"osver")>
		<cfset osVerSupport = arguments.pkgStruct["osver"]>
	</cfif>
	
	<!--- Create Paths --->
	<cfset pkgPath = tmpDir & "/" & arguments.mainPkg & "/" & pkg>
	<cfset pkgPathZip = tmpDir & "/" & pkgName & ".zip">
	<cfset pkgURLPath = "/mp-content/clients/updates/#arguments.gCUUID#/"& GetFilefrompath(pkgPathZip)>
	
	<!--- Add Agent Config To Package --->
    <!--- "#pkgPath#/Contents/Resources/gov.llnl.mpagent.plist" --->
	<cffile action = "write" 
    		file = "#pkgPath#/Resources/gov.llnl.mpagent.plist" 
    		output = "#arguments.agentConfigPlist#">
	
	<!--- Compress the inner pkg --->	
	<cfexecute 
		name = "/usr/bin/ditto"
		arguments = "-c -k --keepParent #pkgPath# #pkgPathZip#"
		variable = "aBaseZipResult"
		timeout = "15">
	</cfexecute>
	
	<cfset pkgHash = getSHA1Hash(pkgPathZip)>
	
	<cfif arguments.ptype EQ "agent">
		<cfset ptype = "app">
    <cfelseif arguments.ptype EQ "updater">    
    	<cfset ptype = "update">
	<cfelse>
		<cfset ptype = "NA">
	</cfif>
	<cftry>
		<cfquery datasource="mpds" name="qAddUpdate">
			Insert INTO mp_client_agents (puuid, type, agent_ver, version, build, framework, pkg_name, pkg_url, pkg_hash, osver)
			Values('#arguments.gCUUID#', '#ptype#', '#agent_version#', '#version#', '#build#', '#framework#', '#pkgName#', '#pkgURLPath#', '#pkgHash#', '#osVerSupport#')
		</cfquery>
	<cfcatch>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
	</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="createAgentConfig" access="public" output="yes" returntype="any">

	<cfset var response = {} />
	<cfset response[ "errorNo" ] = "0" />
	<cfset response[ "errorMsg" ] = "" />
	<cfset response[ "result" ] = {} />

	<cfset var _config = {}>

	<cftry>
		<cfquery datasource="mpds" name="qGetAgentConfig">
			select * from mp_servers
			Where isMaster = 1 OR isProxy = 1
			AND active = 1
		</cfquery>
		
		<cfif qGetAgentConfig.RecordCount GTE 1>
			<cfset _defaultID = getDefaultAgentConfigID()>
			<cfdump var="#_defaultID#">
			<cfif _defaultID.errorNo NEQ 0>
				<!--- We have a error --->
				<!--- Log the error --->
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "#_defaultID.errorMsg#">
				<cfreturn response>
			</cfif>
			<cfdump var="#_defaultID.result#">
			<cfset _config = getDefaultAgentConfigUsingID(_defaultID.result)>
			<cfif _config.errorNo NEQ 0>
				<!--- We have a error --->
				<!--- Log the error --->
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "#_config.errorMsg#">
				<cfreturn response>
			</cfif>
		<cfelse>
			<!--- No Results --->
            <cfset response.errorNo = "1">
			<cfset response.errorMsg = "Error: No MacPatch servers found. Please make sure you have configured the servers first.">
			<cfreturn response>
		</cfif>
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">
			<cfreturn response>
		</cfcatch>
	</cftry>
	
	<cfset var defaultProxy = 0>
	<cfset var defaultMaster = 0>
	<cfset var enforceProxy = 0>
	<cfset var enforceMaster = 0>
	
	<cfset var proxyConfig = "">
	<cfset var masterConfig = "">
	
	<cfset proxyConfig = getServerDataOfType(qGetAgentConfig,"Proxy")>
	<cfset masterConfig = getServerDataOfType(qGetAgentConfig,"Master")>

	

	<cfsavecontent variable="thePlist">
	<cfoutput>	
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>default</key>
		<dict>
			<cfloop query="_config.result">
				<cfif _config.result.enforced EQ 0>
					<cfif FindNoCase("Proxy",_config.result.aKey) GTE 1>
						<!--- If Proxy Config is not enforced --->
						<cfset defaultProxy = 1>
					<cfelseif FindNoCase("MPServer",_config.result.aKey) GTE 1>
						<!--- If Mast server Config is not enforced --->	
						<cfset defaultMaster = 1>
					<cfelse>
						<key>#_config.result.aKey#</key>
						<string>#_config.result.aKeyValue#</string>
					</cfif>
				</cfif>
			</cfloop>
			<cfif defaultProxy EQ 1>
				<key>MPProxyServerAddress</key>
				<string>#proxyConfig.result.MPProxyServerAddress#</string>  
				<key>MPProxyServerPort</key>
				<string>#proxyConfig.result.MPProxyServerPort#</string>  
				<key>MPProxyEnabled</key>
				<string>#proxyConfig.result.MPProxyEnabled#</string>  
			</cfif>
			<cfif defaultMaster EQ 1>
				<key>MPServerAddress</key>
				<string>#masterConfig.result.MPServerAddress#</string>  
				<key>MPServerPort</key>
				<string>#masterConfig.result.MPServerPort#</string>  
				<key>MPServerSSL</key>
				<string>#masterConfig.result.MPServerSSL#</string>  
			</cfif>
		</dict>
		<key>enforced</key>
		<dict>
			<cfloop query="_config.result">
				<cfif _config.result.enforced EQ 1>
					<cfif FindNoCase("Proxy",_config.result.aKey) GTE 1>
					<!--- If Proxy Config is not enforced --->
						<cfset enforceProxy = 1>
					<cfelseif FindNoCase("MPServer",_config.result.aKey) GTE 1>
					<!--- If Mast server Config is not enforced --->
						<cfset enforceMaster = 1>
					<cfelse>
						<key>#_config.result.aKey#</key>
						<string>#_config.result.aKeyValue#</string>
					</cfif>
				</cfif>
			</cfloop>
			<cfif enforceProxy EQ 1>
				<key>MPProxyServerAddress</key>
				<string>#proxyConfig.result.MPProxyServerAddress#</string>  
				<key>MPProxyServerPort</key>
				<string>#proxyConfig.result.MPProxyServerPort#</string>  
				<key>MPProxyEnabled</key>
				<string>#proxyConfig.result.MPProxyEnabled#</string>  
			</cfif>
			<cfif enforceMaster EQ 1>
				<key>MPServerAddress</key>
				<string>#masterConfig.result.MPServerAddress#</string>  
				<key>MPServerPort</key>
				<string>#masterConfig.result.MPServerPort#</string>  
				<key>MPServerSSL</key>
				<string>#masterConfig.result.MPServerSSL#</string>  
			</cfif>
		</dict>
	</dict>
	</plist>
	</cfoutput>
	</cfsavecontent>
	<cfset xy = htmlCompressFormat(thePlist, 2)>
	<cfset response.result = xy>
	<!---
	<cffile action = "write" 
    		file = "#arguments.mainPkgPath#/Contents/Resources/gov.llnl.mpagent.plist" 
    		output = "#xy#">
	--->
	<cfreturn response>
</cffunction>

<cffunction name="getServerDataOfType" access="public" output="no" returntype="any">
	
	<cfargument name="data" hint="Query">
	<cfargument name="type" hint="Master or Proxy">
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	<cfset result.result = {}>
    
	<cfset var serverInfo = Structnew()>
	
	<cfif arguments.type EQ "Master">
		<cfset serverInfo.MPServerAddress = "">
		<cfset serverInfo.MPServerPort = "2600">
		<cfset serverInfo.MPServerSSL = "1">
		
		<cfoutput query="arguments.data">
			<cfif arguments.data.isMaster EQ 1>
				<cfset serverInfo.MPServerAddress = arguments.data.server>
				<cfset serverInfo.MPServerPort = arguments.data.port>
				<cfset serverInfo.MPServerSSL = arguments.data.useSSL>
			</cfif>
		</cfoutput>
		
	<cfelseif arguments.type EQ "Proxy">
		<cfset serverInfo.MPProxyServerAddress = "">
		<cfset serverInfo.MPProxyServerPort = "2600">
		<cfset serverInfo.MPProxyEnabled = "0">
		
		<cfoutput query="arguments.data">
			<cfif arguments.data.isProxy EQ 1>
				<cfset serverInfo.MPProxyServerAddress = arguments.data.server>
				<cfset serverInfo.MPProxyServerPort = arguments.data.port>
				<cfset serverInfo.MPProxyEnabled = 1>
			</cfif>
		</cfoutput>
	<cfelse>	
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Invalid argument.">
		<cfreturn result>
	</cfif>
	
	<cfset result.result = serverInfo>
	<cfreturn result>
</cffunction>

<cffunction name="getDefaultAgentConfigID" access="public" output="no" returntype="any">
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	<cfset result.result = "">
    
	<cftry>
		<cfquery datasource="mpds" name="qGetAgentConfigID">
			Select aid From mp_agent_config
			Where isDefault = 1
		</cfquery>
		<cfif qGetAgentConfigID.RecordCount EQ 1>
			<cfset result.result = qGetAgentConfigID.aid>
		<cfelse>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "Error: No config data found.">	
		</cfif>
		<cfcatch>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
	</cftry>

	<cfreturn result>
</cffunction>

<cffunction name="getDefaultAgentConfigUsingID" access="public" output="no" returntype="any">
	<cfargument name="ConfigID">
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	<cfset result.result = {}>
	
	<cftry>
		<cfquery datasource="mpds" name="qGetAgentConfigData">
			Select * From mp_agent_config_data
			Where aid = "#Arguments.ConfigID#"
		</cfquery>
		<cfif qGetAgentConfigData.RecordCount GTE 1>
			<cfset result.result = qGetAgentConfigData>
		<cfelse>
			<cfset result.errorNo = "2">
			<cfset result.errorMsg = "Error: No config data found for ID #Arguments.ConfigID#">	
		</cfif>
		<cfcatch>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSHA1Hash" access="public" output="no">
    <cfargument name="aBinToHash">
    
	<cfexecute 
		name = "/usr/bin/openssl"
		arguments = "sha1 #arguments.aBinToHash#"
		variable = "sha1Result"
		timeout = "5">
	</cfexecute>
	<cfset sha1 = #ListGetAt(sha1Result,2,"= ")#>
	
	<cfreturn sha1>
</cffunction>

<cfscript>
/**
 * Replaces a huge amount of unnecessary whitespace from your HTML code.
 * 
 * @param sInput      HTML you wish to compress. (Required)
 * @return Returns a string. 
 * @author Jordan Clark (JordanClark@Telus.net) 
 * @version 1, November 19, 2002 
 */
function HtmlCompressFormat(sInput)
{
   var level = 2;
   if( arrayLen( arguments ) GTE 2 AND isNumeric(arguments[2]))
   {
      level = arguments[2];
   }
   // just take off the useless stuff
   sInput = trim(sInput);
   switch(level)
   {
      case "3":
      {
         //   extra compression can screw up a few little pieces of HTML, doh         
         sInput = reReplace( sInput, "[[:space:]]{2,}", " ", "all" );
         sInput = replace( sInput, "> <", "><", "all" );
         sInput = reReplace( sInput, "<!--[^>]+>", "", "all" );
         break;
      }
      case "2":
      {
         sInput = reReplace( sInput, "[[:space:]]{2,}", chr( 13 ), "all" );
         break;
      }
      case "1":
      {
         // only compresses after a line break
         sInput = reReplace( sInput, "(" & chr( 10 ) & "|" & chr( 13 ) & ")+[[:space:]]{2,}", chr( 13 ), "all" );
         break;
      }
   }
   return sInput;
}
</cfscript>
