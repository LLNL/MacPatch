<cfcomponent output="false">
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
            <cfset arrUsers[i] = [#id#, #selected#, #name#, #title#, #Reboot#, #type#, #patch_state#, #DateTimeFormat( postdate, "yyyy-MM-dd HH:mm:ss" )#]>
			<cfset i = i + 1>
		</cfloop>

		<cfset totalPages = Ceiling(qGetPatches.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qGetPatches.recordcount#,rows=#arrUsers#}>
		<cfreturn stcReturn>
	</cffunction>

    <cffunction name="buildSearchString" access="private" hint="Returns the Search Opeator based on Short Form Value">
		<cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">

        	<cfset var searchCol = "b.#Arguments.searchField#">
			<cfset var searchVal = "">
			<cfscript>
				switch(Arguments.searchOper)
				{
					case "eq":
						searchVal = "#searchCol# = '#Arguments.searchString#'";
						break;
					case "ne":
						searchVal = "#searchCol# <> '#Arguments.searchString#'";
						break;
					case "lt":
						searchVal = "#searchCol# < '#Arguments.searchString#'";
						break;
					case "le":
						searchVal = "#searchCol# <= '#Arguments.searchString#'";
						break;
					case "gt":
						searchVal = "#searchCol# > '#Arguments.searchString#'";
						break;
					case "ge":
						searchVal = "#searchCol# >= '#Arguments.searchString#'";
						break;
					case "bw":
						searchVal = "#searchCol# LIKE '#Arguments.searchString#%'";
						break;
					case "ew":
						//Purposefully breaking ends with operator (no leading ')
						searchVal = "#searchCol# LIKE %#Arguments.searchString#'";
						break;
					case "cn":
						searchVal = "#searchCol# LIKE '%#Arguments.searchString#%'";
						break;
				}
			</cfscript>
			<cfreturn searchVal>
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
					<cfset strSearch = "WHERE (#PreserveSingleQuotes(strSearchVal)#)">
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
		<cfset var searchCol = "b.#Arguments.strField#">

		<cfif Arguments.strValue EQ "">
			<cfreturn "">
		</cfif>

		<cfscript>
			switch(Arguments.strOp)
			{
				case "eq":
					//ID is numeric so we will check for that
					if(searchCol EQ "id")
					{
						searchVal = "#searchCol# = #Arguments.strValue#";
					}else{
						searchVal = "#searchCol# = '#Arguments.strValue#'";
					}
					break;
				case "lt":
					searchVal = "#searchCol# < #Arguments.strValue#";
					break;
				case "le":
					searchVal = "#searchCol# <= #Arguments.strValue#";
					break;
				case "gt":
					searchVal = "#searchCol# > #Arguments.strValue#";
					break;
				case "ge":
					searchVal = "#searchCol# >= #Arguments.strValue#";
					break;
				case "bw":
					searchVal = "#searchCol# LIKE '#Arguments.strValue#%'";
					break;
				case "ew":
					searchVal = "#searchCol# LIKE '%#Arguments.strValue#'";
					break;
				case "cn":
					searchVal = "#searchCol# LIKE '%#Arguments.strValue#%'";
					break;
			}
		</cfscript>

		<cfreturn searchVal>
	</cffunction>

	<cffunction name="togglePatch" access="remote" returnformat="json">
		<cfargument name="id" required="true">
		<cfargument name="gid" required="true">

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
        <cfset _x = xObj.GetPatchGroupPatches(Arguments.id)>
        <cfset _a = AddPatchGroupData(Arguments.id,_x,'JSON')>
        <!--- SOAP < 2.1.1 --->
        <!--- No Longer Support XML
        <cfset _y = xObj.GetPatchGroupPatchesExtended(Arguments.id)>
        <cfset _b = AddPatchGroupData(Arguments.id,_y,'SOAP')>
        --->
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
        <cfcatch>
        	<cfset logError("patch_group_edit","RemovePatchGroupData",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
    	</cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="AddPatchGroupData" returntype="any" output="no" access="private">
        <cfargument name="PatchGroupID">
        <cfargument name="PatchGroupData">
        <cfargument name="PatchGroupDataType">

        <cftry>
            <cfset _hash = hash(#arguments.PatchGroupData#, "MD5")>
            <cfquery datasource="#session.dbsource#" name="qPut">
                Insert Into mp_patch_group_data (pid, hash, data, data_type)
                Values ('#arguments.PatchGroupID#', '#_hash#', '#arguments.PatchGroupData#', '#arguments.PatchGroupDataType#')
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
				<cfset logError("patch_group_edit","recordHistory",#cfcatch.message#,#cfcatch.Detail#,#cfcatch.type#)>
			</cfcatch>
		</cftry>

	</cffunction>

	<cffunction name="logError" access="private">
		<cfargument name="log" required="yes">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="Detail: NA">
	    <cfargument name="type" required="no" default="Type: NA">
		
		<cfif #arguments.type# NEQ "NA">
			<cflog file="#arguments.log#" type="error" application="no" text="[#arguments.method#] - Type: #arguments.type#">
		</cfif>
    	<cflog file="#arguments.log#" type="error" application="no" text="[#arguments.method#] - Message: #arguments.message#">
    	<cfif #arguments.detail# NEQ "NA">
        	<cflog file="#arguments.log#" type="error" application="no" text="[#arguments.method#] - Detail: #arguments.detail#">
        </cfif>
	</cffunction>

</cfcomponent>
