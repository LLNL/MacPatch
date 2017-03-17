<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "mp_agent_keys" />

	<cffunction name="getConfig" access="remote" returnformat="json">
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
			<cfquery name="qGet" datasource="#session.dbsource#" result="res">
				select * From mp_clients_reg_conf	
			</cfquery>

            <cfcatch type="any">
				<cfset blnSearch = false>
				<cfset strMsgType = "Error">
				<cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">
			</cfcatch>
		</cftry>

		<cfset records = qGet>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="qGet" startrow="#start#" endrow="#end#">
			<cfset _autoreg = (autoreg EQ 0 ? "No" : "Yes") />
			<cfset _parking = (client_parking EQ 0 ? "No" : "Yes") />
			<cfset arrResults[i] = [#rid#, #_autoreg#, #autoreg_key#, #_parking#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qGet.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qGet.recordcount#,rows=#arrResults#}>
		<cfreturn stcReturn>
	</cffunction>

	<cffunction name="editConfig" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
            <cfset strMsg = "Reg Key Editted">
			<!--- Take the data, update your record. Simple. --->
			<cftry>
				<cfquery name="editKey" datasource="#session.dbsource#">
					UPDATE
						mp_clients_reg_conf
					SET
						autoreg = <cfqueryparam value="#Arguments.autoreg#">,
						client_parking = <cfqueryparam value="#Arguments.client_parking#">
					WHERE
						rid = #Val(Arguments.id)#
				</cfquery>
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when editting reg key. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Error">
            <cfset strMsg = "Error occured when adding reg key settings. An Error report has been submitted to support.">
        <cfelseif oper EQ "del">
            <cfset strMsgType = "Error">
            <cfset strMsg = "Error occured when removing a reg key settings. An Error report has been submitted to support.">
		</cfif>

		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>

	<cffunction name="getKeys" access="remote" returnformat="json">
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
				From mp_reg_keys
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
			<cfset _type = (keyType EQ 0 ? "Client" : "Group") />
			<cfset _active = (active EQ 0 ? "No" : "Yes") />
			<cfset arrResults[i] = [#rid#, #regKey#, #_type#, #keyQuery#, #validFromDate#, #validToDate#, #_active#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qServers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qServers.recordcount#,rows=#arrResults#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editKeys" access="remote" hint="Add or Edit" returnformat="json" output="no">
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
						mp_reg_keys
					SET
						keyType = <cfqueryparam value="#Arguments.keyType#">,
						keyQuery = <cfqueryparam value="#Arguments.keyQuery#">,
						validFromDate = #ParseDateTime(Arguments.validFromDate)#,
						validToDate = #ParseDateTime(Arguments.validToDate)#,
						active = <cfqueryparam value="#Arguments.active#">
					WHERE
						rid = #Val(Arguments.id)#
				</cfquery>
				
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when editting reg key. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		<cfelseif oper EQ "add">
			<cftry>
				<cfset _regKey = CreateUUID() />
				<cfquery name="addKey" datasource="#session.dbsource#">
					Insert Into mp_reg_keys (regKey, keyType, keyQuery, validFromDate, validToDate, active)
					Values (<cfqueryparam value="#_regKey#">,<cfqueryparam value="#Arguments.keyType#">,<cfqueryparam value="#Arguments.keyQuery#">,
							#ParseDateTime(Arguments.validFromDate)#, #ParseDateTime(Arguments.validToDate)#, <cfqueryparam value="#Arguments.active#">)
				</cfquery>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when adding keys. An Error report has been submitted to support. #cfcatch.Message# #cfcatch.ExtendedInfo#">
                </cfcatch>
			</cftry>
        <cfelseif oper EQ "del">
            <cftry>
	        	<cfquery name="delServer" datasource="#session.dbsource#">
					Delete from mp_reg_keys
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