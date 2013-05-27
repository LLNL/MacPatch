<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">
<script>
$(document).ready(function(){
	$("#dialog-confirm").dialog({
			bgiframe: true,
			resizable: false,
			height:200,
			modal: true,
			buttons: {
				'New Baseline': function() {
					window.location.href = "<cfoutput>#session.cflocFix#/admin/index.cfm?adm_mp_patch_baseline_create=True</cfoutput>";
				},
				Cancel: function() {
					window.location.href = "<cfoutput>#session.cflocFix#/admin/index.cfm?patch_baseline</cfoutput>";
				}
			},
			close: function(){window.location.href = "<cfoutput>#session.cflocFix#/admin/index.cfm?patch_baseline</cfoutput>";}
	});
});
</script>

<div id="dialog-confirm" title="Create New Patch Baseline">
  <p style="text-align:left;"><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>You are about to create a new patch baseline.<br />
    <br />
    Are you sure?</p>
    <cfoutput>#session.cflocFix#/admin/index.cfm?adm_mp_patch_baseline_create=True</cfoutput>
</div>