<cfcomponent displayname="mpbase">
	
	<cfparam name="mpDBSource" default="mpds">
	<cfparam name="sqlregex" default="(SELECT\s[\w\*\)\(\,\s]+\sFROM\s[\w]+)|(UPDATE\s[\w]+\sSET\s[\w\,\'\=]+)|(INSERT\sINTO\s[\d\w]+[\s\w\d\)\(\,]*\sVALUES\s\([\d\w\'\,\)]+)|(DELETE\sFROM\s[\d\w\'\=]+)|(DROP\sTABLE\s[\d\w\'\=]+)">
	
	<cffunction name="init" access="public" output="no" returntype="mpbase">
		<cfreturn this>
	</cffunction>
	
	<cffunction name="logger" access="public" returntype="void" output="no">
		<cfargument name="aEventType">
		<cfargument name="aEvent">
		<cfscript>
			try {
				inet = CreateObject("java", "java.net.InetAddress");
				inet = inet.getLocalHost();
			} catch (any e) {
				inet = "localhost";
			}
		</cfscript>
		<cflog file="MPWSController" type="#arguments.aEventType#" application="no" text="[#inet#]: #arguments.aEvent#">
	</cffunction>
	
	<cffunction name="ilog" access="public" returntype="void" output="no">
		<cfargument name="aEvent">
		<cfif IsSimpleValue(arguments.aEvent)>
			<cfset logger("Information",arguments.aEvent)>
		</cfif>
	</cffunction>
	
	<cffunction name="elog" access="public" returntype="void" output="no">
		<cfargument name="aEvent">
		<cfif IsSimpleValue(arguments.aEvent)>
			<cfset logger("Error",arguments.aEvent)>
		</cfif>
	</cffunction>

	<cffunction name="genRow" access="public" returntype="struct" output="no">
		<cfargument name="aCols" type="Array">
		<cfargument name="aData" type="Array">
		
		<cfset var row = StructNew()>
		<cfif ArrayLen(arguments.aCols) EQ ArrayLen(arguments.aData)>
			<cfloop from="1" to="#ArrayLen(arguments.aCols)#" index="i">
				<cfset row[arguments.aCols[i]] = arguments.aData[i]>
			</cfloop>
		</cfif>
		
		<cfreturn row>
	</cffunction>
	
	<cffunction name="fieldExists" access="public" returntype="any" output="no">
		<cfargument name="aField">
		<cfargument name="aTable">
		
		<cfset var _res = Structnew()>
		<cfset _res.error = "0">
		<cfset _res.errorMessage = "">
		<cfset _res.result = false>
		
		<cfif isSimpleValue(arguments.aField) AND refindnocase(sqlregex,arguments.aField)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Field (#arguments.aField#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<cfif isSimpleValue(arguments.aTable) AND refindnocase(sqlregex,arguments.aTable)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table (#arguments.aTable#) is not valid.">
			<cfreturn _res> 
		</cfif>
		<cftry>
			<cfquery name="qGet" datasource="#mpDBSource#">
				SHOW COLUMNS FROM #arguments.aTable# Where Field = '#arguments.aField#'
			</cfquery>	
			<cfcatch>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Table (#arguments.aTable#) is not valid.">
				<cfreturn _res> 
			</cfcatch>
		</cftry>		
		
		<cfif qGet.RecordCount EQ 1>
			<cfset _res.result = true>	
		</cfif>	
		
		<cfreturn _res>
	</cffunction>

	<cffunction name="checkRowHash" access="public" returntype="any" output="no">
		<cfargument name="aData" type="Array">
		<cfargument name="aKCol">
		<cfargument name="aKVal">
		<cfargument name="aTbl">
		
		<cfset var dataHash = #hash(ArrayToList(arguments.aData,","),'SHA1')#>
		
		<cfquery name="qGet" datasource="#mpDBSource#">
			Select rhash from #arguments.aTbl#
			Where #arguments.aKCol# = <cfqueryparam value="#arguments.aKVal#"> 
		</cfquery>
		
		<cfif qGet.RecordCount EQ 0>
			<cfreturn false>
		<cfelseif qGet.RecordCount EQ 1>
			<cfif Trim(qGet.rhash) EQ Trim(dataHash)>
				<!--- Hash Matches, no update --->
                <cfquery name="qUpdate" datasource="#mpDBSource#">
                	UPDATE #arguments.aTbl#
                    Set rhash = <cfqueryparam value="#dataHash#">
                    WHERE #arguments.aKCol# = '#arguments.aKVal#'
                </cfquery>
				<cfreturn true>
			<cfelse>
				<cfreturn false>
			</cfif>
		<cfelse>
			<!--- Might be a bigger issue if we get here. --->
			<cfreturn false>
		</cfif>		
	
	</cffunction>
	
	<cffunction name="colExists" access="public" returntype="any" output="no">
		<cfargument name="aCol">
		<cfargument name="aVal">
		<cfargument name="aTbl">
		
		<cfset var _res = Structnew()>
		<cfset _res.error = "0">
		<cfset _res.errorMessage = "">
		<cfset _res.qresult = QueryNew("")>
		
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(sqlregex,arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<cfquery name="qGet" datasource="#mpDBSource#">
			Select rid, rhash from #arguments.aTbl#
			Where #arguments.aCol# = <cfqueryparam value="#arguments.aVal#"> 
		</cfquery>
		<cfdump var="#qGet#">
		<cfset _res.qresult = qGet>
		
		<cfdump var="#_res.qresult#">
		<cfdump var="#_res.qresult.rid#">
		<cfreturn _res>
	</cffunction>
	
	<cffunction name="rowInsert" access="public" returntype="any" output="no">
		<cfargument name="aCols" type="array">
		<cfargument name="aVals" type="array">
		<cfargument name="aTbl">
		
		<cfset var _res = Structnew()>
		<cfset _res.error = "0">
		<cfset _res.errorMessage = "">
		<cfset _res.qresult = QueryNew("rid")>
		
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(sqlregex, arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<cfloop array="#arguments.aCols#" index="i">
			<cfif isSimpleValue(i) AND refindnocase(sqlregex,i)>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Column (#i#) is not valid. Row insert will not occure.">
				<cfreturn _res>
			</cfif>
		</cfloop>
		<cftry>
			<cfset var dataHash = #hash(ArrayToList(arguments.aVals,","),'SHA1')#>
			<cfquery name="qInsert" datasource="#mpDBSource#" result="qRes">
				INSERT INTO #arguments.aTbl# ( rhash,#ArrayToList(arguments.aCols,",")# )
				Values (
				<cfqueryparam value="#dataHash#">
				,<cfqueryparam value="#arguments.aVals[1]#">
				<cfif #Arraylen(aVals)# GTE 2>
				<cfloop from="2" to="#Arraylen(arguments.aVals)#" index="v">
				,<cfqueryparam value="#arguments.aVals[v]#">
				</cfloop>
				</cfif>
				)
			</cfquery>
		<cfcatch>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Inserting data, #cfcatch.message# #cfcatch.detail#">
				<cfreturn _res>
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>

	<cffunction name="rowUpdate" access="public" returntype="any" output="yes">
		<cfargument name="aCols" type="array">
		<cfargument name="aVals" type="array">
		<cfargument name="aKCol">
		<cfargument name="aKVal">
		<cfargument name="aTbl">
		
		<cfset var _res = Structnew()>
		<cfset _res.error = "0">
		<cfset _res.errorMessage = "">
		<cfset _res.qresult = QueryNew("")>
		
		<!--- Argument Validations, dont want to allow SQL injections. --->
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(sqlregex,arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		<!--- Argument Validations, dont want to allow SQL injections. --->
		<cfif isSimpleValue(arguments.aKCol) AND refindnocase(sqlregex,arguments.aKCol)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Column (#arguments.aKCol#) is not valid.">
			<cfreturn _res> 
		</cfif>
		<!--- Argument Validations, dont want to allow SQL injections. --->
		<cfloop array="#arguments.aCols#" index="i">
			<cfif isSimpleValue(i) AND refindnocase(sqlregex,i)>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Column (#i#) is not valid. Row insert will not occure.">
				<cfreturn _res>
			</cfif>
		</cfloop>
		
		<cfset var dataHash = "NA">
		<cfset hasRHash = fieldExists("rhash",arguments.aTbl)>
		<cfif hasRHash.result EQ true>
			<cfset il = iLog("hasRHash.result EQ true")>
			<cfset hashMatches = checkRowHash(arguments.aVals,arguments.aKCol,arguments.aKVal,arguments.aTbl)>
			<cfset il = iLog("hashMatches = #hashMatches#")>
			<cfif hashMatches EQ true>
				<!--- Data is the same no need to update record --->
				<cfdump var="No update needed, data is identical.">
				<cfreturn _res>	
			</cfif>
			<cfset dataHash = #hash(ArrayToList(arguments.aVals,","),'SHA1')#>
			<cfset il = iLog("dataHash = #dataHash#")>
		</cfif>
		
		<cftry>
			<cfquery name="qUpdate" datasource="#mpDBSource#" result="qRes">
				UPDATE #arguments.aTbl#
				SET 
				<cfif hasRHash.result EQ true>
				rhash=<cfqueryparam value="#dataHash#">,
				</cfif>
				#arguments.aCols[1]#=<cfqueryparam value="#arguments.aVals[1]#">
				<cfif #Arraylen(aVals)# GTE 2>
				<cfloop from="2" to="#Arraylen(arguments.aCols)#" index="c">
				,#arguments.aCols[c]#=<cfqueryparam value="#arguments.aVals[c]#">
				</cfloop>
				</cfif>
				WHERE #arguments.aKCol# = '#arguments.aKVal#'
			</cfquery>
		<cfcatch>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Updating data, #cfcatch.message# #cfcatch.detail#">
				<cfreturn _res>
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>
	
	<cffunction name="verifyTable" access="public" returntype="any" output="yes">
		<cfargument name="aTbl">
		<cfargument name="aCols" type="array">
		
		<cfset var _res = Structnew()>
		<cfset _res.errorCode = "0">
		<cfset _res.errorMessage = "">
		
		<cftry>
			<cfquery name="qGetFields" datasource="#mpDBSource#">
				SHOW COLUMNS FROM #arguments.aTbl#
			</cfquery>	
		<cfcatch>
				<cfset elog("Error, #cfcatch.message#")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "#cfcatch.message#">
				<cfreturn _res>
		</cfcatch>
		</cftry>
		
		<cfset var _colsNeeded = ArrayNew(1)>
		<cfset var FieldsList = ValueList(qGetFields.Field,",")>
		<cfset var _curCols = ArrayToList(arguments.aCols,",")>
		
		<cfloop list="#_curCols#" index="l_Col" delimiters = ",">
			<cfif ListContainsNoCase(FieldsList,l_Col,",") EQ 0>
				<cfset tmp = #ArrayAppend(_colsNeeded,l_Col)#>
			</cfif>
		</cfloop>
		
		<cfif ArrayLen(_colsNeeded) GTE 1>
			<cfset alterTableResult = #alterTable(arguments.aTbl,_colsNeeded)#>
			<cfset _res = alterTableResult>
		</cfif>
	
		<cfreturn _res>
	</cffunction>

	<cffunction name="alterTable" access="public" returntype="any" output="yes">
		<cfargument name="aTbl">
		<cfargument name="aCols" type="array">
		
		<cfset var _res = Structnew()>
		<cfset _res.errorCode = "0">
		<cfset _res.errorMessage = "">
		
		<cftry>
			<!------>
			<cfquery name="qGet" datasource="#mpDBSource#">
				ALTER TABLE #arguments.aTbl#
				<cfloop from="1" to="#arraylen(arguments.aCols)#" index="a">
						<cfif #arguments.aCols[a]# NEQ "rid" OR #arguments.aCols[a]# NEQ "mdate" OR #arguments.aCols[a]# NEQ "cdate" OR #arguments.aCols[a]# NEQ "rhash" OR #arguments.aCols[a]# NEQ "cuuid">
						<cfif a EQ 1>	
							ADD COLUMN `#arguments.aCols[a]#` varchar(255) DEFAULT 'NA'
						<cfelse>
							,ADD COLUMN `#arguments.aCols[a]#` varchar(255) DEFAULT 'NA'
						</cfif>
					</cfif>
				</cfloop>
			</cfquery>
		<cfcatch>
				<cfset elog("Error, #cfcatch#")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "#cfcatch#">
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>
</cfcomponent>