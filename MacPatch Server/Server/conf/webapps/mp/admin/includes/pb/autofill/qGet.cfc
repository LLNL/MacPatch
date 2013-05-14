<cfcomponent>
	<cffunction name="getData" access="public" returntype="query">
    	<cfargument name="query" required="yes" type="string">       	
		<cfquery name="qFindStuff" datasource="#session.dbsource#">
			SELECT Distinct bundle_id AS bundle_id
			FROM mp_patches
			WHERE bundle_id LIKE <cfqueryparam value="#arguments.query#%" cfsqltype="cf_sql_varchar" />
		</cfquery>
		<cfreturn qFindStuff>
	</cffunction>
</cfcomponent>