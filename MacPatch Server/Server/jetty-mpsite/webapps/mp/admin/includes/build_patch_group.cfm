<!--- Modal Dialog - jquery --->
<script type="text/javascript" src="./_assets/js/jquery/jquery-ui-1.9.2.custom.min.js"></script>

<script type="text/javascript">	
	function loadContent(param, id) {
		$("#dialog").load("includes/available_patches_apple_description.cfm?pid="+id);
		$("#dialog").dialog(
		 	{
			bgiframe: false,
			height: 300,
			width: 600,
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
	function checkAllFields(ref)
	{
		var chkAll = document.getElementById('checkAll');
		var checks = document.getElementsByName('addPatch');
		var removeButton = document.getElementById('removeChecked');
		var boxLength = checks.length;
		var allChecked = false;
		var totalChecked = 0;
		
		if ( ref == 1 ) {
			if ( chkAll.checked == true )
			{
				for ( i=0; i < boxLength; i++ )
				checks[i].checked = true;
			}
			else
			{
				for ( i=0; i < boxLength; i++ )
				checks[i].checked = false;
			}
		} else {
			for ( i=0; i < boxLength; i++ )
			{
				if ( checks[i].checked == true )
				{
				allChecked = true;
				continue;
				}
				else
				{
				allChecked = false;
				break;
				}
			}
			if ( allChecked == true )
			chkAll.checked = true;
			else
			chkAll.checked = false;
		}
		
		for ( j=0; j < boxLength; j++ )
		{
			if ( checks[j].checked == true )
			totalChecked++;
		}
		removeButton.value = "Remove ["+totalChecked+"] Selected";
	}
	
	
	function expand(param)
	{
		param.style.display=(param.style.display=="none")?"":"none";
	}
</script>

<cfquery datasource="#session.dbsource#" name="qGet">
    select * 
    From combined_patches_view
    Order By postdate DESC
</cfquery>

<h3>Build/Create New Patch Group</h3>
<cfform name="PatchList" action="includes/create_patch_group.cfm">
	<table width="100%" cellspacing="0">
    <tr>
        <td>
        <fieldset style="padding: 1em; border: 1px solid #000000;">
         	<legend>Group Name:</legend>
   		 	Name: <cfinput type="text" name="groupname" size="50"><cfinput type="submit" name="CreatePatchGroup" value="Create Group">
         </fieldset>
         <fieldset style="padding: 1em; border: 1px solid #000000;">
         	<legend>Group Type:</legend>
         	<cfinput type="radio" name="type" value="0" checked="yes"> Production<br />
            <cfinput type="radio" name="type" value="1"> QA<br />
         	<cfinput type="radio" name="type" value="2"> Development<br />
         </fieldset>
         </td>
    </tr>
    <tr>
        <td>
        <br />
   		Select  All: <input type="checkbox" onclick="checkAllFields(1);" id="checkAll" />
       	<br />
        </td>
    </tr>
    </table>
    <table id="buildPatchGroup" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
        <thead> 
        <tr> 
            <th><!--- Include&nbsp;&nbsp;&nbsp; --->Include</th>
            <th>Patch</th>
            <th>Description</th>
            <th>Reboot&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th>Type&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th>Patch State&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th>Release Date&nbsp;&nbsp;</th>
        </tr> 
        </thead> 
        <tbody>
			<cfoutput query="qGet">
				<tr>
				  <td><cfinput name="addPatch" type="checkbox" value="#id#" checked="#iif(FindNoCase('firmware',title) GTE 1, DE('no'),DE('yes'))#"></td>
					<td>#name#</td>
					<td valign="top"><a href="##" onclick="loadContent('info','#id#');" style="font-size:11px; border-bottom-style: dotted; border-width: 1px;">#title#</a></td>
					<td align="center">#reboot#</td>
					<td align="center">#type#</td>
                    <td align="center">#patch_state#</td>
					<td align="center">#DateFormat(postdate,"yyyy-mm-dd")#</td>
				</tr>
			</cfoutput>
        </tbody>
        <tfoot> 
        <tr> 
            <th><!--- Include&nbsp;&nbsp;&nbsp; --->Include</th>
            <th>Patch</th>
            <th>Description</th>
            <th>Reboot&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th>Type&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th>Release Date&nbsp;&nbsp;</th>
        </tr> 
        </tfoot> 
    </table>
</cfform>
<div id="dialog" title="Detailed Patch Information" style="text-align:left;" class="ui-dialog-titlebar"></div>

