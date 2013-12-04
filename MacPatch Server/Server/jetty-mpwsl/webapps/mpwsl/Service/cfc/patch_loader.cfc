<cfcomponent name="patch_loader" extends="_mpbase">
	
	<cfparam name="mainTable" default="apple_patches">
	<cfparam name="mainTableAdditions" default="apple_patches_mp_additions">
    <cfset this.logTable = "ws_srv_logs">
    
    <cffunction name="init" returntype="patch_loader" output="no">
    	<cfargument name="aLogTable" required="no" default="ws_log">

		<cfset this.logTable = arguments.aLogTable>
		<cfreturn this>
	</cffunction>

	<cffunction name="_apple" access="public" returntype="any" output="no">
		<cfargument name="data" hint="Encoded Data">
		<cfargument name="type" hint="Encodign Type">
		
		<cfset var l_data = "">
		<cfset var l_result = "0">
		
		<cfset var _res = StructNew()>
		<cfset _res.errorCode = "0">
		<cfset _res.errorMessage = "">
		<cfset _res.result = true>
		
		<cfif arguments.type EQ "JSON">
			<cfif isJson(arguments.data) EQ false>
				<!--- Log issue --->
				<cfset elogit("Not JSON Data.")>
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
				<cfset elogit("No columns defined, length = 0.")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "No columns defined, length = 0.">
				<cfset _res.result = false>
				<cfreturn _res>	
			</cfif>
			<cfif ArrayLen(xData) EQ 0>
				<cfset elogit("No data defined, length = 0.")>
				<cfset _res.errorCode = "1">
				<cfset _res.errorMessage = "No data defined, length = 0.">
				<cfset _res.result = false>
				<cfreturn _res>
			</cfif>
			
			<cfloop array="#l_data['DATA']#" index="iArr">
				<cfif ArrayLen(iArr) EQ ArrayLen(xCols)>
					
					<cfset l_row = #genRow(xCols,iArr)#>
					<cflog file="patch_loader" type="Information" application="no" text="rowInsert">
					<cfset _ires = rowInsert(xCols,iArr,mainTable)>
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
		
		<cfif isSimpleValue(arguments.aTbl) AND refindnocase(this.sqlregex, arguments.aTbl)>
			<cfset _res.error = "1">
			<cfset _res.errorMessage = "Error: Table(#arguments.aTbl#) is not valid.">
			<cfreturn _res> 
		</cfif>
		
		<!--- Check Structure of Data for Insert/Update --->
		<cfloop array="#arguments.aCols#" index="i">
			<cfif isSimpleValue(i) AND refindnocase(this.sqlregex,i)>
				<cfset _res.error = "1">
				<cfset _res.errorMessage = "Error: Column (#i#) is not valid. Row insert will not occure.">
				<cfreturn _res>
			</cfif>
		</cfloop>
		
		<cftry>
			<!--- Check to See if the Patch Already Exists --->
			<cfset _PatchVersion = ArrayFindnocase(arguments.aCols,"version")>
			<cfset _PatchVersionVal = arguments.aVals[_PatchVersion]>
			<cfset _SUPatchName = ArrayFindnocase(arguments.aCols,"supatchname")>
			<cfset _SUPatchNameVal = arguments.aVals[_SUPatchName]>
			
			<cflog file="patch_loader" type="Information" application="no" text="_PatchVersion=#_PatchVersion#">
			<cflog file="patch_loader" type="Information" application="no" text="_PatchVersionVal=#_PatchVersionVal#">
			<cflog file="patch_loader" type="Information" application="no" text="_SUPatchName=#_SUPatchName#">
			<cflog file="patch_loader" type="Information" application="no" text="_SUPatchNameVal=#_SUPatchNameVal#">
			
			<cflog file="patch_loader" type="Information" application="no" text="_rowExists">
			
			<cfset _rowExists = existsInTable(arguments.aTbl,'supatchname',_SUPatchNameVal)>
			
			<cflog file="patch_loader" type="Information" application="no" text="_rowExists=#_rowExists#">
			
			<cfif _rowExists EQ False>
				<cflog file="patch_loader" type="Information" application="no" text="Do Insert">
			
				<cfquery name="qInsert" datasource="#this.ds#" result="qRes">
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
				
				<!--- Insert Additional MP Data --->
				<cfquery name="qInsertAlt" datasource="#this.ds#" result="qResAlt">
					INSERT INTO #mainTableAdditions# ( version, supatchname )
					Values (<cfqueryparam value="#_PatchVersionVal#">,<cfqueryparam value="#_SUPatchNameVal#">)
				</cfquery>
			</cfif>
		<cfcatch>
				<cflog file="patch_loader" type="Error" application="no" text="Error: Inserting data, #cfcatch.message# #cfcatch.detail#">
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
		<cfquery name="qCopyToHistory" datasource="#this.ds#">
			Select * from apple_patches_real Limit 1
		</cfquery>
		<cfset tblCols = #ArrayToList(qCopyToHistory.getColumnNames(),",")#>
		<cfset tblCols = ListDeleteAt(tblCols,ListContainsNoCase(tblCols,"rid"),",")>	
			
		<cfquery name="qCopyToHistory" datasource="#this.ds#">
			INSERT INTO #mainTableHst# (#tblCols#) (SELECT #tblCols# FROM #mainTable# Where osver_support = <cfqueryparam value="#arguments.osver#">)
		</cfquery>
		<cfcatch>
			<cfset elogit("Error [qCopyToHistory]: #cfcatch.message#")>
			<cfset _res.errorCode = "1">
			<cfset _res.errorMessage = "[qCopyToHistory]: #cfcatch.message# #cfcatch.Detail#">
			<cfset _res.result = false>
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>
	
	<cffunction name="existsInTable" access="private" returntype="any" output="no">
		<cfargument name="aTable">
		<cfargument name="aField">
		<cfargument name="aFieldValue">

    	<cfquery datasource="#this.ds#" name="qGet">
            Select #arguments.aField#
            From #arguments.aTable#
            Where #arguments.aField# = <cfqueryparam value="#arguments.aFieldValue#">
        </cfquery>
		
        <cfif qGet.RecordCount EQ 0>
        	<cfreturn False>
        <cfelse>
        	<cfreturn True>
        </cfif>
	</cffunction>
	
	<!--- Not Used Anymore --->
	<cffunction name="existsInAltTable" access="private" returntype="any" output="no">
		<cfargument name="theKey">

    	<cfquery datasource="#this.ds#" name="qGet" >
            Select akey
            From #mainTableAlt#
            Where akey = <cfqueryparam value="#arguments.theKey#">
        </cfquery>
		
        <cfif qGet.RecordCount EQ 0>
        	<cfreturn False>
        <cfelse>
        	<cfreturn True>
        </cfif>
	</cffunction>
    
	<!--- Not Used Anymore --->
    <cffunction name="isSameInAltTable" access="private" returntype="any" output="no">
		<cfargument name="theKey">
        <cfargument name="thePatchName">
        <cfargument name="theSUPatchName">
        <cfargument name="thePatchVersion">

    	<cfquery datasource="#this.ds#" name="qGet" >
            Select akey
            From #mainTableAlt#
            Where akey = <cfqueryparam value="#arguments.theKey#">
            AND patchname = <cfqueryparam value="#arguments.thePatchName#">
            AND supatchname = <cfqueryparam value="#arguments.theSUPatchName#">
            AND version = <cfqueryparam value="#arguments.thePatchVersion#">
        </cfquery>
		
        <cfif qGet.RecordCount EQ 0>
        	<cfreturn False>
        <cfelse>
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
		<cfquery name="qDeleteFromTable" datasource="#this.ds#">
			Delete from #mainTable# Where osver_support = <cfqueryparam value="#arguments.osver#">
		</cfquery>
		<cfcatch>
			<cfset elogit("Error [qDeleteFromTable]: #cfcatch.message#")>
			<cfset _res.errorCode = "1">
			<cfset _res.errorMessage = "[qDeleteFromTable]: #cfcatch.message#">
			<cfset _res.result = false>
		</cfcatch>
		</cftry>
		
		<cfreturn _res>
	</cffunction>

</cfcomponent>