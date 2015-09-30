<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>MP Task worker...</title>
</head>

<body>
<cfif #CGI.HTTP_USER_AGENT# EQ "BlueDragon">
	<cffunction name="UpdatePatchSize" access="private" output="no" returntype="any">
		<cfargument name="PatchID" required="yes">
	    <cfargument name="PatchSize" required="yes">
	    
	    <cftry>
	        <cfquery name="qUpdatePatch" datasource="mpds" result="res">
	            Update mp_patches
	            Set pkg_size = <cfqueryparam value="#arguments.PatchSize#">
	            Where puuid = <cfqueryparam value="#arguments.PatchID#">
	        </cfquery>
	    <cfcatch type="any"></cfcatch>
	    </cftry>
	</cffunction>
	<cffunction name="GetPatchSize" access="private" output="no" returntype="any">
		<cfargument name="PatchPath" required="yes">
	    
	    <cfif NOT FileExists(arguments.PatchPath)><cfreturn "0"></cfif>
	    <cfset _fileInfo = GetFileinfo(arguments.PatchPath)>
	    <cfset _fileSize = Round(_fileInfo.size / 1024) >
		
		<cfreturn #_fileSize#>
	</cffunction>
	
	<cfquery name="qSelPatches" datasource="mpds" result="res">
	    select puuid, patch_name, pkg_path
	    From mp_patches
	    Where pkg_size = <cfqueryparam value="0">
	</cfquery>

	<cfoutput query="qSelPatches">
	#patch_name# (#GetPatchSize(pkg_path)#) #UpdatePatchSize(puuid,GetPatchSize(pkg_path))#<br />
	</cfoutput>
</cfif>
</body>
</html>
