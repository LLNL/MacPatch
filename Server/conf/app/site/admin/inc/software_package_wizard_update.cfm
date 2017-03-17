<cfsetting requesttimeout="1800">

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
<cfif IsDefined("form.mainPackage") AND isEmpty(form.mainPackage)>
	
    <cfset BaseSwDistPath = #server.mpsettings.settings.paths.content# & "/sw">
	<cfset SwDistDir = #BaseSwDistPath# & "/" & #form.suuid#>
    <!--- Create dirs if missing --->
    <cfif NOT DirectoryExists(BaseSwDistPath)>
       <cfdirectory action = "create" directory = "#BaseSwDistPath#" >
    </cfif>
    <cfif NOT DirectoryExists(SwDistDir)>
       <cfdirectory action = "create" directory = "#SwDistDir#" >
    </cfif>
    <!--- Upload the software --->
    <cffile action="upload" fileField="form.mainPackage" destination="#SwDistDir#" nameconflict="overwrite" result="upFile"/>

    <cfset theFilePath = #BaseSwDistPath# & "/" & #form.suuid# & "/" & #upFile.clientfile#>
    <cfset _sw_url = "/sw/" & #form.suuid# & "/" & #upFile.clientfile#>
    <cfset _fileSize = #GetFileinfo(theFilePath).size#>
    <!---
    Only if it's not a Mac
    <cfset _sw_sizeK = #_fileSize# / 1024>
    --->
    <cfset _sw_sizeK = #_fileSize# / 1000>
    
    <!--- Get the file hash of the uploaded file (MD5) --->
    <cfparam name="md5Hash" default="0">
	<cfset md5Hash = Hashbinary(theFilePath,"MD5") />
</cfif>

<!--- Insert the new Record --->
<cfset cDate = #CreateODBCDateTime(now())#>

<!--- Define form.vars for non required fields --->
<cfparam name="form.sVendor" default="NULL">
<cfparam name="form.sVendorURL" default="NULL">
<cfparam name="form.sDescription" default="NULL">
<cfparam name="form.sVendorURL" default="NULL">
<cfparam name="form.patch_bundle_id" default="NULL">
<cfparam name="form.auto_patch" default="0">
<cfparam name="form.sw_pre_install_script" default="NULL">
<cfparam name="form.sw_post_install_script" default="NULL">
<cfparam name="form.sw_env_var" default="NULL">
<cfparam name="form.sw_uninstall_script" default="NULL">

<!--- Update the Main Record --->
<cfquery name="qInsert1" datasource="#session.dbsource#" result="res">
	Update mp_software
    Set 
		mdate = #CREATEODBCDATETIME(Now())#
        <cfif IsDefined("Form.patch_bundle_id") AND isEmpty(Form.patch_bundle_id)>
        	,patch_bundle_id = <cfqueryparam value="#form.patch_bundle_id#">
        <cfelse>
        	,patch_bundle_id = ''
        </cfif>
        <cfif IsDefined("Form.auto_patch") AND isEmpty(Form.auto_patch)>
        	<cfif NOT IsDefined("Form.patch_bundle_id")>
            ,auto_patch = '0'>
            <cfelse>
        	,auto_patch = <cfqueryparam value="#form.auto_patch#">
            </cfif>
        </cfif>
        <cfif IsDefined("Form.sState") AND isEmpty(Form.sState)>
        	,sState = <cfqueryparam value="#form.sState#">
        </cfif>
		<cfif IsDefined("Form.sName") AND isEmpty(Form.sName)>
        	,sName = <cfqueryparam value="#form.sName#">
        </cfif>
        <cfif IsDefined("Form.sVersion") AND isEmpty(Form.sVersion)>
        	,sVersion = <cfqueryparam value="#form.sVersion#">
        </cfif>
		<cfif IsDefined("Form.sVendor") AND isEmpty(Form.sVendor)>
        	,sVendor = <cfqueryparam value="#form.sVendor#">
        </cfif>
        <cfif IsDefined("Form.sDescription")>
        	,sDescription = <cfqueryparam value="#form.sDescription#">
        </cfif>
        <cfif IsDefined("Form.sVendorURL")>
        	,sVendorURL = <cfqueryparam value="#form.sVendorURL#">
        </cfif>
		<cfif IsDefined("Form.sReboot")>
        	,sReboot = <cfqueryparam value="#form.sReboot#">
        </cfif>
        <cfif IsDefined("sw_type")>
        	,sw_type = <cfqueryparam value="#sw_type#">
        </cfif>
        <cfif IsDefined("theFilePath")>
        	,sw_path = <cfqueryparam value="#theFilePath#">
        </cfif>
        <cfif IsDefined("_sw_url")>
        	,sw_url = <cfqueryparam value="#_sw_url#">
        </cfif>
        <cfif IsDefined("_sw_sizeK")>
        	,sw_size = <cfqueryparam value="#_sw_sizeK#" cfsqltype="cf_sql_bigint">
        </cfif>
        <cfif IsDefined("md5Hash")>
        	,sw_hash = <cfqueryparam value="#md5Hash#">
        </cfif>
        <cfif IsDefined("Form.sw_pre_install_script")>
        	,sw_pre_install_script = <cfqueryparam value="#form.sw_pre_install_script#" cfsqltype="CF_SQL_LONGVARCHAR">
        </cfif>
		<cfif IsDefined("Form.sw_post_install_script")>
        	,sw_post_install_script = <cfqueryparam value="#form.sw_post_install_script#" cfsqltype="CF_SQL_LONGVARCHAR">
        </cfif>
        <cfif IsDefined("Form.sw_uninstall_script")>
        	,sw_uninstall_script = <cfqueryparam value="#form.sw_uninstall_script#" cfsqltype="CF_SQL_LONGVARCHAR">
        </cfif>
        <cfif IsDefined("Form.sw_env_var")>
        	,sw_env_var = <cfqueryparam value="#form.sw_env_var#" cfsqltype="cf_sql_varchar">
        </cfif>
    Where suuid = <cfqueryparam value="#form.suuid#">
