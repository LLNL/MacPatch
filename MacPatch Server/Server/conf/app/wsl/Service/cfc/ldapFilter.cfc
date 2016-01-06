<cfcomponent displayname="ldapFilter">
	
	<cfset this.ds = "mpds">
	<cfset this.ldapDSArray = arrayNew(1)>
	
	<cffunction name="init" access="public" output="no" returntype="ldapFilter">

		<cfif StructKeyExists(server.mpsettings.settings,'ldap_filters')>
			<cfset this.ldapDSArray = server.mpsettings.settings.ldap_filters>
		</cfif>
		<cfreturn this>
	</cffunction>

    <cffunction name="clientExistsInLDAP">
		<cfargument name="ClientID" required=true/>
		<cfargument name="LDAPDataSource" required=true/>
		<cfargument name="SearchInPath" required=true/>

		<cftry>
			<cfset var ldapDS = dataSourceConfig(arguments.LDAPDataSource) />
			<cfif ldapDS EQ "NA">
				<cfreturn false>
			</cfif>

			<cfset var ldap_start = ldapDS['searchbase'] />
			<cfset var ldap_filter = "(&(objectClass=*))" />

			<cfif ListFirst(arguments.SearchInPath , "=") EQ "OU">
				<cfset ldap_start = #arguments.SearchInPath# />
				<cfset ldap_filter = "(&(objectClass=computer))" />
			<cfelseif ListFirst(arguments.SearchInPath , "=") EQ "CN">
				<cfset ldap_filter = "(&(objectClass=computer)(memberOf=#arguments.SearchInPath#))" />
			<cfelse>
				<cfreturn false>
			</cfif>

			<cfif ldapDS['secure'] EQ 1 OR ldapDS['secure'] EQ "True">
				<cfldap
				    server="#ldapDS['server']#"
				    action="QUERY"
				    name="lqry"
				    start="#ldap_start#"
				    attributes="cn,name,dn,samAccountName,memberOf"
				    filter="#ldap_filter#"
				    scope="SUBTREE"
				    port="#ldapDS['port']#"
				    username="#ldapDS['userDN']#"
				    password="#ldapDS['userPas']#"
				    secure="CFSSL_BASIC"
				>
			<cfelse>
				<cfldap
				    server="#ldapDS['server']#"
				    action="QUERY"
				    name="lqry"
				    start="#ldap_start#"
				    attributes="cn,name,dn,samAccountName,memberOf"
				    filter="#ldap_filter#"
				    scope="SUBTREE"
				    port="#ldapDS['port']#"
				    username="#ldapDS['userDN']#"
				    password="#ldapDS['userPas']#"
				>
			</cfif>

			<cfloop query="lqry">
				<cfset cid = containsClient(samAccountName) />
				<cfif cid EQ "NA">
					<cfcontinue>
				<cfelse>
					<cfif cid EQ arguments.ClientID>
						<cfreturn true>
						<cfbreak>					
					</cfif>
				</cfif>
			</cfloop>

			<cfreturn false>

			<cfcatch type="any">
				<cflog file="ldapFilter" type="ERR" THREAD="no" application="no" text="#cfcatch.message# #cfcatch.detail#">
				<cfreturn false>
			</cfcatch>			
		</cftry>

		<cfreturn false>
	</cffunction>

	<cffunction name="containsClient" access="private">
		<cfargument name="name" required=true/>
		
		<cfquery datasource="#this.ds#" name="qGet">
			Select cuuid, mpa_distinguishedName from mpi_DirectoryServices
			Where mpa_AD_Kerberos_ID like "#arguments.name#%"
			OR mpa_cn like "#arguments.name#%"
		</cfquery>

		<cfif qGet.recordcount EQ 1>
			<cfreturn qGet.cuuid>
		<cfelse>
			<cfreturn "NA">
		</cfif>
	</cffunction>

	<cffunction name="dataSourceConfig" access="private">
		<cfargument name="DataSourceName" required=true/>

		<cfif Len(this.ldapDSArray) LTE 0>
			<cfreturn "NA">
		</cfif>

		<cfloop array="this.ldapDSArray" index="item">
			<cfif FindNoCase(item['config_name'],arguments.DataSourceName) GTE 1>
				<cfreturn item['config_ldap']>
			</cfif>
		</cfloop>
		
		<cfreturn "NA">
	</cffunction>

</cfcomponent>