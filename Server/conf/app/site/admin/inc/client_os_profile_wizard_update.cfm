<cfheader name="expires" value="#now()#">
<cfheader name="pragma" value="no-cache">
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate">

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
<cfif IsDefined("form.profileFile") AND isEmpty(form.profileFile)>
	
    <!--- Upload the file. --->
    <cffile
        action="upload"
        filefield="form.profileFile"
        destination="#ExpandPath( './' )#"
        nameconflict="makeunique"
        />

    <!--- Read in the binary data. --->
    <cfset theFile = "#ExpandPath( './' )##CFFILE.ServerFile#" />
    <cffile
        action="readbinary"
        file="#theFile#"
        variable="binProfile"
        />
        
    <!--- Get the file hash of the uploaded file (MD5) --->
    <cfparam name="md5Hash" default="0">
    <cfset md5Hash = HashBinary(theFile) />

    <!--- Delete file from server. --->
    <cffile
        action="delete"
        file="#ExpandPath( './' )##CFFILE.ServerFile#"
        />
        
</cfif>

<!--- Insert the new Record --->
<cfset cDate = #CreateODBCDateTime(now())#>

<!--- Define form.vars for non required fields --->
<cfparam name="form.profileDescription" default="NULL">
<cfparam name="form.profileRev" default="0">
<cfparam name="form.enabled" default="0">

<cfif IsDefined("Form.profileRev")>
	<cfset profileRevision = form.profileRev + 1>
</cfif>

<!--- Update the Main Record --->
<cftry>
<cfquery name="qUpdate1" datasource="#session.dbsource#">
	Update mp_os_config_profiles
    Set 
		mdate = #CREATEODBCDATETIME(Now())#
        <cfif IsDefined("Form.profileName") AND isEmpty(Form.profileName)>
        	,profileName = <cfqueryparam value="#form.profileName#">
        </cfif>
		<cfif IsDefined("Form.profileIdentifier") AND isEmpty(Form.profileIdentifier)>
        	,profileIdentifier = <cfqueryparam value="#form.profileIdentifier#">
        </cfif>
        <cfif IsDefined("Form.profileDescription") AND isEmpty(Form.profileDescription)>
        	,profileDescription = <cfqueryparam value="#form.profileDescription#">
        </cfif>
		<cfif IsDefined("Form.profileRev")>
        	,profileRev = <cfqueryparam value="#profileRevision#" cfsqltype="cf_sql_integer">
        </cfif>
        <cfif IsDefined("binProfile")>
            ,profileData = <cfqueryparam value="#binProfile#" cfsqltype="cf_sql_blob">
        </cfif>    
        <cfif IsDefined("Form.uninstallOnRemove")>
        	,uninstallOnRemove = <cfqueryparam value="#form.uninstallOnRemove#">
        <cfelse>
        	,uninstallOnRemove = <cfqueryparam value="0">
        </cfif>
        <cfif IsDefined("Form.enabled")>
        	,enabled = <cfqueryparam value="#form.enabled#">
        <cfelse>
        	,enabled = <cfqueryparam value="0">
        </cfif>
        <cfif IsDefined("md5Hash") AND isEmpty(md5Hash)>
        	,profileHash = <cfqueryparam value="#md5Hash#" cfsqltype="cf_sql_varchar">
        </cfif>
    Where profileID = <cfqueryparam value="#form.profileID#">
</cfquery>
<cfcatch>
	<cfoutput>#cfcatch.Message#<br />#cfcatch.Detail#</cfoutput>
    <cfabort>
</cfcatch>
</cftry>
<cflocation url="#session.cflocFix#/admin/inc/client_os_profiles.cfm">

