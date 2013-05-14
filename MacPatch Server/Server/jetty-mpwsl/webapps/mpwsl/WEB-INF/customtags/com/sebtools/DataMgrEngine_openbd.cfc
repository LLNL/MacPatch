<cfcomponent>

<cffunction name="runSQL" access="public" returntype="any" output="no" hint="I run the given SQL.">
	<cfargument name="sql" type="string" required="yes">
	
	<cfset var qQuery = 0>
	<cfset var thisSQL = "">
	
	<cfif Len(arguments.sql)>
		<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
			<cfquery name="qQuery" datasource="#variables.datasource#" preservesinglequotes="true" username="#variables.username#" password="#variables.password#">#Trim(arguments.sql)#</cfquery>
		<cfelse>
			<cfquery name="qQuery" datasource="#variables.datasource#" preservesinglequotes="true">#Trim(arguments.sql)#</cfquery>
		</cfif>
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
			<cfif StructKeyExists(variables,"username") AND StructKeyExists(variables,"password")>
				<cfquery name="qQuery" datasource="#variables.datasource#" preservesinglequotes="true" username="#variables.username#" password="#variables.password#" result="res1">
                <cfloop index="i" from="1" to="#ArrayLen(aSQL)#" step="1">
					<cfif IsSimpleValue(aSQL[i])>
						<cfset temp = Trim(aSQL[i])> #temp#
					<cfelseif IsStruct(aSQL[i])>
						<cfset aSQL[i] = queryparam(argumentCollection=aSQL[i])>
                        <cfswitch expression="#aSQL[i].cfsqltype#">
                        	<cfcase value="CF_SQL_BIT">#getBooleanSqlValue(aSQL[i].value)#</cfcase>
                            <cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">#CreateODBCDateTime(aSQL[i].value)#</cfcase>
                            <cfdefaultcase>
							<!--- <cfif ListFindNoCase(variables.dectypes,aSQL[i].cfsqltype)>#Val(aSQL[i].value)#<cfelse> --->
                            <cfqueryparam value="#aSQL[i].value#" cfsqltype="#aSQL[i].cfsqltype#" maxlength="#aSQL[i].maxlength#" scale="#aSQL[i].scale#" list="#aSQL[i].list#" separator="#aSQL[i].separator#"><!--- '#aSQL[i].value#' ---><!--- </cfif> --->
                            </cfdefaultcase>
                        </cfswitch>
                    </cfif>
                </cfloop>
                </cfquery>
			<cfelse>
				<cfquery name="qQuery" datasource="#variables.datasource#" preservesinglequotes="false" result="res2">
                	<cfloop index="i" from="1" to="#ArrayLen(aSQL)#" step="1">
					<cfif IsSimpleValue(aSQL[i])>
						<cfset temp = Trim(aSQL[i])> #temp#
					<cfelseif IsStruct(aSQL[i])>
						<cfset aSQL[i] = queryparam(argumentCollection=aSQL[i])>
                        <cfswitch expression="#aSQL[i].cfsqltype#">
                        	<cfcase value="CF_SQL_BIT">#getBooleanSqlValue(aSQL[i].value)#</cfcase>
                            <cfcase value="CF_SQL_DATE,CF_SQL_DATETIME">#CreateODBCDateTime(aSQL[i].value)#</cfcase>
                            <cfdefaultcase>
                            <cfqueryparam value="#aSQL[i].value#" cfsqltype="#aSQL[i].cfsqltype#" maxlength="#aSQL[i].maxlength#" scale="#aSQL[i].scale#" list="#aSQL[i].list#" separator="#aSQL[i].separator#"><!--- '#aSQL[i].value#' --->
                            </cfdefaultcase>
                        </cfswitch>
                    </cfif>
                  	</cfloop>
                </cfquery>
			</cfif>
		</cfif>
	<cfcatch type="any">
		<cfthrow message="#CFCATCH.Message#" detail="#CFCATCH.detail#" extendedinfo="#readableSQL(aSQL)#">
	</cfcatch>
	</cftry>
	
	<cfif IsDefined("qQuery") AND isQuery(qQuery)>
		<cfreturn qQuery>
	</cfif>
	
</cffunction>

</cfcomponent>