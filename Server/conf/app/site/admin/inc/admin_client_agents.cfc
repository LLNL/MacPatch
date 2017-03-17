<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "admin_client_agents" />
	
	<cffunction name="getClientAgents" access="remote" returnformat="json">
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
					select * from mp_client_agents
					WHERE
						0 = 0 
					AND
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
                select * from mp_client_agents
				WHERE
					0 = 0
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
		<cfset var l_app_ver = "NA">  
		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
			<cfset arrUsers[i] = [#rid#, #agent_ver#,  #osver#, #version#, #build#, #pkg_name#, #pkg_url#, #pkg_hash#, #state#, #IIF(active EQ 1,DE("Yes"),DE("No"))#, #cdate#, #mdate#]>
			<cfset i = i + 1>			
		</cfloop>
		
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>		
		<cfreturn stcReturn>
	</cffunction>
            
    <cffunction name="editClientAgents" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">
		<cfargument name="active" required="no" hint="Field that was editted">
		<cfargument name="pkg_url" required="no" hint="Field that was editted">
		<cfargument name="description" required="no" hint="Field that was editted">
		
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        <cfset var pkgBaseLoc = #application.settings.paths.content# & "/clients">

        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit."> 
            <cfset strMsg = "User Editted">		
            
            
            <!--- Get The Patch ID --->
            <cfquery name="qGetID" datasource="#session.dbsource#" maxrows="1">
                Select puuid From mp_client_agents WHERE rid = <cfqueryparam value="#Arguments.id#">
            </cfquery>
            <cfset _pid = qGetID.puuid>
            
			<!--- Take the data, update the record. Simple. --->
			<cftry>
				<!--- Get The Active Flag Update Type --->
				<cfquery name="qGetType" datasource="#session.dbsource#">
					Select type From mp_client_agents WHERE rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<cfset xType = #qGetType.type#>
				
				<!--- Only Allow One Active at a time --->
				<cfif #Arguments.active# EQ 1>
					<cfquery name="qSetType" datasource="#session.dbsource#">
						Update mp_client_agents Set active = '0' WHERE type = <cfqueryparam value="#xType#">
					</cfquery>
				</cfif>
				
				<!--- Set the Active Flag --->
				<cfquery name="editAgentPatch" datasource="#session.dbsource#">
					UPDATE
						mp_client_agents
					SET
						osver = <cfqueryparam value="#Arguments.osver#">,
						version = <cfqueryparam value="#Arguments.version#">,
						build = <cfqueryparam value="#Arguments.build#">,
						active = <cfqueryparam value="#Arguments.active#" cfsqltype="cf_sql_integer">,
						pkg_url = <cfqueryparam value="#Arguments.pkg_url#">
					WHERE
						rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
                
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when Editting. #cfcatch.Detail# | #cfcatch.Message#">
                    <cflog application="yes" type="Error" text="#cfcatch.Detail# | #cfcatch.Message#">
                </cfcatch>
			</cftry>
        <cfelseif oper EQ "del">    
            <cftry>
            	<cfquery name="qAgentInfo" datasource="#session.dbsource#" maxrows="1">
					Select * FROM mp_client_agents WHERE rid = #Arguments.id#
				</cfquery>
                <cfset _pid = qAgentInfo.puuid>
				<cfquery name="delPatch" datasource="#session.dbsource#">
					DELETE FROM mp_client_agents WHERE puuid = '#_pid#'
				</cfquery>
                
                <!--- Remove the Files from FileSystem --->
				<cfset pkgDir = #pkgBaseLoc# & "/" & _pid>
                <cfif directoryexists(pkgDir) EQ True>
                    <cfdirectory action="delete" directory="#pkgDir#" recurse="true">
                </cfif>
                
				<cfset strMsgType = "Success">
				<cfset strMsg = "Delete Client Agent #pkgDir#">
				<cfcatch>
					<!--- Error, return message --->
					<cfset strMsgType = "Error">
					<cfset strMsg = "Error occured when Deleting MP patch. An error report has been submitted to support.">
                    <cflog application="yes" type="Error" text="#cfcatch.Detail# | #cfcatch.Message#">
				</cfcatch>
			</cftry>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>
<!--- Agent Filters Section --->

	<cffunction name="getClientAgentFilters" access="remote" returnformat="json">
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
					select * from mp_client_agents_filters
					WHERE
						0 = 0 
					AND
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
                select * from mp_client_agents_filters
				WHERE
					0 = 0
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
		<cfset var l_app_ver = "NA">  
		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
			<cfset arrUsers[i] = [#rid#, #attribute#, #attribute_oper#, #attribute_filter#, #attribute_condition#]>
			<cfset i = i + 1>			
		</cfloop>
		
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>
            
    <cffunction name="editClientAgentFilters" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">
		<cfargument name="attribute" required="no">
		<cfargument name="attribute_oper" required="no">
		<cfargument name="attribute_filter" required="no">
		<cfargument name="attribute_condition" required="no">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit."> 
			<!--- Take the data, update your record. Simple. --->
			<cftry>
				<cfquery name="editRow" datasource="#session.dbsource#">
					UPDATE
						mp_client_agents_filters
					SET
						attribute = <cfqueryparam value="#Arguments.attribute#">,
						attribute_oper = <cfqueryparam value="#Arguments.attribute_oper#">,
						attribute_filter = <cfqueryparam value="#Arguments.attribute_filter#">,
						attribute_condition = <cfqueryparam value="#Arguments.attribute_condition#">
					WHERE
						rid = <cfqueryparam value="#id#">
				</cfquery>
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when editting row. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		<cfelseif oper EQ "add">
        	<!--- We do not support adding a user yet --->
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add.">
			<cftry>
				<cfquery name="addRow" datasource="#session.dbsource#">
					Insert Into mp_client_agents_filters (type,attribute,attribute_oper,attribute_filter,attribute_condition)
					Values('app',<cfqueryparam value="#Arguments.attribute#">, <cfqueryparam value="#Arguments.attribute_oper#">, <cfqueryparam value="#Arguments.attribute_filter#">, <cfqueryparam value="#Arguments.attribute_condition#">)
				</cfquery>
			<cfcatch type="any">
                <!--- Error, return message --->
                <cfset strMsgType = "Error">
                <cfset strMsg = "Error occured when adding row. An Error report has been submitted to support.">
            </cfcatch>
			</cftry>	
        <cfelseif oper EQ "del">    
            <cftry>
				<cfquery name="delPatch" datasource="#session.dbsource#">
					DELETE FROM mp_client_agents_filters WHERE rid = <cfqueryparam value="#id#">
				</cfquery>
				<cfset strMsgType = "Success">
				<cfset strMsg = "Delete Client Agent">
				<cfcatch>
					<!--- Error, return message --->
					<cfset strMsgType = "Error">
					<cfset strMsg = "Error occured when deleting row. An error report has been submitted to support.">
				</cfcatch>
			</cftry>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>	
	
</cfcomponent>	
