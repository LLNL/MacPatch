<cfcomponent>
<cffunction name="getCF8QueryAttributes" access="public" returntype="struct" output="no">
	
	<cfset var sQuery = StructNew()>
	
	<cfset sQuery["name"] = "qQuery">
	<cfset sQuery["datasource"] = variables.datasource>
	<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
		<cfset sQuery["username"] = variables.username>
		<cfset sQuery["password"] = variables.password>
	</cfif>
	<cfif variables.SmartCache>
		<cfset sQuery["cachedafter"] = "#variables.CacheDate#">
	</cfif>
	
	<cfreturn sQuery>
</cffunction>

<cffunction name="getDataBase" access="public" returntype="string" output="false" hint="I return the database platform being used.">
	
	<cfscript>
	var sDBInfo = 0;
	var db = "";
	var type = "";
	</cfscript>
	
	<cfif Len(variables.datasource)>
		<cfdbinfo datasource="#variables.datasource#" name="sDBInfo" type="Version"  />
		<cfscript>
		db = sDBInfo.DATABASE_PRODUCTNAME;
		
		switch(db) {
			case "Microsoft SQL Server":
				type = "MSSQL";
			break;
	
			case "MySQL":
				type = "MYSQL";
			break;
	
			case "PostgreSQL":
				type = "PostGreSQL";
			break;
	
			case "Oracle":
				type = "Oracle";
			break;
			
			case "MS Jet":
				type = "Access";
			break;
			
			case "Apache Derby":
				type = "Derby";
			break;
			
			default:
				type = "unknown";
				type = db;
			break;
		}
		</cfscript>
	<cfelse>
		<cfset type="Sim">
	</cfif>
	
	<cfreturn type>
</cffunction>

<cffunction name="runSQL" access="public" returntype="any" output="no" hint="I run the given SQL.">
	<cfargument name="sql" type="string" required="yes">
	
	<cfset var qQuery = 0>
	<cfset var thisSQL = "">
	
	<cfif Len(arguments.sql)>
		<cfquery attributeCollection="#getCF8QueryAttributes()#">#Trim(DMPreserveSingleQuotes(arguments.sql))#</cfquery>
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
			<cfquery attributeCollection="#getCF8QueryAttributes()#"><cfloop index="ii" from="1" to="#ArrayLen(aSQL)#" step="1"><cfif IsSimpleValue(aSQL[ii])><cfset temp = aSQL[ii]>#Trim(DMPreserveSingleQuotes(temp))#<cfelseif IsStruct(aSQL[ii])><cfset aSQL[ii] = queryparam(argumentCollection=aSQL[ii])><cfswitch expression="#aSQL[ii].cfsqltype#"><cfcase value="CF_SQL_BIT">#getBooleanSqlValue(aSQL[ii].value)#</cfcase><cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">#CreateODBCDateTime(aSQL[ii].value)#</cfcase><cfdefaultcase><!--- <cfif ListFindNoCase(variables.dectypes,aSQL[ii].cfsqltype)>#Val(aSQL[ii].value)#<cfelse> ---><cfqueryparam value="#aSQL[ii].value#" cfsqltype="#aSQL[ii].cfsqltype#" maxlength="#aSQL[ii].maxlength#" scale="#aSQL[ii].scale#" null="#aSQL[ii].null#" list="#aSQL[ii].list#" separator="#aSQL[ii].separator#"><!--- </cfif> ---></cfdefaultcase></cfswitch></cfif> </cfloop></cfquery>
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