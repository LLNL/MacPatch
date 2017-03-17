<cfscript>
   function isEmpty(str) {
      if(NOT len(trim(str)))
         return false;
      else
         return true;
      } 
</cfscript>
<!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">

<!--- Upload the patch package file --->
<cfif IsDefined("form.mainPatchFile") AND isEmpty(form.mainPatchFile)>
	
    <cfset BasePatchPath = #application.settings.paths.content# & "/patches">
	<cfset PatchDir = #BasePatchPath# & "/" & #form.puuid#>
    
    <cfif NOT DirectoryExists(BasePatchPath)>
       <cfdirectory action = "create" directory = "#BasePatchPath#" >
    </cfif>
    <cfif NOT DirectoryExists(PatchDir)>
       <cfdirectory action = "create" directory = "#PatchDir#" >
    </cfif>
    <cffile action="upload" fileField="form.mainPatchFile" destination="#PatchDir#" nameconflict="overwrite" />
    <cfset theFilePath = #BasePatchPath# & "/" & #form.puuid# & "/" & #clientfile#>
    <cfset pkg_url = "/patches/" & #form.puuid# & "/" & #clientfile#>
    <cfset pkg_sizeK = #fileSize# / 1024>
    
    <!--- Get the Name of the package --->
    <cfparam name="pkg_name" default="NULL">
    <cfzip action="list" zipfile="#theFilePath#" variable="zipContents" recurse="FALSE" />
    <cfloop query="zipContents">
        <cfif (#name# Contains ".mpkg" OR #name# Contains ".pkg") AND #type# EQ "Dir">
            <cfif #name.endsWith(".pkg/")# EQ "YES">
                <cfset thePkgName = #SpanExcluding(name,"/")#>
                <cfbreak>
            </cfif>
        </cfif>
    </cfloop>
    <!--- If We Got the Var --->
    <cfif IsDefined('serverfilename')>
        <cfset pkg_name=#serverfilename#>
    <cfelse>   
		<cfset pkg_name=#thePkgName#> 
    </cfif>
    
    <!--- Get the file hash of the uploaded file (MD5) --->
    <cfparam name="md5Hash" default="0">
    <cfset md5Hash = HashBinary(theFilePath) />
</cfif>

<!--- Insert the new Record --->
<cfset cDate = #CreateODBCDateTime(now())#>

<!--- Define form.vars for non required fields --->
<cfparam name="form.req_script" default="NULL">
<cfparam name="form.description" default="NULL">
<cfparam name="form.description_url" default="NULL">
<cfparam name="form.cve_id" default="NULL">
<cfparam name="form.active" default="0">

<!--- Update the Main Record --->
<cfquery name="qInsert1" datasource="#session.dbsource#" result="res">
	Update mp_patches
    Set 
		mdate = #CREATEODBCDATETIME(Now())#
        <cfif IsDefined("Form.patch_name") AND isEmpty(Form.patch_name)>
        	,patch_name = <cfqueryparam value="#form.patch_name#">
        </cfif>
        <cfif IsDefined("Form.patch_ver") AND isEmpty(Form.patch_ver)>
        	,patch_ver = <cfqueryparam value="#form.patch_ver#">
        </cfif>
		<cfif IsDefined("Form.patch_vendor") AND isEmpty(Form.patch_vendor)>
        	,patch_vendor = <cfqueryparam value="#form.patch_vendor#">
        </cfif>
        <cfif IsDefined("Form.description")>
        	,description = <cfqueryparam value="#form.description#" cfsqltype="cf_sql_varchar">
        </cfif>
        <cfif IsDefined("Form.description_url")>
        	,description_url = <cfqueryparam value="#form.description_url#" cfsqltype="cf_sql_varchar">
        </cfif>
		<cfif IsDefined("Form.patch_severity")>
        	,patch_severity = <cfqueryparam value="#form.patch_severity#">
        </cfif>
        <cfif IsDefined("Form.patch_state")>
        	,patch_state = <cfqueryparam value="#form.patch_state#">
        </cfif>
        <cfif IsDefined("Form.cve_id")>
        	,cve_id = <cfqueryparam value="#form.cve_id#">
        </cfif>
        <cfif IsDefined("Form.bundle_id") AND isEmpty(Form.bundle_id)>
        	,bundle_id = <cfqueryparam value="#form.bundle_id#">
        </cfif>
        <cfif IsDefined("Form.active")>
        	,active = <cfqueryparam value="#form.active#">
        <cfelse>
        	,active = <cfqueryparam value="0">
        </cfif>
        <cfif IsDefined("md5Hash") AND isEmpty(md5Hash)>
        	,pkg_hash = <cfqueryparam value="#md5Hash#" cfsqltype="cf_sql_varchar">
        </cfif>
        <cfif IsDefined("pkg_name") AND isEmpty(pkg_name)>
        	,pkg_name = <cfqueryparam value="#pkg_name#" cfsqltype="cf_sql_varchar">
        </cfif>
        <cfif IsDefined("theFilePath") AND isEmpty(theFilePath)>
        	,pkg_path = <cfqueryparam value="#theFilePath#" cfsqltype="cf_sql_varchar">
        </cfif>
        <cfif IsDefined("pkg_url") AND isEmpty(pkg_url)>
        	,pkg_url = <cfqueryparam value="#pkg_url#" cfsqltype="cf_sql_varchar">
        </cfif>
        <cfif IsDefined("pkg_sizeK") AND isEmpty(pkg_sizeK)>
        	,pkg_size = <cfqueryparam value="#pkg_sizeK#">
        </cfif>
		<cfif IsDefined("Form.patchInstallWeight") AND isEmpty(Form.patchInstallWeight)>
        	,patch_install_weight = <cfqueryparam value="#form.patchInstallWeight#">
        </cfif>
        <cfif IsDefined("Form.patch_reboot") AND isEmpty(Form.patch_reboot)>
        	,patch_reboot = <cfqueryparam value="#form.patch_reboot#">
        </cfif>
		<cfif IsDefined("Form.pkg_preinstall")>
        	,pkg_preinstall = <cfqueryparam value="#form.pkg_preinstall#" cfsqltype="CF_SQL_LONGVARCHAR">
        </cfif>
		<cfif IsDefined("Form.pkg_postinstall")>
        	,pkg_postinstall = <cfqueryparam value="#form.pkg_postinstall#" cfsqltype="CF_SQL_LONGVARCHAR">
        </cfif>
		<cfif IsDefined("Form.pkg_env_var")>
        	,pkg_env_var = <cfqueryparam value="#form.pkg_env_var#" cfsqltype="cf_sql_varchar">
        </cfif>
    Where puuid = <cfqueryparam value="#form.puuid#">
</cfquery>


<!--- Insert the patch criteria --->
<cfquery name="qInsert2RM" datasource="#session.dbsource#">
    Delete from mp_patches_criteria
    Where puuid = <cfqueryparam value="#form.puuid#">
</cfquery>
<cfquery name="qInsert2RM" datasource="#session.dbsource#">
    Delete from mp_patches_requisits
    Where puuid = <cfqueryparam value="#form.puuid#">
</cfquery>
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
                <cfqueryparam value="#form.puuid#">, <cfqueryparam value="#Evaluate("TYPE_"&nid)#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(ntitle&"_"&nid)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#order#'
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
                <cfqueryparam value="#form.puuid#">, '1', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("POSTPATCHPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("POSTPATCHPKG_"&nid)#" cfsqltype="cf_sql_varchar">
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
                <cfqueryparam value="#form.puuid#">, '0', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("PREPATCHPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("PREPATCHPKG_"&nid)#" cfsqltype="cf_sql_varchar">
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
                <cfqueryparam value="#form.puuid#">, <cfqueryparam value="#theType#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(TheField)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#theOrder#'
            )
        </cfquery>
	</cfif>
</CFLOOP>

<cflocation url="#session.cflocFix#/admin/inc/available_patches_mp.cfm">

