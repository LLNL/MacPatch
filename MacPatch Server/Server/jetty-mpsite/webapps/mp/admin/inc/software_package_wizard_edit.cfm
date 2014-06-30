<cfheader name="expires" value="#now()#">
<cfheader name="pragma" value="no-cache">
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate">

<cfset isReq="Yes">
<cfset hasOSArch="true">
<cfset swDistID = #url.packageID#>

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
    <!--- CFML --->
    <cfsilent>   
        <cfquery name="selSwDist" datasource="#session.dbsource#">
            select *
            From mp_software
            Where suuid = '#swDistID#'
        </cfquery>
        <cfquery name="selSwDistCri" datasource="#session.dbsource#">
            select *
            From mp_software_criteria
            Where suuid = '#swDistID#'
            Order By type_order Asc
        </cfquery>
        <cfquery name="selSwDistCriArchTest" dbtype="query">
            Select * From selSwDistCri
            Where type = 'OSArch'
        </cfquery>
        <cfif selSwDistCriArchTest.RecordCount EQ 0>
            <cfset hasOSArch="false">
        </cfif>
        <cfquery name="selSwDistReq" datasource="#session.dbsource#">
            select *
            From mp_software_requisits
            Where mp_software_requisits.suuid = '#swDistID#'
            Order By type_order Asc
        </cfquery>
          
        <cffunction name="getSwDistInfo" access="public" returntype="any">
          <cfargument name="swDistID" required="yes">
              <cfquery name="qGet" datasource="#session.dbsource#">
                    select *
                    From mp_software
                    Where suuid = '#swDistID#'
              </cfquery>
              <cfset xy = #qGet.sName# & " (" & #qGet.sVersion# & ")">
          <cfreturn xy>
        </cffunction>
        <cfif IsDefined("isReadOnly") IS false>
          <cfset isReadOnly="false">
          <cfset action="./includes/sw_dist/update.cfm">
          <cfelse>
          <cfset action="">
        </cfif>
    </cfsilent>
    <!--- Wizard --->
    <script type="text/javascript">
        $().ready(function() {
            $('.wiz-container').smartWizard();
        });
    </script>
    <!--- Picker --->
    <script type="text/javascript">	
		function showSoftwareList(frmEleName) {
		  sList = window.open("software_package_picker.cfm?INName="+frmEleName, "list", "width=400,height=500");
		}
		/*
		function showSoftwareList(frmEleName) 
		{
			$("#dialogSW").load("software_package_picker.cfm?INName="+frmEleName);
			$("#dialogSW").dialog(
				{
				bgiframe: false,
				height: 500,
				width: 500,
				modal: true
				}
			); 
			$("#dialogSW").dialog('open');
		}
		*/
		function showPatchList(frmEleName) 
		{
			$("#dialogPT").load("software_patch_bundle_picker.cfm?INName="+frmEleName);
			$("#dialogPT").dialog(
				{
				bgiframe: false,
				height: 500,
				width: 500,
				modal: true
				}
			); 
			$("#dialogPT").dialog('open');
		}
	</script>
    
    <SCRIPT LANGUAGE="JavaScript">
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
            $("#"+divid).append("<p id='row" + frmFieldName + id +"' style='margin-top:4px;'>"+rmRef+"&nbsp;<img src='/admin/images/info_16.png' style='vertical-align:middle;' height='14' width='14' onClick=\"showSoftwareList('"+frmFieldName+":"+id+"')\;\">&nbsp;<input type='text' size='50' name='pName" + frmFieldName + ":" + id + "' id='pName" + frmFieldName + ":" + id +"' disabled><input type='hidden' size='20' name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"'>&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4'>(Order)&nbsp;<p>");
        }
    
        function removeFormField(id) {
            var x=window.confirm("Are you sure you want to remove this?")
            if (x) {
                $(id).remove();
            }
        }
    </script>
    <!---
	<script type="text/javascript">
        function addFormCriteriaField(frmFieldName, pid, divid) {
            var id = document.getElementById(pid).value;
            <cfif selSwDistCri.RecordCount GT 2>
                if (id == 0) {
                    <cfif hasOSArch EQ true>
                        id = parseInt(<cfoutput>#evaluate(selSwDistCri.RecordCount - 3)#</cfoutput>) + 1;
                    <cfelse>
                        id = parseInt(<cfoutput>#evaluate(selSwDistCri.RecordCount - 2)#</cfoutput>) + 1;
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
	--->
</head>
<cfsilent>    
    <cfif session.IsAdmin IS true>
        <cfset action="software_package_wizard_update.cfm">
    <cfelse>
        <cfset action="">
    </cfif>
</cfsilent>
<body>
<div id="wrapper">
  <div style="float:left;" id="1"><div class="wizardTitle">Software Package Edit - Wizard</div></div>
  <div style="float:right;" id="2"><input class="btn" id="next" type="button" value="Cancel" onclick="history.go(-1);" /></div>
  <div style="clear:both"></div>
</div>

<cfform name="stepIt" method="post" action="#action#" enctype="multipart/form-data">
  <cfinput type="hidden" name="suuid" value="#swDistID#">
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
                <cfinput type="text" name="sName" SIZE="50" required="#isReq#" message="Error [software name]: Name is required." value="#selSwDist.sName#">
              </div>
              <div id="right"> (e.g. "FireFox") </div>
            </div>
            <div id="row">
              <div id="left"> Version </div>
              <div id="center">
                <cfinput type="text" name="sVersion" SIZE="50" required="#isReq#" message="Error [software version]: Version is required." value="#selSwDist.sVersion#">
              </div>
              <div id="right"> (e.g. "3.5.4") </div>
            </div>
            <div id="row">
              <div id="left"> Vendor </div>
              <div id="center">
                <cfinput type="text" name="sVendor" SIZE="50" value="#selSwDist.sVendor#">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Description </div>
              <div id="center">
                <textarea name="sDescription" cols="48" rows="9"><cfoutput>#selSwDist.sDescription#</cfoutput></textarea>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Vendor Info URL </div>
              <div id="center">
                <cfinput type="text" name="sVendorURL" SIZE="50" value="#selSwDist.sVendorURL#">
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> Package State </div>
              <div id="center">
                <cfselect name="sState" size="1">
                <cfoutput>
                <option value="0" #IIf(selSwDist.sState is "0", DE("Selected"), DE(""))#>Create</option>
                <option value="1" #IIf(selSwDist.sState is "1", DE("Selected"), DE(""))#>QA</option>
                <option value="2" #IIf(selSwDist.sState is "2", DE("Selected"), DE(""))#>Production</option>
                <option value="3" #IIf(selSwDist.sState is "3", DE("Selected"), DE(""))#>Disabled</option>
                </cfoutput>
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
                <cfinput type="file" name="mainPackage">
                <br>
                <div style="font-size:10px;padding:10px;">
                	<cfoutput>
                	<a href="http://#CGI.SERVER_NAME#/mp-content#selSwDist.sw_url#" style="font-size:10px;color:ffffff;"><img src="/admin/images/icons/arrow_down.png" height="14" />#ListLast(selSwDist.sw_url,"/")# (#selSwDist.sw_hash#)</a>
                	</cfoutput>
                </div>
              </div>
              <div id="right">Note: The file must be a zip file for dmg file.</div>
            </div>
            <div id="row">
              <div id="left"> Package Type </div>
              <div id="center">
                <cfselect name="sw_type" size="1">
                <cfoutput>
                <option value="scriptZip" #IIf(selSwDist.sw_type is "scriptZip", DE("Selected"), DE(""))#>Script/Zip</option>
                <option value="packageZip" #IIf(selSwDist.sw_type is "packageZip", DE("Selected"), DE(""))#>Package/Zip (pkg/mpkg)</option>
                <option value="appZip" #IIf(selSwDist.sw_type is "appZip", DE("Selected"), DE(""))#>Application/Zip</option>
                <option value="packageDMG" #IIf(selSwDist.sw_type is "packageDMG", DE("Selected"), DE(""))#>DMG/Package</option>
                <option value="appDMG" #IIf(selSwDist.sw_type is "appDMG", DE("Selected"), DE(""))#>DMG/Application</option>
                </cfoutput>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
            <div id="row">
              <div id="left"> PreInstall Script </div>
              <div id="center">
                <cftextarea name="sw_pre_install_script" cols="60" rows="7" value="#selSwDist.sw_pre_install_script#" />
              </div>
              <div id="right"> Note: The return code of "0" is True. </div>
            </div>
            <div id="row">
              <div id="left"> PostInstall Script </div>
              <div id="center">
                <cftextarea name="sw_post_install_script" cols="60" rows="7" value="#selSwDist.sw_post_install_script#" />
              </div>
              <div id="right"> Note: The return code of "0" is True. </div>
            </div>
            <div id="row">
              <div id="left"> Installer Env Variables </div>
              <div id="center">
                <cfinput type="text" id="env_var" name="sw_env_var" SIZE="60" value="#selSwDist.sw_env_var#">
              </div>
              <div id="right">(Example: ATTR=VALUE,ATTR=VALUE)</div>
            </div>
            <div id="row">
              <div id="left"> Patch Requires Reboot </div>
              <div id="center">
                <cfselect name="sReboot" size="1">
                <cfoutput>
                <option value="1" #IIf(selSwDist.sReboot is "1", DE("Selected"), DE(""))#>Yes</option>
                <option value="0" #IIf(selSwDist.sReboot is "0", DE("Selected"), DE(""))#>No</option>
                </cfoutput>
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
              	<cfquery name="selSwDistCriType" dbtype="query">
					Select * From selSwDistCri
					Where type = 'OSType'
				</cfquery>
                <cfselect name="req_os_type" size="1">
                <cfoutput>
                <option #IIf(selSwDistCriType.type_data is "Mac OS X", DE("Selected"), DE(""))#>Mac OS X</option>
                <option #IIf(selSwDistCriType.type_data is "Mac OS X Server", DE("Selected"), DE(""))#>Mac OS X Server</option>
                <option #IIf(selSwDistCriType.type_data is "Mac OS X, Mac OS X Server", DE("Selected"), DE(""))#>Mac OS X, Mac OS X Server</option>
                </cfoutput>
                </cfselect>
              </div>
              <div id="right"> (e.g. "Mac OS X, Mac OS X Server") </div>
            </div>
            <div id="row">
              <div id="left"> OS Version </div>
              <div id="center">
              	<cfset _osver = "">
                <cfloop query="selSwDistCri">
                  <cfif selSwDistCri.type EQ "OSVersion">
                    <cfset _osver = #selSwDistCri.type_data#>
                  </cfif>
                </cfloop>
                <cfinput type="text" name="req_os_ver" SIZE="50" required="#isReq#" message="Error [Required OS Version]: A OS version is required." value="#_osver#">
              </div>
              <div id="right"> (e.g. "10.4.*,10.5.*") </div>
            </div>
            <div id="row">
              <div id="left"> Architecture Type </div>
              <div id="center">
              	<cfquery name="selSwDistCriArch" dbtype="query">
					Select * From selSwDistCri
					Where type = 'OSArch'
				</cfquery>
                <cfselect name="req_os_arch" size="1">
                <cfoutput>
                <option #IIf(selSwDistCriArch.type_data is "PPC", DE("Selected"), DE(""))#>PPC</option>
                <option #IIf(selSwDistCriArch.type_data is "X86", DE("Selected"), DE(""))#>X86</option>
                <option #IIf(selSwDistCriArch.type_data is "PPC, X86", DE("Selected"), DE(""))#>PPC, X86</option>
                </cfoutput>
                </cfselect>
              </div>
              <div id="right"> (e.g. "PPC, X86"; Universal) </div>
            </div>
            <div id="row">
              <div id="left"> Uninstall Script </div>
              <div id="center">
                <textarea name="sw_uninstall_script" cols="60" rows="9"><cfoutput>#selSwDist.sw_uninstall_script#</cfoutput></textarea>
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
              <div id="center"> <img src='/admin/images/info_16.png' style='vertical-align:middle;' height='16' width='16' onClick="showPatchList('patch_bundle_id');">
                <cfinput type="text" id="patch_bundle_id" name="patch_bundle_id" SIZE="50" value="#selSwDist.patch_bundle_id#">
              </div>
              <div id="right"> (e.g. org.mozilla.firefox) </div>
            </div>
            <div id="row">
              <div id="left"> Enable Auto-Patch </div>
              <div id="center">
                <cfselect name="auto_patch" size="1">
                <cfoutput>
                <option #IIf(selSwDist.auto_patch is "1", DE("Selected"), DE(""))# value="1">Yes</option>
                <option #IIf(selSwDist.auto_patch is "0", DE("Selected"), DE(""))# value="0">No</option>
                </cfoutput>
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
      <!--- End wizard-4 --->
      <div id="wizard-4">
        <div class="wiz-content">
          <div id="textbox">
            <p class="alignleftH2">Install Requisites &amp; Save</p>
            <br />
          </div>
          <div id="container">
            <label>Pre-Requisite Package(s)</label>
            <h3><a href="#" onClick="addFormField('preSWPKG','preid','divTxtPre'); return false;"><img src="/admin/images/pkg_add.png" />Add</a></h3>
            <cfset preStartID = 0>
            <div id="divTxtPre">
            <cfloop query="selSwDistReq">
              <cfif #selSwDistReq.type# EQ "0">
                <cfoutput>
                  <cfset preStartID = #preStartID# + 1>
                  <p id="rowprePatchPKG#selSwDistReq.type_order#" style="margin-top:4px;">
                    <img onClick='removeFormField("##rowprePatchPKG#selSwDistReq.type_order#"); return false;' src="/admin/images/cancel.png" style="vertical-align:middle;" height="14" width="14"> <img src='/admin/images/info_16.png' style='vertical-align:middle;' height='14' width='14' onClick="showSoftwareList('prePatchPKG:#selSwDistCri.type_order#');">
                    <input type='hidden' size='20' name="prePatchPKG_#selSwDistReq.type_order#" id="prePatchPKG#selSwDistReq.type_order#" value="#selSwDistReq.suuid_ref#">
                    <input type='text' size='50' name="pNameprePatch:#selSwDistReq.type_order#" id="pNameprePatch:#selSwDistReq.type_order#" value="#getPatchInfo(selSwDistReq.suuid_ref)#">
                    &nbsp;
                    <input type="text" name="prePatchPKGOrder_#selSwDistReq.type_order#" value="#selSwDistReq.type_order#" size="3">
                    (Order)&nbsp; </p>
                  <p>&nbsp;</p>
                </cfoutput>
              </cfif>
            </cfloop>
            </div>
            <input type="hidden" id="preid" value="<cfoutput>#preStartID#</cfoutput>">
            <br />
            <label>Post-Requisite Package(s)</label>
            <h3><a href="#" onClick="addFormField('postSWPKG','postid','divTxtPost'); return false;"><img src="/admin/images/pkg_add.png" />Add</a></h3>
            <input type="hidden" id="postid" value="0">
            <div id="divTxtPost">
                <cfloop query="selSwDistReq">
                  <cfif #selSwDistReq.type# EQ "1">
                    <cfoutput>
                      <p id="rowpostPatchPKG#selSwDistReq.type_order#" style="margin-top:4px;">
                        <img onClick='removeFormField("##rowpostPatchPKG#selSwDistReq.type_order#"); return false;' src="/admin/images/cancel.png" style="vertical-align:middle;" height="14" width="14"> <img src='/admin/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick="showSoftwareList('postPatchPKG:#selSwDistCri.type_order#');">
                        <input type='hidden' size='20' name="postPatchPKG_#selSwDistReq.type_order#" id="postPatchPKG#selSwDistReq.type_order#" value="#selSwDistReq.suuid_ref#">
                        <input type='text' size='50' name="pNamepostPatch:#selSwDistReq.type_order#" id="pNamepostPatch:#selSwDistReq.type_order#" value="#getPatchInfo(selSwDistReq.suuid_ref)#">
                        &nbsp;
                        <input type="text" name="postPatchPKGOrder_#selSwDistReq.type_order#" value="#selSwDistReq.type_order#" size="3">
                        (Order)&nbsp; </p>
                      <p>&nbsp;</p>
                    </cfoutput>
                  </cfif>
                </cfloop>
            </div>
          </div>
        </div>
        <!--- End wiz-content --->
        <div class="wiz-nav">
          <input class="back btn" id="back" type="button" value="< Back" />
		<cfif session.IsAdmin IS true>	
          <input class="btn" id="next" type="submit" value="Save" />
		</cfif>
        </div>
      </div>
      <!--- End wizard-4 --->
    </div>
  </div>
</cfform>
<div id="dialogSW" title="Select Software - Click Select and Close Dialog" style="text-align:left;" class="ui-dialog-titlebar"></div>
<div id="dialogPT" title="Select Patch - Click Select and Close Dialog" style="text-align:left;" class="ui-dialog-titlebar"></div>
</body>
</html>