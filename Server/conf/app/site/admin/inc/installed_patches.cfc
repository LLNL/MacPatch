<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "installed_patches" />

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
			Select mip.cuuid as cuuid, mip.mdate as idate, mip.patch as a_patch, mip.type, mcv.Domain, mcv.PatchGroup, mcv.hostname, mpp.patch_name as t_patch,
          	IF(mip.type_int = 1,  CONCAT(mpp.patch_name, '-', mpp.patch_ver), mip.patch) as patch
          	FROM mp_installed_patches mip
          	LEFT JOIN mp_clients_view mcv ON (mip.cuuid = mcv.cuuid)
          	LEFT JOIN mp_patches mpp ON (mip.patch = mpp.puuid)
            <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
            </cfif>

            ORDER BY #sidx# #sord#
		</cfquery>

		<cfset records = selUsers>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="selUsers" startrow="#start#" endrow="#end#">
            <cfif #cuuid# NEQ "">
				<cfset arrUsers[i] = [#i#, #cuuid#, #patch#, #hostname#, #domain#, #DateTimeFormat( idate, "yyyy-MM-dd HH:mm:ss" )#]>
                <cfset i = i + 1>
            </cfif>			
		</cfloop>

		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
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
</cfcomponent>	