</cfquery>


<!--- Insert the patch criteria --->
<cfquery name="qInsert2RM" datasource="#session.dbsource#">
    Delete from mp_software_criteria
    Where suuid = <cfqueryparam value="#form.suuid#">
</cfquery>
<cfquery name="qInsert2RM" datasource="#session.dbsource#">
    Delete from mp_software_requisits
    Where suuid = <cfqueryparam value="#form.suuid#">
</cfquery>
<CFLOOP INDEX="TheField" list="#Form.FieldNames#">
	<cfif TheField Contains "REQPATCHCRITERIA_">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>
        <cfset order = (#Evaluate("REQPATCHCRITERIAORDER_"&nid)# + 3)>
		
        <cfquery name="qInsert2" datasource="#session.dbsource#">
            Insert Into mp_software_criteria (
                suuid, type, type_data, type_order
            )
            Values (
                <cfqueryparam value="#form.suuid#">, <cfqueryparam value="#Evaluate("TYPE_"&nid)#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(ntitle&"_"&nid)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#order#'
            )
        </cfquery>
	<cfelseif TheField Contains "POSTPATCHPKG">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>

    	<cfquery name="qInsert3" datasource="#session.dbsource#">
        	
            Insert IGNORE Into mp_software_requisits (
                suuid, type, type_txt, type_order, suuid_ref
            )
            Values (
                <cfqueryparam value="#form.suuid#">, '1', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("POSTPATCHPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("POSTPATCHPKG_"&nid)#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    <cfelseif TheField Contains "PREPATCHPKG">
    	<cfset nid = ListGetAt(TheField,2,"_")>
        <cfset ntitle = ListGetAt(TheField,1,"_")>
    
    	<cfquery name="qInsert3" datasource="#session.dbsource#">
            Insert IGNORE Into mp_software_requisits (
                suuid, type, type_txt, type_order, suuid_ref
            )
            Values (
                <cfqueryparam value="#form.suuid#">, '0', <cfqueryparam value="#ntitle#" cfsqltype="cf_sql_varchar">, '#Evaluate("PREPATCHPKGORDER_"&nid)#', <cfqueryparam value="#Evaluate("PREPATCHPKG_"&nid)#" cfsqltype="cf_sql_varchar">
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
                <cfqueryparam value="#form.suuid#">, <cfqueryparam value="#theType#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#Evaluate(TheField)#" cfsqltype="CF_SQL_LONGVARCHAR">, '#theOrder#'
            )
        </cfquery>
	</cfif>
</CFLOOP>
<cftry>
	<cfquery datasource="#session.dbsource#" name="qGetGroupsToUpdate">
		select sw_group_id from mp_software_group_tasks
		Where sw_task_id = 
		(
			select mpst.tuuid  from 
			mp_software mps 
			Left JOIN mp_software_task mpst ON mps.suuid = mpst.primary_suuid
			Where suuid = '#form.suuid#'
		)
	</cfquery>
	<cfset obj = CreateObject("component","software_group_edit")>
	<cfloop query="qGetGroupsToUpdate">
		<cfset res = obj.PopulateSoftwareGroupData(sw_group_id)>
		<cfoutput>#res#<br></cfoutput>
	</cfloop>
	<cfcatch>
		<cfscript>Logger(cfcatch.detail,"Error");</cfscript>
	</cfcatch>
</cftry>

<cflocation url="#session.cflocFix#/admin/inc/software_packages.cfm">