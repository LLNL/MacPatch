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
					window.location.href = "index.cfm?adm_mp_patch_baseline_create=True";
				},
				Cancel: function() {
					window.location.href = "<cfoutput>#CGI.HTTP_REFERER#</cfoutput>";
				}
			},
			close: function(){window.location.href = "<cfoutput>#CGI.HTTP_REFERER#</cfoutput>";}
	});		
  /*  
	$('#dialog').dialog({modal: true, close: function(){window.location.href = "cancel.cfm";}})
	*/	
});
</script>

<div id="dialog-confirm" title="Create New Patch Baseline">
  <p style="text-align:left;"><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>You are about to create a new patch baseline.<br />
    <br />
    Are you sure?</p>
</div>