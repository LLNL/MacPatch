<cfheader name="expires" value="#now()#">
<cfheader name="pragma" value="no-cache">
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate">

<cfset isReq="Yes">
<cfset hasOSArch="true">

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
<!--- Validate that we have our params --->
<cfif NOT IsDefined("swTaskID")>
	<h2>Error: invalid request. Params missing.</h2>
	<cfabort>
</cfif>
<!--- Get the Record we need to update --->
<cftry>
	<cfquery name="selSwTask" datasource="#session.dbsource#" maxrows="1">
	    select *
	    From mp_software_task
	    Where tuuid = '#swTaskID#'
	</cfquery>
	<cfif selSwTask.RecordCount NEQ 1>
		<h2>Error: invalid request. Content does not exist.</h2>
		<cfabort>
	</cfif>
	<cfcatch type="any">
		<h2>Error: invalid request. Content does not exist.</h2>
		<cfabort>
	</cfcatch>
</cftry>

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
<div></div>
<cfform name="stepIt" method="post" action="#IIF(session.IsAdmin,DE("./includes/sw_dist/sw_task_update.cfm"),DE(""))#" enctype="multipart/form-data">
	<cfinput type="hidden" name="tuuid" value="#swTaskID#">
	<div id="smartwizard" class="wiz-container">
		<ul id="wizard-anchor">
			<li><a href="#wizard-1">
					<h2>
						New Software Task
					</h2>
				</a></li>
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
							<div id="left">Name</div>
							<div id="center">
								<cfinput type="text" name="name" SIZE="50" required="#isReq#" message="Error [software name]: Name is required." value="#selSwTask.name#" />
							</div>
							<div id="right">(e.g. "FireFox")</div>
						</div>
						<div id="row">
							<div id="left">Primary Software Package</div>
							<div id="center">
								<cfquery name="selSwInfo" datasource="#session.dbsource#" maxrows="1">
								    select sName, sVersion
								    From mp_software
								    Where suuid = '#selSwTask.primary_suuid#'
								</cfquery>
								<cfinput type="hidden" name="primary_suuid" id='suuid' SIZE="50" required="#isReq#" message="Error, software package is required." value="#selSwTask.primary_suuid#" />
								<input type='text' size='50' name='pName' id='pName' disabled value="<cfoutput>#selSwInfo.sName# v#selSwInfo.sVersion#</cfoutput>">
								<img src='./_assets/images/info.png' style='vertical-align:middle;' height='14' width='14' onClick="showSWDistList('suuid:pName');">
							</div>
							<div id="right"></div>
						</div>
						<div id="row">
							<div id="left">Task Type</div>
							<div id="center">
								<cfselect name="sw_task_type" size="1">
									<cfoutput>
									<option value="o" #IIf(selSwTask.sw_task_type is "o", DE("Selected"), DE(""))#>Optional</option>
									<option value="om" #IIf(selSwTask.sw_task_type is "om", DE("Selected"), DE(""))#>Optional - Mandatory</option>
									<option value="m" #IIf(selSwTask.sw_task_type is "m", DE("Selected"), DE(""))#>Mandatory</option>
									</cfoutput>
								</cfselect>
							</div>
							<div id="right">&nbsp;</div>
						</div>
						<div id="row">
							<div id="left">Start Date & Time</div>
							<div id="center">
								<cfinput type="text" name="sw_start_datetime" SIZE="50" id="datepicker_start" required="#isReq#" message="Error: Start Date & Time is required." value="#TSToDateTime(selSwTask.sw_start_datetime)#" />
							</div>
							<div id="right"></div>
						</div>
						<div id="row">
							<div id="left">End Date & Time</div>
							<div id="center">
								<cfinput type="text" name="sw_end_datetime" SIZE="50" id="datepicker_end" required="#isReq#" message="Error: End Date & Time is required." value="#TSToDateTime(selSwTask.sw_end_datetime)#" />
							</div>
							<div id="right"></div>
						</div>
						<div id="row">
							<div id="left">Active</div>
							<div id="center">
								<cfselect name="active" size="1">
									<cfoutput>
									<option value="1" #IIf(selSwTask.active is "1", DE("Selected"), DE(""))#>Enabled</option>
									<option value="0" #IIf(selSwTask.active is "0", DE("Selected"), DE(""))#>Disabled</option>
									</cfoutput>
								</cfselect>
							</div>
							<div id="right">&nbsp;</div>
						</div>
					</div>
					<!--- End container --->
				</div>
				<!--- End wiz-content --->
				<cfif session.IsAdmin IS true>
				<div class="wiz-nav"><input class="btn" id="next" type="submit" value="Save" /></div>
				</cfif>
			</div>
			<!--- End wizard-1 --->
		</div>
		<!--- End wizard-body --->
	</div>
</cfform>

<cffunction name="TSToDateTime" access="public" returntype="string" output="false">
	<cfargument name="Date" type="string" required="true"/>

	<cfset var x = "">
	<cfset x = #DateFormat(arguments.Date, "yyyy-mm-dd")# & " " & #TimeFormat(arguments.Date, "hh:mm:ss")# />

	<cfreturn #x#>
</cffunction>
