<!--- **************************************************************************************** --->
<!---
        MPClientService 
        Database type is MySQL
        MacPatch Version 2.2.x
--->
<!---   Notes:
--->
<!--- **************************************************************************************** --->
<cfcomponent>
    <!--- Configure Datasource --->
    <cfset this.ds = "mpds">
    <cfset this.cacheDirName = "cacheIt">
    <cfset this.logTable = "ws_clt_logs">

    <cffunction name="init" returntype="MPClientService" output="no">
        <cfargument name="aTableLog" required="no" default="ws_clt_logs">

        <cfset this.logTable = arguments.aTableLog>
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
        <cftry>
        <cfquery datasource="#this.ds#" name="qGet">
            Insert Into #this.logTable# (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#arguments.aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
        <cfcatch>
            <cflog file="#this.logTable#" type="#arguments.aEventType#" application="no" text="[#inet#]: #arguments.aEvent#">
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="elogit" access="public" returntype="void" output="no">
        <cfargument name="aEvent">
        
        <cfset l = logit("Error",arguments.aEvent)>
    </cffunction>

<!--- **************************************************************************************** --->
<!--- Begin Client WebServices Methods --->

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Simple Test To See if WebService is alive and working
    --->
    <cffunction name="WSLTest" access="remote" returnType="struct" returnFormat="json" output="false">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = #CreateODBCDateTime(now())# />
        
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Clear Query Caches
    --->
    <cffunction name="clearCache" access="remote" returnType="struct" returnFormat="json" output="false">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cftry>
            <cfobjectcache action="CLEAR">

            <cfcatch type="any">
                <cfset l = elogit("[clearCache]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = "[clearCache]: #cfcatch.Detail# -- #cfcatch.Message#">
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: 
    --->
    <cffunction name="client_checkin_base" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="data">
        <cfargument name="type">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cfset aObj = CreateObject( "component", "cfc.client_checkin" ) />
        <cfset res = aObj._base(arguments.data, arguments.type) />
        
        <cfset response[ "errorno" ] = res.errorCode />
        <cfset response[ "errormsg" ] = res.errorMessage />
        <cfset response[ "result" ] = res.result />
        
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: 
    --->
    <cffunction name="client_checkin_plist" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="data">
        <cfargument name="type">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cfset aObj = CreateObject( "component", "cfc.client_checkin" ) />
        <cfset res = aObj._plist(arguments.data, arguments.type) />
        
        <cfset response[ "errorno" ] = res.errorCode />
        <cfset response[ "errormsg" ] = res.errorMessage />
        <cfset response[ "result" ] = res.result />
        
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Name: GetAgentUpdaterUpdates
        Description: Returns The Agent Updater update info
    --->
    <cffunction name="GetAgentUpdaterUpdates" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID">
        <cfargument name="agentUp2DateVer">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetLatestVersion">
                Select agent_ver as agent_version, version, framework as agent_framework, build as agent_build,
                pkg_Hash, pkg_Url, puuid, pkg_name, osver
                From mp_client_agents
                Where type = 'update'
                AND active = '1'
                ORDER BY
                INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
                INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC
            </cfquery>

            <cfcatch type="any">
                <cfset l = elogit("[GetAgentUpdaterUpdates][qGetLatestVersion]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = "[GetAgentUpdaterUpdates][qGetLatestVersion]: #cfcatch.Detail# -- #cfcatch.Message#">
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfset var count = 0>
        <cfset var agentVerReq = "10.5.8">

        <cfif qGetLatestVersion.RecordCount EQ 1>
            <cfset agentVerReq = #replacenocase(qGetLatestVersion.osver,"+","", "All")#>
            <cfoutput query="qGetLatestVersion">
                <cfif versionCompare(version,arguments.agentUp2DateVer) EQ 1>
                    <cfset count = count + 1>
                </cfif>
            </cfoutput>
        </cfif>

       <!--- If a Version Number is Higher check filter --->
        <cfif count GTE 1>
            <cfif Len(Trim(arguments.clientID)) EQ 0>
                <!--- No CUUID Info --->
                <cfset count = 0>
            <cfelse>
                <!--- CUUID is found --->
                <cfset qGetClientGroup = clientDataForID(arguments.clientID)>
                <cfif qGetClientGroup.RecordCount NEQ 0>
                    <!--- This is for testing Update only certain clients. based on cuuid return data --->
                    <cfif versionCompare(agentVerReq,qGetClientGroup.osver) EQ 1>
                        <cfset count = 0>
                    <cfelse>
                        <cfoutput query="qGetClientGroup">
                            <cfset x = SelfUpdateFilter("app")>
                            <cfif Len(x) GTE 1>
                                <cfif evaluate(x)>
                                    <cfset count = 1>
                                <cfelse>
                                    <cfset count = 0>
                                </cfif>
                            <cfelse>
                                <cfset count = 0>
                            </cfif>
                        </cfoutput>
                    </cfif>    
                <cfelse>
                    <cfset count = 0>
                </cfif>
            </cfif>
        </cfif>
        
        <cfset update = {} />
        <cfset update[ "updateAvailable" ] = #IIF(count GTE 1,DE('true'),DE('false'))# />
        <cfif count GTE 1>
            <cfset update[ "SelfUpdate" ] = {} />
            <cfset SelfUpdate = {} />
            <cfoutput query="qGetLatestVersion">
                <cfloop list="#qGetLatestVersion.ColumnList#" index="column">
                    <cfset SelfUpdate[ column ] = #iif(len(Evaluate(column)) GTE 1,DE(Trim(Evaluate(column))),DE('Null'))# />
                </cfloop>
            </cfoutput>
            <cfset update[ "SelfUpdate" ] = #SelfUpdate# />
        </cfif>

        <cfset response[ "result" ] = #update# />
        <cfreturn response>
    </cffunction>

    <!--- 
        Type: Private
        Used By: GetAgentUpdaterUpdates
        Description: Compares version strings
    --->
    <cffunction name="versionCompare" access="private" returntype="numeric" output="no">
        <!--- It returns 1 when argument 1 is greater, -1 when argument 2 is greater, and 0 when they are exact matches. --->
        <cfargument name="leftVersion" required="yes" default="0">
        <cfargument name="rightVersion" required="yes" default="0">

        <cfset var len1 = listLen(arguments.leftVersion, '.')>
        <cfset var len2 = listLen(arguments.rightVersion, '.')>
        <cfset var piece1 = "">
        <cfset var piece2 = "">

        <cfif len1 GT len2>
            <cfset arguments.rightVersion = arguments.rightVersion & repeatString('.0', len1-len2)>
        <cfelse>
            <cfset arguments.leftVersion = arguments.leftVersion & repeatString('.0', len2-len1)>
        </cfif>

        <cfloop index = "i" from="1" to=#listLen(arguments.leftVersion, '.')#>
            <cfset piece1 = listGetAt(arguments.leftVersion, i, '.')>
            <cfset piece2 = listGetAt(arguments.rightVersion, i, '.')>

            <cfif piece1 NEQ piece2>
                <cfif piece1 GT piece2>
                    <cfreturn 1>
                <cfelse>
                    <cfreturn -1>
                </cfif>
            </cfif>
        </cfloop>

        <cfreturn 0>
    </cffunction>

    <!--- 
        Type: Private
        Used By: GetAgentUpdaterUpdates
        Description: Builds self update query string 
    --->
    <cffunction name="selfUpdateFilter" access="private" returntype="string" output="no">
        <cfargument name="aType">
        <cftry>
            <cfquery datasource="#this.ds#" name="qGet">
                Select * From mp_client_agents_filters
                Where type = <cfqueryparam value="#arguments.aType#">
                Order By rid ASC
            </cfquery>
            <cfset var result = "">
            <cfoutput query="qGet">
                <cfset result = listAppend(result,IIF(attribute EQ "All",DE("""All"""),DE(attribute)))>
                <cfset result = listAppend(result,attribute_oper)>
                <cfset result = listAppend(result,""""&attribute_filter&"""")>
                <cfset result = listAppend(result,attribute_condition)>
            </cfoutput>
            <cfset result = ListDeleteAt(result, ListLen(result))>
            <cfset result = Replace(result,","," ","All")>
        <cfcatch>
            <!--- If Error, default to none --->
            <cfset l = elogit("[SelfUpdateFilter][Set Result to No]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
            <cfset result = """All"" EQ ""NO""">
        </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns The Agent Updater info
    --->
    <cffunction name="GetAgentUpdates" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no">
        <cfargument name="agentVersion" default="0">
        <cfargument name="agentBuild" default="0">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetLatestVersion" maxrows="1">
                Select agent_ver as agent_version, version, framework as agent_framework, build as agent_build,
                pkg_Hash, pkg_Url, puuid, pkg_name, osver
                From mp_client_agents
                Where type = 'app'
                AND
                active = '1'
                ORDER BY
                INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
                INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC
            </cfquery>
            <cfcatch type="any">
                <cfset l = elogit("[GetAgentUpdates]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = "[GetAgentUpdates]: #cfcatch.Detail# -- #cfcatch.Message#">
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfset var count = 0>
        <cfset var agentVerReq = "10.5.8">
        <cfif qGetLatestVersion.RecordCount EQ 1>
            <cfset agentVerReq = #replacenocase(qGetLatestVersion.osver,"+","", "All")#>
            <cfoutput query="qGetLatestVersion">
                <cfif versionCompare(agent_version,arguments.agentVersion) EQ 1>
                    <cfset count = count + 1>
                </cfif>
                <cfif versionCompare(agent_build,arguments.agentBuild) EQ 1 AND #arguments.agentBuild# NEQ "0">
                    <cfset count = count + 1>
                </cfif>
            </cfoutput>
        <cfelse>
            <cfset l = elogit("[GetSelfUpdates][qGetLatestVersion][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response.errorno = "2">
            <cfset response.errormsg = "[GetAgentUpdates]: Found #qGetLatestVersion.RecordCount# records. Should only find 1.">
            <cfreturn response>
        </cfif>

        <!--- If a Version Number is Higher check filter --->
        <cfif count GTE 1>
            <cfif Len(Trim(arguments.clientID)) EQ 0>
                <!--- No CUUID Info --->
                <cfset count = 0>
            <cfelse>
                <!--- CUUID is found --->
                <cfset qGetClientGroup = clientDataForID(arguments.clientID)>
                <cfif qGetClientGroup.RecordCount NEQ 0>
                    <!--- This is for testing Update only certain clients. based on cuuid return data --->
                    <cfif versionCompare(agentVerReq,qGetClientGroup.osver) EQ 1>
                        <cfset count = 0>
                    <cfelse>
                        <cfoutput query="qGetClientGroup">
                            <cfset x = SelfUpdateFilter("app")>
                            <cfif evaluate(x)>
                                <cfset count = 1>
                            <cfelse>
                                <cfset count = 0>
                            </cfif>
                        </cfoutput>
                   </cfif>     
                <cfelse>
                    <cfset count = 0>
                </cfif>
            </cfif>
        </cfif>
        
        <cfset update = {} />
        <cfset update[ "updateAvailable" ] = #IIF(count GTE 1,DE('true'),DE('false'))# />
        <cfif count GTE 1>
            <cfset update[ "SelfUpdate" ] = {} />
            <cfset SelfUpdate = {} />
            <cfoutput query="qGetLatestVersion">
                <cfloop list="#qGetLatestVersion.ColumnList#" index="column">
                    <cfset SelfUpdate[ column ] = #iif(len(Evaluate(column)) GTE 1,DE(Trim(Evaluate(column))),DE('Null'))# />
                </cfloop>
            </cfoutput>
            <cfset update[ "SelfUpdate" ] = #SelfUpdate# />
        </cfif>

        <cfset response[ "result" ] = #update# />
        <cfreturn response>
    </cffunction>

    <!--- 
        Type: Private
        Used By: GetAgentUpdaterUpdates, GetAgentUpdates
        Description: Returns client info from the ClientID as query
    --->
    <cffunction name="clientDataForID" access="private" returntype="query" output="no">
        <cfargument name="clientID">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGet">
                Select cuuid, ipaddr, hostname, Domain, ostype, osver
                From mp_clients_view
                Where cuuid = <cfqueryparam value="#arguments.clientID#">
            </cfquery>
            
            <cfreturn qGet>
        <cfcatch>
            <!--- If Error, default to none --->
            <cfset l = elogit("[clientDataForID][Set Result to No]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
        </cfcatch>
        </cftry>

        <cfreturn QueryNew("cuuid, ipaddr, hostname, Domain, ostype, osver")>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns The Current AVDefs date
    --->
    <cffunction name="GetAVDefsDate"  access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="avAgent" required="true">
        <cfargument name="theArch" required="false" default="x86">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />
        
        <cfif arguments.avAgent NEQ "SEP" AND arguments.avAgent NEQ "SAV">
            <cfset l = elogit("[GetAVDefsDate]: Unknown avAgent config. Schema may de out of date.")>
            <cfset response[ "errorno" ] = "1" />
            <cfset response[ "errormsg" ] = "[GetAVDefsDate]: Unknown avAgent config. Schema may de out of date." />
            <cfreturn response>
        </cfif>
        
        <cftry>
            <cfquery datasource="#this.ds#" name="qGet">
                Select defdate from savav_defs
                Where arch = <cfqueryparam value="#Trim(arguments.theArch)#">
                AND current = 'YES'
            </cfquery>
            
            <cfif qGet.RecordCount EQ 1>
                <cfset response.result = "#qGet.defdate#">
            <cfelse>
                <cfset response.result = "NA">
            </cfif>

            <cfcatch type="any">
                <cfset l = elogit("[GetAVDefsDate]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = cfcatch.Message>
            </cfcatch>
        </cftry>
                
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns The Current AVDefs file path for install 
    --->
    <cffunction name="GetAVDefsFile" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="avAgent" required="true">
        <cfargument name="theArch" required="false" default="x86">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />
        
        <cfif arguments.avAgent NEQ "SEP" AND arguments.avAgent NEQ "SAV">
            <cfset l = elogit("[GetAVDefsFile]: Unknown avAgent config. Schema may de out of date.")>
            <cfset response[ "errorno" ] = "1" />
            <cfset response[ "errormsg" ] = "[GetAVDefsFile]: Unknown avAgent config. Schema may de out of date." />
            <cfreturn response>
        </cfif>
        
        <cftry>
            <cfquery datasource="#this.ds#" name="qGet">
                Select file from savav_defs
                Where arch = <cfqueryparam value="#Trim(arguments.theArch)#">
                AND current = 'YES'
            </cfquery>
            
            <cfif qGet.RecordCount EQ 1>
                <cfset response.result = "#qGet.file#">
            <cfelse>
                <cfset response.result = "NA">
            </cfif>

            <cfcatch type="any">
                <cfset l = elogit("[GetAVDefsFile]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = cfcatch.Message>
            </cfcatch>
        </cftry>
                
        <cfreturn response>
    </cffunction> 

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns the JSON formatted patch group data for a requested group
    --->
    <cffunction name="GetIsHashValidForPatchGroup" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no" default="0" type="string">
        <cfargument name="PatchGroup" required="yes">
        <cfargument name="Hash" required="yes" type="string">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />
    
        <cftry>
            <!--- Get the Patch Group ID from the PatchGroup Name --->
            <cfset pid = patchGroupIDFromName(arguments.PatchGroup)>
            <cfquery datasource="#this.ds#" name="qGetGroupID" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                SELECT mdate FROM mp_patch_group_data
                WHERE pid = <cfqueryparam value="#pid#">
                AND hash = <cfqueryparam value="#arguments.Hash#">
            </cfquery>
            
            <cfif qGetGroupID.RecordCount EQ 1>
                <cfset response[ "result" ] = "1" />
            <cfelse>    
                <cfset l = logit("Error","[GetIsHashValidForPatchGroup][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: No group was found for #arguments.PatchGroup#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetIsHashValidForPatchGroup][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: No group was found for #arguments.PatchGroup#" />
                <cfreturn response>
            </cfif>
            
            <cfcatch>
                <cfset l = logit("Error","[GetIsHashValidForPatchGroup]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetIsHashValidForPatchGroup][qGetGroupID]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

    <!--- 
        Type: Private
        Used By: GetIsHashValidForPatchGroup
        Description: Returns Patch Group ID from name
    --->
    <cffunction name="patchGroupIDFromName" access="private" returntype="any" output="no">
        <cfargument name="patchGroup">

        <cftry>
            <cfset l = elogit("[patchGroupIDFromName][SQL]: Select id from mp_patch_group Where name = #arguments.patchGroup#")>
            
            <cfquery datasource="#this.ds#" name="qGet">
                Select id from mp_patch_group 
                Where name = <cfqueryparam value="#arguments.patchGroup#">
            </cfquery>
            
            <cfset l = elogit("[patchGroupIDFromName][SQL][Result]: #qGet.id#")>
            <cfreturn #qGet.id#>
        <cfcatch>
            <!--- If Error, default to none --->
            <cfset l = elogit("[patchGroupIDFromName][Set Result to No]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
        </cfcatch>
        </cftry>

        <cfreturn "0">
    </cffunction>
    
    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns the JSON formatted patch group data for a requested group
    --->
    <cffunction name="GetPatchGroupPatches" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no" default="0" type="string">
        <cfargument name="PatchGroup" required="yes">
        <cfargument name="DataType" required="no" default="JSON" type="string">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />
    
        <cftry>
            <!--- Get the Patch Group ID from the PatchGroup Name --->
            <cfquery datasource="#this.ds#" name="qGetGroupID" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                Select id from mp_patch_group
                Where name = <cfqueryparam value="#arguments.PatchGroup#">
            </cfquery>
            <cfif qGetGroupID.RecordCount NEQ 1>
                <cfset l = logit("Error","[GetPatchGroupPatches][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: No group was found for #arguments.PatchGroup#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetPatchGroupPatches][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: No group was found for #arguments.PatchGroup#" />
                <cfreturn response>
            </cfif>
            <cfcatch>
                <cfset l = logit("Error","[GetPatchGroupPatches]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetPatchGroupPatches][qGetGroupID]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
            </cfcatch>
        </cftry>
        
        <cftry>
            <cfquery datasource="#this.ds#" name="qGetGroupData" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                Select data from mp_patch_group_data
                Where pid = <cfqueryparam value="#qGetGroupID.id#">
                AND data_type = <cfqueryparam value="#arguments.DataType#">
            </cfquery>
            <cfif qGetGroupID.RecordCount NEQ 1>
                <cfset l = logit("Error","[GetPatchGroupPatches][qGetGroupData]: No group data was found for id #qGetGroupID.id#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetPatchGroupPatches][qGetGroupData]: No group data was found for id #qGetGroupID.id#" />
                <cfreturn response>
            </cfif>
            <cfset response.result  =  #qGetGroupData.data#> />
            
            <cfcatch>
                <cfset l = logit("Error","[GetPatchGroupPatches]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetPatchGroupPatches][qGetGroupData]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns the custom patch scan data
    --->
    <cffunction name="GetScanList" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no" default="0" type="string">
        <cfargument name="state" required="no" default="all" type="string">
        <cfargument name="active" required="no" default="1" type="string">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />
        
        <cfset var jData = "">
        <cftry>
            <cfset var myObj = CreateObject("component","cfc.PatchScanManifest").init(this.ds)>
            <cfset jData = myObj.createScanListJSON(arguments.state,arguments.active)>
            <cfset response.result = DeserializeJSON(jData) />
            
            <cfcatch type="any">
                <cfset l = elogit("[GetScanList][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetScanList][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#" />
            </cfcatch>
        </cftry>
    
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Add client AV data for SEP or SAV types
    --->
    <cffunction name="PostClientAVData" access="remote" returnType="struct" returnformat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="avAgent" required="true">
        <cfargument name="jsonData" required="true">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cfif Trim(arguments.avAgent) NEQ "SEP" AND Trim(arguments.avAgent) NEQ "SAV">
            <cfset l = elogit("[PostClientAVData]: Unknown avAgent config. Schema may be out of date.")>
            <cfset response[ "errorno" ] = "1" />
            <cfset response[ "errormsg" ] = "[PostClientAVData]: Unknown avAgent #arguments.avAgent# config. Schema may be out of date." />
            <cfreturn response>
        </cfif>

        <cftry>
            <cfset var avData = DeserializeJSON(arguments.jsonData)>
            <cfcatch type="any">
                <cfset l = elogit("[PostClientAVData][Deserializejson]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "0" />
                <cfset response[ "errormsg" ] = "[PostClientAVData][Deserializejson]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
        </cftry>


        <cfquery datasource="#this.ds#" name="qGetClient" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
            Select cuuid From savav_info
            Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
        </cfquery>
        
        <cftry>
            <cfparam name="l_CFBundleExecutable" default="NA" />
            <cfparam name="l_NSBundleResolvedPath" default="NA" />
            <cfparam name="l_CFBundleVersion" default="NA" />
            <cfparam name="l_CFBundleShortVersionString" default="NA" />
            <cfparam name="l_LastFullScan" default="NA" />
            <cfparam name="l_DefsDate" default="NA" />
    
            <cfif structkeyexists(avData,"CFBundleExecutable")>
                <cfset l_CFBundleExecutable = trim(avData.CFBundleExecutable)>
            </cfif>
            <cfif structkeyexists(avData,"NSBundleResolvedPath")>
                <cfset l_NSBundleResolvedPath = trim(avData.NSBundleResolvedPath)>
            </cfif>
            <cfif structkeyexists(avData,"CFBundleVersion")>
                <cfset l_CFBundleVersion = trim(avData.CFBundleVersion)>
            </cfif>
            <cfif structkeyexists(avData,"CFBundleShortVersionString")>
                <cfset l_CFBundleShortVersionString = trim(avData.CFBundleShortVersionString)>
            </cfif>
            <cfif structkeyexists(avData,"DefsDate")>
                <cfset l_DefsDate = trim(avData.DefsDate)>
            </cfif>
    
            <!--- Client Data Does not Exist, if there remove it --->
            <cfif l_CFBundleExecutable EQ "NA" AND l_CFBundleVersion EQ "NA"> 
                <cfif qGetClient.RecordCount GTE 1>
                    <cfquery datasource="#this.ds#" name="qRmClient">
                        Delete From savav_info
                        Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
                    </cfquery>
                </cfif>
                <cfreturn response>
            </cfif>
        
            <cfcatch type="any">
                <cfset l = elogit("[PostClientAVData]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "2" />
                <cfset response[ "errormsg" ] = "[PostClientAVData]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
        </cftry>

        <!--- Query the table to see if we need a update or a insert --->
        <cfif qGetClient.RecordCount EQ 0>
            <cftry>
                <cfquery datasource="#this.ds#" name="qPut">
                    Insert Into savav_info
                        (cuuid,defsDate,savShortVersion,savBundleVersion,
                        appPath,lastFullScan,savAppName,mdate)
                    Values
                        (<cfqueryparam value="#arguments.clientID#">,<cfqueryparam value="#l_DefsDate#">,
                        <cfqueryparam value="#l_CFBundleShortVersionString#">,<cfqueryparam value="#l_CFBundleVersion#">,
                        <cfqueryparam value="#l_NSBundleResolvedPath#">,<cfqueryparam value="#l_LastFullScan#">,
                        <cfqueryparam value="#l_CFBundleExecutable#">,#CreateODBCDateTime(now())#)
                </cfquery>
            <cfcatch type="any">
                <cfset l = elogit("[AddClientSAVData][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[PostClientAVData][qPut]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
            </cftry>
        <cfelse>
            <cftry>
                <cfquery datasource="#this.ds#" name="qPut">
                    UPDATE savav_info
                    SET defsDate =              <cfqueryparam value="#l_DefsDate#">,
                        savShortVersion =       <cfqueryparam value="#l_CFBundleShortVersionString#">,
                        savBundleVersion =      <cfqueryparam value="#l_CFBundleVersion#">,
                        appPath =               <cfqueryparam value="#l_NSBundleResolvedPath#">,
                        lastFullScan =          <cfqueryparam value="#l_LastFullScan#">,
                        savAppName =            <cfqueryparam value="#l_CFBundleExecutable#">,
                        mdate =             #CreateODBCDateTime(now())#
                    Where cuuid = <cfqueryparam value="#arguments.clientID#">
                </cfquery>
            <cfcatch type="any">
                <cfset l = elogit("[AddClientSAVData][Update]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[PostClientAVData][qPut]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
            </cftry>
        </cfif>

        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Post DataMgr XML and write it out for inventory app to pick it up
    --->
    <cffunction name="PostDataMgrXML" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID">
        <cfargument name="encodedXML">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <!--- Clean a bit of the XML char before parsing --->
        <cfset var theXML = ToString(ToBinary(Trim(arguments.encodedXML)))>

        <cftry>
            <cfset jvmObj = CreateObject("java","java.lang.System").getProperties() />
            <!--- Figureout if Jetty Or Tomcat --->
            <cfif IsDefined("jvmObj.catalina.base")>
                <cfset _InvData = #jvmObj.catalina.base# & "/InvData">
            <cfelseif IsDefined("jvmObj.jetty.home")>
                <cfset _InvData = #jvmObj.jetty.home# & "/InvData">
            </cfif>
            <!--- Create Nessasary Dirs --->
            <cfif DirectoryExists(_InvData) EQ False>
                <cfset tmpD = DirectoryCreate(_InvData)>
            </cfif>

            <cfset _InvFiles = #_InvData# &"/Files">
            <cfif DirectoryExists(_InvFiles) EQ False>
                <cfset tmpD = DirectoryCreate(_InvFiles)>
            </cfif>

            <cfset dirF = #_InvFiles# & "/mpi_" & #CreateUuid()# & ".txt">
            <cffile action="write" NAMECONFLICT="makeunique" file="#dirF#" output="#theXML#">

            <cfcatch type="any">
                <cfset l = elogit("[PostDataMgrXML][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[PostDataMgrXML][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
        </cftry>
        
        <cfreturn response>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Post Client Patch Install Results
    --->
    <cffunction name="PostInstalledPatch" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="clientKey" required="false" default="0" />
        <cfargument name="patch" required="false" default="0" />
        <cfargument name="patchType" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qAddPatchInstall">
                INSERT INTO mp_installed_patches
                Set
                cuuid = <cfqueryparam value="#arguments.clientID#">,
                patch = <cfqueryparam value="#arguments.patch#">,
                patch_name = <cfqueryparam value="#getPatchName(arguments.patch, arguments.patchType)#">,
                type = <cfqueryparam value="#arguments.patchType#">,
                date = #CreateODBCDateTime(now())#
            </cfquery>

            <cfset _updateIt = #updateInstalledPatchStatus(arguments.clientID, arguments.patch, arguments.patchType)#>
            <cfif _updateIt EQ false>
                <cfset l = elogit("[addInstalledPatch][updateInstalledPatchStatus]: Returned false for #arguments.clientID#, #arguments.patch#, #arguments.patchType#")>
            </cfif>

            <cfcatch type="any">
                <cfset l = elogit("[PostInstalledPatch]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = cfcatch.Message>
            </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!--- 
        Type: Private
        Used By: PostInstalledPatch
        Description: Updates the patch info for the client status
    --->
    <cffunction name="updateInstalledPatchStatus" access="private" returntype="boolean">
        <cfargument name="cuuid" required="yes">
        <cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">

        <cftry>
            <cfif arguments.type EQ "Apple">
                <cfquery datasource="#this.ds#" name="qGet">
                    Select cuuid From mp_client_patches_apple
                    Where patch = <cfqueryparam value="#arguments.patch#">
                    AND cuuid = <cfqueryparam value="#Trim(arguments.cuuid)#">
                </cfquery>
                <cfif qGet.RecordCount EQ 1>
                    <cfquery datasource="#this.ds#" name="qDel">
                        Delete from mp_client_patches_apple
                        Where rid = <cfqueryparam value="#qGet.rid#">
                    </cfquery>
                </cfif>
            </cfif>
            <cfif arguments.type EQ "Third">
                <cfquery datasource="#this.ds#" name="qGet">
                    Select cuuid From mp_client_patches_third
                    Where patch_id = <cfqueryparam value="#arguments.patch#">
                    AND cuuid = <cfqueryparam value="#Trim(arguments.cuuid)#">
                </cfquery>
                <cfif qGet.RecordCount EQ 1>
                    <cfquery datasource="#this.ds#" name="qDel">
                        Delete from mp_client_patches_third
                        Where rid = <cfqueryparam value="#qGet.rid#">
                    </cfquery>
                </cfif>
            </cfif>
        <cfcatch type="any">
            <cfset l = elogit("[updateInstalledPatchStatus]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfreturn false>
        </cfcatch>
        </cftry>

        <cfreturn true>
    </cffunction>

    <!--- 
        Type: Private
        Used By: PostInstalledPatch
        Description: Returns the patch name from the patch ID
    --->
    <cffunction name="GetPatchName" access="private" returntype="any">
        <cfargument name="patchID" required="yes">
        <cfargument name="type" required="yes">

        <cfif UCase(arguments.type) EQ "APPLE">
            <cfreturn arguments.patchID>
        <cfelse>
            <cftry>
                <cfquery datasource="#this.ds#" name="qGet">
                    Select patch_name, patch_ver From mp_patches
                    Where puuid = <cfqueryparam value="#arguments.patchID#">
                </cfquery>
                <cfset result = "#qGet.patch_name#-#qGet.patch_ver#">
                <cfreturn result>
            <cfcatch>
                <cfset l = elogit("[getPatchName]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfreturn arguments.patchID>
            </cfcatch>
            </cftry>
        </cfif>

        <!--- Should Not Get Here --->
        <cfreturn arguments.patchID>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns Apple Software Update Catalogs based on OSMinior version
    --->
    <cffunction name="GetAsusCatalogs" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="osminor" required="yes" type="string">
        <cfargument name="clientKey" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetCatalogs" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                select catalog_url, proxy
                from mp_asus_catalogs
                Where os_minor = <cfqueryparam value="#arguments.osminor#">
                Order By c_order ASC
            </cfquery>
            
            <cfset _CatalogURLS = arrayNew(1)>
            <cfset _ProxyCatalogURLS = arrayNew(1)>
            
            <cfoutput query="qGetCatalogs">
                <cfif #proxy# EQ "0"><cfset ArrayAppend(_CatalogURLS, Trim(catalog_url))></cfif>
            </cfoutput>
            <cfoutput query="qGetCatalogs">
                <cfif #proxy# EQ "1"><cfset ArrayAppend(_ProxyCatalogURLS, Trim(catalog_url))></cfif>
            </cfoutput>

            <cfset catalogs = {} />
            <cfset catalogs[ "CatalogURLS" ] = {} />
            <cfset catalogs[ "ProxyCatalogURLS" ] = {} />

            <cfset catalogs = {} />
            <cfset catalogs[ "CatalogURLS" ] = "#_CatalogURLS#" />
            <cfset catalogs[ "ProxyCatalogURLS" ] = "#_ProxyCatalogURLS#" />
            
            <cfset result = catalogs />
            <cfset response.result = serializeJSON(result)>
            
        <cfcatch>
            <cfset l = elogit("[GetAsusCatalogs]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response.errorno = "1">
            <cfset response.errormsg = cfcatch.Message>            
        </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns the number of patches needed by a client
    --->
    <cffunction name="GetClientPatchStatusCount" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="clientKey" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cfset _result = {} />
        <cfset _result[ "totalPatchesNeeded" ] = "NA" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetClientPatchGroup" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                select id from mp_patch_group
                Where name = (  select PatchGroup from mp_clients_view
                                Where cuuid = <cfqueryparam value="#arguments.clientID#">)
            </cfquery>
            <cfset var l_PatchGroupID = #qGetClientPatchGroup.id#>

            <cfquery datasource="#this.ds#" name="qGetClientPatchState">
                select 1 from client_patch_status_view
                Where
                    cuuid = <cfqueryparam value="#arguments.clientID#">
                AND patch_id in (
                    select patch_id
                    from mp_patch_group_patches
                    where mp_patch_group_patches.patch_group_id = <cfqueryparam value="#l_PatchGroupID#"> )
                Order By date Desc
            </cfquery>

            <cfset _result[ "totalPatchesNeeded" ] = "#qGetClientPatchState.RecordCount#" />
            <cfset response.result = serializeJSON(_result)>

            <cfcatch type="any">
                <cfset response.errorno = "1">
                <cfset response.errormsg = cfcatch.Message>
                <cfset l = elogit("[GetClientPatchStatusCount]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns the last datetime a client checked in
    --->
    <cffunction name="GetLastCheckIn" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="clientKey" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cfset _result = {} />
        <cfset _result[ "mdate" ] = "NA" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGet">
                SELECT mdate
                FROM mp_clients_view
                WHERE cuuid = <cfqueryparam value="#arguments.clientID#">
            </cfquery>

            <cfset _result[ "mdate" ] = "#DateFormat(qGet.mdate, "mm/dd/yyyy")# #TimeFormat(qGet.mdate, "HH:mm:ss")#" />
            <cfset response.result = serializeJSON(_result)>

        <cfcatch>
            <cfset l = elogit("[GetLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response.errorno = "1">
            <cfset response.errormsg = cfcatch.Message>
        </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns json data of SW tasks for a SW group
        Note: This function needs to be updated so that the entire JSON result is not 
        stored in the DB just the data.
    --->
    <cffunction name="GetSoftwareTasksForGroup" access="remote" returnType="any" returnFormat="plain" output="false">
        <cfargument name="GroupName">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "1" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />
        
        <cftry>
            <cfset gid = softwareGroupID(arguments.GroupName)>
            <cfquery datasource="#this.ds#" name="qGetGroupTasksData" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                Select gData From mp_software_tasks_data
                Where gid = '#gid#'
            </cfquery>
            
            <cfif qGetGroupTasksData.RecordCount EQ 1>
                <!--- Response is already stored in DB, fully formatted --->
                <cfreturn #qGetGroupTasksData.gData#>
            <cfelse>
                <cfset response[ "errormsg" ] = "No task group data found for #arguments.GroupName#." />
                <cfset response[ "result" ] = {} />
            </cfif>    
        <cfcatch>
            <cfset l = elogit("[GetSoftwareTasksForGroup]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response[ "errormsg" ] = "[GetSoftwareTasksForGroup]: #cfcatch.Detail# -- #cfcatch.Message#" />
        </cfcatch> 
        </cftry>
        <cfreturn SerializeJson(response)>
    </cffunction>

    <!--- 
        Type: Private
        Used By: GetSoftwareTasksForGroup
        Description: Returns the patch name from the patch ID
    --->
    <cffunction name="softwareGroupID" access="private" returntype="any" output="no">
        <cfargument name="GroupName">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetID" cachedwithin="#CreateTimeSpan(0,8,0,0)#">
                Select gid from mp_software_groups
                Where gName = '#arguments.GroupName#'
            </cfquery>

            <cfif qGetID.RecordCount EQ 1>
                <cfreturn #qGetID.gid#>
            </cfif>
        <cfcatch>
            <cfset l = elogit("[softwareGroupID]: #cfcatch.Detail# -- #cfcatch.Message#")>
        </cfcatch>    
        </cftry>
        <cfreturn "0">
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Returns a list of software group names and description
    --->
    <cffunction name="GetSWDistGroups" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="state" required="false" default="1" />
        
        <cfset var gState = "state IN (1)">
        <cfif IsNumeric(arguments.state)>
            <cfif arguments.state EQ "3">
                <cfset gState = "state IN (1,2)">
            <cfelse>
                <cfset gState = "state IN (#arguments.state#)"> 
            </cfif>
        <cfelse>    
            <cfset l = logit("Error","[GetSWDistGroups]: State arguments was not of numeric value. Setting state to Production.")>
        </cfif>

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetHosts">
                SELECT gName, gDescription
                FROM mp_software_groups
                Where #gState#
            </cfquery>
            
            <cfset _Groups = arrayNew(1)>

            <cfoutput query="qGetHosts">
                <cfset _result = {} />
                <cfset _result[ "Name" ] = "#qGetHosts.gName#" />
                <cfset _result[ "Desc" ] = "#qGetHosts.gDescription#" />
                <cfset a = ArrayAppend(_Groups,_result)>
            </cfoutput>

            <cfset response.result = serializeJSON(_Groups)>
            
        <cfcatch>
            <cfset l = elogit("[GetSWDistGroups]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response.errorno = "1">
            <cfset response.errormsg = cfcatch.Message>
        </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!--- 
        Remote API
        Type: Public/Remote
        Description: Function to post client software install results
    --->
    <cffunction name="PostSoftwareInstallResults" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="ClientID">
        <cfargument name="SWTaskID">
        <cfargument name="SWDistID">
        <cfargument name="ResultNo">
        <cfargument name="ResultString">
        <cfargument name="Action">
        
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />
        
        <cfif NOT validClientID(arguments.ClientID)>
            <cfset response[ "errorno" ] = "1000" />
            <cfset response[ "errormsg" ] = "Unable to add software install results for #arguments.ClientID#" />
            <cfreturn response>
        </cfif>
        
        <cftry>
            <cfquery datasource="#this.ds#" name="qSWInstall">
                Insert Into mp_software_installs (cuuid, tuuid, suuid, result, resultString, action)
                Values (<cfqueryparam value="#arguments.ClientID#">, <cfqueryparam value="#arguments.SWTaskID#">, 
                        <cfqueryparam value="#arguments.SWDistID#">, <cfqueryparam value="#arguments.ResultNo#">, 
                        <cfqueryparam value="#arguments.ResultString#">, <cfqueryparam value="#arguments.Action#">)
            </cfquery>
            <cfcatch type="any">
                <cfset l = elogit("Error inserting results for #arguments.ClientID#. Message[#cfcatch.ErrNumber#]: #cfcatch.Detail# #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "1001" />
                <cfset response[ "errormsg" ] = "Error inserting results for #arguments.ClientID#" />
            </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

    <!--- 
        Type: Private
        Used By: PostSoftwareInstallResults
        Description: Returns the patch name from the patch ID
    --->
    <cffunction name="validClientID" access="private" returntype="any" output="no">
        <cfargument name="ClientID">
    
        <cftry>
            <cfquery datasource="#this.ds#" name="qGetID" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
                Select cuuid from mp_clients
                Where cuuid = '#arguments.ClientID#'
            </cfquery>

            <cfif qGetID.RecordCount EQ 1>
                <cfreturn true>
            <cfelse>
                <cfreturn flase>
            </cfif>

        <cfcatch type="any">
            <cfset l = elogit("[validClientID][#cfcatch.ErrNumber#]: #cfcatch.Detail# #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn flase>
    </cffunction>
</cfcomponent>
