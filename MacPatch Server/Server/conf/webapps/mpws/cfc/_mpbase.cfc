<cfcomponent displayname="mpbase">
	
	<cfset this.ds = "mpds">
	<cfset this.sqlregex = "(SELECT\s[\w\*\)\(\,\s]+\sFROM\s[\w]+)|(UPDATE\s[\w]+\sSET\s[\w\,\'\=]+)|(INSERT\sINTO\s[\d\w]+[\s\w\d\)\(\,]*\sVALUES\s\([\d\w\'\,\)]+)|(DELETE\sFROM\s[\d\w\'\=]+)|(DROP\sTABLE\s[\d\w\'\=]+)">
	
	<cffunction name="init" access="public" output="no" returntype="mpbase">
		<cfreturn this>
	</cffunction>

    <cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">

        <cfscript>
			try {
				inet = CreateObject("java", "java.net.InetAddress");
				inet = inet.getLocalHost();
			} catch (any e) {
				inet = "localhost";
			}
		</cfscript>

    	<cfquery datasource="#this.ds#" name="qGet">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
    </cffunction>

    <cffunction name="elogit" access="public" returntype="void" output="no">
        <cfargument name="aEvent">
        
        <cfset l = logit("Error",arguments.aEvent)>
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
		
		<cfif isSimpleValue(arguments.aField) AND refindnocase(this.sqlregex,arguments.aField)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Field (#arguments.aField#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<cfif isSimpleValue(arguments.aTable) AND refindnocase(this.sqlregex,arguments.aTable)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table (#arguments.aTable#) is not valid.">
			<cfreturn _res> 
		</cfif>
		<cftry>
			<cfquery name="qGet" datasource="#this.ds#">
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
		
		<cfquery name="qGet" datasource="#this.ds#">
			Select rhash from #arguments.aTbl#
			Where #arguments.aKCol# = <cfqueryparam value="#arguments.aKVal#"> 
		</cfquery>
		
		<cfif qGet.RecordCount EQ 0>
			<cfreturn false>
		<cfelseif qGet.RecordCount EQ 1>
			<cfif Trim(qGet.rhash) EQ Trim(dataHash)>
				<!--- Hash Matches, no update --->
                <cfquery name="qUpdate" datasource="#this.ds#">
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
		
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(this.sqlregex,arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<cfquery name="qGet" datasource="#this.ds#" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
			Select rid, rhash from #arguments.aTbl#
			Where #arguments.aCol# = <cfqueryparam value="#arguments.aVal#"> 
		</cfquery>
		
		<cfset _res.qresult = qGet>
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
		
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(this.sqlregex, arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<cfloop array="#arguments.aCols#" index="i">
			<cfif isSimpleValue(i) AND refindnocase(this.sqlregex,i)>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Column (#i#) is not valid. Row insert will not occure.">
				<cfreturn _res>
			</cfif>
		</cfloop>
		<cftry>
			<cfset var dataHash = #hash(ArrayToList(arguments.aVals,","),'SHA1')#>
			<cfquery name="qInsert" datasource="#this.ds#" result="qRes">
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
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(this.sqlregex,arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		<!--- Argument Validations, dont want to allow SQL injections. --->
		<cfif isSimpleValue(arguments.aKCol) AND refindnocase(this.sqlregex,arguments.aKCol)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Column (#arguments.aKCol#) is not valid.">
			<cfreturn _res> 
		</cfif>
		<!--- Argument Validations, dont want to allow SQL injections. --->
		<cfloop array="#arguments.aCols#" index="i">
			<cfif isSimpleValue(i) AND refindnocase(this.sqlregex,i)>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Column (#i#) is not valid. Row insert will not occure.">
				<cfreturn _res>
			</cfif>
		</cfloop>
		
		<cfset var dataHash = "NA">
		<cfset hasRHash = fieldExists("rhash",arguments.aTbl)>
		<cfif hasRHash.result EQ true>
			<cfset hashMatches = checkRowHash(arguments.aVals,arguments.aKCol,arguments.aKVal,arguments.aTbl)>
			<cfif hashMatches EQ true>
				<!--- Data is the same no need to update record --->
				<cfdump var="No update needed, data is identical.">
				<cfreturn _res>	
			</cfif>
			<cfset dataHash = #hash(ArrayToList(arguments.aVals,","),'SHA1')#>
		</cfif>
		
		<cftry>
			<cfquery name="qUpdate" datasource="#this.ds#" result="qRes">
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
			<cfquery name="qGetFields" datasource="#this.ds#" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
				SHOW COLUMNS FROM #arguments.aTbl#
			</cfquery>	
		<cfcatch>
				<cfset <cfset lg = logit("Error, #cfcatch.message#")>
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
			<cfquery name="qGet" datasource="#this.ds#">
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
				<cfset <cfset lg = logit("Error, #cfcatch#")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "#cfcatch#">
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>
</cfcomponent>