<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "admin_asus_servers" />

	<cffunction name="getAsusServers" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">

		<cfset var arrUsers = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = false>
		<cfset var strSearch = "">

		<cfif Arguments._search>
			<cfset strSearch = buildSearchString(Arguments.searchField,Arguments.searchOper,Arguments.searchString)>
			<cfset blnSearch = true>
			<cftry>
				<cfquery name="selUsers" datasource="#session.dbsource#" result="res">
					select *
					From mp_asus_catalogs
					WHERE
						#PreserveSingleQuotes(strSearch)#
				</cfquery>

                <cfcatch type="any">
					<cfset blnSearch = false>
					<cfset strMsgType = "Error">
					<cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">
				</cfcatch>
			</cftry>
		<cfelse>
            <cfquery name="selUsers" datasource="#session.dbsource#" result="res">
                select *
				From mp_asus_catalogs
                Where 0=0
                <cfif blnSearch>
                    AND
                        #PreserveSingleQuotes(strSearch)#
                </cfif>
                ORDER BY #sidx# #sord#
            </cfquery>
		</cfif>

		<cfset records = selUsers>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
			<cfset arrUsers[i] = [#rid#, #catalog_url#, #os_major#, #os_minor#, #c_order#, #proxy#, #catalog_group_name#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editAsusServers" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
        <cfargument name="catalog_url" required="no" hint="Field that was Added or editted">
		<cfargument name="os_major" required="no" hint="Field that was Added or editted">
		<cfargument name="os_minor" required="no" hint="Field that was Added or editted">
		<cfargument name="c_order" required="no" hint="Field that was Added or editted">
		<cfargument name="proxy" required="no" hint="Field that was Added or editted">
		<cfargument name="catalog_group_name" required="no" hint="Field that was Added or editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit.">
            <cfset strMsg = "User Editted">
			<!--- Take the data, update your record. Simple. --->
			<cftry>
				<cfquery name="editProxyServer" datasource="#session.dbsource#">
					UPDATE
						mp_asus_catalogs
					SET
						catalog_url = <cfqueryparam value="#Arguments.catalog_url#">,
						os_major = <cfqueryparam value="#Arguments.os_major#">,
						os_minor = <cfqueryparam value="#Arguments.os_minor#">,
						c_order = <cfqueryparam value="#Arguments.c_order#">,
						proxy = <cfqueryparam value="#Arguments.proxy#">,
						catalog_group_name = <cfqueryparam value="#Arguments.catalog_group_name#">
					WHERE
						rid = #Val(Arguments.id)#
				</cfquery>
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when Editting User. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		<cfelseif oper EQ "add">
			<cftry>
	        	<cfquery name="addProxyServer" datasource="#session.dbsource#">
					Insert Into mp_asus_catalogs (catalog_url, os_major, os_minor, c_order, proxy, catalog_group_name)
					Values (<cfqueryparam value="#Arguments.catalog_url#">,<cfqueryparam value="#Arguments.os_major#">,<cfqueryparam value="#Arguments.os_minor#">,<cfqueryparam value="#Arguments.c_order#">,<cfqueryparam value="#Arguments.proxy#">,<cfqueryparam value="#Arguments.catalog_group_name#">)
				</cfquery>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when adding proxy server. An Error report has been submitted to support. #cfcatch.Message# #cfcatch.ExtendedInfo#">
                </cfcatch>
			</cftry>
        <cfelseif oper EQ "del">
            <cftry>
	        	<cfquery name="delProxyServer" datasource="#session.dbsource#">
					Delete from mp_asus_catalogs
					Where rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<cfquery name="delProxyServer" datasource="#session.dbsource#">
					Delete from mp_asus_catalogs
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

</cfcomponent>