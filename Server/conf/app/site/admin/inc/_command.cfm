<cfsilent>
</cfsilent>
	

	<!--- stick everything in form and url into a struct for easy reference --->
	
	<cfloop collection="#url#" item="urlKey">
	  <cfset args[urlKey] = url[urlKey] />
	</cfloop>
	
	<cfloop collection="#form#" item="formKey">
	  <cfset args[formKey] = form[formKey] />
	</cfloop>
	
	<cfswitch expression="#args.action#">
		<cfcase value="AddNewAgentConfig,0">
			<cftry>
				<cfset cID = CreateUuid()>
				<cfquery datasource="#session.dbsource#" name="addConfig">
					Insert Into mp_agent_config (aid, name)
					Values (<cfqueryparam value="#cID#">,<cfqueryparam value="#args.name#">)
				</cfquery>
				<cfset x = 1>
				<cfloop index="i" list="#args.FIELDNAMES#" delimiters=",">
					<cfif Left(i,2) EQ "p_">
						<cfswitch expression="#ReplaceNoCase(i,"p_","")#">
							<cfcase value="ALLOWCLIENT"> 
						    	<cfset fKeyName = "AllowClient">
						    </cfcase> 
						    <cfcase value="ALLOWSERVER"> 
						        <cfset fKeyName = "AllowServer">
						    </cfcase>
							<cfcase value="DESCRIPTION"> 
						        <cfset fKeyName = "Description">
						    </cfcase>
						    <cfcase value="DOMAIN"> 
						        <cfset fKeyName = "Domain">
						    </cfcase>
						    <cfcase value="PATCHGROUP"> 
						        <cfset fKeyName = "PatchGroup">
						    </cfcase>
						    <cfcase value="REBOOT"> 
						        <cfset fKeyName = "Reboot">
						    </cfcase>
						    <cfcase value="SWDISTGROUP"> 
						        <cfset fKeyName = "SWDistGroup">
						    </cfcase>
						    <cfcase value="MPProxyServerAddress"> 
						        <cfset fKeyName = "MPProxyServerAddress">
						    </cfcase>
						    <cfcase value="MPProxyServerPort"> 
						        <cfset fKeyName = "MPProxyServerPort">
						    </cfcase>
						    <cfcase value="MPProxyEnabled"> 
						        <cfset fKeyName = "MPProxyEnabled">
						    </cfcase>
						    <cfcase value="MPServerAddress"> 
						        <cfset fKeyName = "MPServerAddress">
						    </cfcase>
						    <cfcase value="MPServerPort"> 
						        <cfset fKeyName = "MPServerPort">
						    </cfcase>
						    <cfcase value="MPServerSSL"> 
						        <cfset fKeyName = "MPServerSSL">
						    </cfcase>
						    <cfcase value="MPServerAllowSelfSigned"> 
						        <cfset fKeyName = "MPServerAllowSelfSigned">
						    </cfcase>
                            <cfcase value="CheckSignatures"> 
						        <cfset fKeyName = "CheckSignatures">
						    </cfcase>
						</cfswitch>
						<cfquery datasource="#session.dbsource#" name="addConfigData">
							Insert Into mp_agent_config_data (aid, aKey, aKeyValue, enforced)
							Values (<cfqueryparam value="#cID#">,<cfqueryparam value="#fKeyName#">,<cfqueryparam value="#args[i]#">,<cfqueryparam value="#listGetAt(args.ENFORCED, x)#">)
						</cfquery>	
						<cfset x = x + 1>
					</cfif>
				</cfloop>
				
				<!--- Set Revision Hash --->
				<cfset rev = getConfigRevision(cID)>
				<cfif rev.errorNo NEQ 0>
					<cfset rev = 0>
					<cflog type="Error" text="[#rev.errorNo#]: #rev.errorMsg#" application="True">
					<cfabort>
				</cfif>

				<cfquery datasource="#session.dbsource#" name="qUpdateRev">
					Update mp_agent_config
					Set revision = <cfqueryparam value="#rev.result#">
					Where aid = <cfqueryparam value="#cID#">
				</cfquery>
				
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
				</cfcatch>
			</cftry>
			
			<cfset session.message.text = "Added ..." />
			<cfset session.message.type = "info" />		
			<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
		</cfcase>
		<cfcase value="EditAgentConfig,1">
			<cftry>
				<cfset x = 1>
				<cfloop index="i" list="#args.FIELDNAMES#" delimiters=",">
					<cfif Left(i,2) EQ "p_">
						<cfswitch expression="#ReplaceNoCase(i,"p_","")#">
							<cfcase value="ALLOWCLIENT"> 
						    	<cfset efKeyName = "AllowClient">
						    </cfcase> 
						    <cfcase value="ALLOWSERVER"> 
						        <cfset efKeyName = "AllowServer">
						    </cfcase>
							<cfcase value="DESCRIPTION"> 
						        <cfset efKeyName = "Description">
						    </cfcase>
						    <cfcase value="DOMAIN"> 
						        <cfset efKeyName = "Domain">
						    </cfcase>
						    <cfcase value="PATCHGROUP"> 
						        <cfset efKeyName = "PatchGroup">
						    </cfcase>
						    <cfcase value="REBOOT"> 
						        <cfset efKeyName = "Reboot">
						    </cfcase>
						    <cfcase value="SWDISTGROUP"> 
						        <cfset efKeyName = "SWDistGroup">
						    </cfcase>
						    <cfcase value="MPProxyServerAddress"> 
						        <cfset efKeyName = "MPProxyServerAddress">
						    </cfcase>
						    <cfcase value="MPProxyServerPort"> 
						        <cfset efKeyName = "MPProxyServerPort">
						    </cfcase>
						    <cfcase value="MPProxyEnabled"> 
						        <cfset efKeyName = "MPProxyEnabled">
						    </cfcase>
						    <cfcase value="MPServerAddress"> 
						        <cfset efKeyName = "MPServerAddress">
						    </cfcase>
						    <cfcase value="MPServerPort"> 
						        <cfset efKeyName = "MPServerPort">
						    </cfcase>
						    <cfcase value="MPServerSSL"> 
						        <cfset efKeyName = "MPServerSSL">
						    </cfcase>
						    <cfcase value="MPServerAllowSelfSigned"> 
						        <cfset efKeyName = "MPServerAllowSelfSigned">
						    </cfcase>
                            <cfcase value="CheckSignatures"> 
						        <cfset efKeyName = "CheckSignatures">
						    </cfcase>
						</cfswitch>
						
						<cfif containsKey(efKeyName,args.config) EQ true>
							<cfquery datasource="#session.dbsource#" name="qSetDefaultConfigUpdate" result="r">
								Update mp_agent_config_data
								Set aKeyValue = <cfqueryparam value="#args[i]#">,
								enforced = <cfqueryparam value="#listGetAt(args.ENFORCED, x)#">
								Where aid = <cfqueryparam value="#args.config#">
								AND aKey = <cfqueryparam value="#efKeyName#">
							</cfquery>
						<cfelse>
							<cfquery datasource="#session.dbsource#" name="qSetDefaultConfigUpdate" result="r">
								Insert Into mp_agent_config_data (aid,aKey,aKeyValue,enforced)
								Values(<cfqueryparam value="#args.config#">,<cfqueryparam value="#efKeyName#">,
								<cfqueryparam value="#args[i]#">,<cfqueryparam value="#listGetAt(args.ENFORCED, x)#">)
							</cfquery>
						</cfif>						
						<cfset x = x + 1>
					</cfif>
				</cfloop>
				
				<!--- Update Revision Hash --->
				<cfset rev = getConfigRevision(args.config)>
				<cfif rev.errorNo NEQ 0>
					<cfset rev = 0>
					<cflog type="Error" text="[#rev.errorNo#]: #rev.errorMsg#" application="True">
				</cfif>
				<cfquery datasource="#session.dbsource#" name="qSetDefaultConfig">
					Update mp_agent_config
					Set revision = <cfqueryparam value="#rev.result#">
					Where aid = <cfqueryparam value="#args.config#">
				</cfquery>
				
				<cfcatch type="any">
					<cfset session.message.text = "#CFCATCH.Message# #CFCATCH.Detail#" />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
				</cfcatch>				
			</cftry>
			
			<cftry>
			<!--- Update Active Agent Packages with new Config --->
				<cfquery name="qIfBothActive" datasource="#session.dbsource#">
                	Select active, puuid From mp_client_agents WHERE active = '1'
            	</cfquery>
                <cfset _pCount = 0>
				<cfset _distinctList = structNew()>
                <cfoutput query="qIfBothActive">
					<cfset _distinctList[puuid] = "">
                	<cfset _pCount = _pCount + active>
                </cfoutput>
				<cfset distinctList = structKeyList(_distinctList)>
				
                <cfif _pCount EQ 2>
					<cfif ListLen(distinctList) EQ 1>
						<cfset _pkgBaseLoc = #application.settings.paths.content# & "/clients">
						<cfset _pid = ListFirst(distinctList)>
						<!--- Update Agent Config Plist --->
						<cfset caObj = CreateObject("component","agent_config").init(session.dbsource)>
						<cfset pkgResult = caObj.updatePackageConfigWithResult(_pid)>
	                    <cfdump var="#pkgResult#">
	                    
	                	<!--- Move Main Installer Into Production --->
	                    <cfset _mainPkg = #_pkgBaseLoc# & "/MPClientInstall.pkg.zip">
	                    <cfset _newMainPkg = #_pkgBaseLoc# & "/updates/" & #_pid# & "/MPClientInstall.pkg.zip">
	                    <cfif FileExists(_mainPkg)>
	                    	<cfset _rm = FileDelete(_mainPkg)>
	                    </cfif>    
	                    <cfset _cp = FileCopy(_newMainPkg,_mainPkg)>
					</cfif>
                </cfif>
				
				<cfcatch type="any">
					<cfset session.message.text = "#CFCATCH.Message# #CFCATCH.Detail#" />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
				</cfcatch>				
			</cftry>
			
			<cfset session.message.text = "The scheduled task was run successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
		</cfcase>
		<cfcase value="RemoveAgentConfig,2">
			<cftry>
				<cfquery datasource="#session.dbsource#" name="addConfig">
					Delete from mp_agent_config
					Where aid = <cfqueryparam value="#args.config#">
				</cfquery>
				<cfquery datasource="#session.dbsource#" name="addConfig">
					Delete from mp_agent_config_data
					Where aid = <cfqueryparam value="#args.config#">
				</cfquery>
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
				</cfcatch>
			</cftry>  
			<cfset session.message.text = "The scheduled task was deleted successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
		</cfcase>
		<cfcase value="DefaultAgentConfig,3">
			<cftry>
				<cfquery datasource="#session.dbsource#" name="qReSetDefaultConfig">
					Update mp_agent_config
					Set isDefault = '0'
					Where isDefault = '1'
				</cfquery>
                <cfquery datasource="#session.dbsource#" name="qSetDefaultConfig">
					Update mp_agent_config
					Set isDefault = <cfqueryparam value="1">
					Where aid = <cfqueryparam value="#args.config#">
				</cfquery>
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
				</cfcatch>
			</cftry>  
			<cfset session.message.text = "The scheduled task was deleted successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/inc/admin_client_agent_config.cfm" addtoken="false" />
		</cfcase>
	</cfswitch>
	

