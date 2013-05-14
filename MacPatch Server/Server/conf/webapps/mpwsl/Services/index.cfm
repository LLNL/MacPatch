<cfsetting enablecfoutputonly="true">
<cfprocessingdirective SUPPRESSWHITESPACE="true">
<!--- <cferror type="exception" template="errors.cfm"> --->
<!--- POST BASED PROCESSING --->
<cfif #CGI.REQUEST_METHOD# EQ "POST">
<!---
	<cfif #CGI.HTTP_USER_AGENT# EQ "MacPatchAgent">
		<cfif isDefined("form")>
			<cfdump var="#form#">
			<cfdump var="#form.data#">
			<cfset x = Deserializejson(form.data)>
			<cfset xCols = x['COLUMNS']>
			<cfset xData = x['DATA']>
			<!--- --->
			<cfloop array="#x['DATA']#" index="iArr">
				<cfif ArrayLen(iArr) EQ ArrayLen(xCols)>
					<cfset l_row = #genRow(xCols,iArr)#>
					<cfset _rres = colExists('cuuid',l_row.cuuid,'mp_clients')>
					<cfif _rres.error NEQ "0"><cfdump var="#_rres#"><cfabort></cfif>
					<cfif _rres.qresult.RecordCount GTE 1>
						<!--- Update --->
						<cfset _ures = rowUpdate(xCols,iArr,'rid',_rres.qresult.rid,'mp_clients')>
						<cfdump var="#_ures#">
					<cfelse>
						<!--- Insert --->
						<cfset _ires = rowInsert(xCols,iArr,'mp_clients')>
						<cfdump var="#_ires#">
					</cfif>
				</cfif>
			</cfloop>
			<hr>
			<cfdump var="#x#">
		</cfif>
	<cfabort>
	</cfif>
	--->   
	<cfif isDefined("form")>
		<cfif NOT isDefined("form.method")><cfabort></cfif>
		<cfswitch expression="#Trim(form.method)#"> 
		    <cfcase value="client_checkin_base">
				 <cfset aObj = CreateObject( "component", "cfc.client_checkin" ) />
		         <cfset res = aObj._base(form.data, form.type) />
		         <cfset jData = SerializeJson(res)>
		         <cfset y = aObj.elog("#jData#")>
		         <cfoutput>#jData#</cfoutput>
		         <cfabort>
		    </cfcase> 
		    <cfcase value="client_checkin_plist"> 
		        <cfset aObj = CreateObject( "component", "cfc.client_checkin" ) />
				<cfset res = aObj._plist(form.data, form.type) />
				<cfset jData = SerializeJson(res)>
				<cfset y = aObj.elog("#jData#")>
				<cfoutput>#jData#</cfoutput>
				<cfabort>
		    </cfcase> 
		    <cfcase value="client_checkin_vers"> 
		        
		    </cfcase> 
		    <cfcase value="mp_patch_loader"> 
				<cfset aObj = CreateObject( "component", "cfc.patch_loader" ) />
				<cfset res = aObj._apple(form.data, form.type) />
				<cfset jData = SerializeJson(res)>
				<cfset y = aObj.elog("#jData#")>
				<cfoutput>#jData#</cfoutput>
				<cfabort>
		    </cfcase> 
		    <cfdefaultcase> 
		       <!--- Should not get here --->
		       <cfset y = elog("Not a valid method, "&form.method)>
		       <cfabort>
		    </cfdefaultcase> 
		</cfswitch> 
	</cfif>
<cfelse>
	<cfif IsDefined("Test")>
	<cfoutput>Works.</cfoutput>
	</cfif>	
</cfif>
</cfprocessingdirective>