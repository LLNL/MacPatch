<cfcomponent output="false">
	<cffunction name="getMPServers" access="remote" returnformat="json">
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
				select *
				From mp_servers
				Where 0=0
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
			<cfset arrResults[i] = [#rid#, #server#, #port#, #useSSL#, #useSSLAuth#, #isMaster#, #isProxy#, #active#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qServers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qServers.recordcount#,rows=#arrResults#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editMPServers" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit.">
            <cfset strMsg = "Server Editted">
			<!--- Take the data, update your record. Simple. --->
			<cftry>
				<cfquery name="editServer" datasource="#session.dbsource#">
					UPDATE
						mp_servers
					SET
						server = <cfqueryparam value="#Arguments.server#">,
						port = <cfqueryparam value="#Arguments.port#">,
						useSSL = <cfqueryparam value="#Arguments.useSSL#">,
						useSSLAuth = <cfqueryparam value="#Arguments.useSSLAuth#">,
						isMaster = <cfqueryparam value="#Arguments.isMaster#">,
						isProxy = <cfqueryparam value="#Arguments.isProxy#">,
						active = <cfqueryparam value="#Arguments.active#">
					WHERE
						rid = #Val(Arguments.id)#
				</cfquery>
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when editting server. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		<cfelseif oper EQ "add">
			<cftry>
	        	<cfquery name="addServer" datasource="#session.dbsource#">
					Insert Into mp_servers (listid, server, port, usessl, usesslauth, isMaster, isProxy, active)
					Values (<cfqueryparam value="1">,<cfqueryparam value="#Arguments.server#">,<cfqueryparam value="#Arguments.port#">,<cfqueryparam value="#Arguments.useSSL#">,<cfqueryparam value="#Arguments.useSSLAuth#">,
					<cfqueryparam value="#Arguments.isMaster#">,<cfqueryparam value="#Arguments.isProxy#">,<cfqueryparam value="#Arguments.active#">)
				</cfquery>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when adding server. An Error report has been submitted to support. #cfcatch.Message# #cfcatch.ExtendedInfo#">
                </cfcatch>
			</cftry>
        <cfelseif oper EQ "del">
            <cftry>
	        	<cfquery name="delServer" datasource="#session.dbsource#">
					Delete from mp_servers
					Where rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when adding proxy server. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
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
</cfcomponent>