<cfcomponent output="false">
	<cffunction name="getMPSoftware" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">
		
		<cfset var arrSW = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = false>
		<cfset var strSearch = "">	
        
		<cfif Arguments._search>
			<cfset strSearch = buildSearchString(Arguments.searchField,Arguments.searchOper,Arguments.searchString)>
			<cfset blnSearch = true>
			<cftry>
				<cfquery name="qSelSW" datasource="#session.dbsource#" result="res">
					select *
					From mp_software
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
            <cfquery name="qSelSW" datasource="#session.dbsource#" result="res">
                select *
				From mp_software
                Where 0=0
                <cfif blnSearch>
                    AND 
                        #PreserveSingleQuotes(strSearch)#
                </cfif>
                ORDER BY #sidx# #sord#				
            </cfquery>
		</cfif>
        
		<cfset records = qSelSW>
		
		<!--- Calculate the Start Position for the loop query.
		So, if you are on 1st page and want to display 4 rows per page, for first page you start at: (1-1)*4+1 = 1.
		If you go to page 2, you start at (2-)1*4+1 = 5  --->
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		
		<!--- Calculate the end row for the query. So on the first page you go from row 1 to row 4. --->
		<cfset end = (start-1) + arguments.rows>
		
		<!--- When building the array --->
		<cfset i = 1>

		<cfloop query="qSelSW" startrow="#start#" endrow="#end#">
			<!--- Array that will be passed back needed by jqGrid JSON implementation --->
            <cfif sState EQ 0>
            	<cfset _state = "Create">
            <cfelseif sState EQ 1>
            	<cfset _state = "QA">
            <cfelseif sState EQ 2>
            	<cfset _state = "Production">
            <cfelseif sState EQ 3>
            	<cfset _state = "Disabled">
            </cfif>
			<cfset arrSW[i] = [#suuid#, #sw_url#, #sName#, #sVersion#, #IIF(sReboot EQ 0,DE("No"),DE("Yes"))#, #_state#, #sw_Type#, #DateFormat(mdate, 'medium')#, #DateFormat(cdate, 'medium')#] >
			<cfset i = i + 1>			
		</cfloop>
		
		<!--- Calculate the Total Number of Pages for your records. --->
		<cfset totalPages = Ceiling(qSelSW.recordcount/arguments.rows)>
		
		<!--- The JSON return. 
			Total - Total Number of Pages we will have calculated above
			Page - Current page user is on
			Records - Total number of records
			rows = our data 
		--->
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qSelSW.recordcount#,rows=#arrSW#}>
		
		<cfreturn stcReturn>
		
	</cffunction>

            
    <cffunction name="addEditMPSoftware" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit."> 
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add."> 
        <cfelseif oper EQ "del">    
            <cfset strReturn = delMPSoftwareDist(Arguments.id)>
            <cfreturn strReturn>
		</cfif>
        
		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		
		<cfreturn strReturn>
	</cffunction>
    
    <cffunction name="delMPSoftwareDist" access="private" hint="Delete Selected MP Software" returntype="struct">		
		<cfargument name="id" required="yes" hint="id to delete">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
        <cfset var userdata = "">
		
		<cftry>
			<cfset strMsg = "Delete MP patch">
			<cfquery name="delPatch" datasource="#session.dbsource#">
				DELETE FROM mp_software WHERE suuid = <cfqueryparam value="#Arguments.id#">
			</cfquery>
			
            <cfquery name="delPatchCriteria" datasource="#session.dbsource#">
				DELETE FROM mp_software_criteria WHERE suuid = <cfqueryparam value="#Arguments.id#">
			</cfquery>
            <cfquery name="delPatchRequisits" datasource="#session.dbsource#">
				DELETE FROM mp_software_requisits WHERE suuid = <cfqueryparam value="#Arguments.id#">
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