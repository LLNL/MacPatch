<cfcomponent output="false">

    <cffunction name="init" access="public" returntype="any" output="no">
        <cfreturn this>
    </cffunction>
    
    <cffunction name="checkSchemaVersion">
        <cfargument name="schemaConfVersion" required=true/>

        <cfset result = {}>
        <cfset result.runningVersion = "0" />
        <cfset result.requiredVersion = "0" />
        <cfset result.pass = false />
        <cfset result.errno = "0" />
        <cfset result.errmsg = "" />

        <cfset var runningVersion = "0.0.0.0" />

        <cftry>
            <cfquery datasource="mpds" name="qGetSchema">
                SELECT   schemaVersion
                FROM     mp_db_schema
                Order By
                INET_ATON(SUBSTRING_INDEX(CONCAT(schemaVersion,'.0.0.0.0.0'),'.',5)) DESC
            </cfquery>

            <cfif qGetSchema.recordcount EQ 1>
                <cfset runningVersion = qGetSchema.schemaVersion[1] />
            <cfelseif qGetSchema.recordcount GTE 2>
                <!--- Should Have Only One Record, but if not then report last entry --->
                <cfset runningVersion = qGetSchema.schemaVersion[1] />
            </cfif>

            <cfset _vCompare = versionCompare(arguments.schemaConfVersion, runningVersion) />
            <cfif _vCompare EQ 0 >
                <cfset result.runningVersion = runningVersion />
                <cfset result.requiredVersion = arguments.schemaConfVersion />
                <cfset result.pass = true />
            <cfelse>
                <cfset result.runningVersion = runningVersion />
                <cfset result.requiredVersion = arguments.schemaConfVersion />
            </cfif>
            
            <cfcatch>
                <cfset result.errno = cfcatch.ErrorCode />
                <cfset result.errmsg = cfcatch.message />
                <cfset result.pass = false />
            </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="versionCompare" access="private" returntype="numeric" output="no">
        <!--- It returns 1 when argument 1 is greater, -1 when argument 2 is greater, and 0 when they are exact matches. --->
        <cfargument name="leftVersion" required="yes" default="0">
        <cfargument name="rightVersion" required="yes" default="0">

        <cfset var len1 = listLen(arguments.leftVersion, '.')>
        <cfset var len2 = listLen(arguments.rightVersion, '.')>
        <cfset var piece1 = "">
        <cfset var piece2 = "">

        <cfif len1 GT len2>
            <cfset arguments.rightVersion = arguments.rightVersion & repeatString('.0', len1-len2)>
        <cfelse>
            <cfset arguments.leftVersion = arguments.leftVersion & repeatString('.0', len2-len1)>
        </cfif>

        <cfloop index = "i" from="1" to=#listLen(arguments.leftVersion, '.')#>
            <cfset piece1 = listGetAt(arguments.leftVersion, i, '.')>
            <cfset piece2 = listGetAt(arguments.rightVersion, i, '.')>

            <cfif piece1 NEQ piece2>
                <cfif piece1 GT piece2>
                    <cfreturn 1>
                <cfelse>
                    <cfreturn -1>
                </cfif>
            </cfif>
        </cfloop>

        <cfreturn 0>
    </cffunction>

</cfcomponent>