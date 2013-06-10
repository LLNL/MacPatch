<cfcomponent output="false">
	<cffunction name="getInstalledPatches" access="remote" returnformat="json">
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

		<cfquery name="selUsers" datasource="#session.dbsource#">
			Select mip.cuuid as cuuid, mip.date as idate, mip.patch as a_patch, mip.type, mcv.Domain, mcv.PatchGroup, mcv.hostname, mpp.patch_name as t_patch,
          	IF(UCASE(mip.type) = 'THIRD',  CONCAT(mpp.patch_name, '-', mpp.patch_ver), mip.patch) as patch
          	FROM mp_installed_patches mip
          	LEFT JOIN mp_clients_view mcv ON (mip.cuuid = mcv.cuuid)
          	LEFT JOIN mp_patches mpp ON (mip.patch = mpp.puuid)
            <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
            </cfif>

            ORDER BY #sidx# #sord#
		</cfquery>

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
            <!--- DateFormat(postdate,"yyyy-mm-dd") --->
			
            <cfif #cuuid# NEQ "">
				<cfset arrUsers[i] = [#i#, #cuuid#, #patch#, #hostname#, #domain#, #idate#]>
                <cfset i = i + 1>
            </cfif>			
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

            
    <cffunction name="addEditInstalledPatches" access="remote" hint="Add or Edit" returnformat="json" output="no">
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
    
    <cffunction name="delMPPatch" access="private" hint="Delete Selected MP patch" returntype="struct">		
		<cfargument name="id" required="yes" hint="id to delete">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
        <cfset var userdata = "">
		
		<cftry>
			<cfset strMsg = "Delete MP patch">
            <!---
			<cfquery name="delPatch" datasource="#session.dbsource#">
				DELETE FROM mp_patches WHERE puuid = #Val(Arguments.id)#
			</cfquery>
            --->
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

</cfcomponent>	