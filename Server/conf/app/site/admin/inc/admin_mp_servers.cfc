<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "admin_mp_servers" />

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
			<cfset arrResults[i] = [#rid#, #server#, #port#, #useSSL#, #allowSelfSignedCert#, #isMaster#, #isProxy#, #active#]>
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
						allowSelfSignedCert = <cfqueryparam value="#Arguments.allowSelfSignedCert#">,
						isMaster = <cfqueryparam value="#Arguments.isMaster#">,
						isProxy = <cfqueryparam value="#Arguments.isProxy#">,
						active = <cfqueryparam value="#Arguments.active#">
					WHERE
						rid = #Val(Arguments.id)#
				</cfquery>
				<cfset x = updateServerListVersion('Default')>
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when editting server. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		<cfelseif oper EQ "add">
			<cftry>
	        	<cfquery name="addServer" datasource="#session.dbsource#">
					Insert Into mp_servers (listid, server, port, usessl, isMaster, isProxy, active)
					Values (<cfqueryparam value="1">,<cfqueryparam value="#Arguments.server#">,<cfqueryparam value="#Arguments.port#">,<cfqueryparam value="#Arguments.useSSL#">,
					<cfqueryparam value="#Arguments.isMaster#">,<cfqueryparam value="#Arguments.isProxy#">,<cfqueryparam value="#Arguments.active#">)
				</cfquery>
                <cfif #Arguments.active# EQ '1'>
					<cfset x = updateServerListVersion('Default')>
				</cfif>
				<cfset x = updateServerListVersion('Default')>
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
				<cfset x = updateServerListVersion('Default')>
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
    
    <cffunction name="updateServerListVersion" access="private">
		<cfargument name="name" required="no" default="Default" hint="Field to perform Search on">

		<cftry>
        	<cfquery name="qGetVer" datasource="#session.dbsource#">
                Select version FROM mp_server_list
                WHERE
                    name = <cfqueryparam value="#Arguments.name#">
            </cfquery>
            <cfif qGetVer.Recordcount EQ 0>
            	<cfquery name="qCreateList" datasource="#session.dbsource#">
					Insert Into mp_server_list (listid, name, version)
					Values ('1','Default','1')
				</cfquery>
            	<cfreturn>
            </cfif>
			<cfif qGetVer.Recordcount EQ 1>
            	<cfset _ver = qGetVer.version + 1>
                    <cfquery name="editServer" datasource="#session.dbsource#">
                    UPDATE
                        mp_server_list
                    SET
                        version = '#_ver#'
                    WHERE
                        name = <cfqueryparam value="#Arguments.name#">
                </cfquery>
            </cfif>
            <cfif qGetVer.Recordcount GTE 2>
            	<cflog application="no" file="MPServer" type="error" text="[updateServerListVersion]: mp_server_list contained multiple results. Server list version will not be updated." />
            </cfif>
            <cfcatch type="any">
                <cflog application="no" file="MPServer" type="error" text="[updateServerListVersion]: #cfcatch.message# #cfcatch.Detail#" />
            </cfcatch>
        </cftry>
		<cfreturn>
	</cffunction>

</cfcomponent>