<cffunction name="containsKey" access="public" output="Yes" returntype="any">
    <cfargument name="key">
    <cfargument name="configID">

	<cftry>
		<cfquery datasource="mpds" name="qGetAgentConfigData">
			Select aKey From mp_agent_config_data
			Where aid = '#arguments.configID#'
			AND aKey = '#arguments.configID#'
		</cfquery>
		<cfif qGetAgentConfigData.RecordCount GTE 1>
			<cfreturn True>
		</cfif>
		<cfcatch>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "#cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
	</cftry>
	
	<cfreturn False>
</cffunction>	

<cffunction name="getConfigRevision" access="public" output="Yes" returntype="any">
    <cfargument name="configID">
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	<cfset result.result = "">
    
	<cftry>
		<cfquery datasource="mpds" name="qGetAgentConfigData">
			Select aKeyValue From mp_agent_config_data
			Where aid = '#arguments.configID#'
		</cfquery>
		<cfif qGetAgentConfigData.RecordCount GTE 1>
			<cfset confData = "">
			<cfoutput query="qGetAgentConfigData">
				<cfset confData = confData & "#aKeyValue#">
			</cfoutput>
			
			<cfset result.result = Hash(confData,"MD5")>
		<cfelse>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "No config data found.">	
		</cfif>
		<cfcatch>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "#cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
	</cftry>
	<cfdump var="#result.result#">
	<cfreturn result>
</cffunction>