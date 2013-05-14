<cfcomponent output="false">
	<cffunction name="getMPAccounts" access="remote" returnformat="json">
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
					select rid, user_id, group_id, last_login, number_of_logins
					From mp_adm_group_users
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
                select rid, user_id, group_id, last_login, number_of_logins
				From mp_adm_group_users
                Where 0=0
                <cfif blnSearch>
                    AND 
                        #PreserveSingleQuotes(strSearch)#
                </cfif>
                ORDER BY #sidx# #sord#				
            </cfquery>
		</cfif>
        
		<cfset records = selUsers>
		
		<!--- Calculate the Start Position for the loop query.
		So, if you are on 1st page and want to display 4 rows per page, for first page you start at: (1-1)*4+1 = 1.
		If you go to page 2, you start at (2-)1*4+1 = 5  --->
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		
		<!--- Calculate the end row for the query. So on the first page you go from row 1 to row 4. --->
		<cfset end = (start-1) + arguments.rows>
		
		<!--- When building the array --->
		<cfset i = 1>

		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
			<!--- Array that will be passed back needed by jqGrid JSON implementation --->
            <cftry>
            	<cfset loginDate = #DateFormat(last_login, 'medium')#>
            <cfcatch>
            	<cfset loginDate = #last_login#>
            </cfcatch>
            </cftry>    
			<cfset arrUsers[i] = [#rid#, #user_id#, #group_id#, #last_login#, #number_of_logins#]>
			<cfset i = i + 1>			
		</cfloop>
		
		<!--- Calculate the Total Number of Pages for your records. --->
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		
		<!--- The JSON return. 
			Total - Total Number of Pages we will have calculated above
			Page - Current page user is on
			Records - Total number of records
			rows = our data 
		--->
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		
		<cfreturn stcReturn>
		
	</cffunction>

            
    <cffunction name="addEditMPAccounts" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
        <cfargument name="group_id" required="yes" hint="Field that was Added or editted">
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
				<cfquery name="editUser" datasource="#session.dbsource#">
					UPDATE
						mp_adm_group_users
					SET
						group_id = <cfqueryparam value="#Arguments.group_id#" cfsqltype="cf_sql_integer">
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
        	<!--- We do not support adding a user yet ---
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add.">
			---> 
        <cfelseif oper EQ "del">    
            <cfset strReturn = delMPPatch(Arguments.id)>
            <cfreturn strReturn>
		</cfif>
        
		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		
		<cfreturn strReturn>
	</cffunction>
    
    <cffunction name="delMPPatch" access="private" hint="Delete Selected MP patch" returntype="struct">		
		<cfargument name="id" required="yes" hint="id to delete">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
        <cfset var userdata = "">
		
		<cftry>
			<cfset strMsg = "Delete MP patch">
			<cfquery name="delPatch" datasource="#session.dbsource#">
				DELETE FROM mp_adm_group_users WHERE rid = #Val(Arguments.id)# AND user_id IS NOT 'mpadmin'
			</cfquery>
		<cfcatch>
			<!--- Error, return message --->
			<cfset strMsgType = "Error">
			<cfset strMsg = "Error occured when Deleting MP patch. An error report has been submitted to support.">
		</cfcatch>
		</cftry>
		
		<cfset userdata  = {type='#strMsgType#', msg='#strMsg#'}>
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