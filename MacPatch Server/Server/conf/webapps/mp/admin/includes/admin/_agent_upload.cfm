<cfparam name="mainZipFileName" default="MPClientInstaller.mpkg.zip">

<cfif IsDefined("form.AgentPackage") AND form.AgentPackage EQ "Upload">
	<cfif #form.pkg# gt "">
    	<cfset pkgUUID = #CreateUUID()#>
		<cfset ulTmpPath = #GetTempdirectory()# & "/" & #pkgUUID#>
		<cfif directoryexists(ulTmpPath) EQ False>
        	<cfdirectory action="create" directory="#ulTmpPath#" recurse="true">
		</cfif>
		
        <cffile action = "upload"
        	fileField="form.pkg"
        	Destination="#ulTmpPath#"
        	nameConflict="overwrite"
            mode="644"
        	Accept="application/zip">
		
		<cfif #mainZipFileName# NEQ #clientfile#>
			<cfoutput>The uploaded file is not a proper MacPatch updater.</cfoutput>
			<cfdirectory action="delete" directory="#ulTmpPath#" recurse="true">
			<cfabort>
		</cfif>
		
		<!--- Unzip the Main Client Installer --->
		<cfexecute 
   			name = "/usr/bin/ditto"
   			arguments = "-x -k #serverfileuri# #ulTmpPath#"
   			variable = "unzipResult"
  			timeout = "15">
		</cfexecute>

		<cfset iniFile = "#ulTmpPath#/#clientfilename#/Contents/Resources/.mpInfo.ini">
		<cfset sections = GetProfilesections(iniFile)>
		<cfset data = structNew()>
		<cfset pkgs = arrayNew(1)>
		
		<!--- Add the Main Client Installer First, to the pks array --->
		<cfset _a = #Arrayappend(pkgs,clientfile)#>
		
		<!--- Create a Struct of the ini file --->
		<cfloop collection="#sections#" item="akey">
			<cfif structKeyExists(sections, akey)>				
			<cfset aStruct = structNew()>
			<cfloop index="key" list="#Evaluate("sections." & akey)#">
				<cfif key EQ "pkg">
					<cfset _a = #Arrayappend(pkgs,GetFilefrompath(getProfileString(iniFile, akey, key)) & ".zip")#>
				</cfif>	
				<cfset aStruct[key] = getProfileString(iniFile, akey, key)>
			</cfloop>
			<cfset data[akey] = aStruct>
			</cfif>
		</cfloop>

		<cfset results = 0>
		<cfloop collection="#data#" item="key">
			<cfset _i = processPackage(pkgUUID,clientfilename,data[key],key)>
			<cfif _I.errorNo NEQ "0">
				<cfdump var="#_i#">
			</cfif>
			<cfset results = #results# + #_i.errorNo#>
		</cfloop>
		
		<!--- Move Packages To New Location --->
		<cfset baseLoc = "/Library/MacPatch/Content/Web/clients/updates">
		<cfset new_pkgBaseDir = #baseLoc# & "/" & pkgUUID>
		<cfif directoryexists(new_pkgBaseDir) EQ False>
        	<cftry>
        	<cfdirectory action="create" directory="#new_pkgBaseDir#" recurse="true">
            <cfcatch>
            	<cfoutput>Error: #cfcatch.Detail#</cfoutput>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfif>
        pkgs: <cfdump var="#pkgs#"><br>
		<cfloop array="#pkgs#" index="i" from="1" to="#arraylen(pkgs)#">
			<cfset pkg_source = ulTmpPath & "/" & #pkgs[i]#>
            <cfset pkg_source = #Replace(pkg_source,"//","/","All")#>
			<cfdump var="#pkg_source#"><br>
            <cftry>
				<cffile action="move" source="#pkg_source#" destination="#new_pkgBaseDir#">
            <cfcatch>
            	<cfoutput>Error: #cfcatch.Detail#</cfoutput>
                <cfabort>
            </cfcatch>
            </cftry>
		</cfloop>
		
		<cfset rm_File = "#ulTmpPath#/#clientfilename#">
		<cfdirectory action="delete" directory="#rm_File#" recurse="true">
    </cfif>

    <cflocation url="#session.cflocFix#/admin/index.cfm?#session.curRef#">
