<cfcomponent output="false">
	<cffunction name="getMPAccounts" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
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
				Select b.rid, b.user_id, b.user_type, b.group_id, b.last_login, b.number_of_logins, b.enabled, b.user_email, b.email_notification
                from mp_adm_group_users b
                LEFT Join mp_adm_users a ON a.user_id = b.user_id
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
            <cftry>
            	<cfset loginDate = #DateFormat(last_login, 'medium')#>
            <cfcatch>
            	<cfset loginDate = #last_login#>
            </cfcatch>
            </cftry>    
			<cfswitch expression="#group_id#"> 
			    <cfcase value="0"> 
					<cfset gType = "Admin">
			    </cfcase> 
			    <cfcase value="1"> 
					<cfset gType = "User">
			    </cfcase> 
			    <cfcase value="2"> 
					<cfset gType = "AutoPKG">
			    </cfcase> 
			    <cfdefaultcase> 
			    	<cfset gType = "User">
			    </cfdefaultcase> 
			</cfswitch> 
			<cfswitch expression="#enabled#"> 
			    <cfcase value="0"> 
					<cfset eType = "No">
			    </cfcase> 
			    <cfcase value="1"> 
					<cfset eType = "Yes">
			    </cfcase> 
			    <cfdefaultcase> 
			    	<cfset eType = "Yes">
			    </cfdefaultcase> 
			</cfswitch> 
			<cfswitch expression="#email_notification#"> 
			    <cfcase value="0"> 
					<cfset enType = "No">
			    </cfcase> 
			    <cfcase value="1"> 
					<cfset enType = "Yes">
			    </cfcase> 
			    <cfdefaultcase> 
			    	<cfset enType = "No">
			    </cfdefaultcase> 
			</cfswitch> 
			<cfswitch expression="#user_type#"> 
			    <cfcase value="0"> 
					<cfset uType = "Local">
			    </cfcase> 
			    <cfcase value="1"> 
					<cfset uType = "Database">
			    </cfcase> 
			    <cfcase value="2"> 
			        <cfset uType = "Directory/LDAP">
			    </cfcase> 
			    <cfdefaultcase> 
			    	<cfset uType = "Undefined">
			    </cfdefaultcase> 
			</cfswitch> 
			<cfset arrUsers[i] = [#rid#, #user_id#, #uType#, #gType#, #last_login#, #number_of_logins#, #eType#, #user_email#, #enType#]>
			<cfset i = i + 1>			
		</cfloop>

		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>		
		<cfreturn stcReturn>
	</cffunction>
  
    <cffunction name="addEditMPAccounts" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		<cfargument name="oper" required="no" default="edit" hint="Whether this is an add or edit">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit."> 
		<cfelseif oper EQ "add">
        	<!--- We do not support adding ---
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add.">
			---> 
        <cfelseif oper EQ "del">    
            <cftry>
				<cfquery name="qIsDBUser" datasource="#session.dbsource#">
					Select * from mp_adm_group_users
					WHERE rid = #Val(Arguments.id)#
					AND user_type = '1'
				</cfquery>
				<cfif qIsDBUser.RecordCount NEQ 1>
					<cfset strMsgType = "Notice">
                    <cfset strMsg = "User is not of type that supports being deleted.">
				<cfelse>
					<cfif #qIsDBUser.user_id# NEQ #session.Username#>
						<cfquery name="removeUser" datasource="#session.dbsource#">
							Delete from mp_adm_users
							Where user_id = <cfqueryparam value="#qIsDBUser.user_id#">
						</cfquery>
						<cfquery name="removeUserGrp" datasource="#session.dbsource#">
							Delete from mp_adm_group_users
							Where rid = <cfqueryparam value="#Arguments.id#">
						</cfquery>
					</cfif>
				</cfif>
                <cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when Editting User. An Error report has been submitted to support. #cfcatch.Detail#">
                </cfcatch>
			</cftry>
		</cfif>

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