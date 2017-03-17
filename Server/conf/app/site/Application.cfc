<cfcomponent output="false">
	<cfscript>
		// The name of the application
		this.name				= "MP_ADMIN_2900";
		// We wish to enable the session managment
		this.sessionmanagement 	= true;
		// Sets the session timeout to be 15minutes
		this.sessiontimeout 	= CreateTimeSpan( 0, 0, 15, 0 );
	</cfscript>
	
	<!--- ---------------------------------------------
		This is where we can set some variables for the application scope
		http://openbd.org/manual/?/app_application
		--->
	<cffunction name="onApplicationStart">
		<cfset application.starttime = now()>
	</cffunction>
	
	<!--- ---------------------------------------------
		This is called for each request made to a public resource
		We clear down the flag for the user object so they do not accidentally
		log in again
		--->
	<cffunction name="onRequestStart">
		<cfargument name="uri" required="true"/>
		<cfset StructDelete( application, "settings" )>

		<cfset var jFile = "/opt/MacPatch/Server/conf/etc/siteconfig.json">
		<cfif NOT fileExists(jFile)>
			<cfset var jFile = "/opt/MacPatch/Server/etc/siteconfig.json">
		</cfif>
  		
  		<cfif fileExists(jFile)>
			<cfinvoke component="Server.settings" method="getJSONAppSettings" returnvariable="_AppSettings">
				<cfinvokeargument name="cFile" value="#jFile#">
			</cfinvoke>
        <cfelse>
        	<cfoutput>No App Settings file found.</cfoutput>
        	<cfabort>
        </cfif>

        <!--- Simple Way to disable the application --->
        <cfif _AppSettings.services.console EQ false>
        	<cfoutput>Console not enabled.</cfoutput>
        	<cfabort>
        </cfif>

	    <cfset application.settings = _AppSettings>
		<cfset StructDelete( session, "loggedin" )>
	</cffunction>

</cfcomponent>
