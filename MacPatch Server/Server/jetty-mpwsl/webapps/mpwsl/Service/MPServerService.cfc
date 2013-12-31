<!--- **************************************************************************************** --->
<!---
		MPServerService 
	 	Database type is MySQL
		MacPatch Version 2.2.x
		Rev 2
--->
<!---	Notes:
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
    <cfset this.cacheDirName = "cacheIt">
    <cfset this.logTable = "ws_srv_logs">

	<cffunction name="init" returntype="MPServerService" output="no">
    
		<cfreturn this>
	</cffunction>

    <!--- Logging function, replaces need for ws_logger (Same Code) --->
    <cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">

        <cfscript>
			try {
				inet = CreateObject("java", "java.net.InetAddress");
				inet = inet.getLocalHost();
			} catch (any e) {
				inet = "localhost";
			}
		</cfscript>

    	<cfquery datasource="#this.ds#" name="qGet">
            Insert Into #this.logTable# (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
    </cffunction>

    <cffunction name="elogit" access="public" returntype="void" output="no">
        <cfargument name="aEvent">
        
        <cfset l = logit("Error",arguments.aEvent)>
    </cffunction>

<!--- **************************************************************************************** --->
<!--- Begin Server WebServices Methods --->

	<cffunction name="WSLTest" access="remote" returnType="struct" returnFormat="json" output="false">
    
        <cfset response = {} />
        <cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = #CreateODBCDateTime(now())# />
        
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: 
    --->
    <cffunction name="mp_patch_loader" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="data">
        <cfargument name="type">

        <cfset l = logit("Error",arguments.type)>
    
        <cfset response = {} />
        <cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cfset aObj = CreateObject( "component", "cfc.patch_loader" ).init(this.logTable) />
        <cfset res = aObj._apple(arguments.data, arguments.type) />
        
        <cfset response[ "errorNo" ] = res.errorCode />
        <cfset response[ "errorMsg" ] = res.errorMessage />
        <cfset response[ "result" ] = res.result />
        
        <cfreturn response>
    </cffunction>

    <!--- 
        MPDEV
        Remote API
        Type: Public/Remote
        Description: Add SAV AD Defs to database for downloading
        Notes: Replaced AddSavAvDefs
    --->
    <cffunction name="PostSavAvDefs" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="arch">
		<cfargument name="data">
		<cfargument name="token">

        <cfset response = {} />
        <cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = "" />

		<cfswitch expression="#Trim(arguments.arch)#"> 
		    <cfcase value="x86"></cfcase> 
		    <cfcase value="ppc"></cfcase> 
		    <cfdefaultcase> 
		        <cfset response[ "errorNo" ] = "1001" />
		        <cfset response[ "errorMsg" ] = "Invalid Data. (#arguments.arch#) (#data#)" />
		        <cfreturn response>
		    </cfdefaultcase> 
		</cfswitch> 
		
		<!--- Variable for ModDate on Insert --->
		<cfset var vMDate = #CreateODBCDateTime(now())#>
		
		<!--- deserialize json data and check the length --->
		<cfset var jData = deserializejson(arguments.data)>
		<cfif len(jData) LTE 1>
			<cfset response[ "errorNo" ] = "1002" />
		    <cfset response[ "errorMsg" ] = "Invalid Data Length." />
		    <cfreturn response>
		</cfif>
		
		<!--- Delete the records before insert 
				This will be changed in the future so that data will be deleted
				after the new data has been inserted --->
		<cftry>
			<cfquery datasource="#this.ds#" name="qPut">
	            Delete from savav_defs
				Where arch = <cfqueryparam value="#arguments.arch#">
	        </cfquery>
			<cfcatch type="any">
                <cfset response[ "errorNo" ] = "1003" />
			    <cfset response[ "errorMsg" ] = "#cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
			    <cfreturn response>
            </cfcatch>
		</cftry>
		
		<!--- Insert the new data --->
		<cftry>
	        <cfloop index="i" from="1" to="#ArrayLen(jData)#">
	            <cfquery datasource="#this.ds#" name="qPut">
	                Insert Into savav_defs (arch, file, defdate, current, mdate)
	                Values (<cfqueryparam value="#jData[i]['type']#">, <cfqueryparam value="#jData[i]['file']#">, <cfqueryparam value="#jData[i]['date']#">, <cfqueryparam value="#jData[i]['current']#">, #vMDate#)
	            </cfquery>
	        </cfloop>
            <cfcatch type = "Database">
                <cfset response[ "errorNo" ] = "1004" />
			    <cfset response[ "errorMsg" ] = "#cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
			    <cfreturn response>
			</cfcatch>
		</cftry>

        <cfreturn response>
    </cffunction>
</cfcomponent>
