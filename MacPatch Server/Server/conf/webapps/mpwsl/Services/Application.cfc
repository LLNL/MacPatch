<cfcomponent output="false">
 
	<!--- Define the application settings. --->
	<cfset this.name = hash( getCurrentTemplatePath() ) />
	<cfset this.applicationTimeout = createTimeSpan( 0, 0, 5, 0 ) />
 
	<!--- Define the request settings. --->
	<cfsetting requesttimeout="10" showdebugoutput="false"/>
 
	<cffunction name="onRequestStart" access="public" returntype="boolean" output="false">
 
		<!---
			Check to see if the WSDL flag is present in the URL.
			If so, we can block it as we initialize the request.
		--->
		<cfif structKeyExists( url, "wsdl" )>
 
			<!---
				Set the header so that the client understands
				that the WSDL file was purposefuly denied. This
				part is not required, but it will provide less
				confusion if the end-user "believes" there should
				be a WSDL file available.
			--->
			<cfheader statuscode="404" statustext="Forbidden"/>
 
			<!---
				Return False - this will prevent the rest of the
				page from processing (ie. the requested template
				will not execute).
			--->
			<cfreturn true />
		</cfif>
 
		<!--- Return true to let page request process. --->
		<cfreturn true />
	</cffunction>
</cfcomponent>
