<cfheader name="expires" value="<cfoutput>#now()#</cfoutput>">
<cfheader name="pragma" value="no-cache">
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate">

<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title></title>
<link rel="stylesheet" href="/admin/js/smartwizard/css/bp_main.css" type="text/css">
<link rel="stylesheet" href="/admin/js/smartwizard/css/style_wizard.css" type="text/css">
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />

<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<script type="text/javascript" src="/admin/js/smartwizard/js/SmartWizard.js"></script>


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
#overlay {
	width:100%;
	height:100%;
	background-color: black;
	
	position: fixed;
	top: 0; right: 0; bottom: 0; left: 0;
	opacity: 0.6; /* also -moz-opacity, etc. */
	z-index: 10;
	display:none; color:#FFFFFF; text-align:center;
}
</style>

<cfset isReq="Yes">
<cfset hasOSArch="true">
<cfquery name="selPatch" datasource="#session.dbsource#">
    select *
    From mp_patches
    Where puuid = '#url.patchID#'
</cfquery>
<cfquery name="selPatchCri" datasource="#session.dbsource#">
    select *
    From mp_patches_criteria
    Where puuid = '#url.patchID#'
    Order By type_order Asc
</cfquery>
<cfquery name="selPatchCriArchTest" dbtype="query">
	Select * From selPatchCri
	Where type = 'OSArch'
</cfquery>
<cfif selPatchCriArchTest.RecordCount EQ 0>
	<cfset hasOSArch="false">
</cfif>
<cfquery name="selPatchReq" datasource="#session.dbsource#">
    select *
    From mp_patches_requisits
    Where mp_patches_requisits.puuid = '#url.patchID#'
    Order By type_order Asc
</cfquery>

<script type="text/javascript">
	$().ready(function() 
	{
		$("body").prepend('<div id="overlay" class="ui-widget-overlay" style="z-index: 1001; display: none;"><img src="/admin/images/spinner.gif" height="64" width="64" style="display:block;margin:auto;padding-top:10%;" />Saving...</div>');
		$('.wiz-container').smartWizard();	
		$( "#target" ).submit(function( event ) {
			var pass = true;
			if(pass == false){
				return false;
			}
			$("#overlay, #PleaseWait").show();
			return true;
		});
	}); 
</script>
<!--- Picker --->
<SCRIPT LANGUAGE="JavaScript">
    function showList(frmEleName) {
      sList = window.open("custom_patch_picker.cfm?INName="+frmEleName, "list", "width=400,height=500");
    }

    function showHelp() {
      sList = window.open("custom_patch_builder_help.cfm", "Help", "width=800,height=500");
    }

    function remLink() {
      if (window.sList && window.sList.open && !window.sList.closed)
        window.sList.opener = null;
    }
