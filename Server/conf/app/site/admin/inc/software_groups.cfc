<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "software_groups" />

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
			<cfset arrSW[i] = [#gid#, #gid#, #gName#, #gDescription#, #owner#, #txtState#, #DateTimeFormat( mdate, "yyyy-MM-dd HH:mm:ss" )#] >
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

<!--- Software Group Filters --->
	<cffunction name="getGroupFilters" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false">
	    <cfargument name="filters" required="no" default="">

	    <cfargument name="gid" required="yes" default="NA" hint="Group ID">

		<cfset var arrRows = ArrayNew(1)>
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
            <cfquery name="qSWFilters" datasource="#session.dbsource#" result="res">
				select *
				From mp_software_groups_filters
                Where 0=0
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
            	</cfif>
            	AND
            		gid = <cfqueryparam value="#Arguments.gid#">
                ORDER BY #sidx# #sord#
            </cfquery>

            <cfset records = qSWFilters>
			<cfset start = ((arguments.page-1)*arguments.rows)+1>
			<cfset end = (start-1) + arguments.rows>
			<cfset i = 1>

			<cfloop query="qSWFilters" startrow="#start#" endrow="#end#">
				<cfset arrRows[i] = [#rid#, #attribute#, "Database", #attribute_oper#, #attribute_filter#, #attribute_condition#]>
				<cfset i = i + 1>
			</cfloop>

			<cfset totalPages = Ceiling(qSWFilters.recordcount/arguments.rows)>
			<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qSWFilters.recordcount#,rows=#arrRows#}>
			<cfreturn stcReturn>

			<cfcatch type="any">
                <cfset blnSearch = false>
                <cfset strMsgType = "Error">
                <cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">
                <cfreturn {total=0,page=1,records=0,rows="",catch="#cfcatch.message#"}>
            </cfcatch>
		</cftry>
	</cffunction>	

	<cffunction name="editGroupFilters" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
		<cftry>
			
		
			<cfif oper EQ "edit">
				<cfset strMsgType = "Edit">
				<cfset strMsg = "Notice, MP edit.">
				<cfquery name="qEditFilter" datasource="#session.dbsource#">
					Update mp_software_groups_filters
					Set attribute = <cfqueryparam value="#Arguments.attribute#">,
					attribute_oper = <cfqueryparam value="#Arguments.attribute_oper#">,
					attribute_filter = <cfqueryparam value="#Arguments.attribute_filter#">,
					attribute_condition = <cfqueryparam value="#Arguments.attribute_condition#">
					where rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<!---
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
				--->
			<cfelseif oper EQ "add">
				<cfset strMsgType = "Add">
				<cfset strMsg = "Notice, MP add.">
				<cfquery name="qAddFilter" datasource="#session.dbsource#">
					INSERT Into mp_software_groups_filters (gid, attribute, attribute_oper, attribute_filter, attribute_condition)
					Values ( <cfqueryparam value="#arguments.gid#">, <cfqueryparam value="#arguments.attribute#">, <cfqueryparam value="#arguments.attribute_oper#">
							,<cfqueryparam value="#arguments.attribute_filter#">, <cfqueryparam value="#arguments.attribute_condition#">)
				</cfquery>
				<cfset strMsg = "#arguments.id#">
				<cfloop item="key" collection="#ARGUMENTS#">
					<cfset strMsg = strMsg & " ,#ARGUMENTS[ Key ]#">
				</cfloop>
				
	        <cfelseif oper EQ "del">
	            <cfset strMsg = "Delete Software Group">
	            <cfquery name="qDelFilter" datasource="#session.dbsource#">
					DELETE FROM mp_software_groups_filters WHERE rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
			</cfif>
			<cfcatch type="any">
                <cfset blnSearch = false>
                <cfset strMsgType = "Error">
                <cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">
                <cfreturn {msg="#cfcatch.message#"}>
            </cfcatch>
		</cftry>

		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>

		<cfreturn strReturn>
	</cffunction>

</cfcomponent>