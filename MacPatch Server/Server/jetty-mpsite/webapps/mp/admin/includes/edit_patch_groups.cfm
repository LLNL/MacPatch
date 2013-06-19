<script type="text/javascript" src="./_assets/js/jquery/jquery-ui-1.9.2.custom.min.js"></script>

<script type="text/javascript">	
	function loadContent(param, id) {
		$("#dialog").load("includes/available_patches_apple_description.cfm?pid="+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 360,
			width: 700,
			modal: true
			}
		); 
		$("#dialog").dialog('open');
	}
</script>

<script type="text/javascript">	
	
	$.tablesorter.addParser({
        // set a unique id
        id: 'checkboxes',
        is: function(s) {
            // return false so this parser is not auto detected
            return false;
        },
        format: function(s,table,cell) {
            // format your data for normalization
            var checked = $(cell).children(":checkbox").get(0).checked;                  
            return  checked  ? 1 : 0;
        },
        // set type, either numeric or text
        type: 'numeric'
    });
	
	$(function() {
		// Used by build_patch_group.cfm, edit_patch_group.cfm
		$("#buildPatchGroup").tablesorter({
			widgets: ['zebra'],
			headers: {
                0: {
                    sorter:'checkboxes'
                }
            }
		});
		
		$(":checkbox").click(function() {
        	$("#buildPatchGroup").trigger("update");
    	});
		
	});	
</script>	

<script type="text/javascript">
	function checkAllBoxes(checkname, exby) {
  		for (i = 0; i < checkname.length; i++) {
  			checkname[i].checked = exby.checked? true:false
		}
	}
</script>

<script type="text/javascript">
 $(function(){
    $('#checkallBaseline').change(function(){
		$('table.tablesorter').children('tbody').children('tr').each(function() {
			var $tds = $(this).children('td');
			var label = $tds.eq(6).text();
			if( label === "Required" ){
				$tds.eq(0).find("input").attr("checked","checked");
			}
		});
    });
 });
</script>

<style type="text/css">

a.pInfo:link    { color:black; text-decoration:none; border-bottom-style: dotted; border-width: 1px; }
a.pInfo:visited { color:black; text-decoration:none; border-bottom-style: dotted; border-width: 1px; }
a.pInfo:hover   { color:black; text-decoration:none; border-bottom-style: dotted; border-width: 1px; }
a.pInfo:active  { color:black; text-decoration:none; border-bottom-style: dotted; border-width: 1px; }

</style>

<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">

<cfquery datasource="#session.dbsource#" name="qGetName">
    select name, type
    From mp_patch_group
    Where id = '#form.name#'
</cfquery>

<cfquery datasource="#session.dbsource#" name="qGet1">
    Select *
    From mp_patch_group_patches a
	Left Join combined_patches_view b
	ON a.patch_id = b.id
    Where patch_group_id like '#form.name#'
</cfquery>
<cfset currPatchList = "">
<cfset currPatchList = ValueList(qGet1.id, ",")>
<cfif qGetName.type EQ "0">
    <cfquery datasource="#session.dbsource#" name="qGet2">
		select Distinct b.*, IFNULL(ui.baseline_enabled,'0') as baseline_enabled
        From combined_patches_view b
        LEFT JOIN baseline_prod_view ui ON ui.p_id = b.id
		Where b.patch_state = 'Production'
        Order By postdate DESC
    </cfquery>
<cfelseif qGetName.type EQ "1"> 
	<cfquery datasource="#session.dbsource#" name="qGet2">
		select Distinct
		b.id,b.name,b.version, Cast(b.postdate as date) as postdate, b.title, b.reboot,
		b.type,b.suname,b.active,b.severity,b.patch_state,b.size,
 		IFNULL(ui.baseline_enabled,'0') as baseline_enabled
        From combined_patches_view b
        LEFT OUTER JOIN baseline_qa_view ui ON ui.p_id = b.id
        Where b.patch_state IN ('Production','QA')
        Order By postdate DESC
    </cfquery>
<cfelseif qGetName.type EQ "2"> 
	<cfquery datasource="#session.dbsource#" name="qGet2">
        select Distinct b.*, IFNULL(ui.baseline_enabled,'0') as baseline_enabled
        From combined_patches_view b
        LEFT JOIN baseline_qa_view ui ON ui.p_id = b.id
        Where b.patch_state IN ('Production','QA')
        Order By postdate DESC
    </cfquery>
