<cfcomponent output="false">
	<cffunction name="Reports" access="remote" returnformat="json">
		
        <cfset response = {} />
        <cfset rows = ArrayNew(1)> 
        <cfset row = {} />
        <cfset row[ "title" ] = "New Report" />
        <cfset row[ "icon" ] = "box-3d.png" />
        <cfset row[ "href" ] = "/admin/inc/adhoc_report_new.cfm" />
        <cfset rows[1] = row>
        
        <cfquery name="qClientGroups" datasource="#session.dbsource#">
            SELECT	rid, name, owner, rights
			FROM	mp_adhoc_reports
            Where 	(owner In ('Global','#session.Username#') or rights <= 0)
            AND disabled = 0
        </cfquery>
        
        <cfset i = 2>
		<cfloop query="qClientGroups">
        	<cfset _row = {} />
			<cfset _row[ "title" ] = "#name#" />
			<cfset _row[ "icon" ] = "text-list.png" />
            <cfset _row[ "href" ] = "/admin/inc/adhoc_report_run.cfm?id=#rid#" />
			<cfset rows[i] = _row>
			<cfset i = i + 1>		
		</cfloop>
		<cfreturn rows>
	</cffunction>
    
    <cffunction name="ReportInfo" access="public" returntype="struct">
		<cfargument name="id" required="no" default="1" hint="Page user is on">
        
        <cfset response = {} />
        <cfset response[ "rid" ] = 0 />
        <cfset response[ "name" ] = "NA" />
        <cfset response[ "owner" ] = "NA" />
        <cfset response[ "rights" ] = 1 />
        
        <cfquery name="qReportInfo" datasource="#session.dbsource#">
            SELECT	rid, name, owner, rights
			FROM	mp_adhoc_reports
            Where 	rid = <cfqueryparam value="#arguments.id#">
        </cfquery>

		<cfloop query="qReportInfo">
			<cfset response[ "rid" ] = #rid# />
			<cfset response[ "name" ] = #name# />
            <cfset response[ "owner" ] = #owner# />
            <cfset response[ "rights" ] = #rights# />
		</cfloop>
        
		<cfreturn response>
	</cffunction>
</cfcomponent>	