</cfif>	

<cffunction name="processPackage" access="public" output="no" returntype="any">
    <cfargument name="gCUUID">
	<cfargument name="mainPkg">
	<cfargument name="pkgStruct" type="struct">
    <cfargument name="pType">
	
    <cfset var pkg = "0">
	<cfset var pkgName = "">
	<cfset var pkgHash = "">
	<cfset var version = "0">
	<cfset var agent_version = "0">
	<cfset var build = "0">
	<cfset var framework = "0">
	<cfset var osVerSupport = "*">
	
	<cfset tmpDir = #GetTempdirectory()# & #arguments.gCUUID#>
	
	<cfset var result = Structnew()>
	<cfset result.errorNo = "0">
	<cfset result.errorMsg = "">
	
	<cfif StructKeyExists(arguments.pkgStruct,"agent_version")>
		<cfset agent_version = arguments.pkgStruct["agent_version"]>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: agent version attribute was missing.">	
		<cfreturn result>	
	</cfif>	
	
	<cfif StructKeyExists(arguments.pkgStruct,"pkg")>
		<cfset pkg = arguments.pkgStruct["pkg"]>
		<cfset pkgName = GetFilefrompath(pkg)>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: pkg attribute was missing.">	
		<cfreturn result>	
	</cfif>	
	
	<cfif StructKeyExists(arguments.pkgStruct,"version")>
		<cfset version = arguments.pkgStruct["version"]>
	<cfelse>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: version attribute was missing.">	
		<cfreturn result>	
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"build")>
		<cfset build = arguments.pkgStruct["build"]>
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"framework")>
		<cfset framework = arguments.pkgStruct["framework"]>
	</cfif>
	
	<cfif StructKeyExists(arguments.pkgStruct,"osver")>
		<cfset osVerSupport = arguments.pkgStruct["osver"]>
	</cfif>
	
	<cfset pkgPath = tmpDir & "/" & arguments.mainPkg & "/" & pkg>
	<cfset pkgPathZip = tmpDir & "/" & pkgName & ".zip">
	<cfset pkgURLPath = "/mp-content/clients/updates/#arguments.gCUUID#/"& GetFilefrompath(pkgPathZip)>
	
	<!--- Compress the inner pkg --->	
	<cfexecute 
		name = "/usr/bin/ditto"
		arguments = "-c -k --keepParent #pkgPath# #pkgPathZip#"
		variable = "aBaseZipResult"
		timeout = "15">
	</cfexecute>
	
	<cfset pkgHash = getSHA1Hash(pkgPathZip)>
	
	<cfif arguments.ptype EQ "agent">
		<cfset ptype = "app">
    <cfelseif arguments.ptype EQ "updater">    
    	<cfset ptype = "update">
	<cfelse>
		<cfset ptype = "NA">
	</cfif>
	<cftry>
		<cfquery datasource="mpds" name="qAddUpdate">
			Insert INTO mp_client_agents (puuid, type, agent_ver, version, build, framework, pkg_name, pkg_url, pkg_hash, osver)
			Values('#arguments.gCUUID#', '#ptype#', '#agent_version#', '#version#', '#build#', '#framework#', '#pkgName#', '#pkgURLPath#', '#pkgHash#', '#osVerSupport#')
		</cfquery>
	<cfcatch>
		<cfset result.errorNo = "1">
		<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
	</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSHA1Hash" access="public" output="no">
    <cfargument name="aBinToHash">
    
	<cfexecute 
		name = "/usr/bin/openssl"
		arguments = "sha1 #arguments.aBinToHash#"
		variable = "sha1Result"
		timeout = "5">
	</cfexecute>
	<cfset sha1 = #ListGetAt(sha1Result,2,"= ")#>
	
	<cfreturn sha1>
</cffunction>