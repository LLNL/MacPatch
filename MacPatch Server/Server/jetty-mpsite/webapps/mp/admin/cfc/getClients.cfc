<cfcomponent output="false">
	<cffunction name="Groups" access="remote" returnformat="json">
		
        <cfset response = {} />
        <cfset rows = ArrayNew(1)> 
        <cfset row = {} />
        <cfset row[ "title" ] = "All" />
        <cfset row[ "icon" ] = "text-list.png" />
        <cfset row[ "href" ] = "/admin/inc/client_group.cfm?gid=All" />
        <cfset rows[1] = row>
        
        <cfquery name="qClientGroups" datasource="#session.dbsource#">
            SELECT	Domain, COUNT(hostname) AS Clients
            FROM	mp_clients_view
            GROUP BY Domain
        </cfquery>
        
        <cfset i = 2>
		<cfloop query="qClientGroups">
        	<cfset _row = {} />
			<cfset _row[ "title" ] = "#Domain# (#Clients#)" />
			<cfset _row[ "icon" ] = "text-list.png" />
            <cfset _row[ "href" ] = "/admin/inc/client_group.cfm?gid=#Domain#" />
			<cfset rows[i] = _row>
			<cfset i = i + 1>		
		</cfloop>
		<cfreturn rows>
	</cffunction>
</cfcomponent>	