<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />

<cfset dt = "#LSDateFormat(Now())# #LSTimeFormat(Now())#">
<script>
$(document).ready(function(){
	$("#dialog-confirm").dialog({
			bgiframe: true,
			resizable: false,
			height:240,
			width:400,
			modal: true,
			buttons: {
				'New Baseline': function() {
					window.location.href = "<cfoutput>#session.cflocFix#/admin/inc/admin_baseline_patches_save.cfm</cfoutput>";
				},
				Cancel: function() {
					window.location.href = "<cfoutput>#session.cflocFix#/admin/inc/admin_baseline_patches.cfm</cfoutput>";
				}
			},
			close: function(){window.location.href = "<cfoutput>#session.cflocFix#/admin/inc/admin_baseline_patches.cfm</cfoutput>";}
	});
});
</script>

<div id="dialog-confirm" title="Create New Patch Baseline">
  <p style="text-align:left;font-size:13px;"><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>You are about to create a new patch baseline.<br />
    <br />
    Are you sure?</p>
</div>