<cfif session.IsAdmin IS false>
	<cflocation url="#CGI.HTTP_REFERER#">
</cfif>

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
	padding-bottom: 16px;
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
        // The actual autocomplete function, you can hook autocomplete up on a field by field basis.
		$("#suggest").autocomplete('includes/sw_dist/autofill/asproxy.cfm', {
			minChars: 1, // The absolute chars we want is at least 1 character.
			width: 300,  // The width of the auto complete display
			formatItem: function(row){
				return row[0]; // Formatting of the autocomplete dropdown.
			}
		});
    }); 
</script>

<!--- Picker --->
<SCRIPT LANGUAGE="JavaScript">
    function showPatchList(frmEleName) {
      sList = window.open("includes/sw_dist/sw_patch_bundle_picker.cfm?INName="+frmEleName, "list", "width=500,height=500");
    }
    function showSWDistList(frmEleName) {
      sList = window.open("includes/sw_dist/sw_dist_picker.cfm?INName="+frmEleName, "list", "width=500,height=500");
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
        var rmRef = "<img src='./_assets/images/cancel.png' style='vertical-align:middle;' height='14' width='14' onClick='removeFormField(\"#row" + frmFieldName + id +"\")\; return false\;'>";
        $("#"+divid).append("<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>"+rmRef+"&nbsp;<img src='./_assets/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick=\"showList('"+frmFieldName+":"+id+"')\;\">&nbsp;<input type='text' size='50' name='pName" + frmFieldName + ":" + id + "' id='pName" + frmFieldName + ":" + id +"' disabled><input type='hidden' size='20' name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"'>&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4'>(Order)&nbsp;<p>");
    }

    function removeFormField(id) {
        $(id).remove();
        //document.getElementById(id).remove();
    }
</script>
<script type="text/javascript">
    function addFormCriteriaField(frmFieldName, pid, divid) {
        var id = document.getElementById(pid).value;
        id = (id - 1) + 2;
        document.getElementById(pid).value = id;

        var rmRef = "<a href='#' onClick='removeFormField(\"#row" + frmFieldName + id +"\"); return false;'><img src='./_assets/images/cancel.png' style='vertical-align:top;margin-top:2px;' height='14' width='14'></a>";
        var sel = "<select name='type_"+ id + "' id='"+frmFieldName + id +"' size='1' style='vertical-align:top\;'><option>BundleID</option><option>File</option><option>Script</option></select>";
        $("#"+divid).append("<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>&nbsp;"+sel+"&nbsp;<textarea name='" + frmFieldName + "_" + id + "' class='example' id='"+frmFieldName + id +"' cols=\"100\" />&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4' style='vertical-align:top\;'><span style='vertical-align:top\;'>(Order)</span>&nbsp;"+rmRef+"</p>");
        //<p id='row" + id + "'>
    }

    function removeFormField(id) {
        $(id).remove();
        //document.getElementById(id).remove();
    }
</script>

<cfform name="stepIt" method="post" action="./includes/sw_dist/post.cfm" enctype="multipart/form-data">
  <div id="smartwizard" class="wiz-container">
    <ul id="wizard-anchor">
      <li> <a href="#wizard-1">
        <h2>Step 1</h2>
        <small>Software Package Information</small> </a> </li>
      <li> <a href="#wizard-2">
        <h2>Step 2</h2>
        <small>Package</small> </a> </li>
      <li> <a href="#wizard-3">
        <h2>Step 3</h2>
        <small>Criteria</small> </a> </li>
      <li> <a href="#wizard-4">
        <h2>Step 4</h2>
        <small>Save</small> </a> </li>
    </ul>
    <div id="wizard-body" class="wiz-body">
      <div id="wizard-1">
        <div class="wiz-content">
          <div id="textbox">
            <p class="alignleftH2">Software Package Information</p>
            <br />
          </div>
          <div id="container">
            <div id="row">
              <div id="left"> Name </div>
              <div id="center">
                <cfinput type="text" name="sName" SIZE="50" required="#isReq#" message="Error [software name]: Name is required.">
              </div>
              <div id="right"> (e.g. "FireFox") </div>
            </div>
            <div id="row">
              <div id="left"> Version </div>
              <div id="center">
                <cfinput type="text" name="sVersion" SIZE="50" required="#isReq#" message="Error [software version]: Version is required.">
              </div>
              <div id="right"> (e.g. "3.5.4") </div>
            </div>
            <div id="row">
              <div id="left"> Vendor </div>
              <div id="center">
                <cfinput type="text" name="sVendor" SIZE="50">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Description </div>
              <div id="center">
                <textarea name="sDescription" cols="48" rows="9"></textarea>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Vendor Info URL </div>
              <div id="center">
                <cfinput type="text" name="sVendorURL" SIZE="50">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Package State </div>
              <div id="center">
                <cfselect name="sState" size="1">
                <option value="0">Create</option>
                <option value="1">QA</option>
                <option value="2">Production</option>
                <option value="3">Disabled</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
          </div>
          <!--- End container ---> 
        </div>
        <!--- End wiz-content --->
        <div class="wiz-nav">
          <input class="next btn" id="next" type="button" value="Next >" />
        </div>
      </div>
      <!--- End wizard-1 --->
      <div id="wizard-2">
        <div class="wiz-content">
          <div id="textbox">
            <p class="alignleftH2">Package</p>
            <br />
          </div>
          <div id="container">
            <div id="row">
              <div id="left"> Package </div>
              <div id="center">
                <cfinput type="file" name="mainPackage" required="#isReq#" message="Error [Patch File]: A patch package name is required.">
              </div>
              <div id="right">Note: The file must be a zip file for dmg file.</div>
            </div>
            <div id="row">
              <div id="left"> Package Type </div>
              <div id="center">
                <cfselect name="sw_type" size="1">
                <option value="scriptZip">Script/Zip</option>
                <option value="packageZip" selected="selected">Package/Zip (pkg/mpkg)</option>
                <option value="appZip">Application/Zip</option>
                <option value="packageDMG">DMG/Package</option>
                <option value="appDMG">DMG/Application</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> PreInstall Script </div>
              <div id="center">
                <textarea name="sw_pre_install_script" cols="60" rows="7"></textarea>
              </div>
              <div id="right"> Note: The return code of "0" is True. </div>
            </div>
            <div id="row">
              <div id="left"> PostInstall Script </div>
              <div id="center">
                <textarea name="sw_post_install_script" cols="60" rows="7"></textarea>
              </div>
              <div id="right"> Note: The return code of "0" is True. </div>
            </div>
            <div id="row">
              <div id="left"> Installer Env Variables </div>
              <div id="center">
                <input type="text" id="env_var" name="sw_env_var" SIZE="60" value="">
              </div>
              <div id="right">(Example: ATTR=VALUE,ATTR=VALUE)</div>
            </div>
            <div id="row">
              <div id="left"> Patch Requires Reboot </div>
              <div id="center">
                <cfselect name="sReboot" size="1">
                <option value="1">Yes</option>
                <option value="0" selected>No</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
          </div>
          <!--- End container ---> 
        </div>
        <!--- End wiz-content --->
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
          <input class="next btn" id="next" type="button" value="Next >" />
        </div>
      </div>
      <!--- End wizard-2 --->
      <div id="wizard-3">
        <div class="wiz-content">
          <div id="textbox">
            <p class="alignleftH2">Install Criteria</p>
            <br />
          </div>
          <div id="container">
            <div id="row">
              <div id="left"> OS Type </div>
              <div id="center">
                <cfselect name="req_os_type" size="1">
                <option>Mac OS X</option>
                <option>Mac OS X Server</option>
                <option selected>Mac OS X, Mac OS X Server</option>
                </cfselect>
              </div>
              <div id="right"> (e.g. "Mac OS X, Mac OS X Server") </div>
            </div>
            <div id="row">
              <div id="left"> OS Version </div>
              <div id="center">
                <cfinput type="text" name="req_os_ver" SIZE="50" required="#isReq#" message="Error [Required OS Version]: A OS version is required." value="*">
              </div>
              <div id="right"> (e.g. "10.4.*,10.5.*") </div>
            </div>
            <div id="row">
              <div id="left"> Architecture Type </div>
              <div id="center">
                <cfselect name="req_os_arch" size="1">
                <option>PPC</option>
                <option>X86</option>
                <option selected>PPC, X86</option>
                </cfselect>
              </div>
              <div id="right"> (e.g. "PPC, X86"; Universal) </div>
            </div>
            <div id="row">
              <div id="left"> Uninstall Script </div>
              <div id="center">
                <textarea name="sw_uninstall_script" cols="60" rows="9"></textarea>
              </div>
              <div id="right"> &nbsp; </div>
            </div>
            <div id="row">
              <div id="textbox"> <br />
                <p class="alignleftH2">Patching Info</p>
              </div>
            </div>
            <div id="row">
              <div id="left"> Patch Group ID </div>
              <div id="center"> <img src='./_assets/images/info.png' style='vertical-align:middle;' height='16' width='16' onClick="showPatchList('patch_bundle_id');">
                <input type="text" id="patch_bundle_id" name="patch_bundle_id" SIZE="50" value="">
              </div>
              <div id="right"> (e.g. org.mozilla.firefox) </div>
            </div>
            <div id="row">
              <div id="left"> Enable Auto-Patch </div>
              <div id="center">
                <cfselect name="auto_patch" size="1">
                <option value="1">Yes</option>
                <option value="0">No</option>
                </cfselect>
              </div>
              <div id="right"> &nbsp; </div>
            </div>
          </div>
          <!--- End container ---> 
        </div>
        <!--- End wiz-content --->
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
          <input class="next btn" id="next" type="button" value="Next >" />
        </div>
      </div>
      <!--- End wizard-3 --->
      <div id="wizard-4">
        <div class="wiz-content">
          <div id="textbox">
            <p class="alignleftH2">Install Requisites &amp; Save</p>
            <br />
          </div>
          <div id="container">
            <label>Pre-Requisite Package(s)</label>
            <h3><a href="#" onClick="addFormField('preSWPKG','preid','divTxtPre'); return false;"><img src="./_assets/images/pkg_add.png" />Add</a></h3>
            <input type="hidden" id="preid" value="0">
            <div id="divTxtPre"></div>
            <br />
            <label>Post-Requisite Package(s)</label>
            <h3><a href="#" onClick="addFormField('postSWPKG','postid','divTxtPost'); return false;"><img src="./_assets/images/pkg_add.png" />Add</a></h3>
            <input type="hidden" id="postid" value="0">
            <div id="divTxtPost"></div>
          </div>
        </div>
        <!--- End wiz-content --->
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
          <input class="btn" id="next" type="submit" value="Save" />
        </div>
      </div>
      <!--- End wizard-4 ---> 
    </div>
    <!--- End wizard-body ---> 
  </div>
</cfform>
