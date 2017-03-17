<!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">
<cfset new_puuid=CreateUUID()>

<!--- Check to see if the patch id is unique first, if not bail --->
<cfquery name="qCheck" datasource="#session.dbsource#">
	Select puuid From mp_patches
    Where puuid = '#new_puuid#'
</cfquery>

<cfif qCheck.RecordCount NEQ 0>
<h1>Error: Duplicate patch ID.</h1>
<cfabort />
</cfif>

<!--- Upload the patch package file --->
<cfset BasePatchPath = #application.settings.paths.content# & "/patches">
<cfset PatchDir = #BasePatchPath# & "/" & #new_puuid#>
<cfif NOT DirectoryExists(BasePatchPath)>
   <cfdirectory action = "create" directory = "#BasePatchPath#" >
</cfif>
<cfif NOT DirectoryExists(PatchDir)>
   <cfdirectory action = "create" directory = "#PatchDir#" >
</cfif>
<cffile action="upload" fileField="form.mainPatchFile" destination="#PatchDir#" />
<cfset theFilePath = #BasePatchPath# & "/" & #new_puuid# & "/" & #clientfile#>
<cfset pkg_url = "/patches/" & #new_puuid# & "/" & #clientfile#>
<cfset pkg_sizeK = #fileSize# / 1024>

<!--- Get the Name of the package --->
<cfparam name="pkg_name" default="NULL">
<cfif cffile.clientfileext EQ "zip">
	<cfzip action="list" zipfile="#theFilePath#" variable="zipContents" recurse="FALSE" />
	<cfloop query="zipContents">
		<cfif (#name# Contains ".mpkg" OR #name# Contains ".pkg") AND #type# EQ "Dir">
	    	<cfif #name.endsWith(".pkg/")# EQ "YES">
				<cfset thePkgName = #SpanExcluding(name,"/")#>
	        	<cfbreak>
	        </cfif>
	    </cfif>
	</cfloop>
<cfelse>
	<cfset thePkgName = #cffile.ClientFile#>
</cfif>
<!--- If We Got the Var --->
<cfif IsDefined('serverfilename')>
	<cfset pkg_name=#serverfilename#>
<cfelse>
	<cfset pkg_name=#thePkgName#>
</cfif>

<!--- Get the file hash of the uploaded file (MD5) --->
<!--- Old v1.2  Release
<cfinvoke component="fileHash" method="getHash" returnVariable="md5Hash">
   <cfinvokeargument name="filePath" value="#theFilePath#">
</cfinvoke>
--->
<cfparam name="md5Hash" default="0">
<cfset md5Hash = HashBinary(theFilePath) />

<!--- Insert the new Record --->
<cfset cDate = #CreateODBCDateTime(now())#>

<!--- Define form.vars for non required fields --->
<cfparam name="form.req_script" default="NULL">
<cfparam name="form.description" default="NULL">
<cfparam name="form.description_url" default="NULL">
<cfparam name="form.cve_id" default="NULL">
<cfparam name="form.pkg_path" default="NULL">
<cfparam name="form.pkg_url" default="NULL">
<cfparam name="form.bundle_id" default="mp.default">


<!--- Insert the Main Record --->
<cfquery name="qInsert1" datasource="#session.dbsource#">
	Insert Into mp_patches (
    	puuid, bundle_id, patch_name, patch_ver, patch_vendor, description,
        description_url, patch_severity, patch_state, cve_id, cdate, mdate, active,
        pkg_name, pkg_hash, pkg_path, pkg_url, pkg_size, patch_reboot, pkg_preinstall, pkg_postinstall, pkg_env_var,
		patch_install_weight
    )
    Values (
        '#new_puuid#', '#bundle_id#', '#patch_name#', '#patch_ver#', <cfqueryparam value="#patch_vendor#">, <cfqueryparam value="#description#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#description_url#" cfsqltype="cf_sql_varchar">, '#patch_severity#', '#patch_state#', '#cve_id#', #cDate#, #cDate#, '#active#',
        <cfqueryparam value="#pkg_name#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#md5Hash#" cfsqltype="cf_sql_varchar">, '#theFilePath#', <cfqueryparam value="#pkg_url#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#pkg_sizeK#" cfsqltype="cf_sql_varchar">, '#patch_reboot#',<cfqueryparam value="#pkg_preinstall#" cfsqltype="CF_SQL_LONGVARCHAR">,
		<cfqueryparam value="#pkg_postinstall#" cfsqltype="CF_SQL_LONGVARCHAR">,<cfqueryparam value="#pkg_env_var#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#patchInstallWeight#">
    )
</cfquery>

<!--- Insert the patch criteria --->
<CFLOOP INDEX="TheField" list="#Form.FieldNames#">
	<cfif TheField Contains "REQPATCHCRITERIA_">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>
        <cfset order = (#Evaluate("REQPATCHCRITERIAORDER_"&nid)# + 3)>

        <cfquery name="qInsert2" datasource="#session.dbsource#">
            Insert Into mp_patches_criteria (
                puuid, type, type_data, type_order
            )
            Values (
                '#new_puuid#', <cfqueryparam value="#Evaluate("TYPE_"&nid)#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(ntitle&"_"&nid)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#order#'
            )
        </cfquery>
	<cfelseif TheField Contains "POSTPATCHPKG">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>

    	<cfquery name="qInsert3" datasource="#session.dbsource#">
            Insert IGNORE Into mp_patches_requisits (
                puuid, type, type_txt, type_order, puuid_ref
            )
            Values (
                '#new_puuid#', '1', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("POSTPATCHPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("POSTPATCHPKG_"&nid)#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    <cfelseif TheField Contains "PREPATCHPKG">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>

    	<cfquery name="qInsert3" datasource="#session.dbsource#">
            Insert IGNORE Into mp_patches_requisits (
                puuid, type, type_txt, type_order, puuid_ref
            )
            Values (
                '#new_puuid#', '0', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("PREPATCHPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("PREPATCHPKG_"&nid)#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
	<cfelseif TheField EQ "REQ_OS_TYPE" OR TheField EQ "REQ_OS_VER" OR TheField EQ "REQ_OS_ARCH">
		<cfif TheField EQ "REQ_OS_TYPE">
        	<cfset theType = "OSType">
            <cfset theOrder = "1">
        <cfelseif TheField EQ "REQ_OS_VER">
        	<cfset theType = "OSVersion">
            <cfset theOrder = "2">
		<cfelseif TheField EQ "REQ_OS_ARCH">
        	<cfset theType = "OSArch">
            <cfset theOrder = "3">
        </cfif>

    	<cfquery name="qInsert2" datasource="#session.dbsource#">
            Insert Into mp_patches_criteria (
                puuid, type, type_data, type_order
            )
            Values (
                '#new_puuid#', <cfqueryparam value="#theType#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(TheField)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#theOrder#'
            )
        </cfquery>
	</cfif>
</CFLOOP>
<cflocation url="#session.cflocFix#/admin/inc/available_patches_mp.cfm">
<cfabort>