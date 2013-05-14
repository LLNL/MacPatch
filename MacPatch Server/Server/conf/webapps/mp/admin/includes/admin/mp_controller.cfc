<cfcomponent output="false">
    <cffunction name="setAgentUpdateID" access="remote" returntype="any">
        <cfargument name="id" type="any" required="yes">
        <cfset session.updateID = #argument.id#>
        <cfreturn />
    </cffunction>
</cfcomponent>