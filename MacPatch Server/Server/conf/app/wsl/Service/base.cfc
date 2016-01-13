<cfcomponent output="false">

	<!--- Default logName --->
	<cfset this.logName = "console" />
	<cfset this.logLevel = "INF" />

	<cffunction name="Init" access="public" output="false">
        <!--- Return This reference. --->
        <cfreturn THIS />
    </cffunction>

    <!--- Logging --->
    <cffunction name="lErr" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">

		<cfset r = xlog("ERR",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="logError" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfset r = xlog("ERR",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="lInf" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">

		<cfset r = xlog("INF",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="logInfo" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfset r = xlog("INF",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="lDbg" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfset r = xlog("DBG",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="logDebug" access="public">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfset r = xlog("DBG",arguments.method,arguments.message,arguments.detail,arguments.type)>
	</cffunction>

	<cffunction name="xlog" access="public">
		<cfargument name="errType" required="yes" default="error">
		<cfargument name="method" required="yes">
	    <cfargument name="message" required="yes">
	    <cfargument name="detail" required="no" default="NA">
	    <cfargument name="type" required="no" default="NA">
		
		<cfif checkLogLevel(arguments.errType)>
			<cfif #arguments.type# NEQ "NA">
				<cflog file="#this.logName#" type="#arguments.errType#" THREAD="no" application="no" text="[#arguments.method#] - Type: #arguments.type#">
			</cfif>

	    		<cflog file="#this.logName#" type="#arguments.errType#" THREAD="no" application="no" text="[#arguments.method#] - Message: #arguments.message#">
	    	
	    	<cfif #arguments.detail# NEQ "NA">
	        	<cflog file="#this.logName#" type="#arguments.errType#" THREAD="no" application="no" text="[#arguments.method#] - Detail: #arguments.detail#">
	        </cfif>
        </cfif>
	</cffunction>

	<cffunction name="checkLogLevel" access="public">
		<cfargument name="logType" required="yes" default="NA">

		<cfif arguments.logType EQ "NA">
			<cfreturn false>
		</cfif>

		<cfset var lgLvl = 0>
		<cfset var lgTyp = 0>

		<cfswitch expression="#Trim(this.logLevel)#"> 
			<cfcase value="DBG"> 
				<cfset lgLvl = 1>
			</cfcase> 
			<cfcase value="ERR"> 
				<cfset lgLvl = 2>
			</cfcase> 
			<cfcase value="INF"> 
				<cfset lgLvl = 3>
			</cfcase> 
			<cfdefaultcase> 
				<cfset lgLvl = 3>
			</cfdefaultcase> 
		</cfswitch> 

		<cfswitch expression="#Trim(arguments.logType)#"> 
			<cfcase value="DBG"> 
				<cfset lgTyp = 1>
			</cfcase> 
			<cfcase value="ERR"> 
				<cfset lgTyp = 2>
			</cfcase> 
			<cfcase value="INF"> 
				<cfset lgTyp = 3>
			</cfcase> 
			<cfdefaultcase> 
				<cfset lgTyp = 3>
			</cfdefaultcase> 
		</cfswitch> 

		<cfif lgTyp GTE lgLvl>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
		
		<cfreturn false>
	</cffunction>

</cfcomponent>