<cfset baseLoc = "/Library/MacPatch/Content/Web/patches">

<cfset response = responseObj(0) />
<cfif NOT IsDefined("form.patchID") OR NOT IsDefined("form.userID") OR NOT IsDefined("form.token")>
		<cfset response.errorno = "1" />
		<cfset response.errormsg = "Error: Invalid Format." />
		<cfoutput>#Trim(SerializeJSON(response))#</cfoutput>
	<cfabort>
<cfelse>
	<cfif NOT isValidRequest(form.patchID, form.userID)>
		<cfset response.errorno = "2" />
		<cfset response.errormsg = "Error: Invalid Request!" />
		<cfoutput>#Trim(SerializeJSON(response))#</cfoutput>
		<cfabort>
	</cfif>
	<cfif NOT isValidAuthToken(form.userID, form.token)>
		<cfset response.errorno = "3" />
		<cfset response.errormsg = "Error: Invalid Token!" />
		<cfoutput>#Trim(SerializeJSON(response))#</cfoutput>
		<cfabort>
	</cfif>
</cfif>

<cfset pkgUUID = #form.patchID#>
<cfset ulTmpPath = #GetTempdirectory()# & #pkgUUID#>
<cfset response.puuid = #pkgUUID# />

<cfif directoryexists(ulTmpPath) EQ False>
	<cfdirectory action="create" directory="#ulTmpPath#" recurse="true">
</cfif>

<!--- Upload the AutoPKG package --->
<cfset pkgs = ArrayNew(1)> 
<cfif IsDefined("form.autoPKG")>
	<cffile action = "upload"
	      	fileField="form.autoPKG"
	      	Destination="#ulTmpPath#"
	      	nameConflict="overwrite"
	        mode="644" result="pkg1">
	<cfset aap = #ArrayAppend(pkgs, pkg1.clientFile)#>		
</cfif>

<!--- Move Packages To New Location --->
<cfset respObj.pkg = #pkgUUID# />
<cfset new_pkgBaseDir = #baseLoc# & "/" & pkgUUID>

<cfif directoryexists(new_pkgBaseDir) EQ False>
	<cftry>
		<cfdirectory action="create" directory="#new_pkgBaseDir#" recurse="true">
		<cfcatch>
			<cfoutput>Error: #cfcatch.Detail#</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>
<cfelse>
	<cfset response.errorno = "4" />
	<cfset response.errormsg = "Error: Package ID path was already created." />
	<cfoutput>#Trim(SerializeJSON(response))#</cfoutput>
	<cfabort>	
</cfif>

<cfloop array="#pkgs#" index="i" from="1" to="#arraylen(pkgs)#">
	<cfset pkg_source = ulTmpPath & "/" & #pkgs[i]#>
	<cfset pkg_source = #Replace(pkg_source,"//","/","All")#>
	<cftry>
		<cffile action="move" source="#pkg_source#" destination="#new_pkgBaseDir#">
		<cfcatch>
			<cfoutput>Error: #cfcatch.Detail#</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>
</cfloop>

<!--- Clean up the temp Dir --->
<cfset rm_File = "#ulTmpPath#">
<cfdirectory action="delete" directory="#rm_File#" recurse="true">
<cfoutput>#Trim(SerializeJSON(response))#</cfoutput>

<cffunction name="isValidRequest" access="public" output="no" returntype="any">
	<cfargument name="requestID" required="true">
	<cfargument name="userID" required="true">
	
	<cfset var result = false>
	
	<cftry>
		<cfquery datasource="mpds" name="qGetRequestID">
			Select rid, requestID From mp_agent_upload
			Where uid = <cfqueryparam value="#Arguments.userID#">
			AND	requestID = <cfqueryparam value="#Arguments.requestID#">
		</cfquery>
		<cfif qGetRequestID.RecordCount EQ 1>
			<cfset var result = true>
			<cfset var _rid = qGetRequestID.rid>
			<!--- Found the Request now remove it --->
			<cfquery datasource="mpds" name="qDelRequestID">
				Delete From mp_agent_upload
				Where rid = <cfqueryparam value="#_rid#">
			</cfquery>
		</cfif>
		<cfcatch>
			<cfset result.errorNo = "1">
			<cfset result.errorMsg = "Error: #cfcatch.Detail# #cfcatch.message#">	
		</cfcatch>
	</cftry>
	
	<cfreturn result>
</cffunction>

<cffunction name="responseObj" access="private" returntype="struct" output="no">
    <cfargument name="resultType" required="yes" default="0" displayname="0=String,1=Struct">

    <cfset response = {} />
    <cfset response[ "errorno" ] = "0" />
    <cfset response[ "errormsg" ] = "" />
    <cfif arguments.resultType EQ 0>
    	<cfset response[ "result" ] = "" />
    <cfelse>
    	<cfset response[ "result" ] = {} />    
	</cfif>
	<cfset response[ "machineName" ] = "" />
    <cfset response[ "hostName" ] = "" />

    <cftry>
		<cfscript>
        	machineName = createObject("java", "java.net.InetAddress").localhost.getCanonicalHostName();
        	hostaddress = createObject("java", "java.net.InetAddress").localhost.getHostAddress();
    	</cfscript>

    	<cfset response[ "machineName" ] = "#machineName#" />
		<cfset response[ "hostName" ] = "#hostaddress#" />

        <cfcatch type="any">
            <cfset l = elogit("[responseObj]: #cfcatch.Detail# -- #cfcatch.Message#")>
		</cfcatch>
    </cftry>
    
    <cfreturn response>
</cffunction>

<cffunction name="isValidAuthToken" returntype="boolean" access="private">
	<cfargument name="username" required="true"/>
	<cfargument name="token" required="true"/>

	<cfset var qry = true>
    <cftry>
        <cfquery name="qry" datasource="mpds">
            select authToken1, authToken2
            from mp_adm_group_users
            where
                user_id	= <cfqueryparam value="#LCase(arguments.username)#" />
                and enabled = '1'
                and (authToken1 = <cfqueryparam value="#arguments.token#" />
                	or
                	authToken2 = <cfqueryparam value="#arguments.token#" />) 
        </cfquery>
        <cfif qry.recordcount == 0>
            <cfreturn false>
        <cfelse>
        	<cfreturn true>
        </cfif>
		<cfcatch type="any">
	        <cflog file="MPAdminLoginError" type="error" application="no" text="Error: On query for user (#arguments.username#)">
	        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [message]: #cfcatch.message#">
	        <cflog file="MPAdminLoginError" type="error" application="no" text="Error [details]: #cfcatch.detail#">
	    </cfcatch>
    </cftry>
	
    <cfreturn false>
</cffunction>