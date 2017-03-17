<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "admin_agents_parked" />

	<cffunction name="getAgents" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">

		<cfset var arrResults = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = false>
		<cfset var strSearch = "">

		<cfif Arguments._search>
			<cfset strSearch = buildSearchString(Arguments.searchField,Arguments.searchOper,Arguments.searchString)>
			<cfset blnSearch = true>
		</cfif>		
		<cftry>
			<cfquery name="qServers" datasource="#session.dbsource#" result="res">
				select rid, cuuid, enabled, hostname, serialno
				From mp_agent_registration
				Where 0=0
					AND enabled = 0
                <cfif blnSearch>
                    AND
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

		<cfset records = qServers>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="qServers" startrow="#start#" endrow="#end#">
			<cfset _enabled = (enabled EQ 0 ? "No" : "Yes") />
			<cfset arrResults[i] = [#rid#, #cuuid#, #_enabled#, #hostname#, #serialno#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qServers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qServers.recordcount#,rows=#arrResults#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editAgents" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit.">
            <cfset strMsg = "Reg Key Editted">
			<!--- Take the data, update your record. Simple. --->
			<cftry>
				<cfquery name="editKey" datasource="#session.dbsource#">
					UPDATE
						mp_agent_registration
					SET
						enabled = <cfqueryparam value="#Arguments.enabled#">
					WHERE
						rid = #Val(Arguments.id)#
				</cfquery>
				
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when editting reg key. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
        <cfelseif oper EQ "del">
            <cftry>
	        	<cfquery name="delServer" datasource="#session.dbsource#">
					Delete from mp_agent_registration
					Where rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when removing a reg key. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		</cfif>

		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>

</cfcomponent>