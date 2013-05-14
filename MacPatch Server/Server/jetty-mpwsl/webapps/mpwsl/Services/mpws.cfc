<cfcomponent>
	<!--- Configure Datasource --->
	<cfparam name="mpDBSource" default="mpds">
	<cffunction name="logger" access="public" returntype="void" output="no">
		<cfargument name="aEventType">
		<cfargument name="aEvent">
		<cfscript>
			inet = CreateObject("java", "java.net.InetAddress");
			inet = inet.getLocalHost();
		</cfscript>
		<cflog type="#arguments.aEventType#" application="no" text="[#inet#]: #arguments.aEvent#">
	</cffunction>
	<cffunction name="ilog" access="public" returntype="void" output="no">
		<cfargument name="aEvent">
		<cfif IsSimpleValue(arguments.aEvent)>
			<cfset logger("Information",arguments.aEvent)>
		</cfif>
	</cffunction>
	<cffunction name="elog" access="public" returntype="void" output="no">
		<cfargument name="aEvent">
		<cfif IsSimpleValue(arguments.aEvent)>
			<cfset logger("Error",arguments.aEvent)>
		</cfif>
	</cffunction>

	<cffunction name="client_checkin_base" access="public" returntype="any" output="no">
		<cfargument name="data" hint="Encoded Data">
		<cfargument name="type" hint="Encodign Type">
		
		<cfset var l_data = "">
		<cfif arguments.type EQ "JSON">
			<cfif isJson(arguments.data) EQ false>
				<!--- Log issue --->
				<cfset elog("Not JSON Data.")>
				<cfreturn false>	
			</cfif>			
			<cfset l_data = Deserializejson(arguments.data)>
			<cfset ilog(arguments.data)>
		<cfelseif arguments.type EQ "XML">
			<!--- Will Fill This In Later--->	
			<cfreturn false>
		<cfelse>	
			<cfreturn false>
		</cfif>	
	
		<cfreturn false>
	</cffunction>

	<cffunction name="onMissingMethod" access="public" returntype="any" output="false" hint="Handles missing method exceptions.">
	    <cfargument name="missingMethodName" type="string">
	    <cfargument name="missingMethodArguments" type="struct">
	    <cfset elog("Missing method was called, "&arguments.missingMethodName)>    
	    <cfreturn />
	</cffunction>
</cfcomponent>