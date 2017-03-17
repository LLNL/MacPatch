<cfsetting requesttimeout="1800">

<cfscript>
   function isEmpty(str) {
      if(NOT len(trim(str)))
         return false;
      else
         return true;
      } 
</cfscript><!--- This Requires Multiple Database Inserts --->

<!--- Setup Variables that make this entry unique --->
<cfset ts=DateFormat(Now(),"yyyy-mm-dd") & " " & TimeFormat(Now(),"HH:mm:ss") & " ">
<cfset new_suuid=CreateUUID()>

<!--- Check to see if the patch id is unique first, if not bail --->
<cfif CheckForSWDist(new_suuid) NEQ 0>
	<h1>Error: Duplicate patch ID.</h1>
	<cfabort />
</cfif>

<!--- Upload the patch package file --->
<cfset BaseSWPath = #server.mpsettings.settings.paths.content# & "/sw">
<cfset SWDistDir = #BaseSWPath# & "/" & #new_suuid#>
<cfif NOT DirectoryExists(BaseSWPath)>
   <cfdirectory action = "create" directory = "#BaseSWPath#" >
</cfif>
<cfif NOT DirectoryExists(SWDistDir)>
   <cfdirectory action = "create" directory = "#SWDistDir#" >
</cfif>
<cffile action="upload" fileField="form.mainPackage" destination="#SWDistDir#" />
<cfset theFilePath = #BaseSWPath# & "/" & #new_suuid# & "/" & #clientfile#>
<cfset pkg_url = "/sw/" & #new_suuid# & "/" & #clientfile#>
<cfset pkg_sizeK = #fileSize# / 1024>

<!--- Get the file hash of the uploaded file (MD5) --->
<cfparam name="md5Hash" default="0">
<cfset pkgMD5Hash = Hashbinary(theFilePath,"MD5") />

<!--- Insert the new Record --->
<!--- Define form.vars for non required fields --->
<cfparam name="form.sVendor" default="NULL">
<cfparam name="form.sDescription" default="NULL">
<cfparam name="form.sVendorURL" default="NULL">
<cfparam name="form.patch_bundle_id" default="NULL">
<cfparam name="form.auto_patch" default="0">
<cfparam name="form.sw_pre_install_script" default="NULL">
<cfparam name="form.sw_post_install_script" default="NULL">
<cfparam name="form.sw_env_var" default="NULL">
<cfparam name="form.sw_uninstall_script" default="NULL">


<!--- Insert the Main Record --->
<cfquery name="qInsert1" datasource="#session.dbsource#">
	Insert Into mp_software (
    	suuid, sw_path, sw_url, sw_size, sw_hash, 
        sName, sVersion, sVendor, sDescription, sVendorURL, sState,
        patch_bundle_id, auto_patch, sw_pre_install_script, sw_post_install_script, sw_type, sw_env_var, sReboot,
        sw_uninstall_script
    )
    Values (
        '#new_suuid#', <cfqueryparam value="#theFilePath#">, <cfqueryparam value="#pkg_url#">, <cfqueryparam value="#pkg_sizeK#">, <cfqueryparam value="#pkgMD5Hash#">,
        <cfqueryparam value="#form.sName#">, <cfqueryparam value="#form.sVersion#">, <cfqueryparam value="#form.sVendor#">, <cfqueryparam value="#form.sDescription#">, <cfqueryparam value="#form.sVendorURL#">, <cfqueryparam value="#form.sState#">,
        <cfqueryparam value="#form.patch_bundle_id#">, <cfqueryparam value="#form.auto_patch#">, <cfqueryparam value="#form.sw_pre_install_script#">, <cfqueryparam value="#form.sw_post_install_script#">, <cfqueryparam value="#form.sw_type#">, <cfqueryparam value="#form.sw_env_var#">, <cfqueryparam value="#form.sReboot#">, <cfqueryparam value="#form.sw_uninstall_script#">
    )
</cfquery>

<!--- Insert the software criteria --->
<CFLOOP INDEX="TheField" list="#Form.FieldNames#">
	<cfif TheField Contains "POSTSWPKG">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>
    
    	<cfquery name="qInsert3" datasource="#session.dbsource#">
            Insert IGNORE Into mp_software_requisits (
                suuid, type, type_txt, type_order, suuid_ref
            )
            Values (
                '#new_suuid#', '1', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("POSTSWPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("POSTSWPKG_"&nid)#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    <cfelseif TheField Contains "PRESWPKG">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>
    
    	<cfquery name="qInsert3" datasource="#session.dbsource#">
            Insert IGNORE Into mp_software_requisits (
                suuid, type, type_txt, type_order, suuid_ref
            )
            Values (
                '#new_suuid#', '0', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("PRESWPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("PRESWPKG_"&nid)#" cfsqltype="cf_sql_varchar">
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
            Insert Into mp_software_criteria (
                suuid, type, type_data, type_order
            )
            Values (
                '#new_suuid#', <cfqueryparam value="#theType#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(TheField)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#theOrder#'
            )
        </cfquery>
	</cfif>
</CFLOOP>

<cflocation url="#session.cflocFix#/admin/inc/software_packages.cfm">

<cffunction name="CheckForSWDist" returntype="any">
	<cfargument name="uid" type="string" required="true">
	<cftry>
        <cfquery name="qCheck" datasource="#session.dbsource#">
            Select suuid From mp_software
            Where suuid = <cfqueryparam value="#arguments.uid#">
        </cfquery>
        <cfif qCheck.RecordCount EQ 0>
        	<cfreturn "0">
        <cfelse>
        	<cfreturn "1">
        </cfif>    
        <cfcatch type="any">
        	<cfreturn "-1">
        </cfcatch>
    </cftry> 
    	<cfreturn "-1">   
</cffunction>

