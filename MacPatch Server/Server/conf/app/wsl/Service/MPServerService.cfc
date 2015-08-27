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
    
    <cffunction name="clientRequestCheck" access="private" returntype="boolean" output="no">
        <cfargument name="headers" required="yes" type="struct">
        <cfargument name="reqVers" default="0">
        
        <cfset var mpSettings = server.mpsettings.settings>
        
		<cfif structKeyExists(mpSettings,"webservices")> 
        	<cfif structKeyExists(mpSettings.webservices,"enabled")> 
            	<cfif mpSettings.webservices.enabled EQ "YES">
                	<!--- Client Header Checks is enabled --->
                	<!--- Validate header contains needed keys --->
                    <cfif structKeyExists(mpSettings.webservices,"checkVersion")> 
                    	<cfif mpSettings.webservices.checkVersion EQ "YES">
                        	<!--- Check Method Version Support --->
							<cfif NOT StructKeyExists(arguments.headers, "MPVersion-API")>
                                <cflog type="Error" file="MPServerService" text="[clientRequestCheck]: MPVersion-API was not passed up in the request.">
                                <cfreturn false>
                            </cfif> 
                            <cfset apiVersion = headers["MPVersion-API"]> 
                            <cfif apiVersion NEQ arguments.reqVer>
                                <cflog type="Error" file="MPServerService" text="[clientRequestCheck]:MPVersion-API did not equal the supported version">
                                <cflog type="Error" file="MPServerService" text="[clientRequestCheck]:MPVersion-API = #apiVersion# : SupportedVersion = #arguments.reqVer#">
                                <cfreturn false>
                            </cfif>
                        </cfif>
                    </cfif>
                    <cfif structKeyExists(mpSettings.webservices,"key")> 
                    	<cfif NOT StructKeyExists(arguments.headers, "MPClient-API")>
                            <cflog type="Error" file="MPServerService" text="[clientRequestCheck]: MPClient-API was not included in the headers.">
                            <cfreturn false>
                        </cfif>
                    	<cfif Hash(mpSettings.webservices.key,'MD5') NEQ arguments.headers["MPClient-API"]>
                            <cflog type="Error" file="MPServerService" text="[clientRequestCheck]: Key did not match.">
                            <cfreturn false>
                        </cfif>
                    </cfif>
				</cfif> <!--- enabled = yes --->
            </cfif> <!--- enabled check --->
        </cfif> <!--- webservices --->
            
        <!--- By Default we return true --->
        <cfreturn true>
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
        Remote API
        Type: Public/Remote
        Description: Post apple patch data collected from Apple SUS server
    --->
    <cffunction name="PostApplePatchContent" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="data" hint="JSON Formatted Apple Patch Data" required="yes">
        <cfargument name="type" default="JSON" required="no">
		<cfargument name="token" default="0" required="no">
		
		<cfset var mTable = "apple_patches">
		<cfset var mTableAlt = "apple_patches_mp_additions">
    
        <cfset response = {} />
        <cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = "" />
        
        <cfset supportedVersion = "1.0.0">
        
        <!--- Supported Versions --->
        <cfset headers = getHttpRequestData().headers>
        <cfif clientRequestCheck(headers, supportedVersion) EQ False>
        	<cflog type="Error" file="MPPatchLoader" text="Client Request API Check failed.">
			<cfset response[ "errorNo" ] = "1" />
            <cfreturn response>
        </cfif>
        
		<cftry>
			<cfset jData = deserializejson(arguments.data)>
			<cfcatch type="any">
				<cflog type="Error" file="MPPatchLoader" text="[1001]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
            	<cfset response[ "errorNo" ] = "1001" />
	    		<cfset response[ "errorMsg" ] = "#cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
	    		<cfreturn response>
			</cfcatch>
		</cftry>

		<cftry>
			<cflog file="MPPatchLoader" type="Information" text="---------------------------------------------">
            <cflog file="MPPatchLoader" type="Information" text="Adding #ArrayLen(jData)# patches">
			<cfloop index="i" from="1" to="#ArrayLen(jData)#">
            	<!--- Make Sure the Patch Structure is valid before trying to insert the data --->
				<cfif isValidPatchStruct(jData[i])>
                	<!--- If the patch does not exists insert the data, no need to update the data --->
					<cfset _rowExists = existsInTable(mTable,'supatchname',jData[i]['suname'])>
					<cfif _rowExists EQ False>
                    	<cflog type="Error" text="Adding #jData[i]['akey']# - #jData[i]['title']#" application="true">
						<cfquery name="qInsert" datasource="#this.ds#" result="qRes">
							INSERT INTO #mTable# ( postdate, akey, version, restartaction, title, supatchname, patchname, description64  )
							Values (
							<cfqueryparam value="#Trim(jData[i]['postdate'])#">,
							<cfqueryparam value="#Trim(jData[i]['akey'])#">,
							<cfqueryparam value="#Trim(jData[i]['version'])#">,
							<cfqueryparam value="#Trim(jData[i]['restart'])#">,
							<cfqueryparam value="#Trim(jData[i]['title'])#">,
							<cfqueryparam value="#Trim(jData[i]['suname'])#">,
							<cfqueryparam value="#Trim(jData[i]['name'])#">,
							<cfqueryparam value="#Trim(jData[i]['description'])#">
							)
						</cfquery>
                    <cfelse>
                   		<cflog file="MPPatchLoader" type="Information" text="Skipping #jData[i]['suname']#, already exists.">
					</cfif>
					<!--- Insert Additional MP Data --->
					<cfset _rowExistsAlt = existsInTable(mTableAlt,'supatchname',jData[i]['suname'])>
					<cfif _rowExistsAlt EQ False>
						<cfquery name="qInsertAlt" datasource="#this.ds#" result="qResAlt">
							INSERT INTO #mTableAlt# ( version, supatchname )
							Values (<cfqueryparam value="#jData[i]['version']#">,<cfqueryparam value="#jData[i]['suname']#">)
						</cfquery>
					</cfif>
				<cfelse>
					<cflog file="MPPatchLoader" type="Error" text="Skipping #jData[i]['suname']# not a valid patch object.">
				</cfif>
			</cfloop>
			<cfcatch type="any">
				<cflog type="Error" file="MPPatchLoader" text="[1002]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
            	<cfset response[ "errorNo" ] = "1002" />
	    		<cfset response[ "errorMsg" ] = "#cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
	    		<cfreturn response>
			</cfcatch>
		</cftry>
        <cfreturn response>
    </cffunction>
    
	<!--- Private Helper Method --->
	<cffunction name="existsInTable" access="private" returntype="any" output="no">
		<cfargument name="aTable">
		<cfargument name="aField">
		<cfargument name="aFieldValue">
		<cftry>
	    	<cfquery datasource="#this.ds#" name="qGet">
	            Select #arguments.aField#
	            From #arguments.aTable#
	            Where #arguments.aField# = <cfqueryparam value="#arguments.aFieldValue#">
	        </cfquery>

	        <cfif qGet.RecordCount EQ 0>
	        	<cfreturn False>
	        <cfelse>
	        	<cfreturn True>
	        </cfif>
	        
			<cfcatch type="any">
				<cflog type="Error" file="MPPatchLoader" text="[existsInTable][1001]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
	    		<cfreturn false>
			</cfcatch>
		</cftry>
		<cfreturn false>
	</cffunction>
	<!--- Private Helper Method --->
	<cffunction name="isValidPatchStruct" access="private" returntype="any" output="no">
		<cfargument name="aPatch">
		
		<cfif NOT IsStruct(arguments.aPatch)>
			<cflog file="MPPatchLoader" type="Error" text="[isValidPatchStruct]: NOT IsStruct">
			<cfreturn False>
		</cfif>
		<cfset keys = StructKeyList(arguments.aPatch)>
		<cfset reqKeys = "postdate,akey,version,restart,title,suname,name,description">
		<cfloop index="key" list="#reqKeys#" delimiters = ",">
			<cfif ListContainsNoCase(keys, key) EQ 0>
				<cflog type="Error" text="isValidPatchStruct[ListContainsNoCase]: #keys# (#key#)" application="true">
				<cfreturn False>
			</cfif>
		</cfloop>
		<cfreturn True>
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
