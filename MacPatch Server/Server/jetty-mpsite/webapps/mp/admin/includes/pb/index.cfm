<cfset isReq="Yes">
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Demo</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
	<script type="text/javascript">
        $().ready(function() {
            $('.wiz-container').smartWizard();
        }); 
    </script>
    
    <!--- Picker --->
    <SCRIPT LANGUAGE="JavaScript">
		function showList(frmEleName) {
		  sList = window.open("patch_picker.cfm?INName="+frmEleName, "list", "width=400,height=500");
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
		
			//var rmRef = "<a href='#' onClick='removeFormField(\"#row" + id + "\"); return false;'><img src='./_assets/images/cancel.png' style='vertical-align:middle;' height='14' width='14'></a>";
			var rmRef = "<a href='#' onClick='removeFormField(\"#row" + frmFieldName + id +"\"); return false;'><img src='./_assets/images/cancel.png' style='vertical-align:middle;' height='14' width='14'></a>";
			$("#"+divid).append("<p id='row" + frmFieldName + id +"'>"+rmRef+"&nbsp;<input type='text' size='50' name='pName:"+id+"' id='pName:"+id+"' onClick=\"showList('"+frmFieldName+":"+id+"')\;\"><input type='hidden' size='20' name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"'>&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4'>(Order)&nbsp;<p>");
			//<p id='row" + id + "'>
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
		
			//var rmRef = "<a href='#' onClick='removeFormField(\"#row" + id + "\"); return false;'><img src='./_assets/images/cancel.png' style='vertical-align:middle;' height='14' width='14'></a>";
			var rmRef = "<a href='#' onClick='removeFormField(\"#row" + frmFieldName + id +"\"); return false;'><img src='./_assets/images/cancel.png' style='vertical-align:top;margin-top:2;' height='14' width='14'></a>";
			var sel = "<select name='type_"+ id + "' id='"+frmFieldName + id +"' size='1' style='vertical-align:top\;'><option>BundleID</option><option>File</option><option>Script</option></select>";
			$("#"+divid).append("<p id='row" + frmFieldName + id +"'>&nbsp;"+sel+"&nbsp;<textarea name='" + frmFieldName + "_" + id + "' id='"+frmFieldName + id +"' cols=\"60\" />&nbsp;<input type='text' name='"+frmFieldName+"Order_"+id+"' value='"+id+"' size='4' style='vertical-align:top\;'><span style='vertical-align:top\;'>(Order)</span>&nbsp;"+rmRef+"</p>");
			//<p id='row" + id + "'>
		}
    
		function removeFormField(id) {
			$(id).remove();
			//document.getElementById(id).remove();
		}
    </script>
    
</head>

<body onUnload="remLink()">
<cfform name="stepIt" method="post" action="post.cfm" enctype="multipart/form-data">

<div id="smartwizard" class="wiz-container">
		<ul id="wizard-anchor">
			<li><a href="#wizard-1"><h2>Step 1</h2>
          <small>Patch Information</small></a></li>
			<li><a href="#wizard-2"><h2>Step 2</h2>
          <small>Patch Criteria</small></a></li>
			<li><a href="#wizard-3"><h2>Step 3</h2>
          <small>Patch Package</small></a></li>
			<li><a href="#wizard-4"><h2>Step 4</h2>
          <small>Additional Patches &amp; Save</small></a></li>
		</ul>
		<div id="wizard-body" class="wiz-body">
  			<div id="wizard-1" >
  			   <div class="wiz-content">
                <h2>Patch Information</h2>
                <p>
                <div id="container">
                    <div id="row">
                        <div id="left">
                            Patch Name
                        </div>
                        <div id="center">
                            <cfinput type="text" name="patch_name" SIZE="50" required="#isReq#" message="Error [patch name]: A patch name is required.">
                        </div> 
                        <div id="right">
                        	(e.g. "FireFox") 
                        </div> 
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Version
                        </div>
                        <div id="center">
                            <cfinput type="text" name="patch_ver" SIZE="50" required="#isReq#" message="Error [patch version]: A patch version is required.">
                        </div>
                        <div id="right">
                        	(e.g. "3.5.4") 
                        </div> 
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Description
                        </div>
                        <div id="center">
                            <cftextarea name="description" cols="48" rows="9"></cftextarea>
                        </div>
                        <div id="right">&nbsp;</div>  
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Info URL 
                        </div>
                        <div id="center">
                            <cfinput type="text" name="description_url" SIZE="50">
                        </div>
                        <div id="right">&nbsp;</div> 
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch Severity
                        </div>
                        <div id="center">
                            <cfselect name="patch_severity" size="1" required="yes">
                                <option>High</option>
                                <option>Medium</option>
                                <option>Low</option>
                                <option>Unknown</option>
                            </cfselect>
                        </div>    
                        <div id="right">&nbsp;</div>  
                    </div>
                    <div id="row">
                        <div id="left">
                            Patch State
                        </div>
                        <div id="center">
                            <cfselect name="patch_state" size="1">
                                <option>Create</option>
                                <option>QA</option>
                                <option>Production</option>
                            </cfselect>
                        </div>  
                        <div id="right">&nbsp;</div>    
                    </div>
                    <div id="row">
                        <div id="left">
                            CVE ID
                        </div>
                        <div id="center">
                            <cfinput type="text" name="cve_id" SIZE="50">
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
                <h2>Patch Criteria</h2>	
                <p>
                	<div id="container">
                       <div id="row">
                            <div id="left">
                                OS Type
                            </div>
                            <div id="center">
                                <cfselect name="req_os_type" size="1">
                                    <option>Mac OS X</option>
                                    <option>Mac OS X Server</option>
                                    <option selected>Mac OS X, Mac OS X Server</option>
                                </cfselect>
                            </div>
                            <div id="right">
                                (e.g. "Mac OS X, Mac OS X Server") 
                            </div>  
                        </div>
                        <div id="row">
                            <div id="left">
                                OS Version
                            </div>
                            <div id="center">
                                <cfinput type="text" name="req_os_ver" SIZE="50" required="#isReq#" message="Error [Required OS Version]: A OS version is required." value="*">
                            </div>
                            <div id="right">
                                (e.g. "10.4.*,10.5.*") 
                        	</div> 
                    	</div>
                    </div>   
					<p><a href="#" onClick="addFormCriteriaField('reqPatchCriteria','reqid','divTxtReq'); return false;">Add Criteria</a></p>
                    <input type="hidden" id="reqid" value="0">
                    <div id="divTxtReq"></div>
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
                            <div id="left">
                                PreInstall Script
                            </div>
                            <div id="center">
                                <textarea name="pkg_preinstall" cols="60" rows="8"></textarea>
                            </div>
                            <div id="right">
                                Note: The return code of "0" is True.
                            </div>  
                    	</div>
                        <div id="row">
                            <div id="left">
                                PostInstall Script
                            </div>
                            <div id="center">
                                <textarea name="pkg_postinstall" cols="60" rows="8"></textarea>
                            </div>
                            <div id="right">
                                Note: The return code of "0" is True.
                            </div>   
                        </div>
                        <!---
                        <div id="row">
                            <div id="left">
                                Patch Package Name
                            </div>
                            <div id="center">
                                <cfinput type="text" name="pkg_name" SIZE="50" required="#isReq#" message="Error [Patch PKG Name]: A patch package name is required.">
                            </div>
                            <div id="right">
                                (e.g. "FireFox 3.5.4 for Mac OS X")
                            </div>  
                    	</div>
						--->
                        <div id="row">
                            <div id="left">
                                Patch Package
                            </div>
                            <div id="center">
                                <cfinput type="file" name="mainPatchFile" required="#isReq#" message="Error [Patch File]: A patch package name is required.">
                            </div>
                            <div id="right">(Note: The file must be a zipped pkg or mpkg)</div>  
                    	</div>
                        <div id="row">
                            <div id="left">
                                Patch Requires Reboot
                            </div>
                            <div id="center">
                                <cfselect name="patch_reboot" size="1">
                                    <option>Yes</option>
                                    <option selected>No</option>
                                </cfselect>
                            </div>  
                            <div id="right">&nbsp;</div>    
                        </div>
                    </div>
                </p>   
            </div>           
            <div class="wiz-nav">
              <input class="back btn" id="back" type="button" value="< Back" />
              <input class="next btn" id="next" type="button" value="Next >" />            </div>             
        </div>
		<div id="wizard-4">
            <div class="wiz-content">
                <h2>Additional Patches &amp; Finish</h2>	
                
                <label>Pre-Requisit Package(s)</label>
                <p><a href="#" onClick="addFormField('prePatchPKG','preid','divTxtPre'); return false;">Add</a></p>
                <input type="hidden" id="preid" value="0">
                <div id="divTxtPre"></div>
                <br />
                <label>Post-Requisit Package(s)</label>
                <p><a href="#" onClick="addFormField('postPatchPKG','postid','divTxtPost'); return false;">Add</a></p>
                <input type="hidden" id="postid" value="0">
                <div id="divTxtPost"></div>
                </div>            
                    <div class="wiz-nav">
                      <input type="hidden" name="active" value="0" SIZE="50">
                      
                      <input class="back btn" id="back" type="button" value="< Back" />
                      <input class="btn" id="next" type="submit" value="Save" />
                    </div>             
                </div>
            </div>
		</div>	  
</cfform>        
</body>
</html>