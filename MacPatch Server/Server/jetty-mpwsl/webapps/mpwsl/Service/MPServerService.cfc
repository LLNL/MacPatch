<!--- **************************************************************************************** --->
<!---
		MPServerService 
	 	Database type is MySQL
		MacPatch Version 2.2.x
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
        <cfargument name="theXmlFile">

        <cfset response = {} />
        <cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = "" />

        <cfreturn response>

        <!--- To Be Developed

        <cfset var vTheXML = #Trim(arguments.theXmlFile)#>
        <cfset vTheXML = ToString(ToBinary(vTheXML))>

        <!--- Parse the XML File--->
        <cftry>
            <cfset var xmldoc = XmlParse(vTheXML)>
            <cfcatch type="any">
                <!--- the message to display --->
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddSavAvDefs][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn False>
            </cfcatch>
        </cftry>

        <cfset var XMLRoot = xmldoc.XmlRoot>
        <cfset var arrNodes1 = XmlSearch(xmldoc,"//sav/arch[ @type = 'ppc' ]/def") />
        <cfset var arrNodes2 = XmlSearch(xmldoc,"//sav/arch[ @type = 'x86' ]/def") />
        <cfset var vMdate = #CreateODBCDateTime(now())#>

        <!--- Check to make sure the XMLSearch has values before clearing the DB --->
        <cfif #ArrayLen(arrNodes1)# GTE 1 AND #ArrayLen(arrNodes2)# GTE 1>
            <cfquery datasource="#this.ds#" name="qPut">
                Delete from savav_defs
            </cfquery>
        </cfif>

        <cfoutput>
        <!--- Loop Over the PPC Defs --->
            <cftry>
            <cfloop index="i" from="1" to="#ArrayLen(arrNodes1)#">
                <cfquery datasource="#this.ds#" name="qPut">
                    Insert Into savav_defs (arch, file, defdate, current, mdate)
                    Values ('ppc', <cfqueryparam value="#arrNodes1[i].XmlText#">, <cfqueryparam value="#arrNodes1[i].XmlAttributes.date#">, <cfqueryparam value="#arrNodes1[i].XmlAttributes.current#">, #vMdate#)
                </cfquery>
            </cfloop>
                <cfcatch type = "Database">
                    <cfinvoke component="ws_logger" method="LogEvent">
                        <cfinvokeargument name="aEventType" value="Error">
                        <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                        <cfinvokeargument name="aEvent" value="[AddSavAvDefs][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                    </cfinvoke>
                    <cfreturn False>
               </cfcatch>
           </cftry>
        <!--- Loop Over the x86 Defs --->
            <cftry>
            <cfloop index="i" from="1" to="#ArrayLen(arrNodes2)#">
                <cfquery datasource="#this.ds#" name="qPut">
                    Insert Into savav_defs (arch, file, defdate, current, mdate)
                    Values ('x86', <cfqueryparam value="#arrNodes2[i].XmlText#">, <cfqueryparam value="#arrNodes2[i].XmlAttributes.date#">, <cfqueryparam value="#arrNodes2[i].XmlAttributes.current#">, #vMdate#)
                </cfquery>
            </cfloop>
            <cfcatch type = "Database">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddSavAvDefs][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn False>
           </cfcatch>
           </cftry>
        </cfoutput>

        <cfreturn True>
        --->
    </cffunction>
</cfcomponent>
