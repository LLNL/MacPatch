<cfsilent>
	<cfparam name="args.action" type="string" default="" />

	<!--- stick everything in form and url into a struct for easy reference --->
	<cfset args = StructNew() />
	
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
					<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
				</cfcatch>
			</cftry>
			
			<cfset session.message.text = "Added ..." />
			<cfset session.message.type = "info" />		
			<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
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
						</cfswitch>
						<cfquery datasource="#session.dbsource#" name="qSetDefaultConfig">
							Update mp_agent_config_data
							Set aKeyValue = <cfqueryparam value="#args[i]#">,
							enforced = <cfqueryparam value="#listGetAt(args.ENFORCED, x)#">
							Where aid = <cfqueryparam value="#args.config#">
							AND aKey = <cfqueryparam value="#efKeyName#">
						</cfquery>
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
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cfdump var="#session.message#">
					<cfabort>
					<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
				</cfcatch>
			</cftry>
			
			<cfset session.message.text = "The scheduled task was run successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
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
					<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
				</cfcatch>
			</cftry>  
			<cfset session.message.text = "The scheduled task was deleted successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
		</cfcase>
		<cfcase value="DefaultAgentConfig,3">
			<cftry>
				<cfquery datasource="#session.dbsource#" name="qSetDefaultConfig">
					Update mp_agent_config
					Set isDefault = <cfqueryparam value="1">
					Where aid = <cfqueryparam value="#args.config#">
				</cfquery>
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cfdump>
					<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
				</cfcatch>
			</cftry>  
			<cfset session.message.text = "The scheduled task was deleted successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/index.cfm?agent_config" addtoken="false" />
		</cfcase>
	</cfswitch>
</cfsilent>	

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