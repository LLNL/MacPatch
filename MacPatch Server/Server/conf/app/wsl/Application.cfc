<cfcomponent output="false">

    <cfscript>
    	// The name of the application
    	this.name = "MP_WSL_2800";
        this.sessionmanagement = false;
        this.clientmanagement = false;
    </cfscript>

    <!--- Define the request settings. --->
    <cfsetting showdebugoutput="false" />

    <cffunction name="onRequestStart">
        <cfargument name="uri" required="true"/>

        <cfset var jFile = "/Library/MacPatch/Server/conf/etc/siteconfig.json">
        
        <cfif fileExists(jFile)>
            <cfinvoke component="Server.settings" method="getJSONAppSettings" returnvariable="_AppSettings">
                <cfinvokeargument name="cFile" value="#jFile#">
            </cfinvoke>
        <cfelse>
            <cfoutput>No App Settings file found.</cfoutput>
            <cfabort>
        </cfif>

        <!--- Simple Way to disable the application --->
        <cfif _AppSettings.services.mpwsl EQ false>
            <cfoutput>WebServices not enabled.</cfoutput>
            <cfabort>
        </cfif>
    </cffunction>

    <!--- ----------------------------------------------------------------------
    	Error handeling for the app.
    --->	
        
    <cffunction name="onError" access="public" returntype="void" output="true">
        
        <cfargument name="Exception" required=true/>
        <cfargument name="EventName" type="String" required=true/>
        
        <cflog file="MP_WSL_OnError" type="Error" text="*******************************************">
        <cflog file="MP_WSL_OnError" type="Error" text="Message: #ARGUMENTS.Exception.Message#">
        <cflog file="MP_WSL_OnError" type="Error" text="Detail: #ARGUMENTS.Exception.Detail#">
        <cflog file="MP_WSL_OnError" type="Error" text="SCRIPT_NAME: #CGI.SCRIPT_NAME#">
        <cflog file="MP_WSL_OnError" type="Error" text="QUERY_STRING: #CGI.QUERY_STRING#">

        <cfheader statuscode="404" statustext="ERROR" />
     
        <!--- Steam binary contact back. --->
        <cfset var LOCAL = {} />
        <cfset LOCAL.errorno = "404" />
        <cfcontent type="text/plain" variable="#ToBinary( ToBase64( SerializeJSON(LOCAL) ) )#" />

        <cfreturn />
     </cffunction>

</cfcomponent>
