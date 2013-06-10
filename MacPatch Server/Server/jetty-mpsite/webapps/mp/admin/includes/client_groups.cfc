<cfcomponent output="false">
	<cffunction name="getClientsForGroup" access="remote" returnformat="json">
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
	    <cfargument name="orderedCols" required="no" default="">
	    
        
        <cfargument name="clientgroup" required="yes" default="" hint="patchgroup">
		
		<cfset var arrUsers = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = false>
		<cfset var strSearch = "">
        <cfset var hasHWData = false>
        
        <cfif IsDefined("Arguments.clientgroup") AND Len(Arguments.clientgroup) GTE 2>
        	<cfset cGroup = #Arguments.clientgroup#>
        <cfelse>
        	<cfset cGroup = "%">
        </cfif>    
        <cfif Arguments.searchType>
        	<cfset Arguments._search = true>
        </cfif>
        
        <cftry>
            <cfquery name="hasHW" datasource="#session.dbsource#">
                SELECT hw.mpa_Model_Name, hw.mpa_Model_Identifier FROM mpi_SPHardwareOverview hw LIMIT 0,1
            </cfquery>
            <cfcatch type="any">
                <cfset hasHWData = false>				
            </cfcatch>		
        </cftry>
        <cfif #hasHW.RecordCount# EQ 1>
        	<cfset hasHWData = true>
        </cfif>
        
        
		<cfif Arguments._search>
			<cfset strSearch = buildSearchString(Arguments.searchField,Arguments.searchOper,Arguments.searchString)>
			<cfset blnSearch = true>
			<cftry>
				<cfquery name="selUsers" datasource="#session.dbsource#" result="res">
                	SELECT	cci.*, sav.defsDate
                    <cfif hasHWData EQ true>
                    	, hw.mpa_Model_Name, hw.mpa_Model_Identifier
                    </cfif>
                    FROM	mp_clients_view cci
                    LEFT 	JOIN savav_info sav 
                    ON cci.cuuid = sav.cuuid
                    <cfif hasHWData EQ true>
                    	LEFT JOIN mpi_SPHardwareOverview hw ON
                    	cci.cuuid = hw.cuuid
                    </cfif>    
                    Where 
                    	cci.Domain like '#cGroup#'        
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
                	SELECT	cci.*, sav.defsDate
                    <cfif hasHWData EQ true>
                    	, hw.mpa_Model_Name, hw.mpa_Model_Identifier
                    </cfif>
                    FROM	mp_clients_view cci
                    LEFT 	JOIN savav_info sav 
                    ON cci.cuuid = sav.cuuid
                    <cfif hasHWData EQ true>
                    	LEFT JOIN mpi_SPHardwareOverview hw ON
                    	cci.cuuid = hw.cuuid
                    </cfif>  
                    Where 
                    	cci.Domain like '#cGroup#'  
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
			<cfset _dataArr = ArrayNew(1)>
			<cfloop list="#arguments.orderedCols#" index="col" delimiters=",">
				<cfif col EQ "cdate" OR col EQ "mdate" OR col EQ "sdate" OR col EQ "date"> 
					<cfset _dts = #DateFormat(evaluate(col), "mm/dd/yyyy")# & " " & #TimeFormat(evaluate(col), "HH:mm:ss")#>
					<cfset x = ArrayAppend(_dataArr,_dts)>
				<cfelse>
					<cfset _x = ArrayAppend(_dataArr,evaluate(col))>
				</cfif>
			</cfloop>

            <cfif hasHWData EQ true>
				<cfset _arr = ArrayAppend(arrUsers,_dataArr)>	
			<cfelse>
				<cfset _arr = ArrayAppend(arrUsers,_dataArr)>
            </cfif>  
			<cfset i = i + 1>			
		</cfloop>
		

		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editClientsForGroup" access="remote" hint="Add or Edit" returnformat="json" output="no">
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
            <cfset strReturn = delMPPatch(Arguments.id)>
            <cfreturn strReturn>
		</cfif>
        
		<!--- We just need to pass back some user data for display purposes --->
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		
		<cfreturn strReturn>
	</cffunction>
    
    <cffunction name="delMPPatch" access="private" hint="Delete Selected MP Client" returntype="struct">		
		<cfargument name="id" required="yes" hint="id to delete">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
        <cfset var userdata = "">
        
		<cfloop index="index_name" list="#Arguments.id#" delimiters=",">
		
	        <cfquery name="ClientInfo" datasource="#session.dbsource#">
	            Select * FROM mp_clients_view WHERE cuuid = '#index_name#'
	        </cfquery>
	        
	        <cfset strMsg = "Delete MP Client">
	            <cflog type="Error" file="MPDeleteClient" text="DELETE FROM mp_clients_view WHERE cuuid = #index_name#">
	            <cfinvoke component="ws_logger" method="LogEvent">
	                <cfinvokeargument name="aEventType" value="Info">
	                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
	                <cfinvokeargument name="aEvent" value="[Delete Client]: #Session.Username# deleted client (#index_name#, #ClientInfo.hostname#, #ClientInfo.ipaddr#)">
	            </cfinvoke>
			
			<cftry>
	            <cfinvoke component="remove_Client" method="removeClient">
	                <cfinvokeargument name="id" value="#index_name#">
	            </cfinvoke>
	            <!--- 
				<cfquery name="delPatch" datasource="#session.dbsource#">
					DELETE FROM ClientCheckIn WHERE cuuid = '#Arguments.id#'
				</cfquery>
	            --->
			<cfcatch type="any">
				<!--- Error, return message --->
				<cfset strMsgType = "Error">
				<cfset strMsg = "Error occured when Deleting MP client (#index_name# -- #session.dbsource#). An error report has been submitted to support. #cfcatch.Detail# -- #cfcatch.Message#">
			</cfcatch>
			</cftry>
		
		</cfloop>
		
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