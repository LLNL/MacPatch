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
						<cfquery datasource="#session.dbsource#" name="addConfigData">
							Insert Into mp_agent_config_data (aid, aKey, aKeyValue, enforced)
							Values (<cfqueryparam value="#cID#">,<cfqueryparam value="#ReplaceNoCase(i,"p_","")#">,<cfqueryparam value="#args[i]#">,<cfqueryparam value="#listGetAt(args.ENFORCED, x)#">)
						</cfquery>	
						<cfset x = x + 1>
					</cfif>
				</cfloop>
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
						<cfquery datasource="#session.dbsource#" name="qSetDefaultConfig">
							Update mp_agent_config_data
							Set aKeyValue = <cfqueryparam value="#args[i]#">,
							enforced = <cfqueryparam value="#listGetAt(args.ENFORCED, x)#">
							Where aid = <cfqueryparam value="#args.config#">
							AND aKey = <cfqueryparam value="#ReplaceNoCase(i,"p_","")#">
						</cfquery>
						<cfset x = x + 1>
					</cfif>
				</cfloop>
				
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