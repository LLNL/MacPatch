<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "available_patches_mp" />

	<cffunction name="getMPPatches" access="remote" returnformat="json">
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
				select puuid, pkg_url, patch_name, patch_ver, bundle_id, active,
				patch_severity, patch_reboot, patch_state, mdate, cdate
				From mp_patches
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
			<cfset arrUsers[i] = [#puuid#, #pkg_url#, #patch_name#, #patch_ver#, #bundle_id#, #patch_severity#, #patch_reboot#, #patch_state#, #active#, #DateTimeFormat( mdate, "yyyy-MM-dd HH:mm:ss" )#] >
			<cfset i = i + 1>			
		</cfloop>
		<cfset totalPages = Ceiling(selUsers.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#selUsers.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>
     
    <cffunction name="addEditMPPatch" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cftry>
				<cfquery name="editRecord" datasource="#session.dbsource#" result="res">
					UPDATE mp_patches
					SET patch_name = <cfqueryparam value="#Arguments.patch_name#">,
						patch_ver = <cfqueryparam value="#Arguments.patch_ver#">,
						patch_severity = <cfqueryparam value="#Arguments.patch_severity#">,
						patch_reboot = <cfqueryparam value="#Arguments.patch_reboot#">,
						patch_state = <cfqueryparam value="#Arguments.patch_state#">,
						active = <cfqueryparam value="#Arguments.active#">
					WHERE
						puuid = <cfqueryparam value="#arguments.id#">
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
        	<cflog log="Application" type="information" text="Delete: (#Arguments.id#)" >
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
			<cflog log="Application" type="information" text="[delMPPatch] #Arguments.id#">
			<cfloop index="pid" list="#Arguments.id#" delimiters=",">
				<cfset strMsg = "Delete MP patch">
				<cflog log="Application" type="information" text="[delMPPatch]Delete: (#pid#)">
				<cfquery name="qPatch" datasource="#session.dbsource#">
					Select * FROM mp_patches WHERE puuid = <cfqueryparam value="#pid#">
				</cfquery>

				<cfif fileExists(qPatch.pkg_path)>
					<cfset patchDirName = getDirectoryFromPath( qPatch.pkg_path ) />
					<cfif FileDelete(qPatch.pkg_path)>
						<cfset delDir = DirectoryDelete(patchDirName) />
					</cfif>
				</cfif>

				<cfquery name="delPatch" datasource="#session.dbsource#">
					DELETE FROM mp_patches WHERE puuid = <cfqueryparam value="#pid#">
				</cfquery>
				
	            <cfquery name="delPatchCriteria" datasource="#session.dbsource#">
					DELETE FROM mp_patches_criteria WHERE puuid = <cfqueryparam value="#pid#">
				</cfquery>
	            
	            <cfquery name="delPatchRequisits" datasource="#session.dbsource#">
					DELETE FROM mp_patches_requisits WHERE puuid = <cfqueryparam value="#pid#">
				</cfquery>
			</cfloop>
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