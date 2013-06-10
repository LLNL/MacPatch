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

/* css for timepicker */
.ui-timepicker-div .ui-widget-header { margin-bottom: 8px; }
.ui-timepicker-div dl { text-align: left; }
.ui-timepicker-div dl dt { height: 25px; margin-bottom: -25px; }
.ui-timepicker-div dl dd { margin: 0 10px 10px 65px; }
.ui-timepicker-div td { font-size: 90%; }
.ui-tpicker-grid-label { background: none; border: none; margin: 0; padding: 0; }

/* Override width of left column in wizard */
#left {
	width: 200px;
}

</style>
<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/ui/jquery.ui.datepicker.js"></script>
<script type="text/javascript" src="/admin/_assets/js/jquery_1.8.18/addons/jquery-ui-timepicker-addon.js"></script>
<script>
	$(function() {
		$( "#datepicker_start" ).datetimepicker({
			dateFormat:	'yy-mm-dd',
			timeFormat: 'hh:mm:00',
			separator: ' '
		});
		$( "#datepicker_end" ).datetimepicker({
			dateFormat:	'yy-mm-dd',
			timeFormat: 'hh:mm:00',
			separator: ' '
		});
	});
</script>

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
    function showSWDistList(frmEleName) {
      sList = window.open("includes/sw_dist/sw_dist_picker.cfm?INName="+frmEleName, "list", "width=500,height=500");
    }
    function remLink() {
      if (window.sList && window.sList.open && !window.sList.closed)
        window.sList.opener = null;
    }
</SCRIPT>

<cfform name="stepIt" method="post" action="./includes/sw_dist/post_sw_task.cfm" enctype="multipart/form-data">
  <div id="smartwizard" class="wiz-container">
    <ul id="wizard-anchor">
      <li>
      <a href="#wizard-1">
        <h2>New Software Task</h2>
      </a>
      </li>
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
                <cfinput type="text" name="name" SIZE="50" required="#isReq#" message="Error [software name]: Name is required.">
              </div>
              <div id="right"> (e.g. "FireFox") </div>
            </div>
            <div id="row">
              <div id="left"> Primary Software Package </div>
              <div id="center">
                <cfinput type="hidden" name="primary_suuid" id='suuid' SIZE="50" required="#isReq#" message="Error, software package is required.">
				<input type='text' size='50' name='pName' id='pName' disabled>
				<img src='./_assets/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick="showSWDistList('suuid:pName');">
              </div>
              <div id="right"></div>
            </div>
            <div id="row">
              <div id="left"> Task Type </div>
              <div id="center">
                <cfselect name="sw_task_type" size="1">
                <option value="o" selected>Optional</option>
                <option value="om">Optional - Mandatory</option>
                <option value="m">Mandatory</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
			<div id="row">
              <div id="left"> Start Date & Time </div>
              <div id="center">
                <cfinput type="text" name="sw_start_datetime" SIZE="50" id="datepicker_start" required="#isReq#" message="Error [software name]: Name is required.">
              </div>
              <div id="right"></div>
            </div>
			<div id="row">
              <div id="left"> End Date & Time </div>
              <div id="center">
                <cfinput type="text" name="sw_end_datetime" SIZE="50" id="datepicker_end" required="#isReq#" message="Error [software name]: Name is required.">
              </div>
              <div id="right"></div>
            </div>
            <div id="row">
              <div id="left"> Active </div>
              <div id="center">
                <cfselect name="active" size="1">
                <option value="1">Enabled</option>
                <option value="0" selected>Disabled</option>
                </cfselect>
              </div>
              <div id="right">&nbsp;</div>
            </div>
          </div>
          <!--- End container --->
        </div>
        <!--- End wiz-content --->
        <div class="wiz-nav">
          <input class="btn" id="next" type="submit" value="Save" />
        </div>
      </div>
      <!--- End wizard-1 --->
    </div>
    <!--- End wizard-body --->
  </div>
</cfform>
