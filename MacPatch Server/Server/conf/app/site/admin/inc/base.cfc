<cfcomponent output="false">

	<!--- Default logName --->
	<cfset this.logName = "console" />

	<cffunction name="Init" access="public" output="false">
        <!--- Return This reference. --->
        <cfreturn THIS />
    </cffunction>

    <!--- Logging --->
	<cffunction name="logError" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfset r = xlog("ERR",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="logInfo" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfset r = xlog("INF",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="xlog" access="public">
		<cfargument name="errType" required="yes" default="error">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfif #arguments.type# NEQ "NA">
			<cflog file="#this.logName#" type="#arguments.errType#" THREAD="no" application="no" text="[#arguments.method#] - Type: #arguments.type#">
		</cfif>

    		<cflog file="#this.logName#" type="#arguments.errType#" THREAD="no" application="no" text="[#arguments.method#] - Message: #arguments.message#">
    	
    	<cfif #arguments.detail# NEQ "NA">
        	<cflog file="#this.logName#" type="#arguments.errType#" THREAD="no" application="no" text="[#arguments.method#] - Detail: #arguments.detail#">
        </cfif>
	</cffunction>

</cfcomponent>	