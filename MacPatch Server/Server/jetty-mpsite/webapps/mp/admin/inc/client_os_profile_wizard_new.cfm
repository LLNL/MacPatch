<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
<link rel="stylesheet" href="/admin/js/smartwizard/css/bp_main.css" type="text/css">
<link rel="stylesheet" href="/admin/js/smartwizard/css/style_wizard.css" type="text/css">
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/smartwizard/js/SmartWizard.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>


<cfset isReq="Yes">

<style type="text/css">
.example {
	padding: 20;
}
.alignleftH2 {
	float: left;
	vertical-align:text-top;
	font-size: 16px;
	font-weight: bold;
	padding-bottom: 6px;
}
.alignleft {
	float: left;
	vertical-align:text-top;
}
.alignright {
	float: right;
	vertical-align:text-top;
}
</style>


<!--- Smart Wizard Setup --->
<script type="text/javascript">
    $().ready(function() {
        $('.wiz-container').smartWizard();
    }); 
</script>
<body>
<div id="wrapper">
  <div style="float:left;" id="1"><div class="wizardTitle">New OS Profile - Wizard</div></div>
  <div style="float:right;" id="2"><input class="btn" id="next" type="button" value="Cancel" onclick="history.go(-1);" /></div>
  <div style="clear:both"></div>
</div>
<cfform name="stepIt" method="post" action="client_os_profile_wizard_save.cfm" enctype="multipart/form-data">
  <div id="smartwizard" class="wiz-container">
    <ul id="wizard-anchor">
      <li><a href="#wizard-1">
        <h2>Step 1</h2>
        <small>Profile Information</small></a></li>
      <li><a href="#wizard-2">
        <h2>Step 2</h2>
        <small>Profile Data</small></a></li>
    </ul>
    <div id="wizard-body" class="wiz-body">
      <div id="wizard-1">
        <div class="wiz-content">
          <h2>Patch Information</h2>
          <p>
          <div id="container">
            <div id="row">
              <div id="left"> Profile Name </div>
              <div id="center">
                <cfinput type="text" name="profileName" SIZE="50" required="#isReq#" message="Error [patch name]: A patch name is required." value="">
              </div>
              <div id="right"> (e.g. "FireFox") </div>
            </div>
            <div id="row">
              <div id="left"> Profile Description </div>
              <div id="center">
                <textarea name="profileDescription" cols="100" rows="26"></textarea>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Profile Revision </div>
              <div id="center">
                <cfinput type="text" name="profileRev" SIZE="50" value="1" readonly="YES">
              </div>
              <div id="right">&nbsp;</div>
            </div>
          </div>
        </div>
        </p>
        <div class="wiz-nav">
          <input class="next btn" id="next" type="button" value="Next >" />
        </div>
      </div>
      <div id="wizard-2">
        <div class="wiz-content">
          <h2>Patch Data</h2>
          <p>
          <div id="container">
            
            <div id="row">
              <div id="left"> Upload New Profile </div>
              <div id="center">
                <cfinput type="file" name="profileFile" required="no" message="Error [Profile File]: A profile is required.">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            
			<div id="row">
              <div id="left">Profile Identifier</div>
              <div id="center">
                <cfinput type="text" name="profileIdentifier" SIZE="50" required="#isReq#" message="Error: A profileIdentifier is required." value="">
              </div>
              <div id="right"> (Sometimes Also Called "PayloadIdentifier") </div>
            </div>
			
            <div id="row">
              <div id="left"> Profile Enabled </div>
              <div id="center">
              	<cfselect name="enabled" size="1" required="yes">
                <option value="1">Yes</option>
                <option value="0" selected="selected">No</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            
            <div id="row">
              <div id="left"> Profile Uninstall On Remove </div>
              <div id="center">
              	<cfselect name="uninstallOnRemove" size="1" required="yes">
                <option value="1" selected="selected">Yes</option>
                <option value="0">No</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
          </div>
        </div>
        </p>
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
          <cfif session.IsAdmin IS true>
            <input class="btn" id="next" type="submit" value="Save" />
          </cfif>
        </div>
      </div>
    </div>
  </div>
</cfform>
</body>
</html>
