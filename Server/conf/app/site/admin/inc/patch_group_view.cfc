<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "patch_group_view" />

	<cffunction name="getPatchGroupPatches" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
	    <cfargument name="_search" required="no" default="false" hint="Whether search is performed by user on data grid">
	    <cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">
        <cfargument name="filters" required="no" default="">
        
        <cfargument name="patchgroup" required="yes" default="RecommendedPatches" hint="patchgroup">
	
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
        	<cfoutput>
        	<cfsavecontent variable="theQuery">
            	select distinct id, name, title, type, postdate
                From mp_patch_group_patches a
                Left Join combined_patches_view b
                ON a.patch_id = b.id
                
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND
                    a.patch_group_id = '#Arguments.patchgroup#'
                <cfelse>
                    Where 
                    a.patch_group_id = '#Arguments.patchgroup#'   
                </cfif>
                ORDER BY #sidx# #sord#	
            </cfsavecontent>
            </cfoutput>
            <cflog application="yes" text="#theQuery#">
            <cfquery name="selUsers" datasource="#session.dbsource#" result="res">
                select distinct id, name, title, type, postdate
                From mp_patch_group_patches a
                Left Join combined_patches_view b
                ON a.patch_id = b.id
                
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND
                    a.patch_group_id = '#Arguments.patchgroup#'
                <cfelse>
                    Where 
                    a.patch_group_id = '#Arguments.patchgroup#'   
                </cfif>
                ORDER BY #sidx# #sord#				
            </cfquery>
            
            <cfcatch>
                <cflog application="yes" text="#cfcatch.Detail#">
                <cfabort>
            </cfcatch>
        </cftry>
		<cfset records = selUsers>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
            <cfif #id# NEQ "">
				<cfset arrUsers[i] = [#id#, #name#, #title#, #type#, #DateTimeFormat( postdate, "yyyy-MM-dd HH:mm:ss" )#]>
                <cfset i = i + 1>
            </cfif>			
		</cfloop>
		
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
        <cflog application="yes" text="#serializejson(stcReturn)#">
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="addEditgetPatchGroupPatches" access="remote" hint="Add or Edit" returnformat="json" output="no">
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