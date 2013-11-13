<cfsetting enablecfoutputonly="true">
<cfprocessingdirective SUPPRESSWHITESPACE="true">
<!--- POST BASED PROCESSING --->
<cfif #CGI.REQUEST_METHOD# EQ "POST"> 
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