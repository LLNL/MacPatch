<cfcomponent output="false">
	<cffunction name="getMPPatches" access="remote" returnformat="json">
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
					From mp_baseline
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
				From mp_baseline
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
			<!--- Array that will be passed back needed by jqGrid JSON implementation --->
			<CFSWITCH EXPRESSION="#state#">
			<CFCASE VALUE="0">
				<cfset l_state = "Inactive">
			</CFCASE>
			<CFCASE VALUE="1">
				<cfset l_state = "Production">
			</CFCASE>
			<CFCASE VALUE="2">	
				<cfset l_state = "QA">
			</CFCASE>
			</CFSWITCH>
			
            <cfset cdateNew = #DateFormat(cdate, "yyyy-mm-dd")# & " " & #TimeFormat(cdate, "HH:mm:ss")#>
            <cfset mdateNew = #DateFormat(mdate, "yyyy-mm-dd")# & " " & #TimeFormat(mdate, "HH:mm:ss")#>
			<cfset arrUsers[i] = [#baseline_id#, #name#, #description#, #cdateNew#, #mdateNew#, #l_state#]>
			<cfset i = i + 1>			
		</cfloop>

		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>		
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>
    
    <cffunction name="getMPBaselinePatches" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
        <cfargument name="searchType" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">
		
		<cfset var arrUsers = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = false>
		<cfset var strSearch = "">	
        
        <cfif Arguments.searchType>
        	<cfset Arguments._search = true>
        </cfif>
        
		<cfif Arguments._search>
			<cfset strSearch = buildSearchString(Arguments.searchField,Arguments.searchOper,Arguments.searchString)>
			<cfset blnSearch = true>            
		</cfif>
        
        <cfquery name="selUsers" datasource="#session.dbsource#" result="res">
                select *
				From mp_baseline_patches
                <!--- Join mp_baseline on baseline_id = baseline_id --->
                <cfif blnSearch>
                Where
					#PreserveSingleQuotes(strSearch)#
                </cfif>
                ORDER BY #sidx# #sord#				
            </cfquery>
        
		<cfset records = selUsers>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
			<cfset arrUsers[i] = [#rid#, #baseline_enabled#, #p_name#, #p_version#, #p_type#, #p_postdate#]>
			<cfset i = i + 1>			
		</cfloop>
		
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		
		<cfreturn stcReturn>
		
	</cffunction>
	<cffunction name="addEditMPBaselinePatches" access="remote" hint="Add or Edit" returnformat="json" output="no">
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
			<cfloop list="#Arguments.id#" index="item" delimiters=",">
				<cfquery name="delPatch" datasource="#session.dbsource#">
					DELETE FROM mp_baseline_patches WHERE rid = <cfqueryPARAM value="#item#">
				</cfquery>
        	</cfloop>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
    </cffunction>
            
    <cffunction name="addEditMPBaseline" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, Edit patch baseline #Arguments.ID#.">
            <cftry>
            <cfquery name="editBaseline" datasource="#session.dbsource#" result="res">
            Update
            	mp_baseline
            Set
            	name		= '#name#',
            	description = '#description#', 
                mdate = #CreateODBCDateTime(now())#, 
                state = '#state#'  
            Where
            	baseline_id = '#Arguments.ID#'
            AND
            	cdate = '#cdate#'    
            </cfquery>
            <cfcatch type="any">
            	<cfset strMsgType = "Error">
            	<cfset strMsg = "Error occured when Editting User. An Error report has been submitted to support. #cfcatch.detail# -- #cfcatch.message#">
            </cfcatch>
            </cftry>
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add."> 
        <cfelseif oper EQ "del"> 
            <cfquery name="delPatch" datasource="#session.dbsource#">
				DELETE FROM mp_baseline WHERE baseline_id = '#Arguments.id#'
			</cfquery>
            <cfquery name="delPatch" datasource="#session.dbsource#">
				DELETE FROM mp_baseline_patches WHERE baseline_id = '#Arguments.id#'
			</cfquery>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
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

	<cffunction name="toggleBaselinePatch" access="remote" returnformat="json">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cftry>
        	<cfquery name="checkIt" datasource="#session.dbsource#">
                Select baseline_enabled From mp_baseline_patches
                where rid = <cfqueryparam value="#Arguments.id#">
            </cfquery>
            <cfif checkIt.RecordCount EQ 1>        
                <cfquery name="setIt" datasource="#session.dbsource#">
                    Update mp_baseline_patches
                    Set baseline_enabled = <cfqueryparam value="#IIF(checkIt.baseline_enabled EQ '1', DE('0'),DE('1'))#">
                    where rid = <cfqueryparam value="#Arguments.id#">
                </cfquery>
            </cfif>
        	<cfcatch type="any">
            	<cfset strMsgType = "Error">
            	<cfset strMsg = "Error occured while setting baseline state. #cfcatch.detail# -- #cfcatch.message#">
            </cfcatch>
        </cftry>
			
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>
    
</cfcomponent>	