<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "software_packages" />

	<cffunction name="getMPSoftware" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="filters" required="no" default="">
		
		<cfset var arrSW = ArrayNew(1)>
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
				select *
				From mp_software
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
            <cfif sState EQ 0>
            	<cfset _state = "Create">
            <cfelseif sState EQ 1>
            	<cfset _state = "QA">
            <cfelseif sState EQ 2>
            	<cfset _state = "Production">
            <cfelseif sState EQ 3>
            	<cfset _state = "Disabled">
            </cfif>
			<cfset arrSW[i] = [#suuid#, #sw_url#, #sName#, #sVersion#, #IIF(sReboot EQ 0,DE("No"),DE("Yes"))#, #_state#, #sw_Type#, #DateTimeFormat( mdate, "yyyy-MM-dd HH:mm:ss" )#, #DateTimeFormat( cdate, "yyyy-MM-dd HH:mm:ss" )#] >
			<cfset i = i + 1>			
		</cfloop>
		
		<cfset totalPages = Ceiling(qSelSW.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qSelSW.recordcount#,rows=#arrSW#}>
		<cfreturn stcReturn>
	</cffunction>
     
    <cffunction name="addEditMPSoftware" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cftry>
				<cfquery name="editRecord" datasource="#session.dbsource#" result="res">
					UPDATE mp_software
					SET	 sName = <cfqueryparam value="#Arguments.sName#">,
	 					 sVersion = <cfqueryparam value="#Arguments.sVersion#">,
	 					 sReboot = <cfqueryparam value="#Arguments.sReboot#">,
						 sState = <cfqueryparam value="#Arguments.sState#">
					WHERE suuid = <cfqueryparam value="#arguments.id#">
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
</cfcomponent>	