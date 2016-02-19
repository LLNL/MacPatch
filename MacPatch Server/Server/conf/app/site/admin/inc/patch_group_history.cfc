<cfcomponent output="false">
	<cffunction name="showHistoryForGroup" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="cdate" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">
        <cfargument name="filters" required="no" default="">

        <cfargument name="patchgroup" required="yes" default="RecommendedPatches" hint="patchgroup">

		<cfset var arrRecords = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = Arguments._search>
		<cfset var strSearch = "patchgroup = <cfqueryparam value='#Arguments.patchgroup#'>">

		<cfif Arguments.filters NEQ "" AND blnSearch>
			<cfset stcSearch = DeserializeJSON(Arguments.filters)>
            <cfif isDefined("stcSearch.groupOp")>
            	<cfset strSearch = buildSearch(stcSearch)>
            </cfif>
        </cfif>

        <cftry>
        	<cfoutput>
        		<cfsavecontent variable="foo">
        			SELECT * FROM mp_patch_selection_history
	                <cfif blnSearch AND strSearch NEQ "">
	                    #PreserveSingleQuotes(strSearch)#
	                    AND
	                    patchgroup = #Arguments.patchgroup#
	                <cfelse>
	                    WHERE
	                    patchgroup = #Arguments.patchgroup#
	                </cfif>
	                ORDER BY #sidx# #sord#
        		</cfsavecontent>
        	</cfoutput>
        	<cfset logError("patch_group_history","showHistoryForGroup","#foo#")>
            <cfquery datasource="#session.dbsource#" name="qHistory">
                SELECT * FROM mp_patch_selection_history
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND
                    patchgroup = <cfqueryparam value="#Arguments.patchgroup#">
                <cfelse>
                    WHERE
                    patchgroup = <cfqueryparam value="#Arguments.patchgroup#">
                </cfif>
                ORDER BY #sidx# #sord#
            </cfquery>

            <cfcatch type="any">
            	<cfset logError("patch_group_history","showHistoryForGroup",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
                <cfset totalPages = 0>
				<cfset stcReturn = {}>
                <cfreturn stcReturn>
            </cfcatch>
        </cftry>

		<cfset records = qHistory>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>

		<cfset i = 1>
		<cfloop query="qHistory" startrow="#start#" endrow="#end#">
            <cfset arrRecords[i] = [#rid#, #patch#, #patchtype#, #IIF(state EQ "1",DE('Enabled'),DE('Disabled'))#, #userid#, #DateTimeFormat( cdate, "yyyy-MM-dd HH:mm:ss" )#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qHistory.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qHistory.recordcount#,rows=#arrRecords#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="buildSearchString" access="private" hint="Returns the Search Opeator based on Short Form Value">
		<cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">

        	<cfset var searchCol = "b.#Arguments.searchField#">
			<cfset var searchVal = "">
			<cfscript>
				switch(Arguments.searchOper)
				{
					case "eq":
						searchVal = "#searchCol# = '#Arguments.searchString#'";
						break;
					case "ne":
						searchVal = "#searchCol# <> '#Arguments.searchString#'";
						break;
					case "lt":
						searchVal = "#searchCol# < '#Arguments.searchString#'";
						break;
					case "le":
						searchVal = "#searchCol# <= '#Arguments.searchString#'";
						break;
					case "gt":
						searchVal = "#searchCol# > '#Arguments.searchString#'";
						break;
					case "ge":
						searchVal = "#searchCol# >= '#Arguments.searchString#'";
						break;
					case "bw":
						searchVal = "#searchCol# LIKE '#Arguments.searchString#%'";
						break;
					case "ew":
						//Purposefully breaking ends with operator (no leading ')
						searchVal = "#searchCol# LIKE %#Arguments.searchString#'";
						break;
					case "cn":
						searchVal = "#searchCol# LIKE '%#Arguments.searchString#%'";
						break;
				}
			</cfscript>
			<cfreturn searchVal>
	</cffunction>

    <cffunction name="buildSearch" access="private" hint="Build our Search Parameters">
		<cfargument name="stcSearch" required="true">

		<!--- strOp will be either AND or OR based on user selection --->
		<cfset var strGrpOp = stcSearch.groupOp>
		<cfset var arrFilter = stcSearch.rules>
		<cfset var strSearch = "">
		<cfset var strSearchVal = "">

		<!--- Loop over array of passed in search filter rules to build our query string --->
		<cfloop array="#arrFilter#" index="arrIndex">
			<cfset strField = arrIndex["field"]>
			<cfset strOp = arrIndex["op"]>
			<cfset strValue = arrIndex["data"]>

			<cfset strSearchVal = buildSearchArgument(strField,strOp,strValue)>

			<cfif strSearchVal NEQ "">
				<cfif strSearch EQ "">
					<cfset strSearch = "WHERE (#PreserveSingleQuotes(strSearchVal)#)">
				<cfelse>
					<cfset strSearch = strSearch & "#strGrpOp# (#PreserveSingleQuotes(strSearchVal)#)">
				</cfif>
			</cfif>

		</cfloop>

		<cfreturn strSearch>
	</cffunction>

	<cffunction name="buildSearchArgument" access="private" hint="Build our Search Argument based on parameters">
		<cfargument name="strField" required="true" hint="The Field which will be searched on">
		<cfargument name="strOp" required="true" hint="Operator for the search criteria">
		<cfargument name="strValue" required="true" hint="Value that will be searched for">

		<cfset var searchVal = "">
		<cfset var searchCol = "#Arguments.strField#">

		<cfif Arguments.strValue EQ "">
			<cfreturn "">
		</cfif>

		<cfscript>
			switch(Arguments.strOp)
			{
				case "eq":
					//ID is numeric so we will check for that
					if(searchCol EQ "id")
					{
						searchVal = "#searchCol# = #Arguments.strValue#";
					}else{
						searchVal = "#searchCol# = '#Arguments.strValue#'";
					}
					break;
				case "lt":
					searchVal = "#searchCol# < #Arguments.strValue#";
					break;
				case "le":
					searchVal = "#searchCol# <= #Arguments.strValue#";
					break;
				case "gt":
					searchVal = "#searchCol# > #Arguments.strValue#";
					break;
				case "ge":
					searchVal = "#searchCol# >= #Arguments.strValue#";
					break;
				case "bw":
					searchVal = "#searchCol# LIKE '#Arguments.strValue#%'";
					break;
				case "ew":
					searchVal = "#searchCol# LIKE '%#Arguments.strValue#'";
					break;
				case "cn":
					searchVal = "#searchCol# LIKE '%#Arguments.strValue#%'";
					break;
			}
		</cfscript>

		<cfreturn searchVal>
	</cffunction>

	<cffunction name="logError" access="private">
		<cfargument name="log" required="yes">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="Detail: NA">
	    <cfargument name="type" required="no" default="Type: NA">
		
		<cfif #arguments.type# NEQ "NA">
			<cflog file="#arguments.log#" type="error" application="no" text="[#arguments.method#] - Type: #arguments.type#">
		</cfif>
    	<cflog file="#arguments.log#" type="error" application="no" text="[#arguments.method#] - Message: #arguments.message#">
    	<cfif #arguments.detail# NEQ "NA">
        	<cflog file="#arguments.log#" type="error" application="no" text="[#arguments.method#] - Detail: #arguments.detail#">
        </cfif>
	</cffunction>

</cfcomponent>