</cfif>
<h3>Update Patch Group <cfoutput>"#qGetName.name#"</cfoutput></h3>
<p>Patch Count: (<cfoutput>#qGet2.RecordCount#</cfoutput>)</p>
<form name="UpdatePatchGroup" action="index.cfm" method="post">
    <table class="generictable" width="100%" cellspacing="0">
        <tr>
            <td>&nbsp;</td>
            <td align="right" height="22px" valign="top">
                <a  href="#gAdmins" style="color:000000;">Edit Group Admins</a>
            </td>
        </tr>
        <tr>
            <td>
                Select  All: <input type="checkbox" onclick="checkAllBoxes(document.UpdatePatchGroup.addPatch,this);" /> All Baseline: <input type="checkbox" id="checkallBaseline" />
            </td>
            <td align="right">
            	Group Type: <select name="type"> 
                	<option value="0" <cfif qGetName.type EQ "0">selected="selected"</cfif>>Production</option>
                    <option value="1" <cfif qGetName.type EQ "1">selected="selected"</cfif>>QA</option>
                    <option value="2" <cfif qGetName.type EQ "2">selected="selected"</cfif>>Development</option>
                </select>    
                <input type="submit" name="UpdatePatchGroup" value="Update Group">
            </td>
        </tr>
    </table>

    <table id="buildPatchGroup" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
    	<thead>
			<tr>
				<th>Select&nbsp;&nbsp;</th>
				<th>Patch</th>
				<th>Description</th>
				<th>Reboot&nbsp;&nbsp;</th>
				<th>Type&nbsp;&nbsp;</th>
                <th>Patch State&nbsp;&nbsp;</th>
                <th>Baseline&nbsp;&nbsp;</th>
				<th>Release Date&nbsp;&nbsp;</th>
			</tr>
        </thead>
        <tbody>
        	<cfloop query="qGet2"><cfoutput>
			<tr>
				<td align="center"><input name="addPatch" type="checkbox" value="#id#" #iif(ListFindNocase(currPatchList,id,",") GTE 1,DE('checked'),DE(''))#></td>
                <td>#qGet2.name#</td>
                <td><img src="_assets/images/info.png" height="14" width="14" onclick="loadContent('info','#id#');" style="padding-right:6px;">#qGet2.title#</td>
				<td align="center">#Reboot#</td>
				<td align="center">#type#</td>
				<td align="center">#patch_state#</td>
                <td align="center"><cfif #baseline_enabled# EQ 1>Required</cfif></td>
				<td align="center">#DateFormat(postdate,"mm/dd/yyyy")#</td>
			</tr>
			</cfoutput></cfloop>
        </tbody>
        <tfoot>
        	<tr>
        	<td colspan="7">
                Select  All: <input name="btm_button" type="checkbox" onclick="checkAllBoxes(document.UpdatePatchGroup.addPatch,this);" />
            </td>
        	<td align="right">
                <input type="submit" name="UpdatePatchGroup" value="Update Group">
            </td>
            </tr>
        </tfoot>
    </table>
	<input type="hidden" name="group_id" size="50" value="<cfoutput>#form.name#</cfoutput>">
</form>


<cfsilent>
<cfquery datasource="#session.dbsource#" name="qGet3">
    Select *
    From mp_patch_group_members
    where patch_group_id = '#form.name#'
    Order By is_owner Desc
</cfquery>
</cfsilent>
<hr>
<h5>Patch Group Admins</h5>
<table class="tableinfo" cellpadding="1">
    <tr>
        <th>UserID</th>
        <th>&nbsp;</th>
    </tr>
    <cfoutput query="qGet3">
    <tr>
        <td>#user_id#<cfif is_owner EQ 1>&nbsp;(Owner)</cfif></td>
        <td>
        <cfif user_id NEQ session.username>
        <cfform name="DeletePatchGroupUsers" action="index.cfm">
        	<cfinput type="hidden" name="user_id" value="#user_id#">
        	<cfinput type="hidden" name="group_id" value="#patch_group_id#"><cfinput type="submit" name="UpdatePatchGroup" value="Delete">
        </cfform>
        <cfelse>
        	&nbsp;
        </cfif>
        </td>
    </tr>		
    </cfoutput>
    <cfform name="UpdatePatchGroupUsers" action="index.cfm">
    <tr>
    	<td><cfinput type="text" name="user_id" value=""> (UID)</td>
    	<td><cfinput type="hidden" name="group_id" size="50" value="#form.name#"><cfinput type="submit" name="UpdatePatchGroup" value="Add"></td>
    </tr>
    </cfform>
</table>

<a name="gAdmins" id="gAdmins"></a>
<p>&nbsp;</p>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>