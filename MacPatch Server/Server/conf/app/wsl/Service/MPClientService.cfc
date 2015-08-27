<!--- **************************************************************************************** --->
<!---
        MPClientService
        Database type is MySQL
        MacPatch Version 2.7.0.x
        Rev 2
--->
<!---   Notes:
--->
<!--- **************************************************************************************** --->
<cfcomponent>
    <!--- Configure Datasource --->
    <cfset this.ds = "mpds">
    <cfset this.cacheDirName = "cacheIt">
    <cfset this.logTable = "ws_clt_logs">
    <cfset this.debug = false>

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

    <cffunction name="dlogit" access="public" returntype="void" output="no">
        <cfargument name="aEvent">

        <cfif this.debug EQ true>
            <cfset l = logit("Debug",arguments.aEvent)>
        </cfif>
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
                <cfelseif versionCompare(agent_version,arguments.agentVersion) EQ 0>
                    <cfif versionCompare(agent_build,arguments.agentBuild) EQ 1 AND #arguments.agentBuild# NEQ "0">
                        <cfset count = count + 1>
                    </cfif>
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
                Select cuuid, ipaddr, hostname, Domain, ostype, osver, client_version, agent_version, agent_build
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
        Description: Returns True/False if it's the latest revision
    --->
    <cffunction name="GetIsLatestRevisionForPatchGroup" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no" default="0" type="string">
        <cfargument name="PatchGroup" required="yes">
        <cfargument name="revision" required="yes" type="numeric">
    
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = 0 />

        <cftry>
            <!--- Get the Patch Group ID from the PatchGroup Name --->
            <cfset pid = patchGroupIDFromName(arguments.PatchGroup)>
            <cfquery datasource="#this.ds#" name="qGetGroupID">
                SELECT mdate FROM mp_patch_group_data
                WHERE pid = <cfqueryparam value="#pid#">
                AND rev = <cfqueryparam value="#arguments.revision#">
                AND data_type = 'JSON'
            </cfquery>

            <cfif qGetGroupID.RecordCount EQ 1>
                <cfset response[ "result" ] = 1 />
            <cfelse>
                <cfset l = logit("Error","[GetIsLatestRevisionForPatchGroup][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: Matching data was not found.")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetIsLatestRevisionForPatchGroup][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: Matching data was not found." />
                <cfreturn response>
            </cfif>

            <cfcatch>
                <cfset l = logit("Error","[GetIsLatestRevisionForPatchGroup]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetIsLatestRevisionForPatchGroup][qGetGroupID]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
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
            <cfquery datasource="#this.ds#" name="qGetGroupID">
                SELECT mdate FROM mp_patch_group_data
                WHERE pid = <cfqueryparam value="#pid#">
                AND hash = <cfqueryparam value="#arguments.Hash#">
                AND data_type = 'JSON'
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
            <cfset l = dlogit("[patchGroupIDFromName][SQL]: Select id from mp_patch_group Where name = #arguments.patchGroup#")>

            <cfquery datasource="#this.ds#" name="qGet">
                Select id from mp_patch_group
                Where name = <cfqueryparam value="#arguments.patchGroup#">
            </cfquery>

            <cfset l = dlogit("[patchGroupIDFromName][SQL][Result]: #qGet.id#")>
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
            <cfquery datasource="#this.ds#" name="qGetGroupID" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
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
            <cfquery datasource="#this.ds#" name="qGetGroupData" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
                Select data from mp_patch_group_data
                Where pid = <cfqueryparam value="#qGetGroupID.id#">
                AND data_type = <cfqueryparam value="#arguments.DataType#">
            </cfquery>

            <cfif qGetGroupData.RecordCount EQ 0>
                <cfset response[ "errorno" ] = "0" />
                <cfset response[ "errormsg" ] = "[GetPatchGroupPatches][qGetGroupData]: No group data was found for #arguments.PatchGroup#" />
                <cfset response[ "result" ] = {"AppleUpdates":[],"CustomUpdates":[]} />
            <cfelseif qGetGroupData.RecordCount EQ 1>
                <cfset response.result  =  #qGetGroupData.data#> />    
            <cfelse>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[GetPatchGroupPatches][qGetGroupData]: Data found found, but wrong amount." />
            </cfif>

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
        Description: Post Patch Scan Data for Apple & Custom content
        Note: New for MacPatch 2.5.43 and higher 
    --->
    <cffunction name="PostClientScanData" access="remote" returnType="struct" returnformat="json" output="false">
        <cfargument name="clientID" required="true" default="0" />
        <cfargument name="type" required="true" default="0" hint="0 = error, 1 = Apple, 2 = Third" />
        <cfargument name="jsonData" required="true">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <!--- Type should not be 0 --->
            <cfif arguments.type EQ 0>
                <cfset l = elogit("[PostClientScanData][type: #arguments.type#]: #arguments.clientID#: #arguments.jsonData#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[PostClientScanData]: Missing type." />
                <cfreturn response>
            </cfif>

            <cfset var patchData = DeserializeJSON(arguments.jsonData)>
            <cfif StructKeyExists(patchData,"rows")>
                <cfset pArr = #patchData['rows']# />
            <cfelse>
                <cfset pArr = ArrayNew(1) />
            </cfif>

            <!---  Apple Patches --->
            <cfif arguments.type EQ 1>

                <cfquery datasource="#this.ds#" name="qPurgeClientApplePatches">
                    Delete From mp_client_patches_apple
                    Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
                </cfquery>

                <cfif ArrayLen(pArr) EQ 0>
                    <cfset response[ "errorno" ] = "0" />
                    <cfset response[ "errormsg" ] = "[PostClientScanData][Apple]: Patches posted successfully." />
                    <cfreturn response>
                </cfif>
                <cfloop array=#patchData['rows']# index="p">
                    <!--- Add row object check --->
                    <cfif NOT IsValidApplePatchObj(p)>
                        <cfset jErr = serializeJSON(p) />
                        <cfset l = elogit("[PostClientScanData][type: #arguments.type#][insert][#arguments.clientID#]: #jErr#")>
                        <cfcontinue>
                    </cfif>
                    <cfquery datasource="#this.ds#" name="qInsertClientApplePatches">
                        Insert Into mp_client_patches_apple
                            (cuuid,mdate,type,patch,description,size,recommended,restart,version)
                        Values
                            (<cfqueryparam value="#arguments.clientID#">,#CreateODBCDateTime(now())#,
                            <cfqueryparam value="#p['type']#">,<cfqueryparam value="#p['patch']#">,
                            <cfqueryparam value="#p['description']#">,<cfqueryparam value="#p['size']#">,
                            <cfqueryparam value="#p['recommended']#">,<cfqueryparam value="#p['restart']#">,<cfqueryparam value="#p['version']#">)
                    </cfquery>
                    <cfset response[ "errormsg" ] = "[PostClientScanData][Apple]: Patches posted successfully." />
                </cfloop>

            </cfif>

            <!---  Third Patches --->
            <cfif arguments.type EQ 2>

                <cfquery datasource="#this.ds#" name="qPurgeClientCustomPatches">
                    Delete From mp_client_patches_third
                    Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
                </cfquery>

                <cfif ArrayLen(pArr) EQ 0>
                    <cfset response[ "errorno" ] = "0" />
                    <cfset response[ "errormsg" ] = "[PostClientScanData][Third]: Patches posted successfully." />
                    <cfreturn response>
                </cfif>
                <cfloop array=#patchData['rows']# index="p">
                    <!--- Add row object check --->
                    <cfif NOT IsValidCustomPatchObj(p)>
                        <cfset jErr = serializeJSON(p) />
                        <cfset l = elogit("[PostClientScanData][type: #arguments.type#][insert][#arguments.clientID#]: #jErr#")>
                        <cfcontinue>
                    </cfif>
                    <cfquery datasource="#this.ds#" name="qInsertClientApplePatches">
                        Insert Into mp_client_patches_third
                            (cuuid,mdate,type,patch,patch_id,description,size,recommended,restart,version,bundleID)
                        Values
                            (<cfqueryparam value="#arguments.clientID#">,#CreateODBCDateTime(now())#,<cfqueryparam value="#p['type']#">,
                            <cfqueryparam value="#p['patch']#">,<cfqueryparam value="#p['patch_id']#">,<cfqueryparam value="#p['description']#">,
                            <cfqueryparam value="#p['size']#">,<cfqueryparam value="#p['recommended']#">,<cfqueryparam value="#p['restart']#">,
                            <cfqueryparam value="#p['version']#">,<cfqueryparam value="#p['bundleID']#">)
                    </cfquery>
                    <cfset response[ "errormsg" ] = "[PostClientScanData][Third]: Patches posted successfully." />
                </cfloop>

            </cfif>

            <cfcatch>
                <cfset l = elogit("[PostClientScanData]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "1004" />
                <cfset response[ "errormsg" ] = "[PostClientScanData]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

    <!---
        Type: Private
        Used By: PostClientScanData
        Description: Returns True/False if object is valid
        Note: New for MacPatch 2.5.43 and higher 
    --->
    <cffunction name="IsValidApplePatchObj" access="private" returntype="any" output="no">
        <cfargument name="model" required="true" type="struct" />
        <cfset result = 0 />

        <cfset objKeys=["type","patch","description","size","recommended","restart","version"]>
        <cfloop array=#objKeys# index="o">
            <cfif NOT structkeyexists(arguments.model,o)>
                <cfset result = 1 />
            </cfif>
        </cfloop>
        
        <cfif result EQ 0>
            <cfreturn True>
        <cfelse>
            <cfreturn False>
        </cfif>
    </cffunction>

    <!---
        Type: Private
        Used By: PostClientScanData
        Description: Returns True/False if object is valid
        Note: New for MacPatch 2.5.43 and higher 
    --->
    <cffunction name="IsValidCustomPatchObj" access="private" returntype="any" output="no">
        <cfargument name="model" required="true" type="struct" />
        <cfset result = 0 />

        <cfset objKeys=["type","patch","patch_id","description","size","recommended","restart","version","bundleID"]>
        <cfloop array=#objKeys# index="o">
            <cfif NOT structkeyexists(arguments.model,o)>
                <cfset result = 1 />
            </cfif>
        </cfloop>
        
        <cfif result EQ 0>
            <cfreturn True>
        <cfelse>
            <cfreturn False>
        </cfif>
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


        <cfquery datasource="#this.ds#" name="qGetClient" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
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
        Description: Post DataMgr XML and write it out for inventory app to pick it up
    --->
    <cffunction name="PostDataMgrJSON" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID">
        <cfargument name="encodedData">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <!---
        <cflog file="PostDataMgrJSON" type="error" application="no" text="#arguments.clientID#">
        <cflog file="PostDataMgrJSON" type="error" application="no" text="#arguments.encodedData#">
        --->

        <!--- Clean a bit of the XML char before parsing --->
        <cfset var theJSON = ToString(ToBinary(Trim(arguments.encodedData)))>

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

            <cfset dirF = #_InvFiles# & "/mpi_" & #CreateUuid()# & ".mpd">
            <cffile action="write" NAMECONFLICT="makeunique" file="#dirF#" output="#theJSON#">

            <cfcatch type="any">
                <cfset l = elogit("[PostDataMgrJSON][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
                <cfset response[ "errorno" ] = "1" />
                <cfset response[ "errormsg" ] = "[PostDataMgrJSON][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
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
            <cflog application="yes" type="error" text="updateInstalledPatchStatus: #arguments.clientID#, #arguments.patch#, #arguments.patchType#">
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
                <cflog application="yes" type="error" text="arguments.type EQ Apple">
                <cfquery datasource="#this.ds#" name="qGet">
                    Select rid, cuuid From mp_client_patches_apple
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
                <cflog application="yes" type="error" text="arguments.type EQ Third">
                <cfquery datasource="#this.ds#" name="qGet">
                    Select rid, cuuid From mp_client_patches_third
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
            <cfquery datasource="#this.ds#" name="qGetCatalogs" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
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
            <cfquery datasource="#this.ds#" name="qGetClientPatchGroup" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
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
    <cffunction name="GetSoftwareTasksForGroup" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="GroupName">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "1" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <cfset gid = softwareGroupID(arguments.GroupName)>
        <cfif gid EQ 0>
                <cfset response[ "errormsg" ] = "No group data found for #arguments.GroupName#." />
                <cfreturn response>
            </cfif>
            <cfquery datasource="#this.ds#" name="qGetGroupTasksData" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
                Select gData From mp_software_tasks_data
                Where gid = '#gid#'
            </cfquery>

            <cfif qGetGroupTasksData.RecordCount EQ 1>
                <!--- Response is already stored in DB, fully formatted, have to rename keys app wants lowercase --->
                <cfset x = #DeserializeJSON(qGetGroupTasksData.gData)#>
                <cfset response[ "errorno" ] = #x.errorno# />
                <cfset response[ "errormsg" ] = #x.errormsg# />
                <cfset response[ "result" ] = #x.result# />
                <cfreturn response>
            <cfelse>
                <cfset response[ "errormsg" ] = "No task group data found for #arguments.GroupName#." />
                <cfset response[ "result" ] = {} />
            </cfif>
        <cfcatch>
            <cfset l = elogit("[GetSoftwareTasksForGroup]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response[ "errormsg" ] = "[GetSoftwareTasksForGroup]: #cfcatch.Detail# -- #cfcatch.Message#" />
        </cfcatch>
        </cftry>
        <cfreturn response>
    </cffunction>

    <!---
        Remote API
        Type: Public/Remote
        Description: Returns json data of SW tasks for a SW group filtering software on os version
        Note: These results are dynamic and not stored in the database
        Alt: Uses cfc/softwareDistribution.cfc  file
    --->
    <cffunction name="GetSoftwareTasksForGroupUsingOSVer" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="GroupName">
        <cfargument name="osver" required="no" default="*">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "1" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <cfset gid = softwareGroupID(arguments.GroupName)>
            <cfif gid EQ 0>
                <cfset response[ "errormsg" ] = "No group data found for #arguments.GroupName#." />
                <cfreturn response>
            </cfif>

            <cfscript>
                swDistCFC=CreateObject("component","cfc.softwareDistribution").init(arguments.GroupName);
                if (arguments.osver == "*") {
                    qGetGroupTasksData = swDistCFC.GetSoftwareGroupData();
                } else {
                    qGetGroupTasksData = swDistCFC.GetSoftwareGroupData(arguments.osver);
                }
            </cfscript>

            <cfif qGetGroupTasksData.errorno EQ 0>
                <cfset response[ "errorno" ] = #qGetGroupTasksData.errorno# />
                <cfset response[ "errormsg" ] = #qGetGroupTasksData.errormsg# />
                <cfset response[ "result" ] = #qGetGroupTasksData.result# />
                <cfreturn response>
            <cfelse>
                <cfset response[ "errormsg" ] = "No task group data found for #arguments.GroupName#." />
                <cfset response[ "result" ] = {} />
            </cfif>
            <cfcatch>
                <cfset l = elogit("[GetSoftwareTasksForGroup]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorno" ] = "2" />
                <cfset response[ "errormsg" ] = "[GetSoftwareTasksForGroup]: (#cfcatch.Detail#) -- #cfcatch.Message#" />
            </cfcatch>
        </cftry>

        <cfreturn response>
    </cffunction>

    <!---
        Remote API
        Type: Public/Remote
        Description: Returns json data of SW tasks for a SW group
        Note: This function needs to be updated so that the entire JSON result is not
        stored in the DB just the data.
    --->
    <cffunction name="GetSoftwareTasksUsingID" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="TaskID">

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cfset _task = {} />
        <cfset _task = softwareTaskData(arguments.TaskID)>
        <cfset _task[ "Software" ] = softwareData(_task.suuid) />
        <cfset _task[ "SoftwareCriteria" ] = softwareCritera(_task.suuid) />
        <!---
        Not implemented yet
        <cfset _task[ "SoftwareRequisistsPre" ] = {} />
        <cfset _task[ "SoftwareRequisistsPost" ] = {} />
        --->

        <cfset response[ "result" ] = _task />
        <cfreturn response>
    </cffunction>

    <!---
        Type: Private
        Used By: GetSoftwareTasksUsingID
        Description: Returns the task Object for task ID
    --->
    <cffunction name="softwareTaskData" access="private" returntype="any" output="no">
        <cfargument name="taskID">

        <!--- Empty Task --->
        <cfset _task = {} />
        <cfset _task[ "name" ] = "ERROR" />
        <cfset _task[ "id" ] = "1000" />
        <cfset _task[ "sw_task_type" ] = "o" />
        <cfset _task[ "sw_task_privs" ] = "Global" />
        <cfset _task[ "sw_start_datetime" ] = "2000-01-01 00:00:00" />
        <cfset _task[ "sw_end_datetime" ] = "2000-01-01 00:00:00" />
        <cfset _task[ "active" ] = "0" />
        <cfset _task[ "suuid" ] = "0" />
        <cfset _task[ "Software" ] = {} />
        <cfset _task[ "SoftwareCriteria" ] = {} />
        <!--- Pre & Post Not Supported Yet, place holder --->
        <cfset _task[ "SoftwareRequisistsPre" ] = {} />
        <cfset _task[ "SoftwareRequisistsPost" ] = {} />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetTask">
                Select * from mp_software_task
                Where tuuid = <cfqueryparam value="#arguments.TaskID#">
            </cfquery>

            <cfif qGetTask.RecordCount EQ 1>
                <cfoutput>
                <cfset _task[ "name" ] = "#qGetTask.name#" />
                <cfset _task[ "id" ] = "#qGetTask.tuuid#" />
                <cfset _task[ "sw_task_type" ] = "#qGetTask.sw_task_type#" />
                <cfset _task[ "sw_task_privs" ] = "#qGetTask.sw_task_privs#" />
                <cfset _task[ "sw_start_datetime" ] = "#qGetTask.sw_start_datetime#" />
                <cfset _task[ "sw_end_datetime" ] = "#qGetTask.sw_end_datetime#" />
                <cfset _task[ "active" ] = "#qGetTask.active#" />
                <cfset _task[ "suuid" ] = "#qGetTask.primary_suuid#" />
                </cfoutput>
            <cfelse>

            </cfif>
        <cfcatch>
            <cfset l = elogit("[softwareGroupID]: #cfcatch.Detail# -- #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn _task>
    </cffunction>

    <!---
        Type: Private
        Used By: GetSoftwareTasksUsingID
        Description: Returns sw data for sw task
    --->
    <cffunction name="softwareData" access="private" returntype="any" output="no">
        <cfargument name="swID">

        <!--- Empty Task --->
        <cfset _sw = {} />
        <cfset _sw[ "name" ] = "1" />
        <cfset _sw[ "vendor" ] = "0" />
        <cfset _sw[ "vendorUrl" ] = "o" />
        <cfset _sw[ "version" ] = "Global" />
        <cfset _sw[ "description" ] = "2000-01-01 00:00:00" />
        <cfset _sw[ "reboot" ] = "2000-01-01 00:00:00" />
        <cfset _sw[ "sw_type" ] = "0" />
        <cfset _sw[ "sw_url" ] = "" />
        <cfset _sw[ "sw_hash" ] = "" />
        <cfset _sw[ "sw_size" ] = "" />
        <cfset _sw[ "sw_pre_install" ] = "" />
        <cfset _sw[ "sw_post_install" ] = "" />
        <cfset _sw[ "sw_uninstall" ] = "" />
        <cfset _sw[ "sw_env_var" ] = "" />
        <cfset _sw[ "auto_patch" ] = "" />
        <cfset _sw[ "patch_bundle_id" ] = "" />
        <cfset _sw[ "state" ] = "" />
        <cfset _sw[ "sid" ] = "" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetSW" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
                Select * from mp_software
                Where suuid = '#arguments.swID#'
            </cfquery>

            <cfif qGetSW.RecordCount EQ 1>
                <cfoutput>
                <cfset _sw = {} />
                <cfset _sw[ "name" ] = "#qGetSW.sName#" />
                <cfset _sw[ "vendor" ] = "#qGetSW.sVendor#" />
                <cfset _sw[ "vendorUrl" ] = "#qGetSW.sVendorURL#" />
                <cfset _sw[ "version" ] = "#qGetSW.sVersion#" />
                <cfset _sw[ "description" ] = "#qGetSW.sDescription#" />
                <cfset _sw[ "reboot" ] = "#qGetSW.sReboot#" />
                <cfset _sw[ "sw_type" ] = "#qGetSW.sw_type#" />
                <cfset _sw[ "sw_url" ] = "#qGetSW.sw_url#" />
                <cfset _sw[ "sw_hash" ] = "#qGetSW.sw_hash#" />
                <cfset _sw[ "sw_size" ] = "#qGetSW.sw_size#" />
                <cfset _sw[ "sw_pre_install" ] = "#ToBase64(qGetSW.sw_pre_install_script)#" />
                <cfset _sw[ "sw_post_install" ] = "#ToBase64(qGetSW.sw_post_install_script)#" />
                <cfset _sw[ "sw_uninstall" ] = "#ToBase64(qGetSW.sw_uninstall_script)#" />
                <cfset _sw[ "sw_env_var" ] = "#qGetSW.sw_env_var#" />
                <cfset _sw[ "auto_patch" ] = "#qGetSW.auto_patch#" />
                <cfset _sw[ "patch_bundle_id" ] = "#qGetSW.patch_bundle_id#" />
                <cfset _sw[ "state" ] = "#qGetSW.sState#" />
                <cfset _sw[ "sid" ] = "#qGetSW.suuid#" />
                </cfoutput>
            </cfif>
        <cfcatch>
            <cfset l = elogit("[softwareGroupID]: #cfcatch.Detail# -- #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn _sw>
    </cffunction>

    <!---
        Type: Private
        Used By: GetSoftwareTasksUsingID
        Description: Returns sw criteria for sw task
    --->
    <cffunction name="softwareCritera" access="private" returntype="any" output="no">
        <cfargument name="swID">

        <!--- Empty Task --->
        <cfset _sw = {} />
        <cfset _sw[ "os_type" ] = "Mac OS X, Mac OS X Server" />
        <cfset _sw[ "os_vers" ] = "10.5.*" />
        <cfset _sw[ "arch_type" ] = "PPC,X86" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetSWCrit">
                Select * from mp_software_criteria
                Where suuid = <cfqueryparam value="#arguments.swID#">
                Order By type_order ASC
            </cfquery>

            <cfif qGetSWCrit.RecordCount GTE 1>
                <cfoutput query="qGetSWCrit">
                    <cfif #type# EQ "OSType">
                        <cfset _sw[ "os_type" ] = "#type_data#" />
                    </cfif>
                    <cfif #type# EQ "OSArch">
                        <cfset _sw[ "arch_type" ] = "#type_data#" />
                    </cfif>
                    <cfif #type# EQ "OSVersion">
                        <cfset _sw[ "os_vers" ] = "#type_data#" />
                    </cfif>
                </cfoutput>
            </cfif>
        <cfcatch>
            <cfset l = elogit("[softwareCritera]: #cfcatch.Detail# -- #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn _sw>
    </cffunction>

    <!---
        Type: Private
        Used By: GetSoftwareTasksForGroup
        Description: Returns the patch name from the patch ID
    --->
    <cffunction name="softwareGroupID" access="private" returntype="any" output="no">
        <cfargument name="GroupName">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetID" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
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
                <cfset l = elogit("Error inserting results for #arguments.ClientID#. Message[#cfcatch.ErrorCode#]: #cfcatch.Detail# #cfcatch.Message#")>
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
            <cfquery datasource="#this.ds#" name="qGetID">
                Select cuuid from mp_clients
                Where cuuid = '#arguments.ClientID#'
            </cfquery>

            <cfif qGetID.RecordCount EQ 1>
                <cfreturn true>
            <cfelse>
                <cfreturn false>
            </cfif>

        <cfcatch type="any">
            <cfset l = elogit("[validClientID][#cfcatch.ErrorCode#]: #cfcatch.Detail# #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn false>
    </cffunction>

    <!--- New For MacPatch 2.5.x --->
    <!---
        Remote API
        Type: Public/Remote
        Description: Returns Mac OS X OS Profiles for client ID
    --->
    <cffunction name="GetProfileIDDataForClient" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="true" default="0" />
        <cfargument name="clientKey" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = {} />

        <cftry>
            <cfset clientGroup = clientGroupForClient(arguments.clientID)>
            <cfset clientProfilesList = profileIDListForGroup(clientGroup)>
            <cfquery datasource="#this.ds#" name="qGetProfiles">
                select profileID, profileIdentifier, profileRev, profileData, uninstallOnRemove
                from mp_os_config_profiles
                Where profileID IN ('#clientProfilesList#')
                AND enabled = '1'
            </cfquery>

            <cfset Profiles = arrayNew(1)>

            <cfoutput query="qGetProfiles">
                <cfset profile = {} />
                <cfset profile[ "id" ] = #profileID# />
                <cfset profile[ "profileIdentifier" ] = #profileIdentifier# />
                <cfset profile[ "rev" ] = #profileRev# />
                <cfset profile[ "data" ] = #BinaryEncode(profileData, 'Base64')# />
                <cfset profile[ "remove" ] = #uninstallOnRemove# />
                <cfset a = ArrayAppend(Profiles,profile)>
            </cfoutput>

            <cfset response.result = Profiles>
        <cfcatch>
            <cfset l = elogit("[GetProfileIDDataForClient]: #cfcatch.Detail# -- #cfcatch.Message#")>
            <cfset response.errorno = "1">
            <cfset response.errormsg = "#cfcatch.Detail# -- #cfcatch.Message#">
        </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!---
        Type: Private
        Used By: GetProfileIDDataForClient
        Description: Returns the Client Group ID for client ID
    --->
    <cffunction name="clientGroupForClient" access="private" returntype="any" output="no">
        <cfargument name="ClientID">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetID">
                Select Domain from mp_clients_plist
                Where cuuid = '#arguments.ClientID#'
            </cfquery>

            <cfif qGetID.RecordCount EQ 1>
                <cfreturn qGetID.Domain>
            <cfelse>
                <cfreturn "Default">
            </cfif>

        <cfcatch type="any">
            <cfset l = elogit("[clientGrroupForClient]: #cfcatch.Detail# #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn "Default">
    </cffunction>

    <!---
        Type: Private
        Used By: GetProfileIDDataForClient
        Description: Returns the patch name from the patch ID
    --->
    <cffunction name="profileIDListForGroup" access="private" returntype="any" output="no">
        <cfargument name="GroupID">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetProfiles">
                select profileID
                from mp_os_config_profiles_assigned
                Where groupID = <cfqueryparam value="#arguments.GroupID#">
            </cfquery>

            <cfif qGetProfiles.RecordCount GTE 1>
                <cfreturn #ValueList(qGetProfiles.profileID,",")#>
            <cfelse>
                <cfreturn "999999NONE">
            </cfif>

        <cfcatch type="any">
            <cfset l = elogit("[profileIDListForGroup]: #cfcatch.Detail# #cfcatch.Message#")>
        </cfcatch>
        </cftry>
        <cfreturn "999999NONE">
    </cffunction>

    <!---
        Remote API
        Type: Public/Remote
        Description: Returns true/false if client has INV Data
    --->
    <cffunction name="clientHasInventoryData" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = 0 />
        <cfset response[ "machineName" ] = "" />
        <cfset response[ "hostName" ] = "" />

        <cfscript>
            machineName = createObject("java", "java.net.InetAddress").localhost.getCanonicalHostName();
            hostaddress = createObject("java", "java.net.InetAddress").localhost.getHostAddress();
        </cfscript>

        <cfset response[ "machineName" ] = "#machineName#" />
        <cfset response[ "hostName" ] = "#hostaddress#" />

        <cftry>
            <cfset invState = clientInventoryState(arguments.clientID)>

            <cfif invState EQ true>
                <cfset response[ "result" ] = 1>
            <cfelse>
                <cfset response[ "result" ] = 0>
            </cfif>

            <cfcatch>
                <cfset l = elogit("[clientHasInventoryData]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = cfcatch.Message>
            </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <cffunction name="clientInventoryState" access="private" returnType="boolean" output="false">
        <cfargument name="clientID" required="false" default="0" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qHasInv">
                SELECT cuuid
                FROM mp_inv_state
                Where cuuid = <cfqueryparam value="#arguments.clientID#">
            </cfquery>

            <cfif qHasInv.RecordCount EQ 1>
                <cfreturn true>
            <cfelse>
                <cfreturn false>
            </cfif>

            <cfcatch>
                <cfset l = elogit("[clientInventoryState]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>

        <cfreturn false>
    </cffunction>

    <!---
        Remote API
        Type: Public/Remote
        Description: Returns true/false if client has INV Data
    --->
    <cffunction name="postClientHasInventoryData" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = 0 />
        <cfset response[ "machineName" ] = "" />
        <cfset response[ "hostName" ] = "" />

        <cfscript>
            machineName = createObject("java", "java.net.InetAddress").localhost.getCanonicalHostName();
            hostaddress = createObject("java", "java.net.InetAddress").localhost.getHostAddress();
        </cfscript>

        <cfset response[ "machineName" ] = "#machineName#" />
        <cfset response[ "hostName" ] = "#hostaddress#" />

        <cftry>
            <cfif validClientID(arguments.clientID) EQ true>
                <cfif clientInventoryState(arguments.clientID) EQ false>
                    <cfquery datasource="#this.ds#" name="qSetHasInv">
                        Insert Into mp_inv_state (cuuid)
                        Values (<cfqueryparam value="#arguments.clientID#">)
                    </cfquery>
                </cfif>
            </cfif>
            <cfcatch>
                <cfset l = elogit("[clientHasInventoryData]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = cfcatch.Message>
            </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!---
        Remote API
        Type: Public/Remote
        Description:
    --->
    <cffunction name="getServerList" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="listID" required="false" default="1" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = 0 />
        <cfset response[ "machineName" ] = "" />
        <cfset response[ "hostName" ] = "" />

        <cfscript>
            machineName = createObject("java", "java.net.InetAddress").localhost.getCanonicalHostName();
            hostaddress = createObject("java", "java.net.InetAddress").localhost.getHostAddress();
        </cfscript>

        <cfset response[ "machineName" ] = "#machineName#" />
        <cfset response[ "hostName" ] = "#hostaddress#" />

        <cfset _server = {} />
        <cfset _server.name = "NA">
        <cfset _server.version = "0">
        <cfset _server.servers = "">
        <cfset _server.id = "">
        <cfset response.result = serializeJSON(_server)>

        <cftry>
            <cfif validClientID(arguments.clientID) EQ true>
                <cfquery datasource="#this.ds#" name="qGetServerList">
                    Select * from mp_server_list
                    Where name = 'Default' AND listid = <cfqueryparam value="#arguments.listID#">
                </cfquery>
                <cfif qGetServerList.RecordCount EQ 1>
                    <cfset _server.name = qGetServerList.name>
                    <cfset _server.version = qGetServerList.version>
                    <cfset _server.id = qGetServerList.listid>
                    <cfset _listID = qGetServerList.listid>
                </cfif>
                <cfquery datasource="#this.ds#" name="qGetServers">
                    Select * from mp_servers
                    Where active = '1'
                    AND listid = '#_listID#'
                </cfquery>
                <cfif qGetServers.RecordCount GTE 1>
                    <cfset _Servers = arrayNew(1)>

                    <cfoutput query="qGetServers">
                        <cfset _result = {} />
                        <cfset _result[ "host" ] = "#server#" />
                        <cfset _result[ "port" ] = "#port#" />
                        <cfset _result[ "useHTTPS" ] = "#useSSL#" />
                        <cfset _result[ "allowSelfSigned" ] = "#allowSelfSignedCert#" />
                        <cfset _result[ "useTLSAuth" ] = "#useSSLAuth#" />
                        <cfif isMaster EQ "1">
                            <cfset _result[ "serverType" ] = "0" />
                        <cfelse>
                            <cfif isMaster EQ "0" AND isProxy EQ "0">
                                <cfset _result[ "serverType" ] = "1" />
                            </cfif>
                            <cfif isMaster EQ "0" AND isProxy EQ "1">
                                <cfset _result[ "serverType" ] = "2" />
                            </cfif>
                        </cfif>
                        <cfset a = ArrayAppend(_Servers,_result)>
                    </cfoutput>
                    <cfset _server.servers = _Servers>
                <cfelse>
                    <cfset response.errorno = "2">
                    <cfset response.errormsg = "No servers found.">
                </cfif>

                <cfset response.result = serializeJSON(_server)>
            <cfelse>
                <cfset response.errorno = "3">
                <cfset response.errormsg = "Invalid data.">
            </cfif>
            <cfcatch>
                <cfset l = elogit("[getServerList]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = "#cfcatch.Detail# -- #cfcatch.Message#">
            </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>

    <!---
        Remote API
        Type: Public/Remote
        Description:
    --->
    <cffunction name="getServerListVersion" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="false" default="0" />
        <cfargument name="listID" required="false" default="1" />

        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "" />
        <cfset response[ "result" ] = "0" />
        <cfset response[ "machineName" ] = "" />
        <cfset response[ "hostName" ] = "" />

        <cfscript>
            machineName = createObject("java", "java.net.InetAddress").localhost.getCanonicalHostName();
            hostaddress = createObject("java", "java.net.InetAddress").localhost.getHostAddress();
        </cfscript>

        <cfset response[ "machineName" ] = "#machineName#" />
        <cfset response[ "hostName" ] = "#hostaddress#" />

        <cfset _server = {}>
        <cfset _server.version = "0">
        <cfset _server.listid = "0">
        <cfset response.result = serializeJSON(_server)>

        <cftry>
            <cfif validClientID(arguments.clientID) EQ true>
                <cfquery datasource="#this.ds#" name="qGetServerList">
                    Select * from mp_server_list
                    Where listid = <cfqueryparam value="#arguments.listID#">
                </cfquery>
                <cfif qGetServerList.RecordCount EQ 1>
                    <cfset _server.version = #qGetServerList.version#>
                    <cfset _server.listid = #qGetServerList.listid#>
                    <cfset response.result = serializeJSON(_server)>
                <cfelse>
                    <cfset response.errorno = "2">
                    <cfset response.errormsg = "No server list found.">
                </cfif>
            <cfelse>
                <cfset response.errorno = "3">
                <cfset response.errormsg = "Invalid data.">
            </cfif>
            <cfcatch>
                <cfset l = elogit("[getServerListVersion]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response.errorno = "1">
                <cfset response.errormsg = "#cfcatch.Detail# -- #cfcatch.Message#">
            </cfcatch>
        </cftry>

        <cfreturn #response#>
    </cffunction>
</cfcomponent>
