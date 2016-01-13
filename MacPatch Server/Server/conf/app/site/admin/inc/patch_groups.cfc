<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "patch_groups" />

	<cffunction name="getPatchGroups" access="remote" returnformat="json">
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
        	<cfsavecontent variable="one">
            <cfoutput>
				 Select a.name, b.user_id, b.is_owner, b.patch_group_id, a.type,
                (select COUNT(*) As total From mp_clients_view c Where c.PatchGroup = a.name) as cTotal
                From mp_patch_group a
                Left Join mp_patch_group_members b
                ON a.id = b.patch_group_id
                
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND b.is_owner=1  
                <cfelse>  
                	Where b.is_owner=1  
            	</cfif>
				
				ORDER BY #sidx# #sord#
			</cfoutput>
            </cfsavecontent>
            <cflog application="yes" type="error" text="#one#">
        
			<cfquery datasource="#session.dbsource#" name="qGetGroups">
                Select a.name, b.user_id, b.is_owner, b.patch_group_id, a.type,
                (select COUNT(*) As total From mp_clients_view c Where c.PatchGroup = a.name) as cTotal
                From mp_patch_group a
                Left Join mp_patch_group_members b
                ON a.id = b.patch_group_id
                
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND b.is_owner=1  
                <cfelse>  
                	Where b.is_owner=1  
            	</cfif>
				
				ORDER BY #sidx# #sord#
            </cfquery>
			
            <cfcatch type="any">
				<cfset blnSearch = false>					
				<cfset strMsgType = "Error">
				<cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">					
			</cfcatch>		
		</cftry>
        
		<cfset records = qGetGroups>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>
	
		<cfloop query="qGetGroups" startrow="#start#" endrow="#end#">
        	<cfif #type# EQ "0"><cfset _type = "Production"><cfelseif #type# EQ "1"><cfset _type = "QA"><cfelseif #type# EQ "2"><cfset _type = "Dev"></cfif>
			<cfset arrUsers[i] = [#patch_group_id#, #name#, #user_id#, #is_owner#, #_type#, #hasRights(session.username,patch_group_id)#, #cTotal#, #DateTimeFormat( now(), "yyyy-MM-dd HH:mm:ss" )#] >
			<cfset i = i + 1>			
		</cfloop>
		<cfset totalPages = Ceiling(qGetGroups.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qGetGroups.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>

	<cffunction name="addEditPatchGroups" access="remote" hint="Add or Edit" returnformat="json" output="no">
    	<cfargument name="id" required="no" hint="Field that was editted">
        
        <cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit."> 
			
			<cfquery datasource="#session.dbsource#" name="qEditPathcGroup1">
				Update mp_patch_group
				Set type = <cfqueryparam value="#Arguments.type#">,
				name = <cfqueryparam value="#Arguments.name#">
				where id = <cfqueryparam value="#Arguments.id#">
			</cfquery>
			
			<cfquery datasource="#session.dbsource#" name="qEditPathcGroup2">
				Update mp_patch_group_members
				Set user_id = <cfqueryparam value="#Arguments.user_id#">
				where patch_group_id = <cfqueryparam value="#Arguments.id#">
				AND is_owner = 1
			</cfquery>
			
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add."> 
            <cftry>
				<cfset gid = #CreateUUID()#>
                <cfquery datasource="#session.dbsource#" name="qInsertPathcGroup1">
                    INSERT INTO mp_patch_group_members (`user_id`, `patch_group_id`, `is_owner`)
                    VALUES ('#Arguments.user_id#', '#gid#', 1);
                </cfquery>
                <cfquery datasource="#session.dbsource#" name="qInsertPathcGroup2">
                    INSERT INTO mp_patch_group (name, id, type)
                    VALUES ('#Arguments.name#', '#gid#', '#Arguments.type#');
                </cfquery>
                <cfcatch type="any">
                    <cflog application="yes" text="#cfcatch.Detail# #cfcatch.sql# " type="error">				
                </cfcatch>		
            </cftry>
        <cfelseif oper EQ "del">    
			<cfset strMsgType = "Del">
			<cfset strMsg = "Notice, MP del."> 
            <cflog application="yes" text="Delete record #Arguments.id# " type="error">	
            <cftry>
            	<cfquery datasource="#session.dbsource#" name="qDelPathcGroup1">
                    Delete From mp_patch_group_patches Where patch_group_id = <cfqueryparam value="#Arguments.id#">
                </cfquery>
                <cfquery datasource="#session.dbsource#" name="qDelPathcGroup2">
                    Delete From mp_patch_group_members Where patch_group_id = <cfqueryparam value="#Arguments.id#">
                </cfquery>
                <cfquery datasource="#session.dbsource#" name="qDelPathcGroup3">
                    Delete From mp_patch_group_data Where pid = <cfqueryparam value="#Arguments.id#">
                </cfquery>
                <cfquery datasource="#session.dbsource#" name="qDelPathcGroup4">
                    Delete From mp_patch_group Where id = <cfqueryparam value="#Arguments.id#">
                </cfquery>
                <cfcatch type="any">
                    <cflog application="yes" text="#cfcatch.Detail# #cfcatch.sql# " type="error">				
                </cfcatch>	
            </cftry>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
    </cffunction>
    
    <cffunction name="hasRights" access="public" returnType="numeric" output="no">
        <cfargument name="user_id" required="yes">
        <cfargument name="patch_group_id" required="yes">
        
        <cfquery datasource="#session.dbsource#" name="qGet">
            Select a.name, b.user_id, b.is_owner
            From mp_patch_group a
            Left Join 
                mp_patch_group_members b
            ON 
                a.id = b.patch_group_id
            Where 
                b.patch_group_id = '#Arguments.patch_group_id#'
            AND 
                b.user_id = '#Arguments.user_id#'
        </cfquery>
        
        <cfset returnVal=0>
        
        <cfif #qGet.recordcount# EQ 1>
        	
            <!--- We know we are assigned, so we can edit --->
            <cfset returnVal=returnVal+1>
            <cfif qGet.is_owner EQ "1">
                <!--- We know we are the owner, so we can delete --->
                <cfset returnVal=returnVal+1> 
            </cfif>
        </cfif>
        <cfif #session.IsAdmin# EQ true>
            <cfset returnVal=2>
        </cfif>
        <cfreturn returnVal>
    </cffunction>
    
</cfcomponent>	