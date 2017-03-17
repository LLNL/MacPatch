<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "patch_group_edit" />

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
        	<!--- Set up Patch Group Patches Filter --->
        	<cfset var gType = "'Production'">
        	<cfquery datasource="#session.dbsource#" name="qGetGroupType">
            	Select id, type from mp_patch_group
                Where id = '#Arguments.patchgroup#'
            </cfquery>
            <cfif qGetGroupType.RecordCount EQ 1>
            	<cfif qGetGroupType.type EQ 0>
                	<cfset gType = "'Production'">
                <cfelseif qGetGroupType.type EQ 1>
                	<cfset gType = "'Production','QA'">
                <cfelseif qGetGroupType.type EQ 1>
                	<cfset gType = "'Production','QA','Dev'">
                </cfif>
            <cfelse>
                <cfset gType = "'Production'">
            </cfif>

            <cfquery datasource="#session.dbsource#" name="qGetPatches">
                SELECT DISTINCT
                    b.*, IFNULL(p.patch_id,'NA') as Enabled
                FROM
                    combined_patches_view b
                LEFT JOIN (
                    SELECT patch_id FROM mp_patch_group_patches
                    Where patch_group_id = '#Arguments.patchgroup#'
                ) p ON p.patch_id = b.id

                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND
                    b.patch_state IN (#PreserveSingleQuotes(gType)#)
                <cfelse>
                    WHERE
                    b.patch_state IN (#PreserveSingleQuotes(gType)#)
                </cfif>
                ORDER BY #sidx# #sord#
            </cfquery>

            <cfcatch type="any">
            	<cfset logError("patch_group_edit","getPatchGroupPatches",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
                <cfset totalPages = 0>
				<cfset stcReturn = {}>
                <cfreturn stcReturn>
            </cfcatch>
        </cftry>

		<cfset records = qGetPatches>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>

		<cfset i = 1>
		<cfloop query="qGetPatches" startrow="#start#" endrow="#end#">
        	<cfset selected = #IIF(Enabled EQ "NA",DE('0'),DE('1'))#>
            <cfset arrUsers[i] = [#id#, #id#, #selected#, #name#, #title#, #Reboot#, #type#, #patch_state#, #DateTimeFormat( postdate, "yyyy-MM-dd HH:mm:ss" )#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qGetPatches.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qGetPatches.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>

	<cffunction name="togglePatch" access="remote" returnformat="json">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cftry>
        	<cfquery name="checkIt" datasource="#session.dbsource#">
                Select rid From mp_patch_group_patches
                where patch_id = <cfqueryparam value="#Arguments.id#">
                AND patch_group_id = <cfqueryparam value="#Arguments.gid#">
            </cfquery>
            <cfif checkIt.RecordCount EQ 0>
            	<cfquery name="setIt" datasource="#session.dbsource#">
                    Insert Into mp_patch_group_patches (patch_id,patch_group_id)
                    Values (<cfqueryparam value="#Arguments.id#">,<cfqueryparam value="#Arguments.gid#">)
                </cfquery>
                <!--- Record Patch History --->
				<cfset r = recordHistory(Arguments.id,Arguments.gid,"1")>
            </cfif>
			<cfif checkIt.RecordCount EQ 1>
                <cfquery name="remIt" datasource="#session.dbsource#">
                    Delete from mp_patch_group_patches
                    where patch_id = <cfqueryparam value="#Arguments.id#">
                	AND patch_group_id = <cfqueryparam value="#Arguments.gid#">
                </cfquery>
                <!--- Record Patch History --->
				<cfset r = recordHistory(Arguments.id,Arguments.gid,"0")>
            </cfif>
        	<cfcatch type="any">
        		<cfset logError("patch_group_edit","togglePatch",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
            	<cfset strMsgType = "Error">
            	<cfset strMsg = "Error occured while setting baseline state. #cfcatch.detail# -- #cfcatch.message#">
            </cfcatch>
        </cftry>

		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>

    <cffunction name="savePatchGroupData" access="remote" returnformat="json">
		<cfargument name="id" required="no" hint="Field that was editted">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

        <cfset xObj = CreateObject("component","patch_group_save").init(session.dbsource)>

        <cfset _d = RemovePatchGroupData(Arguments.id)>
		<!--- JSON 2.2.x --->
		<cfset _dts = "#DateFormat(now(),"YYYYMMDD")##TimeFormat(now(),"HHMMSS")#" />
        <cfset _x = xObj.GetPatchGroupPatches(Arguments.id)>
        <cfset _d = deserializeJSON(_x) />
        <cfset _d[ "rev" ] = '#_dts#' />
        <cfset _x = SerializeJSON(_d) />
        <cfset _a = AddPatchGroupData(Arguments.id,_x,'JSON',_dts)>
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>

    <cffunction name="RemovePatchGroupData" returntype="any" output="no" access="private">
        <cfargument name="PatchGroupID">

        <cftry>
	        <cfquery datasource="#session.dbsource#" name="qDelete">
	            Delete
	            From mp_patch_group_data
	            Where
	                pid = '#arguments.PatchGroupID#'
	        </cfquery>

	        <cfreturn 1>
        <cfcatch>
        	<cfset logError("patch_group_edit","RemovePatchGroupData",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
        	<cfreturn 1>
    	</cfcatch>
        </cftry>

        <cfreturn -1>
    </cffunction>

    <cffunction name="AddPatchGroupData" returntype="any" output="no" access="private">
        <cfargument name="PatchGroupID">
        <cfargument name="PatchGroupData">
        <cfargument name="PatchGroupDataType">
        <cfargument name="PatchGroupDataRev">

        <cftry>
            <cfset _hash = hash(#arguments.PatchGroupData#, "MD5")>
            
            <cfquery datasource="#session.dbsource#" name="qPut">
                Insert Into mp_patch_group_data (pid, hash, data, data_type, mdate, rev)
                Values ('#arguments.PatchGroupID#', '#_hash#', '#arguments.PatchGroupData#', '#arguments.PatchGroupDataType#', #CreateODBCDateTime(now())#, '#arguments.PatchGroupDataRev#')
            </cfquery>
        <cfcatch>
        	<cfset logError("patch_group_edit","AddPatchGroupData",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
    	</cfcatch>
        </cftry>
    </cffunction>

	<cffunction name="SelectAll" access="remote" returnformat="json" output="no">
		<cfargument name="patchgroup" required="yes" default="RecommendedPatches" hint="patchgroup">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cftry>
			<!--- Get Group ID --->
			<cfquery datasource="#session.dbsource#" name="qGetGroupID">
				Select id from mp_patch_group
				Where id = '#Arguments.patchgroup#'
			</cfquery>
			<cfif qGetGroupID.RecordCount EQ 0>
				<cfreturn strReturn>
			<cfelse>
				<cfset gid = qGetGroupID.id>
			</cfif>
			<!--- Get All Production Patches --->
			<cfquery name="qPatches" datasource="#session.dbsource#" result="res">
				SELECT DISTINCT id, name, type
				FROM combined_patches_view
				Where patch_state like 'Production'
			</cfquery>

			<cfoutput query="qPatches">
				<cfset x = selectPatch(id,gid)>
			</cfoutput>

        	<cfcatch type="any">
        		<cfset logError("patch_group_edit","SelectAll",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
				<cfset strMsgType = "Error">
				<cfset strMsg = "<cfoutput>#cfcatch.message##cfcatch.detail#</cfoutput>">
			</cfcatch>
		</cftry>

		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>

	<cffunction name="SelectApple" access="remote" returnformat="json" output="no">
		<cfargument name="patchgroup" required="yes" default="RecommendedPatches" hint="patchgroup">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cftry>
			<!--- Get Group ID --->
			<cfquery datasource="#session.dbsource#" name="qGetGroupID">
				Select id from mp_patch_group
				Where id = '#Arguments.patchgroup#'
			</cfquery>
			<cfif qGetGroupID.RecordCount EQ 0>
				<cfreturn strReturn>
			<cfelse>
				<cfset gid = qGetGroupID.id>
			</cfif>
			<!--- Get All Production Patches --->
			<cfquery name="qPatches" datasource="#session.dbsource#" result="res">
				SELECT DISTINCT id, name, type
				FROM combined_patches_view
				Where patch_state like 'Production'
				AND type = 'Apple'
			</cfquery>

			<cfoutput query="qPatches">
				<cfset x = selectPatch(id,gid)>
			</cfoutput>

        	<cfcatch type="any">
        		<cfset logError("patch_group_edit","SelectApple",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
				<cfset strMsgType = "Error">
				<cfset strMsg = "<cfoutput>#cfcatch.message##cfcatch.detail#</cfoutput>">
			</cfcatch>
		</cftry>

		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>

	<cffunction name="SelectCustom" access="remote" returnformat="json" output="no">
		<cfargument name="patchgroup" required="yes" default="RecommendedPatches" hint="patchgroup">

		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">

		<cftry>
			<!--- Get Group ID --->
			<cfquery datasource="#session.dbsource#" name="qGetGroupID">
				Select id from mp_patch_group
				Where id = '#Arguments.patchgroup#'
			</cfquery>
			<cfif qGetGroupID.RecordCount EQ 0>
				<cfreturn strReturn>
			<cfelse>
				<cfset gid = qGetGroupID.id>
			</cfif>
			<!--- Get All Production Patches --->
			<cfquery name="qPatches" datasource="#session.dbsource#" result="res">
				SELECT DISTINCT id, name, type
				FROM combined_patches_view
				Where patch_state like 'Production'
				AND type = 'Third'
			</cfquery>

			<cfoutput query="qPatches">
				<cfset x = selectPatch(id,gid)>
			</cfoutput>

        	<cfcatch type="any">
        		<cfset logError("patch_group_edit","SelectCustom",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
				<cfset strMsgType = "Error">
				<cfset strMsg = "<cfoutput>#cfcatch.message##cfcatch.detail#</cfoutput>">
			</cfcatch>
		</cftry>

		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>

	<cffunction name="selectPatch" access="private" hint="Build our Search Parameters">
		<cfargument name="id" required="true">
		<cfargument name="gid" required="true">

		<cftry>
			<cfquery name="checkIt" datasource="#session.dbsource#">
				Select rid From mp_patch_group_patches
				where patch_id = <cfqueryparam value="#Arguments.id#">
				AND patch_group_id = <cfqueryparam value="#Arguments.gid#">
			</cfquery>
			<cfif checkIt.RecordCount EQ 0>
				<cfquery name="setIt" datasource="#session.dbsource#">
					Insert Into mp_patch_group_patches (patch_id,patch_group_id)
					Values (<cfqueryparam value="#Arguments.id#">,<cfqueryparam value="#Arguments.gid#">)
				</cfquery>
				<!--- Record Patch History --->
				<cfset r = recordHistory(Arguments.id,Arguments.gid,"1")>
			</cfif>
			<cfcatch type="any">
				<cfset logError("patch_group_edit","selectPatch",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
				<cfset strMsgType = "Error">
				<cfset strMsg = "There was an issue with the Edit. An Error Report has been submitted to Support.">
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="recordHistory" access="private">
		<cfargument name="patch_id" required="yes">
		<cfargument name="patchgroup_id" required="yes">
		<cfargument name="patch_state" required="yes" hint="0=Disabled, 1=Enabled">

		<cftry>
			<cfset var pName = "NA">
			<cfset var pType = "NA">

			<cfquery name="qPInfo" datasource="#session.dbsource#" result="res">
				SELECT DISTINCT id, name, type
				FROM combined_patches_view
				Where id = <cfqueryparam value="#Arguments.patch_id#">
			</cfquery>

			<cfif qPInfo.RecordCount EQ 1>
				<cfset pName = "#qPInfo.name#">
				<cfset pType = "#qPInfo.type#">
			<cfelse>
				<cfset logError("patch_group_edit","recordHistory","#Arguments.patch_id# was not found.")>
			</cfif>

			<cfquery name="setIt" datasource="#session.dbsource#">
				Insert Into mp_patch_selection_history (patch,patchid,patchgroup,patchtype,state,userid)
				Values ("#pName#",<cfqueryparam value="#Arguments.patch_id#">,<cfqueryparam value="#Arguments.patchgroup_id#">,
						"#pType#",<cfqueryparam value="#Arguments.patch_state#">,<cfqueryparam value="#session.Username#">)
			</cfquery>

			<cfcatch type="any">
				<cfset logError("recordHistory",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
			</cfcatch>
		</cftry>

	</cffunction>


</cfcomponent>
