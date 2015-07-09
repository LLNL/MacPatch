<cfsetting showDebugOutput="No">
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Detailed Info</title>
</head>
<style type="text/css">
fieldset {
	padding: 10px;
	border: 1px solid black;
	border-bottom-width: 1px;
	border-left-width: 1px;
	border-right-width: 1px;
	margin-bottom: 1em;
}
fieldset legend div { margin: 0.3em 0.5em; font-weight:bold; font-size:12px; }

div.block{
  overflow:hidden;
}
div.block label
{
  width:250px;
  display:block;
  float:left;
  text-align:left;
  font-weight:bold;
  font-size:0.8em;
}
div.block value
{
  margin-left:4px;
  float:left;
  font-size:0.8em;
}
</style>

<body>
<cfsilent>
<cfquery datasource="#session.dbsource#" name="qGet">
    select mpst.*, mps.*
    From mp_software_task mpst
	Join mp_software mps on mps.suuid = mpst.primary_suuid
	Where mpst.tuuid = <cfqueryparam value="#url.id#">
</cfquery>
</cfsilent>
	
	<fieldset>
		<legend><div>Task Info</div></legend>
		<cfoutput query="qGet">
			<div class="block">
	  			<label>Name</label>
	  			<value>#name#</value>
	  		</div>	
	  		<div class="block">	
	  			<label>Primary Software Package</label>
	  			<value>#sName#</value>
			</div>
			<div class="block">	
	  			<label>Task Type</label>
	  			<value>#sw_task_type#</value>
			</div>
			<div class="block">	
	  			<label>Active</label>
	  			<value>#IIF(active EQ '1',DE('Yes'),DE('No'))#</value>
			</div>
			<div class="block">	
	  			<label>Task Start DateTime</label>
	  			<value>#sw_start_datetime#</value>
			</div>
			<div class="block">	
	  			<label>Task End/Mandatory DateTime</label>
	  			<value>#sw_end_datetime#</value>
			</div>
		</cfoutput>
	</fieldset>
	
	<fieldset>
		<legend><div> Software Info </div></legend>
		<cfoutput query="qGet">
			<div class="block">
				<label>Name</label>
				<value>#sName#</value>
			</div>
			<div class="block">
				<label>Version</label>
				<value>#sVersion#</value>
			</div>
			<div class="block">
				<label>Vendor</label>
				<value>#sVendor#</value>
			</div>
			<div class="block">
				<label>Description</label>
				<value>#sDescription#</value>
			</div>
			<div class="block">
				<label>Reboot</label>
				<value>#IIF(sReboot EQ '1',DE('Yes'),DE('No'))#</value>
			</div>
			<div class="block">
				<label>Auto-Patch</label>
				<value>#IIF(auto_patch EQ '1',DE('Yes'),DE('No'))#</value>
			</div>
			<div class="block">
				<label>Patch Bundle ID</label>
				<value>#patch_bundle_id#</value>
			</div>
			<div class="block">
				<label>SW Package Type</label>
				<value>#sw_type#</value>
			</div>
		</cfoutput>
	</fieldset>	
</body>
</html>