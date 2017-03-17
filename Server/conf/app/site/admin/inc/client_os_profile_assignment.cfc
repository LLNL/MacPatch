<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "client_os_profile_assignment" />

	<cffunction name="getOSProfileAssignments" access="remote" returnformat="json">
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
			<cfquery name="selUsers" datasource="#session.dbsource#" result="res">
				select a.rid, a.profileID, a.groupID, b.profileName, b.profileDescription, b.enabled
                From mp_os_config_profiles_assigned a
                LEFT JOIN mp_os_config_profiles b ON a.profileID = b.profileID
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
        
		<cfset records = selUsers>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
			<cfset arrUsers[i] = [#rid#, #groupID#, #profileName#, #profileDescription#, #enabled#] >
			<cfset i = i + 1>			
		</cfloop>
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>
     
    <cffunction name="addEditOSProfileAssignments" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cftry>
				<cfquery name="editRecord" datasource="#session.dbsource#" result="res">
					UPDATE mp_os_config_profiles_assigned
					SET profileID = <cfqueryparam value="#Arguments.profileID#">,
						groupID = <cfqueryparam value="#Arguments.assignment#">
					WHERE
						rid = <cfqueryparam value="#arguments.id#">
				</cfquery>
                <cfcatch type="any">			
					<cfset strMsgType = "Error">
					<cfset strMsg = "#cfcatch.detail#">				
				</cfcatch>		
			</cftry>
		<cfelseif oper EQ "add">
			<cftry>
				<cfquery name="addRecord" datasource="#session.dbsource#" result="res">
					Insert Into mp_os_config_profiles_assigned ( profileID, groupID )
                    Values (<cfqueryparam value="#arguments.profileID#">,<cfqueryparam value="#arguments.assignment#">) 
				</cfquery>
                <cfcatch type="any">			
					<cfset strMsgType = "Error">
					<cfset strMsg = "#cfcatch.detail#">					
				</cfcatch>		
			</cftry>
        <cfelseif oper EQ "del">    
            <cftry>
				<cfquery name="removeRecord" datasource="#session.dbsource#" result="res">
					Delete From mp_os_config_profiles_assigned
					WHERE rid = <cfqueryparam value="#arguments.id#">
				</cfquery>
                <cfcatch type="any">			
					<cfset strMsgType = "Error">
					<cfset strMsg = "There was an issue with the delete. An Error Report has been submitted to Support.">					
				</cfcatch>		
			</cftry>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>
</cfcomponent>	