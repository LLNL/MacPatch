<cffunction access="public" output="false" name="getTables" returntype="Query">
	<cfquery name="qSelectTables" datasource="#session.dbsource#" result="res">
		SELECT table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE'
		AND TABLE_SCHEMA = 'MacPatchDB'
	</cfquery>
	<cfreturn qSelectTables>
</cffunction>

<cffunction name="cuuidExists" access="public" returntype="boolean" output="false">
    <cfargument name="cid" required="yes">
	<cfargument name="table" required="yes">
    <cfquery name="qCID" datasource="#session.dbsource#" result="res">
        Select cuuid from #arguments.table# where cuuid = '#arguments.cid#'
    </cfquery>
	<cfif qCID.recordcount GTE 1>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
	</cfif>
</cffunction>

<cffunction name="getRecordsToClean" access="public" returntype="array" output="false">
    <cfargument name="qid" required="yes">
	<cfargument name="table" required="yes">
	
	<cfset array_name = ArrayNew(1)>

    <cfoutput query="arguments.qid">
		<cfif #cuuidExists(cuuid, arguments.table)# EQ false>
			<cfset ArrayAppend(array_name, cuuid)>
		</cfif>
	</cfoutput>
	
	<cfreturn array_name>
</cffunction>

<cfset l_tables = #getTables()#>

<cfform name="CheckTable" method="post" action="#CGI.SCRIPT_NAME#">
	<cfselect name="table" query="l_tables" value="table_name" />
	<cfinput type="submit" name="CheckClientData" value="CheckClientData">
</cfform>

<cfif NOT IsDefined("form.table")>
	<cfabort>
<cfelse>
	<cfquery name="selIDs" datasource="#session.dbsource#" result="res">
		Select Distinct cuuid from #form.table#
	</cfquery>	
	
	<cfset xyz = #getRecordsToClean(selIDs,form.table)#>	
	
	<cfoutput>#arrayLen(xyz)#</cfoutput>
</cfif>

