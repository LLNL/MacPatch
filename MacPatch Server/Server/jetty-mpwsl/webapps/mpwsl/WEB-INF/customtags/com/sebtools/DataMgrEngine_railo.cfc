<cfcomponent>
<cffunction name="getRailoQueryAttributes" access="public" returntype="struct" output="no">
	<cfset var sRailoQuery = StructNew()>
	
	<cfset sRailoQuery["name"] = "qQuery">
	<cfset sRailoQuery["datasource"] = variables.datasource>
	<cfset sRailoQuery["psq"] = "true">
	<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
		<cfset sRailoQuery["username"] = variables.username>
		<cfset sRailoQuery["password"] = variables.password>
	</cfif>
	<cfif variables.SmartCache>
		<cfset sRailoQuery["cachedafter"] = "#variables.CacheDate#">
	</cfif>
	
	<cfreturn sRailoQuery>
</cffunction>

<cffunction name="runSQL" access="public" returntype="any" output="no" hint="I run the given SQL.">
	<cfargument name="sql" type="string" required="yes">
	
	<cfset var qQuery = 0>
	<cfset var thisSQL = "">
	
	<cfif Len(arguments.sql)>
		<cfquery attributeCollection="#getRailoQueryAttributes()#">#Trim(arguments.sql)#</cfquery>
	</cfif>
	
	<cfif IsDefined("qQuery") AND isQuery(qQuery)>
		<cfreturn qQuery>
	</cfif>
	
</cffunction>

<cffunction name="runSQLArray" access="public" returntype="any" output="no" hint="I run the given array representing SQL code (structures in the array represent params).">
	<cfargument name="sqlarray" type="array" required="yes">
	
	<cfset var qQuery = 0>
	<cfset var ii = 0>
	<cfset var temp = "">
	<cfset var aSQL = cleanSQLArray(arguments.sqlarray)>
	
	<cftry>
		<cfif ArrayLen(aSQL)>
			<cfquery attributeCollection="#getRailoQueryAttributes()#"><cfloop index="i" from="1" to="#ArrayLen(aSQL)#" step="1"><cfif IsSimpleValue(aSQL[i])><cfset temp = aSQL[i]>#Trim(temp)#<cfelseif IsStruct(aSQL[i])><cfset aSQL[i] = queryparam(argumentCollection=aSQL[i])><cfswitch expression="#aSQL[i].cfsqltype#"><cfcase value="CF_SQL_BIT">#getBooleanSqlValue(aSQL[i].value)#</cfcase><cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">#CreateODBCDateTime(aSQL[i].value)#</cfcase><cfdefaultcase><!--- <cfif ListFindNoCase(variables.dectypes,aSQL[i].cfsqltype)>#Val(aSQL[i].value)#<cfelse> ---><cfqueryparam value="#aSQL[i].value#" cfsqltype="#aSQL[i].cfsqltype#" maxlength="#aSQL[i].maxlength#" scale="#aSQL[i].scale#" null="#aSQL[i].null#" list="#aSQL[i].list#" separator="#aSQL[i].separator#"><!--- </cfif> ---></cfdefaultcase></cfswitch></cfif> </cfloop></cfquery>
		</cfif>
	<cfcatch>
		<cfthrow message="#CFCATCH.Message#" detail="#CFCATCH.detail#" extendedinfo="#readableSQL(aSQL)#">
	</cfcatch>
	</cftry>
	
	<cfif IsDefined("qQuery") AND isQuery(qQuery)>
		<cfreturn qQuery>
	</cfif>
	
</cffunction>

</cfcomponent>