</SCRIPT>
<!--- Add & Remove Input Form Fields --->
<script type="text/javascript">
    function addFormField(frmFieldName, pid, divid) {
        var id = document.getElementById(pid).value;
        id = (id - 1) + 2;
        document.getElementById(pid).value = id;
        var rmRef = "<img src='/admin/images/cancel.png' style='vertical-align:middle;' height='14' width='14' onClick='removeFormField(\"#row" + frmFieldName + id +"\")\; return false\;'>";
        $("#"+divid).append("<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>"+rmRef+"&nbsp;<img src='/admin/images/info_16.png' style='vertical-align:middle;' height='14' width='14' onClick=\"showList('"+frmFieldName+":"+id+"')\;\">&nbsp;<input type='text' size='50' name='pName" + frmFieldName + ":" + id + "' id='pName" + frmFieldName + ":" + id +"' disabled><input type='hidden' size='20' name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"'>&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4'>(Order)&nbsp;<p>");
    }

    function removeFormField(id) {
    	var x=window.confirm("Are you sure you want to remove this?")
		if (x) {
			$(id).remove();
		}
        //
        //document.getElementById(id).remove();
    }
</script>
<script type="text/javascript">
    function addFormCriteriaField(frmFieldName, pid, divid) {
        var id = document.getElementById(pid).value;
        <cfif selPatchCri.RecordCount GT 2>
			if (id == 0) {
				<cfif hasOSArch EQ true>
        			id = parseInt(<cfoutput>#evaluate(selPatchCri.RecordCount - 3)#</cfoutput>) + 1;
        		<cfelse>
					id = parseInt(<cfoutput>#evaluate(selPatchCri.RecordCount - 2)#</cfoutput>) + 1;
        		</cfif>
			} else {
				id = parseInt(id) + 1;
			}
        <cfelse>
        id = parseInt(id) + 1;
        </cfif>
        document.getElementById(pid).value = id;
        var rmRef = "<a href='#' onClick='removeFormField(\"#row" + frmFieldName + id +"\"); return false;'><img src='/admin/images/cancel.png' style='vertical-align:top;margin-top:2px;' height='14' width='14'></a>";
        var sel = "&nbsp;<select name='type_"+ id + "' id='"+frmFieldName + id +"' size='1' style='vertical-align:top\;'><option>BundleID</option><option>File</option><option>Script</option></select>&nbsp;&nbsp;";
        $("#"+divid).append("&nbsp;<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>&nbsp;"+sel+"&nbsp;<textarea name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"' cols=\"60\" />&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4' style='vertical-align:top\;'><span style='vertical-align:top\;'>(Order)</span>&nbsp;"+rmRef+"</p>");
    }
</script>
<cffunction name="getPatchInfo" access="public" returntype="any">
  <cfargument name="patchID" required="yes">
  <cfquery name="qGet" datasource="#session.dbsource#">
        select *
        From mp_patches
        Where puuid = '#patchID#'
    </cfquery>
  <cfset xy = #qGet.patch_name# & " (" & #qGet.patch_ver# & ")">
  <cfreturn xy>
</cffunction>
<cfif IsDefined("isReadOnly") IS false>
  <cfset isReadOnly="false">
  <cfset action="custom_patch_builder_wizard_update.cfm">
  <cfelse>
  <cfset action="">
</cfif>

<body>
<div id="wrapper">
  <div style="float:left;" id="1"><div class="wizardTitle">Custom Patch Edit - Wizard</div></div>
  <div style="float:right;" id="2"><input class="btn" id="next" type="button" value="Cancel" onclick="history.go(-1);" /></div>
  <div style="clear:both"></div>
</div>

<form id="target" name="stepIt" method="post" action="<cfoutput>#action#</cfoutput>" enctype="multipart/form-data">
  <input type="hidden" name="puuid" value="<cfoutput>#url.patchID#</cfoutput>">
  <div id="smartwizard" class="wiz-container">
    <ul id="wizard-anchor">
      <li><a href="#wizard-1">
        <h2>Step 1</h2>
        <small>Patch Information</small></a></li>
      <li><a href="#wizard-2">
        <h2>Step 2</h2>
        <small>Patch Criteria</small></a></li>
      <li><a href="#wizard-3">
        <h2>Step 3</h2>
        <small>Patch Package</small></a></li>
      <li><a href="#wizard-4">
        <h2>Step 4</h2>
        <small>Additional Patches &amp; Save</small></a></li>
    </ul>
    <div id="wizard-body" class="wiz-body">
      <div id="wizard-1">
        <div class="wiz-content">
          <h2>Patch Information</h2>
          <p>
          <div id="container">
            <div id="row">
              <div id="left"> Patch Name </div>
              <div id="center">
                <input type="text" name="patch_name" SIZE="50" required="#isReq#" message="Error [patch name]: A patch name is required." value="<cfoutput>#selPatch.patch_name#</cfoutput>">
              </div>
              <div id="right"> (e.g. "FireFox") </div>
            </div>
            <div id="row">
              <div id="left"> Patch Version </div>
              <div id="center">
                <input type="text" name="patch_ver" SIZE="50" required="#isReq#" message="Error [patch version]: A patch version is required." value="<cfoutput>#selPatch.patch_ver#</cfoutput>">
              </div>
              <div id="right"> (e.g. "3.5.4") </div>
            </div>
			<div id="row">
              <div id="left"> Patch Vendor </div>
              <div id="center">
                <input type="text" name="patch_vendor" SIZE="50" value="<cfoutput>#selPatch.patch_vendor#</cfoutput>">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Patch Description </div>
              <div id="center">
                <textarea name="description" cols="48" rows="9"><cfoutput>#selPatch.description#</cfoutput></textarea>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Patch Info URL </div>
              <div id="center">
                <input type="text" name="description_url" SIZE="50" value="<cfoutput>#selPatch.description_url#</cfoutput>">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Patch Severity </div>
              <div id="center">
                <select name="patch_severity" size="1" required="yes">
                <option><cfoutput>#selPatch.patch_severity#</cfoutput></option>
                <option>High</option>
                <option>Medium</option>
                <option>Low</option>
                <option>Unknown</option>
                </select>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Patch State </div>
              <div id="center">
                <select name="patch_state" size="1">
                <option><cfoutput>#selPatch.patch_state#</cfoutput></option>
                <option>Create</option>
                <option>QA</option>
                <option>Production</option>
                </select>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> CVE ID </div>
              <div id="center">
                <input type="text" name="cve_id" SIZE="50" value="<cfoutput>#selPatch.cve_id#</cfoutput>">
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
        	<div id="wrapper">
              <div style="float:left;" id="1"><h2>Patch Criteria</h2></div>
              <div style="float:right;" id="2"><a href="#" onClick="showHelp();"><img src="/admin/images/icons/help.png" /></a></div>
              <div style="clear:both"></div>
            </div>
          <div id="container">
            <div id="row">
              <div id="left"> OS Type </div>
              <div id="center">
				<cfquery name="selPatchCriType" dbtype="query">
					Select * From selPatchCri
					Where type = 'OSType'
				</cfquery>
				<select name="req_os_type" size="1">
                    <option selected><cfoutput>#selPatchCriType.type_data#</cfoutput></option>
					<option>Mac OS X</option>
                	<option>Mac OS X Server</option>
                	<option>Mac OS X, Mac OS X Server</option>
                </select>
              </div>
              <div id="right"> (e.g. "Mac OS X, Mac OS X Server") </div>
            </div>
            <div id="row">
              <div id="left"> OS Version </div>
              <div id="center">
                <cfset _osver = "">
                <cfloop query="selPatchCri">
                  <cfif selPatchCri.type EQ "OSVersion">
                    <cfset _osver = #selPatchCri.type_data#>
                  </cfif>
                </cfloop>
                <input type="text" name="req_os_ver" SIZE="50" required="#isReq#" message="Error [Required OS Version]: A OS version is required." value="<cfoutput>#_osver#</cfoutput>">
              </div>
              <div id="right"> (e.g. "10.4.*,10.5.*") </div>
            </div>
			<div id="row">
              <div id="left"> Architecture Type </div>
              <div id="center">
				<cfquery name="selPatchCriArch" dbtype="query">
					Select * From selPatchCri
					Where type = 'OSArch'
				</cfquery>
				<select name="req_os_arch" size="1">
                    <option selected><cfoutput>#selPatchCriArch.type_data#</cfoutput></option>
					<option>PPC</option>
	                <option>X86</option>
	                <option>PPC, X86</option>
                </select>
              </div>
              <div id="right">(e.g. "PPC, X86"; Universal)</div>
            </div>
          </div>
          <h3><a href="#" onClick="addFormCriteriaField('reqPatchCriteria','reqid','divTxtReq'); return false;"><img src="/admin/images/process_add_16.png" />Add Criteria</a></h3>
          <input type="hidden" id="reqid" value="0">
          <div id="divTxtReq">
			<cfset xi = 1>
			<cfif hasOSArch EQ true>
				<cfset orderTypeSize="4">
			<cfelse>
				<cfset orderTypeSize="3">
			</cfif>
            <cfloop query="selPatchCri">
              <cfif selPatchCri.type_order GTE orderTypeSize>
                <cfoutput>
					<p id="rowreqPatchCriteria#xi#" style="margin-top:4px;">&nbsp;
                    <select name="type_#xi#" id="reqPatchCriteria#xi#" size="1" style="vertical-align:top;">
                      <option #IIf(selPatchCri.type is "BundleID", DE("Selected"), DE(""))#>BundleID</option>
                      <option #IIf(selPatchCri.type is "File", DE("Selected"), DE(""))#>File</option>
                      <option #IIf(selPatchCri.type is "Script", DE("Selected"), DE(""))#>Script</option>
                    </select>
                    &nbsp;
                    <textarea name='reqPatchCriteria_#xi#' id='reqPatchCriteria_#xi#' cols="60">#selPatchCri.type_data#</textarea>
                    &nbsp;
					<input type='text' name='reqPatchCriteriaOrder_#xi#' value='#xi#' size='3' style='vertical-align:top;'>
					<span style='vertical-align:top;'>(Order)</span>&nbsp; <a href='##' onClick='removeFormField("##rowreqPatchCriteria#xi#"); return false;'><img src='/admin/images/cancel.png' style='vertical-align:top;margin-top:2px;' height='14' width='14'></a></p>
                </cfoutput>
				<cfset xi = xi + 1>
              </cfif>
            </cfloop>
          </div>
          </p>
        </div>
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
          <input class="next btn" id="next" type="button" value="Next >" />
        </div>
      </div>
      <div id="wizard-3">
        <div class="wiz-content">
          <h2>Patch Package</h2>
          <p>
          <div id="container">
            <div id="row">
              <div id="left"> Patch Group ID </div>
              <div id="center">
                <input type="text" name="bundle_id" SIZE="50" required="#isReq#" message="Error [Patch Group ID]: A patch group id is required." value="<cfoutput>#selPatch.bundle_id#</cfoutput>">
              </div>
              <div id="right"> (e.g. org.mozilla.firefox) </div>
            </div>
            <div id="row">
              <div id="left"> PreInstall Script </div>
              <div id="center">
                <textarea name="pkg_preinstall" cols="60" rows="7"><cfoutput>#selPatch.pkg_preinstall#</cfoutput></textarea>
              </div>
              <div id="right"> Note: The return code of "0" is True. </div>
            </div>
            <div id="row">
              <div id="left"> PostInstall Script </div>
              <div id="center">
                <textarea name="pkg_postinstall" cols="60" rows="7"><cfoutput>#selPatch.pkg_postinstall#</cfoutput></textarea>
              </div>
              <div id="right"> Note: The return code of "0" is True. </div>
            </div>
            <div id="row">
              <div id="left"> Patch Package </div>
              <div id="center">
                <input type="file" name="mainPatchFile" message="Error [Patch File]: A patch package name is required.">
                <br>
                <div style="font-size:10px;padding:10px;">
                	<cfoutput>
                	<a href="http://#CGI.SERVER_NAME#/mp-content#selPatch.pkg_url#" style="font-size:12px;"><img src="/admin/images/icons/arrow_down.png" height="14" />#selPatch.pkg_name# (#selPatch.pkg_hash#)</a>
                	</cfoutput>
                </div>
              </div>
              <div id="right">(Note: The file must be a zipped pkg or mpkg)</div>
            </div>
			<div id="row">
	            <div id="left">
					Installer Env Variables
	            </div>
	            <div id="center">
		            <cfoutput>
	                <input type="text" id="env_var" name="pkg_env_var" SIZE="60" value="<cfoutput>#selPatch.pkg_env_var#</cfoutput>">
	                </cfoutput>
	            </div>
	            <div id="right">(Example: ATTR=VALUE,ATTR=VALUE)</div>
           	</div>
			<div id="row">
            	<div id="left"> Patch Install Weight </div>
            	<div id="center" style="color:black;">
                	<input name="patchInstallWeight" id="patchInstallWeight" type="range" min="0" max="100" step="1" title="" value="<cfoutput>#selPatch.patch_install_weight#</cfoutput>" onchange="document.getElementById('patchInstallWeight-out').innerHTML = this.value" />
					<span id="patchInstallWeight-out"><cfoutput>#selPatch.patch_install_weight#</cfoutput></span>
              	</div>
				<div id="right">Sets a patch install weight order.<br>Lower = Earlier</div>
            </div>
            <div id="row">
              <div id="left"> Patch Requires Reboot </div>
              <div id="center">
                <select name="patch_reboot" size="1"> <cfoutput>
                  <option #IIf(selPatch.patch_reboot is "Yes", DE("Selected"), DE(""))#>Yes</option>
                  <option #IIf(selPatch.patch_reboot is "No", DE("Selected"), DE(""))#>No</option>
                </cfoutput></select>
              </div>
              <div id="right">&nbsp;</div>
            </div>
          </div>
          </p>
        </div>
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
          <input class="next btn" id="next" type="button" value="Next >" />
        </div>
      </div>
      <div id="wizard-4">
        <div class="wiz-content">
          <h2>Additional Patches &amp; Finish</h2>
          <label>Pre-Requisite Package(s)</label>
          <h3><a href="#" onClick="addFormField('prePatchPKG','preid','divTxtPre'); return false;"><img src="/admin/images/pkg_add.png" />Add</a></h3>
          <cfset preStartID = 0>
          <div id="divTxtPre">
            <cfloop query="selPatchReq">
              <cfif #selPatchReq.type# EQ "0">
                <cfoutput>
                  <cfset preStartID = #preStartID# + 1>
                  <p id="rowprePatchPKG#selPatchReq.type_order#" style="margin-top:4px;">
					<img onClick='removeFormField("##rowprePatchPKG<cfoutput>#selPatchReq.type_order#</cfoutput>"); return false;' src="/admin/images/cancel.png" style="vertical-align:middle;" height="14" width="14"> <img src='/admin/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick="showList('prePatchPKG:<cfoutput>#selPatchCri.type_order#</cfoutput>');">
                    <input type='hidden' size='20' name="<cfoutput>prePatchPKG_#selPatchReq.type_order#</cfoutput>" id="<cfoutput>prePatchPKG#selPatchReq.type_order#</cfoutput>" value="<cfoutput>#selPatchReq.puuid_ref#</cfoutput>">
                    <input type='text' size='50' name="<cfoutput>pNameprePatch:#selPatchReq.type_order#</cfoutput>" id="<cfoutput>pNameprePatch:#selPatchReq.type_order#</cfoutput>" value="<cfoutput>#getPatchInfo(selPatchReq.puuid_ref)#</cfoutput>">
                    &nbsp;
                    <input type="text" name="prePatchPKGOrder_<cfoutput>#selPatchReq.type_order#</cfoutput>" value="<cfoutput>#selPatchReq.type_order#</cfoutput>" size="3">
                    (Order)&nbsp; </p>
                  <p>&nbsp;</p>
                </cfoutput>
              </cfif>
            </cfloop>
          </div>
          <input type="hidden" id="preid" value="<cfoutput>#preStartID#</cfoutput>">
          <br />
          <label>Post-Requisite Package(s)</label>
          <h3><a href="#" onClick="addFormField('postPatchPKG','postid','divTxtPost'); return false;"><img src="/admin/images/pkg_add.png" />Add</a></h3>
          <input type="hidden" id="postid" value="0">
          <div id="divTxtPost">
            <cfloop query="selPatchReq">
              <cfif #selPatchReq.type# EQ "1">
                <cfoutput>
                  <p id="rowpostPatchPKG#selPatchReq.type_order#" style="margin-top:4px;">
					<img onClick='removeFormField("##rowpostPatchPKG<cfoutput>#selPatchReq.type_order#</cfoutput>"); return false;' src="/admin/images/cancel.png" style="vertical-align:middle;" height="14" width="14"> <img src='/admin/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick="showList('postPatchPKG:<cfoutput>#selPatchCri.type_order#</cfoutput>');">
                    <input type='hidden' size='20' name="<cfoutput>postPatchPKG_#selPatchReq.type_order#</cfoutput>" id="<cfoutput>postPatchPKG#selPatchReq.type_order#</cfoutput>" value="<cfoutput>#selPatchReq.puuid_ref#</cfoutput>">
                    <input type='text' size='50' name="<cfoutput>pNamepostPatch:#selPatchReq.type_order#</cfoutput>" id="<cfoutput>pNamepostPatch:#selPatchReq.type_order#</cfoutput>" value="<cfoutput>#getPatchInfo(selPatchReq.puuid_ref)#</cfoutput>">
                    &nbsp;
                    <input type="text" name="<cfoutput>postPatchPKGOrder_#selPatchReq.type_order#</cfoutput>" value="<cfoutput>#selPatchReq.type_order#</cfoutput>" size="3">
                    (Order)&nbsp; </p>
                  <p>&nbsp;</p>
                </cfoutput>
              </cfif>
            </cfloop>
          </div>
          <hr />
          Make Patch Active
          <input type="checkbox" name="active" value="1" checked="<cfoutput>#iif(selPatch.active is 1,DE('Yes'),DE('No'))#</cfoutput>">
        </div>
        <div class="wiz-nav">
          <div style="text-align:right;"></div>
          <input class="back btn" id="back" type="button" value="< Back" />
          <cfif session.IsAdmin IS true>
            <input class="btn" id="next" type="submit" value="Save" />
          </cfif>
        </div>
      </div>
    </div>
  </div>
</form>
</body>
</html>