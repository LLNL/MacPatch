<cfcomponent output="false">

	<!--- Default logName --->
	<cfset this.logName = "console" />
	<cfset this.logLevel = "INF" />
	<cfset this.ds = "mpds">

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

	<cffunction name="isValidCUUID" access="public" returntype="boolean">
	    <cfargument name="aUUID" required="yes" default="NA">
		
		<cfreturn REFindNoCase("^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$", arguments.aUUID) />
	</cffunction>

	<cffunction name="isValidSignature" access="public" returntype="boolean">
	    <cfargument name="aSignature" required="yes" default="NA">
	    <cfargument name="aClientID" required="yes" default="NA">
	    <cfargument name="aData" required="yes" default="NA">
	    <cfargument name="aTimeStamp" required="yes" default="NA">

	    <cftry>
            <cfif NOT isValidCUUID(arguments.ClientID)>
                <cfset l = lErr("isValidCUUID", "#arguments.ClientID# is not a valid ClientID format.") />
                <cfreturn false>
            </cfif>

            <cfquery datasource="#this.ds#" name="qGetKey" cachedwithin="#CreateTimeSpan(0,0,15,0)#">
                Select cuuid, cKey from mp_clients_key
                Where cuuid = '#arguments.aClientID#'
            </cfquery>

            <cfif qGetKey.RecordCount EQ 1>

            	<cfset _srvSig = arguments.aClientID & "-" & hash(qGetKey.cKey,"MD5") & "-" & hash(arguments.aData,"MD5") & "-" & arguments.aTimeStamp>
            	<cfset _srvSigHash = hash(_srvSigHash, "SHA1") >
            	<cfif _srvSigHash EQ arguments.aSignature>
					<cfreturn true>
				<cfelse>
					<cfreturn false>            		
            	</cfif>

            <cfelse>
                <cfreturn false>
            </cfif>

	        <cfcatch type="any">
	            <cfset l = lErr("isValidSignature", "#cfcatch.Message#", "#cfcatch.Detail#") />
	            <cfreturn false>
	        </cfcatch>
		</cftry>
		<!--- Should not get here --->
		<cfreturn false>
	</cffunction>

</cfcomponent>