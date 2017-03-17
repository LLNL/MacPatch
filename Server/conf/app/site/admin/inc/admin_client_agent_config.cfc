<cfcomponent>
	<cffunction name="init" access="public" returntype="any" output="no">
        <cfargument name="datasource" type="string" required="yes">

        <cfset var me = 0>
        <cfset variables.datasource = arguments.datasource>
        <cfset variables.logToFile = false>
        <cfset variables.pkgBaseLoc = #application.settings.paths.content# & "/clients">
		<cfset variables.pkgName = "MPClientInstall.pkg.zip">
		<cfset variables.pkgNameNoZip = #ReplaceNocase(variables.pkgName,'.zip','','All')#>
		<cfset variables.pkgList="Base.pkg,Updater.pkg">
        <cfset me = this>
        
        <cfreturn me>
    </cffunction>
	
	<cffunction name="updatePackageConfigWithResult" access="public" returntype="struct" output="no">
		<cfargument name="pkgID" required="yes">
		
		<cfset results = StructNew() />
		<cfset results['errorno'] = 0 />
		<cfset results['errormsg'] = "" />
    	
		<cfset ulTmpPath = #GetTempdirectory()# & "/" & #arguments.pkgID#>
		
		<cfif directoryexists(ulTmpPath) NEQ False>
			<cfdirectory action="DELETE" directory="#ulTmpPath#" recurse="true">
		</cfif>
		
		<cfdirectory action="create" directory="#ulTmpPath#" recurse="true">
		<cffile action="copy" source="#pkgBaseLoc#/updates/#arguments.pkgID#/#variables.pkgName#" destination="#ulTmpPath#/#variables.pkgName#">
		
		<!--- Unzip the Main Client Installer --->
		<cflog type="Error" application="yes" text="Unzip -x -k #ulTmpPath#/#variables.pkgName# #ulTmpPath#">
		<cfexecute 
   			name = "/usr/bin/ditto"
   			arguments = "-x -k #ulTmpPath#/#variables.pkgName# #ulTmpPath#"
   			variable = "unzipResult"
  			timeout = "30">
		</cfexecute>
		
		<!--- Extract Flat Package --->
		<cflog type="Error" application="yes" text="--expand #ulTmpPath#/#pkgNameNoZip# #ulTmpPath#/MPClientInstall">
        <cfexecute 
			name = "/usr/sbin/pkgutil"
			arguments = "--expand #ulTmpPath#/#pkgNameNoZip# #ulTmpPath#/MPClientInstall"
			variable = "pkgExpanded"
			timeout = "15">
		</cfexecute>
		
		<cffile action="delete" file="#ulTmpPath#/#variables.pkgName#">
		<cffile action="delete" file="#ulTmpPath#/#variables.pkgNameNoZip#">

		<cflog application="yes" text="Create Agent Config">
		<cfset agentPlist = {}>
		<cfset agentPlist = createAgentConfig()>
		
		<cfif agentPlist.errorNo NEQ "0">
			<cfset session.lastErrorNo = agentPlist.errorNo>
			<cfset session.lastErrorMsg = agentPlist.errorMsg>
			<cflog type="Error" application="yes" text="Error[#agentPlist.errorNo#]: #agentPlist.errorMsg#">
			
			<cfset results['errorno'] = 2 />
			<cfset results['errormsg'] = agentPlist.errorMsg />
			<cfreturn results>
		</cfif>
		
		<!--- Configure Packages for update mechanisim --->
		<cfset _results = 0>
		<cflog application="yes" text="Configure Packages for update mechanisim ">
		<cfloop index="p" list="#variables.pkgList#" delimiters=","> 
			<cftry>
				<cflog application="yes" text="processPackage: #arguments.pkgID#, #p#, agentPlist">
				<cfset _i = processPackage(arguments.pkgID,p,agentPlist.result)>
				
				<cfif _i.errorNo NEQ "0">
					<cflog type="Error" application="yes" text="Error [#_i.errorNo#]:#_i#">
				</cfif>
				<cfset _results = #_results# + #_i.errorNo#>
				<cfcatch type="any">
					<cfset _results = #_results# + "1">
					<cfset session.lastErrorNo = "#cfcatch.ErrorCode#">
					<cfset session.lastErrorMsg = "#cfcatch.detail# #cfcatch.Message#">
					<cflog type="Error" application="yes" text="[processPackage][#cfcatch.ErrorCode#]: #session.lastErrorMsg#">
				</cfcatch>
			</cftry>
		</cfloop>

		<cfif _results NEQ "0">
			<cfset results['errorno'] = 1 />
			<cfset results['errormsg'] = session.lastErrorMsg />
			<cfreturn results>
		</cfif>
		
		
        
		<cflog application="yes" text="Write Config to Main Package">
		
		<!--- Write Config to Main Package --->
		<cflog application="yes" text="--flatten #ulTmpPath#/MPClientInstall #ulTmpPath#/#pkgNameNoZip#">
        <cfexecute 
			name = "/usr/sbin/pkgutil"
			arguments = "--flatten #ulTmpPath#/MPClientInstall #ulTmpPath#/#pkgNameNoZip#"
			variable = "flattenResult"
			timeout = "15">
		</cfexecute>
		
		<cflog application="yes" text="-c -k #ulTmpPath#/#pkgNameNoZip# #ulTmpPath#/#pkgName#">
		<cfexecute 
			name = "/usr/bin/ditto"
			arguments = "-c -k #ulTmpPath#/#variables.pkgNameNoZip# #ulTmpPath#/#pkgName#"
			variable = "aZipResult"
			timeout = "15">
		</cfexecute>
		
		<!--- Move Packages To New Location --->
		<cfset baseLoc = #application.settings.paths.content# & "/clients/updates">
		<cfset new_pkgBaseDir = #baseLoc# & "/" & #arguments.pkgID#>
		<cfif directoryexists(new_pkgBaseDir) EQ False>
        	<cftry>
        		<cfdirectory action="create" directory="#new_pkgBaseDir#" recurse="true">
            <cfcatch>
				<cfset results['errorno'] = 2 />
				<cfset results['errormsg'] = cfcatch.Detail />
				<cfreturn results>
            </cfcatch>
            </cftry>
		</cfif>
	
		<cflog application="yes" text="#variables.pkgList#">
		<cfset variables.pkgList = ListAppend(variables.pkgList, variables.pkgNameNoZip, ",")>
		<cflog application="yes" text="#variables.pkgList#">
		
		<cfloop index="p" list="#variables.pkgList#" delimiters=","> 
			<cfset pkg_source = ulTmpPath & "/" & #p# & ".zip">
            <cfset pkg_source = #Replace(pkg_source,"//","/","All")#>
            <cftry>
				<cflog application="yes" text="mv #pkg_source#  #new_pkgBaseDir#">
				<cffile action="move" source="#pkg_source#" destination="#new_pkgBaseDir#">
            <cfcatch>
            	<cfset results['errorno'] = 2 />
				<cfset results['errormsg'] = cfcatch.Detail />
				<cfreturn results>
            </cfcatch>
            </cftry>
		</cfloop>

    	<!--- Clean up the temp Dir --->
		<cfdirectory action="delete" directory="#ulTmpPath#" recurse="true">
		
		<cfreturn results>
    </cffunction>
	
	<cffunction name="updatePackageConfig" access="public" returntype="void" output="no">
		<cfargument name="pkgID" required="yes">
    	
		<cfset ulTmpPath = #GetTempdirectory()# & "/" & #arguments.pkgID#>
		
		<cfif directoryexists(ulTmpPath) NEQ False>
			<cfdirectory action="DELETE" directory="#ulTmpPath#" recurse="true">
		</cfif>
		
		<cfdirectory action="create" directory="#ulTmpPath#" recurse="true">
		<cffile action="copy" source="#pkgBaseLoc#/updates/#arguments.pkgID#/#variables.pkgName#" destination="#ulTmpPath#/#variables.pkgName#">
		
		<!--- Unzip the Main Client Installer --->
		<cflog type="Error" application="yes" text="Unzip -x -k #ulTmpPath#/#variables.pkgName# #ulTmpPath#">
		<cfexecute 
   			name = "/usr/bin/ditto"
   			arguments = "-x -k #ulTmpPath#/#variables.pkgName# #ulTmpPath#"
   			variable = "unzipResult"
  			timeout = "30">
		</cfexecute>
		
		<!--- Extract Flat Package --->
		<cflog type="Error" application="yes" text="--expand #ulTmpPath#/#pkgNameNoZip# #ulTmpPath#/MPClientInstall">
        <cfexecute 
			name = "/usr/sbin/pkgutil"
			arguments = "--expand #ulTmpPath#/#pkgNameNoZip# #ulTmpPath#/MPClientInstall"
			variable = "pkgExpanded"
			timeout = "15">
		</cfexecute>
		
		<cffile action="delete" file="#ulTmpPath#/#variables.pkgName#">
		<cffile action="delete" file="#ulTmpPath#/#variables.pkgNameNoZip#">

		<cflog application="yes" text="Create Agent Config">
		<cfset agentPlist = {}>
		<cfset agentPlist = createAgentConfig()>
		
		<cfif agentPlist.errorNo NEQ "0">
			<cfset session.lastErrorNo = agentPlist.errorNo>
			<cfset session.lastErrorMsg = agentPlist.errorMsg>
			<cflog type="Error" application="yes" text="Error[#agentPlist.errorNo#]: #agentPlist.errorMsg#">
			<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm">
			<cfabort>
		</cfif>
		
		<!--- Configure Packages for update mechanisim --->
		<cfset results = 0>
		<cflog application="yes" text="Configure Packages for update mechanisim ">
		<cfloop index="p" list="#variables.pkgList#" delimiters=","> 
			<cftry>
				<cflog application="yes" text="processPackage: #arguments.pkgID#, #p#, agentPlist">
				<cfset _i = processPackage(arguments.pkgID,p,agentPlist.result)>
				
				<cfif _i.errorNo NEQ "0">
					<cflog type="Error" application="yes" text="Error [#_i.errorNo#]:#_i#">
				</cfif>
				<cfset results = #results# + #_i.errorNo#>
				<cfcatch type="any">
					<cfset results = #results# + "1">
					<cfset session.lastErrorNo = "#cfcatch.ErrorCode#">
					<cfset session.lastErrorMsg = "#cfcatch.detail# #cfcatch.Message#">
					<cflog type="Error" application="yes" text="[processPackage][#cfcatch.ErrorCode#]: #session.lastErrorMsg#">
				</cfcatch>
			</cftry>
		</cfloop>

		<cfif results NEQ "0">
			<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm">
			<cfabort>
		</cfif>
        
		<cflog application="yes" text="Write Config to Main Package">
		
		<!--- Write Config to Main Package --->
		<cflog application="yes" text="--flatten #ulTmpPath#/MPClientInstall #ulTmpPath#/#pkgNameNoZip#">
        <cfexecute 
			name = "/usr/sbin/pkgutil"
			arguments = "--flatten #ulTmpPath#/MPClientInstall #ulTmpPath#/#pkgNameNoZip#"
			variable = "flattenResult"
			timeout = "15">
		</cfexecute>
		
		<cflog application="yes" text="-c -k #ulTmpPath#/#pkgNameNoZip# #ulTmpPath#/#pkgName#">
		<cfexecute 
			name = "/usr/bin/ditto"
			arguments = "-c -k #ulTmpPath#/#variables.pkgNameNoZip# #ulTmpPath#/#pkgName#"
			variable = "aZipResult"
			timeout = "15">
		</cfexecute>
		
		<!--- Move Packages To New Location --->
		<cfset baseLoc = #application.settings.paths.content# & "/clients/updates">
		<cfset new_pkgBaseDir = #baseLoc# & "/" & #arguments.pkgID#>
		<cfif directoryexists(new_pkgBaseDir) EQ False>
        	<cftry>
        	<cfdirectory action="create" directory="#new_pkgBaseDir#" recurse="true">
            <cfcatch>
            	<cfoutput>Error: #cfcatch.Detail#</cfoutput>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfif>
	
		<cflog application="yes" text="#variables.pkgList#">
		<cfset variables.pkgList = ListAppend(variables.pkgList, variables.pkgNameNoZip, ",")>
		<cflog application="yes" text="#variables.pkgList#">
		
		<cfloop index="p" list="#variables.pkgList#" delimiters=","> 
			<cfset pkg_source = ulTmpPath & "/" & #p# & ".zip">
            <cfset pkg_source = #Replace(pkg_source,"//","/","All")#>
            <cftry>
				<cflog application="yes" text="mv #pkg_source#  #new_pkgBaseDir#">
				<cffile action="move" source="#pkg_source#" destination="#new_pkgBaseDir#">
            <cfcatch>
            	<cfoutput>Error: #cfcatch.Detail#</cfoutput>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfloop>
	
    	<!--- Clean up the temp Dir --->
		<cfdirectory action="delete" directory="#ulTmpPath#" recurse="true">
		
		<cfreturn>
    </cffunction>

	<cffunction name="processPackage" access="public" output="no" returntype="any">
	    <cfargument name="gCUUID">
		<cfargument name="mainPkg">
		<cfargument name="agentConfigPlist">
		
		<cfset tmpDir = #GetTempdirectory()# & #arguments.gCUUID#>
		
		<cfset var result = Structnew()>
		<cfset result.errorNo = "0">
		<cfset result.errorMsg = "">
		
		<!--- Create Paths --->
		<cfset pkgPath = tmpDir & "/MPClientInstall/" & arguments.mainPkg>
		<cfset pkgPathZip = tmpDir & "/" & arguments.mainPkg & ".zip">
		
		<!--- Add Agent Config To Package --->
		<cflog application="yes" text="[processPackage]: write to #pkgPath#/Scripts/gov.llnl.mpagent.plist">
		<cffile action = "write" 
	    		file = "#pkgPath#/Scripts/gov.llnl.mpagent.plist" 
	    		output = "#arguments.agentConfigPlist#">
	    		
		<cflog application="yes" text="[processPackage]: --flatten #pkgPath# #tmpDir#/#arguments.mainPkg#">		    		        
		<cfexecute 
	        name = "/usr/sbin/pkgutil"
	        arguments = "--flatten #pkgPath# #tmpDir#/#arguments.mainPkg#"
	        variable = "flattenResult"
	        timeout = "15">
	    </cfexecute>
		<!--- Compress the inner pkg --->
		<cflog application="yes" text="[processPackage]: --zip #pkgPath# #pkgPathZip#">
		<cfexecute 
			name = "/usr/bin/ditto"
			arguments = "-c -k #tmpDir#/#arguments.mainPkg# #pkgPathZip#"
			variable = "aBaseZipResult"
			timeout = "15">
		</cfexecute>
		
		<cfset pkgHash = getSHA1Hash(pkgPathZip)>
        <cflog application="yes" text="[processPackage][hash]: #pkgPathZip# #pkgHash#">
		
		<cfset pType = "NA">
		<cfset pType = #IIF(FindNoCase("base",arguments.mainPkg) GTE 1,DE('app'),DE('update'))#>
        
        <cflog application="yes" text="[processPackage]: update mp_client_agents set pkg_hash = '#pkgHash#' Where puuid = '#arguments.gCUUID#' AND type = '#ptype#'">
		<cftry>
			<cfquery datasource="mpds" name="qAddUpdate">
				update mp_client_agents 
				set pkg_hash = '#pkgHash#'
				Where puuid = '#arguments.gCUUID#'
				AND type = '#ptype#'
			</cfquery>
		<cfcatch>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
		</cftry>
		
		<cfreturn result>
	</cffunction>
	
	<cffunction name="createAgentConfig" access="public" output="yes" returntype="any">
	
		<cfset var result = {} />
		<cfset result[ "errorNo" ] = "0" />
		<cfset result[ "errorMsg" ] = "" />
		<cfset result[ "result" ] = {} />
	
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
					<cfset result.errorNo = "1">
					<cfset result.errorMsg = "#_defaultID.errorMsg#">
					<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
					<cfreturn result>
				</cfif>
				<cfdump var="#_defaultID.result#">
				<cfset _config = getDefaultAgentConfigUsingID(_defaultID.result)>
				<cfif _config.errorNo NEQ 0>
					<!--- We have a error --->
					<!--- Log the error --->
					<cfset result.errorNo = "1">
					<cfset result.errorMsg = "#_config.errorMsg#">
					<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
					<cfreturn result>
				</cfif>
			<cfelse>
			
			</cfif>
			<cfcatch>
				<cfset result.errorNo = "1">
				<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">
				<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
				<cfreturn result>
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
		<cfset result.result = xy>
		<cfreturn result>
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
			<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
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
				<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
			</cfif>
			<cfcatch>
				<cfset result.errorNo = "1">
				<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">
				<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
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
				<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
			</cfif>
			<cfcatch>
				<cfset result.errorNo = "1">
				<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
				<cflog application="yes" type="Error" text="Error [#result.errorNo#]: #result.errorMsg#">
			</cfcatch>
		</cftry>
		
		<cfreturn result>
	</cffunction>

	<cffunction name="getSHA1Hash" access="private" output="no">
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
</cfcomponent>	