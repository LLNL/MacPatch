<cfcomponent>
	<cffunction name="getAssignedPatchGroups" access="public" returntype="any">
		<cfquery name="qGetGroups" datasource="#session.dbsource#">
			select distinct patchgroup from mp_clients_plist
		</cfquery>
		
		<cfreturn ValueList(qGetGroups.patchgroup,",")>
	</cffunction>
	
	<cffunction name="getPatchGroups" access="public" returntype="query">
		<cfquery name="qGetGroups" datasource="#session.dbsource#">
			select name, id from mp_patch_group
		</cfquery>
		
		<cfreturn qGetGroups>
	</cffunction>
	
	<cffunction name="patchGroupExists" access="public" returntype="any">
		<cfargument name="aGroup">
		<cfquery name="qGetGroup" datasource="#session.dbsource#">
			select name from mp_patch_group
			where name = '#arguments.aGroup#'
		</cfquery>
		<cfif qGetGroup.RecordCount EQ 0>
			<cfreturn false>
		<cfelse>
			<cfreturn true>
		</cfif>
	</cffunction>
	
	<cffunction name="getPatchGroupClientCount" access="public" returntype="any">
		<cfargument name="aGroup">
		<cfquery name="qGetGroupClientCount" datasource="#session.dbsource#">
			Select Count(*) as xCount 
			From mp_clients_plist
			Where patchgroup = <cfqueryparam value="#arguments.aGroup#">
		</cfquery>
		
		<cfreturn qGetGroupClientCount.xCount>
	</cffunction>
	
	<cffunction name="getInvalidPatchGroups" access="public" returntype="query" output="no">
		<cfset var l_groups = getPatchGroups() />
		<cfset var l_groups_clients = getAssignedPatchGroups() />
		<cfset var l_missing_groups = "">
		
		<cfloop list="#l_groups_clients#" index="it" delimiter=",">
			<cfif patchGroupExists(it) EQ false>
				<cfset l_missing_groups = listappend(l_missing_groups, it)>
			</cfif>
		</cfloop>
		
		<cfscript>
			groupQuery = QueryNew("group,clientCount");
			For (i=1;i LTE ListLen(l_missing_groups); i=i+1) {
          		newRow = QueryAddRow(groupQuery);
				QuerySetCell(groupQuery, "group", ListGetAt(l_missing_groups, i) );
				QuerySetCell(groupQuery, "clientCount", getPatchGroupClientCount(ListGetAt(l_missing_groups, i)));
			}	
		</cfscript>
		
		<cfreturn groupQuery>
	</cffunction>
	
	<cffunction name="showClientsForPatchGroup" access="public" returntype="any" output="no">
		<cfargument name="aGroup">
		
		<cfquery name="qGetGroupClients" datasource="#session.dbsource#">
			Select p.patchgroup,c.hostname,c.ipaddr,p.Domain,c.mdate
			From mp_clients_plist p
			LEFT Join mp_clients c ON p.cuuid = c.cuuid
			Where patchgroup = <cfqueryparam value="#arguments.aGroup#">
		</cfquery>

		<cfreturn qGetGroupClients>
	</cffunction>
</cfcomponent>