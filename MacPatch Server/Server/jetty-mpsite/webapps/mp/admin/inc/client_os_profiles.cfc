<cfcomponent output="false">
	<cffunction name="getOSProfiles" access="remote" returnformat="json">
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
				select rid, profileID, profileName, profileDescription, profileRev, enabled, uninstallOnRemove
				From mp_os_config_profiles
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
			<cfset arrUsers[i] = [#profileID#, #profileName#, #profileDescription#, #profileRev#, #enabled#, #uninstallOnRemove#] >
			<cfset i = i + 1>			
		</cfloop>
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>
     
    <cffunction name="addEditOSProfiles" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cftry>
				<cfquery name="editRecord" datasource="#session.dbsource#" result="res">
					UPDATE mp_os_config_profiles
					SET profileName = <cfqueryparam value="#Arguments.profileName#">,
						profileDescription = <cfqueryparam value="#Arguments.profileDescription#">,
						enabled = <cfqueryparam value="#Arguments.enabled#">,
						uninstallOnRemove = <cfqueryparam value="#Arguments.uninstallOnRemove#">
					WHERE
						profileID = <cfqueryparam value="#arguments.id#">
				</cfquery>
                <cfcatch type="any">			
					<cfset strMsgType = "Error">
					<cfset strMsg = "There was an issue with the Edit. An Error Report has been submitted to Support.">					
				</cfcatch>		
			</cftry>
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add."> 
        <cfelseif oper EQ "del">    
            <cftry>
				<cfquery name="removeRecord" datasource="#session.dbsource#" result="res">
					Delete From mp_os_config_profiles
					WHERE profileID = <cfqueryparam value="#arguments.id#">
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
</cfcomponent>	