<cftry>
    <cfset session.Username = url.someVar>
    Session user was set.
    <cfcatch>
        <cfoutput>
            Oh, Darn! Something bad happened! (#cfcatch.message#)
        </cfoutput>
    </cfcatch>
</cftry>
