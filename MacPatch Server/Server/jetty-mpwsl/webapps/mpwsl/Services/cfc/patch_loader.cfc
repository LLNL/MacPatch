<cfcomponent name="client_checkin" extends="_mpbase">
	
	<cfparam name="mainTable" default="apple_patches_real">
	<cfparam name="mainTableHst" default="apple_patches_real_hst">
	<cfparam name="mainTableAlt" default="apple_patches">

	<cffunction name="_apple" access="public" returntype="any" output="no">
		<cfargument name="data" hint="Encoded Data">
		<cfargument name="type" hint="Encodign Type">
		
		<cfset var l_data = "">
		<cfset var l_result = "0">
		<cfset ilog("#arguments.type#: #arguments.data#")>
		
		<cfset var _res = StructNew()>
		<cfset _res.errorCode = "0">
		<cfset _res.errorMessage = "">
		<cfset _res.result = true>
		
		<cfif arguments.type EQ "JSON">
			<cfif isJson(arguments.data) EQ false>
				<!--- Log issue --->
				<cfset elog("Not JSON Data.")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "Not JSON Data.">
				<cfset _res.result = false>
				<cfreturn _res>	
			</cfif>			
			<cfset l_data = Deserializejson(arguments.data,"false")>
			
			<cfset xOS = l_data['OS']>
			<cfset xCols = #mapColumns(l_data['COLUMNS'])#>
			<cfset xData = l_data['DATA']>
			
			<!--- Check for valid lengths --->
			<cfif ArrayLen(xCols) EQ 0>
				<cfset elog("No columns defined, length = 0.")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "No columns defined, length = 0.">
				<cfset _res.result = false>
				<cfreturn _res>	
			</cfif>
			<cfif ArrayLen(xData) EQ 0>
				<cfset elog("No data defined, length = 0.")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "No data defined, length = 0.">
				<cfset _res.result = false>
				<cfreturn _res>
			</cfif>
			
			<cfset _copyRequest = copyToHistory(xOS)>
			<cfif _copyRequest.errorCode NEQ "0">
				<cfset elog("Error[#_copyRequest.errorCode#]: #_copyRequest.errorMessage#")>
				<cfreturn _copyRequest>
			</cfif>	
			
			<cfset _delRequest = deleteFromTable(xOS)>
			<cfif _delRequest.errorCode NEQ "0">
				<cfset elog("Error[#_delRequest.errorCode#]: #_delRequest.errorMessage#")>
				<cfreturn _delRequest>
			</cfif>	
			
			<cfloop array="#l_data['DATA']#" index="iArr">
				<cfif ArrayLen(iArr) EQ ArrayLen(xCols)>
					<cfset l_row = #genRow(xCols,iArr)#>
					
					<cfset _ires = rowInsert(xCols,iArr,mainTable)>
					<cfset ilog("Insert record for #l_row.akey#. Result[#_ires.error#]: #_ires.errorMessage#")>
					<cfif #_ires.error# NEQ "0">
						<cfset l_result = #l_result# + 1>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		
		<cfif l_result GT 0>
			<cfset _res.result = false>
		</cfif>
		<cfreturn _res>
	</cffunction>	
	
	<cffunction name="mapColumns" access="private" returntype="any" output="no">
		<cfargument name="jsonCols">
		
		<cfset _colsNew = ArrayNew(1)>
		<cfloop array="#arguments.jsonCols#" index="col">
			<cfif col EQ "postdate">
				<cfset arrTmp = ArrayAppend(_colsNew,"postdate")>
			</cfif>
			<cfif col EQ "akey">
				<cfset arrTmp = ArrayAppend(_colsNew,"akey")>
			</cfif>
			<cfif col EQ "CFBundleShortVersionString">
				<cfset arrTmp = ArrayAppend(_colsNew,"version")>
			</cfif>
			<cfif col EQ "IFPkgFlagRestartAction">
				<cfset arrTmp = ArrayAppend(_colsNew,"restartaction")>
			</cfif>
			<cfif col EQ "title">
				<cfset arrTmp = ArrayAppend(_colsNew,"title")>
			</cfif>
			<cfif col EQ "supatchname">
				<cfset arrTmp = ArrayAppend(_colsNew,"supatchname")>
			</cfif>
			<cfif col EQ "description">
				<cfset arrTmp = ArrayAppend(_colsNew,"description64")>
			</cfif>
			<cfif col EQ "patchname">
				<cfset arrTmp = ArrayAppend(_colsNew,"patchname")>
			</cfif>
			<cfif col EQ "osver">
				<cfset arrTmp = ArrayAppend(_colsNew,"osver_support")>
			</cfif>
		</cfloop>
		
		<cfreturn _colsNew>
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
			<cfquery name="qInsert" datasource="#mpDBSource#" result="qRes">
				INSERT INTO #arguments.aTbl# ( #ArrayToList(arguments.aCols,",")# )
				Values (
				<cfqueryparam value="#arguments.aVals[1]#">
				<cfif #Arraylen(aVals)# GTE 2>
				<cfloop from="2" to="#Arraylen(arguments.aVals)#" index="v">
				,<cfqueryparam value="#arguments.aVals[v]#">
				</cfloop>
				</cfif>
				)
			</cfquery>
			
			<cfset _theKey = ArrayFindnocase(arguments.aCols,"akey")>
            <cfset _thePName = ArrayFindnocase(arguments.aCols,"patchname")>
            <cfset _theSUPName = ArrayFindnocase(arguments.aCols,"supatchname")>
            <cfset _theVersion = ArrayFindnocase(arguments.aCols,"version")>
			<cfset _theOSIdx = ArrayFindnocase(arguments.aCols,"osver_support")>
			<cfset var x_theColsArray = arguments.aCols>
			<cfset var x_theValsArray = arguments.aVals>
			
			<cfif _theOSIdx NEQ 0>
				<cfset _arrDel = ArrayDeleteAt(x_theColsArray,_theOSIdx)>
				<cfset _arrDel = ArrayDeleteAt(x_theValsArray,_theOSIdx)>
			</cfif>
			
			<cfif _theKey NEQ 0>
				<cfset _theKeyVal = arguments.aVals[_theKey]>
                <cfset _thePNameVal = arguments.aVals[_thePName]>
                <cfset _theSUPNameVal = arguments.aVals[_theSUPName]>
                <cfset _theVersionVal = arguments.aVals[_theVersion]>
				<cfif existsInAltTable(_theKeyVal) EQ False>
					<cfquery name="qInsertAlt" datasource="#mpDBSource#" result="qResAlt">
						INSERT INTO #mainTableAlt# ( #ArrayToList(x_theColsArray,",")# )
						Values (
						<cfqueryparam value="#x_theValsArray[1]#">
						<cfif #Arraylen(x_theValsArray)# GTE 2>
						<cfloop from="2" to="#Arraylen(x_theValsArray)#" index="v">
						,<cfqueryparam value="#x_theValsArray[v]#">
						</cfloop>
						</cfif>
						)
					</cfquery>
				<cfelse>
                	<cfif isSameInAltTable(_theKeyVal,_thePNameVal,_theSUPNameVal,_theVersionVal) EQ False>
                		<cfquery name="qUpdateAlt" datasource="#mpDBSource#" result="qResAlt">
                            UPDATE #mainTableAlt#
                            SET patchname = <cfqueryparam value="#_thePNameVal#">,
                            supatchname = <cfqueryparam value="#_theSUPNameVal#">,
                            version = <cfqueryparam value="#_theVersionVal#">
                            Where akey = <cfqueryparam value="#_theKeyVal#">
                        </cfquery>	
                
                	</cfif>
					<cfset _res.error = "1">
					<cfset _res.errorMessage = "Error: _theKeyVal was True">
					<cfreturn _res>		
				</cfif>
			<cfelse>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Inserting data, akey not found in columns.">
				<cfreturn _res>	
			</cfif>
			
		<cfcatch>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Inserting data, #cfcatch.message# #cfcatch.detail#">
				<cfreturn _res>
		</cfcatch>
		</cftry>

		<cfreturn _res>
	</cffunction>
	
	<cffunction name="copyToHistory" access="private" returntype="any" output="no">
		<cfargument name="osver">
		
		<cfset var _res = StructNew()>
		<cfset _res.errorCode = "0">
		<cfset _res.errorMessage = "[copyToHistory]">
		<cfset _res.result = true>
		
		<cftry>
		<cfquery name="qCopyToHistory" datasource="#mpDBSource#">
			Select * from apple_patches_real Limit 1
		</cfquery>
		<cfset tblCols = #ArrayToList(qCopyToHistory.getColumnNames(),",")#>
		<cfset tblCols = ListDeleteAt(tblCols,ListContainsNoCase(tblCols,"rid"),",")>	
			
		<cfquery name="qCopyToHistory" datasource="#mpDBSource#">
			INSERT INTO #mainTableHst# (#tblCols#) (SELECT #tblCols# FROM #mainTable# Where osver_support = <cfqueryparam value="#arguments.osver#">)
		</cfquery>
		<cfcatch>
			<cfset elog("Error [qCopyToHistory]: #cfcatch.message#")>
			<cfset _res.errorCode = "1">
			<cfset _res.errorMessage = "[qCopyToHistory]: #cfcatch.message# #cfcatch.Detail#">
			<cfset _res.result = false>
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>
	
	<cffunction name="existsInAltTable" access="private" returntype="any" output="no">
		<cfargument name="theKey">

    	<cfquery datasource="#mpDBSource#" name="qGet" >
            Select akey
            From #mainTableAlt#
            Where akey = <cfqueryparam value="#arguments.theKey#">
        </cfquery>
		
        <cfif qGet.RecordCount EQ 0>
			<cfset elog("existsInAltTable was false for #arguments.theKey#")>
        	<cfreturn False>
        <cfelse>
			<cfset elog("existsInAltTable was true for #arguments.theKey#")>
        	<cfreturn True>
        </cfif>
	</cffunction>
    
    <cffunction name="isSameInAltTable" access="private" returntype="any" output="no">
		<cfargument name="theKey">
        <cfargument name="thePatchName">
        <cfargument name="theSUPatchName">
        <cfargument name="thePatchVersion">

    	<cfquery datasource="#mpDBSource#" name="qGet" >
            Select akey
            From #mainTableAlt#
            Where akey = <cfqueryparam value="#arguments.theKey#">
            AND patchname = <cfqueryparam value="#arguments.thePatchName#">
            AND supatchname = <cfqueryparam value="#arguments.theSUPatchName#">
            AND version = <cfqueryparam value="#arguments.thePatchVersion#">
        </cfquery>
		
        <cfif qGet.RecordCount EQ 0>
			<cfset elog("existsInAltTable was false for #arguments.theKey#")>
        	<cfreturn False>
        <cfelse>
			<cfset elog("existsInAltTable was true for #arguments.theKey#")>
        	<cfreturn True>
        </cfif>
	</cffunction>
	
	<cffunction name="deleteFromTable" access="private" returntype="any" output="no">
		<cfargument name="osver">
		
		<cfset var _res = StructNew()>
		<cfset _res.errorCode = "0">
		<cfset _res.errorMessage = "[deleteFromTable]">
		<cfset _res.result = true>
		
		<cftry>
		<cfquery name="qDeleteFromTable" datasource="#mpDBSource#">
			Delete from #mainTable# Where osver_support = <cfqueryparam value="#arguments.osver#">
		</cfquery>
		<cfcatch>
			<cfset elog("Error [qDeleteFromTable]: #cfcatch.message#")>
			<cfset _res.errorCode = "1">
			<cfset _res.errorMessage = "[qDeleteFromTable]: #cfcatch.message#">
			<cfset _res.result = false>
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>

</cfcomponent>