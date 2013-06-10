<script type="text/javascript">	
	$(function() {
		$("#listPatchGroups").tablesorter({
			widgets: ['zebra'],
			headers: { 0:{sorter: false}, 5:{sorter: false} }
		});
		$("#listInvalidPatchGroups").tablesorter({
			widgets: ['zebra'],
			headers: { 0:{sorter: false} }
		});
	});	
</script>

<script type="text/javascript">	
	function loadContent(id) {
		$("#dialog").load('./includes/patch_group_data.cfm?group='+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 700,
			width: 500,
			modal: true
			}
		); 
		$("#dialog").dialog('open');
	}
</script>	
<cfquery datasource="#session.dbsource#" name="qGetGroups">
    Select a.name, b.user_id, b.is_owner, b.patch_group_id, a.type,
	(select COUNT(*) As total From mp_clients_view c Where c.PatchGroup = a.name) as cTotal
    From mp_patch_group a
    Left Join mp_patch_group_members b
    ON a.id = b.patch_group_id
    Where b.is_owner=1
    Order By cTotal DESC
</cfquery>

<cffunction name="hasRights" access="public" returnType="numeric" output="no">
	<cfargument name="user_id" required="yes">
	<cfargument name="patch_group_id" required="yes">
	
	<cfquery datasource="#session.dbsource#" name="qGet">
		Select a.name, b.user_id, b.is_owner
		From mp_patch_group a
		Left Join 
			mp_patch_group_members b
		ON 
			a.id = b.patch_group_id
		Where 
			b.patch_group_id = '#Arguments.patch_group_id#'
		AND 
			b.user_id = '#Arguments.user_id#'
	</cfquery>
	
	<cfset returnVal=0>
	
	<cfif #qGet.recordcount# EQ 1>
		<!--- We know we are assigned, so we can edit --->
		<cfset returnVal=returnVal+1>
		<cfif qGet.is_owner EQ "1">
			<!--- We know we are the owner, so we can delete --->
			<cfset returnVal=returnVal+1> 
		</cfif>
	</cfif>
	<cfif #session.IsAdmin# EQ true>
		<cfset returnVal=2>
	</cfif>
	<cfreturn returnVal>
</cffunction>

<h3>Patch Groups</h3>
<table id="listPatchGroups" class="tablesorter" border="0" cellpadding="0" cellspacing="0"> 
    <thead>
    <tr>
    	<th>&nbsp;</th>
        <th>Name</th>
        <th>Owner</th>
        <th>Type</th>
		<th>Number of Clients</th>
        <th>&nbsp;</th>
    </tr>
    </thead>
    <tbody>
    	<cfoutput query="qGetGroups">
    		<!---
			<cfform name="UpdatePatchList" action="index.cfm" name="#patch_group_id#">
			--->
			<cfform name="UpdatePatchList" action="index.cfm">
    		<tr>
    			<td width="18">
    				<a href="./index.cfm?showpatchgroup=#patch_group_id#"><img src="./_assets/images/info.png" height="16" width="16" align="texttop"></a>
    			</td>
    			<td>#name#</td>
    			<td align="center">#user_id#</td>
                <td align="center"><cfif #type# EQ "0">Production<cfelseif #type# EQ "1">QA<cfelseif #type# EQ "2">Dev</cfif></td>
    			<td align="right">#cTotal#</td>
                <td align="right">
                    <cfif #hasRights(session.username,patch_group_id)# EQ 2 OR session.username EQ "mpadmin">
                         <cfinput type="submit" name="EditPatchGroup" value="Edit"><cfinput type="submit" name="DeletePatchGroup" value="Delete">
                    <cfelseif #hasRights(session.username,patch_group_id)# EQ 1>
                         <cfinput type="submit" name="EditPatchGroup" value="Edit">
                   	<cfelse>
						&nbsp;
                    </cfif>
					<cfinput type="hidden" name="name" value="#patch_group_id#">
            	</td> 
    		</tr>	
    		</cfform>
    	</cfoutput>
    </tbody>
</table>
<cfinvoke component="patch_group_data" method="getInvalidPatchGroups" returnvariable="invList" />
<cfif invList.RecordCount EQ 0>
	<cfabort>
</cfif>
<hr>
<h3>Invalid Patch Groups</h3>
<table id="listInvalidPatchGroups" class="tablesorter" border="0" cellpadding="0" cellspacing="0"> 
    <thead>
    <tr>
    	<th>&nbsp;</th>
        <th>Group</th>
        <th>No. Clients</th>
    </tr>
    </thead>
    <tbody>
	<cfoutput query="invList">
		<tr>
   			<td><input type='image' style='padding-left:2px;' onclick=loadContent('#group#'); src='./_assets/images/jqGrid/info_16.png'></td>
   			<td>#group#</td>
			<td>#clientCount#</td>
		</tr>
	</cfoutput>
	</tbody>
</table>
<div id="dialog" title="Group Information" class="ui-dialog-titlebar"></div>