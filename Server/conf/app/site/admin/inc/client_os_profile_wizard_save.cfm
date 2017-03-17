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

<!--- Setup Variables that make this entry unique --->
<cfset new_profileID=CreateUUID()>

<!--- Create Main Duplicate Record --->
<cftry>
<cfquery name="qNewProfile" datasource="#session.dbsource#">
	INSERT INTO mp_os_config_profiles (
		profileID, profileIdentifier, profileName, profileDescription, profileRev, profileData, uninstallOnRemove, enabled, profileHash
    )
    Values (
        '#new_profileID#', <cfqueryparam value="#form.profileIdentifier#">, <cfqueryparam value="#form.profileName#">, <cfqueryparam value="#form.profileDescription#">, 1, <cfqueryparam value="#binProfile#" cfsqltype="cf_sql_blob">,
        <cfqueryparam value="#form.uninstallOnRemove#">, <cfqueryparam value="#form.enabled#">, '#md5Hash#'
    )
</cfquery>
<cfcatch>
	<cfoutput>#cfcatch.Message#<br />#cfcatch.Detail#</cfoutput>
    <cfabort>
</cfcatch>
</cftry>
<cflocation url="#session.cflocFix#/admin/inc/client_os_profiles.cfm">
<cfabort>

