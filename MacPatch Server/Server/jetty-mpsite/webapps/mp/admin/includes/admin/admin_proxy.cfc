<cfcomponent output="false">
	<cffunction name="getProxyServer" access="remote" returnformat="json">
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
					From mp_proxy_conf
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
				From mp_proxy_conf
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
			<cfset arrUsers[i] = [#rid#, #address#, #port#, #description#, #mdate#]>
			<cfset i = i + 1>			
		</cfloop>
		

		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="editProxyServer" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
        <cfargument name="address" required="no" hint="Field that was Added or editted">
		<cfargument name="description" required="no" hint="Field that was Added or editted">
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
				<cfquery name="editProxyServer" datasource="#session.dbsource#">
					UPDATE
						mp_proxy_conf
					SET
						address = <cfqueryparam value="#Arguments.address#">,
						description = <cfqueryparam value="#Arguments.description#">
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
			<cftry>
	        	<cfquery name="addProxyServer" datasource="#session.dbsource#">
					Insert Into mp_proxy_conf (address, description, active)
					Values (<cfqueryparam value="#Arguments.address#">,<cfqueryparam value="#Arguments.description#">,<cfqueryparam value="1">)
				</cfquery>
				<cfset var pKey = genProxySrvKey()>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when adding proxy server. An Error report has been submitted to support. #cfcatch.Message# #cfcatch.ExtendedInfo#">
                </cfcatch>
			</cftry>
        <cfelseif oper EQ "del">    
            <cftry>
	        	<cfquery name="delProxyServer" datasource="#session.dbsource#">
					Delete from mp_proxy_conf
					Where rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<cfquery name="delProxyServer" datasource="#session.dbsource#">
					Delete from mp_proxy_conf
					Where rid = <cfqueryparam value="#Arguments.id#">
				</cfquery>
				<cfcatch type="any">
                    <!--- Error, return message --->
                    <cfset strMsgType = "Error">
                    <cfset strMsg = "Error occured when adding proxy server. An Error report has been submitted to support.">
                </cfcatch>
			</cftry>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>
    
	<cffunction name="genProxySrvKey" access="public">
		<cfquery name="hasProxyServerID" datasource="#session.dbsource#">
			Select * From mp_proxy_key
			Where type = <cfqueryparam value="1">
		</cfquery>
		
		<cfif hasProxyServerID.RecordCount EQ 1>
			<cfreturn mp_proxy_key.proxy_key>
		<cfelseif hasProxyServerID.RecordCount EQ 0> 
			<cfset var pKey = CreateUuid()>
			<cfquery name="addProxyServerID" datasource="#session.dbsource#">
				Insert Into mp_proxy_key (proxy_key, type)
				Values (<cfqueryparam value="#pKey#">,'1')
			</cfquery>
			<cfreturn pKey>
		<cfelse>
			<cfreturn "NA">	
		</cfif>
		
		<cfreturn />
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