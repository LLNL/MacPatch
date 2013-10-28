<cfcomponent>
	<cfparam name="MP_ROOT" default="/Library/MacPatch/Server/jetty_mpproxy/webapps/mpproxy/mplogs/cf_logs/">
	<cffunction name="ReadLogFile" access="remote" returntype="any" output="no">
		<cfargument name="logFile">

		<cffile action="READ" file="#MP_ROOT##arguments.logFile#.log" variable="logData"/>

		<cfreturn logData>
	</cffunction>
</cfcomponent>