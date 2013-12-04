<!--- **************************************************************************************** --->
<!---
		MPDistribution - Web Services for MPProxy
	 	Database type is MySQL
		Version 2.0
		Rev: 1
		Last Modified:	10/2/2013
--->
<!--- **************************************************************************************** --->
<cfcomponent output="false">
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
	<cfset this.mpLogFile = "MPProxy">
    <cfset this.cacheDirName = "cacheIt">
    <cfset this.enableLogToFile = false>

	<cffunction name="init" returntype="MPDistribution" output="no">
		<cfreturn this>
	</cffunction>

	<!--- Used to make xml look pretty --->
    <cfsavecontent variable="myXSLT">
        <?xml version="1.0" encoding="UTF-8"?>
        <xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:output method="xml" indent="yes" />
        <xsl:strip-space elements="*" />
        <xsl:template match="/">
            <xsl:copy-of select="." />
        </xsl:template>
        </xsl:transform>
    </cfsavecontent>

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
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, '#aEventType#', '#aEvent#', '#CGI.REMOTE_HOST#', '#CGI.SCRIPT_NAME#', '#CGI.PATH_TRANSLATED#','#CGI.SERVER_NAME#','#CGI.SERVER_SOFTWARE#', '#inet#')
        </cfquery>

		<cfif enableLogToFile EQ true>
            <cflog type="error" file="#mpLogFile#" text="#CreateODBCDateTime(now())# --[#inet#][#aEventType#] #aEvent#">
		</cfif>
    </cffunction>
    
    <cffunction name="getDistributionContentAsJSON" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<!--- Continue --->
        <cftry>
            <cfquery datasource="#this.ds#" name="qGet">
                Select `puuid`, `pkg_url`, `pkg_hash`
                From mp_patches
                Where `patch_state` IN ('Production','QA')
            </cfquery>
        
            <cfif qGet.RecordCount LTE 0>
           		<cfset response[ "errorNo" ] = "1001" />
                <cfset response[ "errorMsg" ] = "No content found." />
                <cfreturn response>
            </cfif>
            <cfcatch>
                <cfset response[ "errorNo" ] = "1" />
                <cfset response[ "errorMsg" ] = "#cfcatch.Detail# #cfcatch.Message#" />
                <cfreturn response>
            </cfcatch>
		</cftry>
        
		<cfset _content = {} />
        <cfset _content[ "Content" ] = {} />
        <cfset _contArr = arrayNew(1)>
        <cfoutput query="qGet">
            <cfset _tmp = {} />
            <cfset _tmp[ "puuid" ] = "#puuid#" />
            <cfset _tmp[ "pkg_url" ] = "#pkg_url#" />
            <cfset _tmp[ "pkg_hash" ] = "#pkg_hash#" />
            <cfset a = ArrayAppend(_contArr,_tmp)>
        </cfoutput>	
        
        <cfset _content.Content = _contArr />
		<cfset response.result = serializeJSON(_content)>
        
		<cfreturn response>
	</cffunction>
    
    <cffunction name="getDistributionContent" access="private" returntype="string" output="no">
		<cfargument name="returnType">
		<cfargument name="encode" default="yes">

		<!--- Continue --->
		<cfquery datasource="#this.ds#" name="qGet">
			Select `puuid`, `pkg_url`, `pkg_hash`
			From mp_patches
			Where `patch_state` IN ('Production','QA')
		</cfquery>

		<cfif qGet.RecordCount LTE 0>
		    <cfreturn false>
		</cfif>

        <cfif arguments.returnType EQ "plist">
            <cfsavecontent variable="theResult">
			<?xml version="1.0" encoding="UTF-8"?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
			<dict>
			    <key>Content</key>
			    <array>
			    <cfoutput query="qGet">
			        <dict>
			            <key>puuid</key>
			            <string>#puuid#</string>
			            <key>pkg_url</key>
			            <string>#pkg_url#</string>
			            <key>pkg_hash</key>
                        <string>#pkg_hash#</string>
			        </dict>
			    </cfoutput>
			    </array>
			</dict>
			</plist>
            </cfsavecontent>
			<cfreturn theResult>
		<cfelseif arguments.returnType EQ "xml">
			<cfsavecontent variable="theResult">
			<?xml version="1.0" encoding="UTF-8"?>
			<root>
			    <Content>
			    <cfoutput query="qGet">
			        <item puuid="#puuid#" url="#pkg_url#" hash="#pkg_hash#" />
			    </cfoutput>
			    </Content>
			</root>
			</cfsavecontent>
			<cfif arguments.encode EQ false>
				<cfreturn theResult>
			</cfif>
            <cfset datax = #ToBase64(theResult)#>
			<cfset data = #ToBinary(datax)#>
			<cfreturn datax>
		</cfif>

		<cfset var res = #ToBase64("ERR")#>
		<cfreturn res>
	</cffunction>
	
    <cffunction name="postSyncResultsJSON" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="logType">
		<cfargument name="logData">
        
        <cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
		
		<cftry>
            <cfquery datasource="#this.ds#" name="qPost" result="res">
                Insert Into mp_proxy_logs (log_type,log_data)
                Values (<cfqueryparam value="#arguments.logType#" CFSQLType="CF_SQL_INTEGER">, <cfqueryparam value="#arguments.logData#">)
            </cfquery>
            <cfcatch type="any">
                <cfset response[ "errorNo" ] = "1" />
                <cfset response[ "errorMsg" ] = "#cfcatch.Detail# #cfcatch.Message#" />
                <cfset log = logit("Error", "#cfcatch.Message# #cfcatch.Detail# ")>
                <cfreturn response>
            </cfcatch>
		</cftry>
        
		<cfreturn response>
	</cffunction>
    
	<cffunction name="postSyncResults" access="remote" returntype="any" output="no">
		<cfargument name="logType">
		<cfargument name="logData">
		
		<cftry>
		<cfquery datasource="#this.ds#" name="qPost" result="res">
			Insert Into mp_proxy_logs (log_type,log_data)
			Values (<cfqueryparam value="#arguments.logType#" CFSQLType="CF_SQL_INTEGER">, <cfqueryparam value="#arguments.logData#">)
		</cfquery>
		<cfcatch type="any">
			<cfset log = logit("Error", "#cfcatch.Message# #cfcatch.Detail# ")>
			<cfreturn false>
		</cfcatch>
		</cftry>
		<cfreturn true>
	</cffunction>
	
	<cffunction name="getPrimaryServer" access="Private" returntype="any" output="no">
		<cftry>
			<cfquery datasource="#this.ds#" name="qGetServer">
				Select	server
				From	mp_servers
				Where	type = '1' AND active = '1'
			</cfquery>
			<cfcatch type="any">
				<cfset log = logit("Error", cfcatch.Message)>
				<cfreturn "ERR">
			</cfcatch>
		</cftry>
		<cfif qGetServer.RecordCount EQ 1>
			<cfreturn #qGetServer.server#>
		<cfelse>
			<cfset log = logit("Error","Query returned more that 1 primary server.")>
			<cfreturn "ERR">
		</cfif>		
	</cffunction>

</cfcomponent>