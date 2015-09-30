<cfsilent>
	<cfparam name="args.action" type="string" default="" />

	<!--- stick everything in form and url into a struct for easy reference --->
	<cfset args = StructNew() />

	<cfloop collection="#url#" item="urlKey">
	  <cfset args[urlKey] = url[urlKey] />
	</cfloop>

	<cfloop collection="#form#" item="formKey">
	  <cfset args[formKey] = form[formKey] />
	</cfloop>

	<cfswitch expression="#args.action#">
		<cfcase value="runScheduledTask,2">
			<cftry>
				<cfschedule action="run" task="#args.task#" />
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_server_jobs.cfm" addtoken="false" />
				</cfcatch>
			</cftry>

			<cfset session.message.text = "The scheduled task was run successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/inc/admin_server_jobs.cfm" addtoken="false" />
		</cfcase>
		<cfcase value="addScheduledTask,0">
			<cftry>
				<cfif ISDefined("args.actionVarName")>
					<cfif ListLen(args.actionVarName,",") GT 1>
						<cfset xURL = ListGetAt(args.actionVarName,1) &"="& ListGetAt(args.actionVar,1)>
						<cfloop index="x" from="2" to="#ListLen(args.actionVarName,",")#">
							<cfset xURL = "#xURL#&#ListGetAt(args.actionVarName,x)#=#ListGetAt(args.actionVar,x)#">
						</cfloop>
					<cfelseif ListLen(args.actionVarName,",") EQ 1>
						<cfset xURL = ListGetAt(args.actionVarName,1) &"="& ListGetAt(args.actionVar,1)>
					<cfelse>
						<cfset xURL = "">
					</cfif>

					<cfset theURL = "#args.URL#?#xURL#">
				<cfelse>
					<cfset theURL = "#args.URL#">
				</cfif>
				<cfschedule action="UPDATE"
							task="#args.TASKNAME#?#form.actionVarName#=#form.actionVar#"
							URL="#args.URL#"
							interval="#args.TASKTYPE#"
							StartDate="#DateFormat(args.TASKSTARTDATETIME,"mm/dd/yyyy")#"
							StartTime="#TimeFormat(args.STARTTIME_RECURRING)#"
							ENDDATE="#DateFormat(args.TASKENDDATETIME,"mm/dd/yyyy")#"
							ENDTIME="#TimeFormat(args.STARTTIME_RECURRING)#"
							publish="NO"
							path=""
							file=""
							REQUESTTIMEOUT="1200"
							operation="HTTPRequest">
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_server_jobs.cfm" addtoken="false" />
				</cfcatch>
			</cftry>

			<cfset session.message.text = "The scheduled task was run successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/inc/admin_server_jobs.cfm" addtoken="false" />
		</cfcase>
		<cfcase value="removeScheduledTask,1">
			<cftry>
				<cfschedule action="DELETE" task="#args.task#" result="taskdataRM"/>
				<cfcatch type="any">
					<cfset session.message.text = CFCATCH.Message />
					<cfset session.message.type = "error" />
					<cflocation url="#session.cflocFix#/admin/inc/admin_server_jobs.cfm" addtoken="false" />
				</cfcatch>
			</cftry>
			<cfset session.message.text = "The scheduled task was deleted successfully." />
			<cfset session.message.type = "info" />
			<cflocation url="#session.cflocFix#/admin/inc/admin_server_jobs.cfm" addtoken="false" />
		</cfcase>
	</cfswitch>
</cfsilent>
