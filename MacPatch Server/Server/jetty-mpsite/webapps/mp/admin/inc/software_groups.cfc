<cfcomponent output="false">
	<cffunction name="getMPSoftwareGroups" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false">
	    <cfargument name="filters" required="no" default="">

		<cfset var arrUsers = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = Arguments._search>
		<cfset var strSearch = "">	
		
		<cfif Arguments.filters NEQ "" AND blnSearch>
			<cfset stcSearch = DeserializeJSON(Arguments.filters)>
            <cfif isDefined("stcSearch.groupOp")>
            	<cfset strSearch = buildSearch(stcSearch)>
            </cfif>            
        </cfif>

        <cftry>
            <cfquery name="qSelSW" datasource="#session.dbsource#" result="res">
				select swg.*, swgp.uid as owner
				From mp_software_groups swg
				Left JOIN mp_software_groups_privs swgp ON swg.gid = swgp.gid Where (swgp.isOwner = 1)
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
            	</cfif>
                ORDER BY #sidx# #sord#
            </cfquery>

            <cfcatch type="any">
                <cfset blnSearch = false>
                <cfset strMsgType = "Error">
                <cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">
            </cfcatch>
        </cftry>

		<cfset records = qSelSW>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="qSelSW" startrow="#start#" endrow="#end#">
			<cfif state GTE 1>
				<cfset txtState = IIF(state EQ 2,DE('QA'),DE('Production'))>
			<cfelse>
				<cfset txtState = "Disabled">
			</cfif>
			<cfset arrSW[i] = [#gid#, #gName#, #gDescription#, #owner#, #txtState#, #DateTimeFormat( mdate, "yyyy-MM-dd HH:mm:ss" )#] >
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qSelSW.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qSelSW.recordcount#,rows=#arrSW#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editMPSoftwareGroups" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit.">
			
			<cfquery name="updateGroupData" datasource="#session.dbsource#">
				Update mp_software_groups
				Set gName = <cfqueryparam value="#Arguments.gName#">,
				gDescription = <cfqueryparam value="#Arguments.gDescription#">,
				state = <cfqueryparam value="#Arguments.state#">
				where gid = <cfqueryparam value="#Arguments.id#">
			</cfquery>
			<cfif session.IsAdmin IS true>
				<cfquery name="updateOwnerData" datasource="#session.dbsource#">
					Update mp_software_groups_privs
					Set uid = <cfqueryparam value="#Arguments.owner#">
					where gid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
			</cfif>
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add.">
			<cfset _gid = CreateUuid()>
			<cfquery name="addGroup1" datasource="#session.dbsource#">
				INSERT Into mp_software_groups (gid, gName, gDescription)
				Values ( <cfqueryparam value="#_gid#">, <cfqueryparam value="#arguments.gName#">, <cfqueryparam value="#arguments.gDescription#">)
			</cfquery>
			<cfquery name="addGroup2" datasource="#session.dbsource#">
				INSERT Into mp_software_groups_privs (gid,uid,isOwner)
				Values ( '#_gid#', '#session.Username#', '1')
			</cfquery>
        <cfelseif oper EQ "del">
            <cfset strMsg = "Delete Software Group">
			<cfquery name="delTask1" datasource="#session.dbsource#">
				DELETE FROM mp_software_groups WHERE gid = <cfqueryparam value="#Arguments.id#">
			</cfquery>
			<cfquery name="delTask2" datasource="#session.dbsource#">
				DELETE FROM mp_software_group_tasks WHERE sw_group_id = <cfqueryparam value="#Arguments.id#">
			</cfquery>
			<cfquery name="delTask3" datasource="#session.dbsource#">
				DELETE FROM mp_software_groups_privs WHERE gid = <cfqueryparam value="#Arguments.id#">
			</cfquery>
		</cfif>

		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>

	 <cffunction name="buildSearchString" access="private" hint="Returns the Search Opeator based on Short Form Value">
		<cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">

			<cfset var searchVal = "">

			<cfscript>
				switch(Arguments.searchOper)
				{
					case "eq":
						searchVal = "#Arguments.searchField# = '#Arguments.searchString#'";
						break;
					case "ne":
						searchVal = "#Arguments.searchField# <> '#Arguments.searchString#'";
						break;
					case "lt":
						searchVal = "#Arguments.searchField# < '#Arguments.searchString#'";
						break;
					case "le":
						searchVal = "#Arguments.searchField# <= '#Arguments.searchString#'";
						break;
					case "gt":
						searchVal = "#Arguments.searchField# > '#Arguments.searchString#'";
						break;
					case "ge":
						searchVal = "#Arguments.searchField# >= '#Arguments.searchString#'";
						break;
					case "bw":
						searchVal = "#Arguments.searchField# LIKE '#Arguments.searchString#%'";
						break;
					case "ew":
						//Purposefully breaking ends with operator (no leading ')
						searchVal = "#Arguments.searchField# LIKE %#Arguments.searchString#'";
						break;
					case "cn":
						searchVal = "#Arguments.searchField# LIKE '%#Arguments.searchString#%'";
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
					<cfset strSearch = "HAVING (#PreserveSingleQuotes(strSearchVal)#)">
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
		
		<cfif Arguments.strValue EQ "">
			<cfreturn "">
		</cfif>
		
		<cfscript>
			switch(Arguments.strOp)
			{
				case "eq":
					//ID is numeric so we will check for that
					if(Arguments.strField EQ "id")
					{
						searchVal = "#Arguments.strField# = #Arguments.strValue#";
					}else{
						searchVal = "#Arguments.strField# = '#Arguments.strValue#'";
					}
					break;				
				case "lt":
					searchVal = "#Arguments.strField# < #Arguments.strValue#";
					break;
				case "le":
					searchVal = "#Arguments.strField# <= #Arguments.strValue#";
					break;
				case "gt":
					searchVal = "#Arguments.strField# > #Arguments.strValue#";
					break;
				case "ge":
					searchVal = "#Arguments.strField# >= #Arguments.strValue#";
					break;
				case "bw":
					searchVal = "#Arguments.strField# LIKE '#Arguments.strValue#%'";
					break;
				case "ew":					
					searchVal = "#Arguments.strField# LIKE '%#Arguments.strValue#'";
					break;
				case "cn":
					searchVal = "#Arguments.strField# LIKE '%#Arguments.strValue#%'";
					break;
			}			
		</cfscript>
		<cfreturn searchVal>
	</cffunction>
</cfcomponent>