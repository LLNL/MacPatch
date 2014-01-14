<cfparam name="mpDBSource" default="mpds">
<cfparam name="logFile" default="MPWS_JSON">
<cfparam name="wsURL" default="https://#server.mp.settings.proxyserver.primaryServer#:#server.mp.settings.proxyserver.primaryServerPort#/Services/index.cfm">
<cfsetting enablecfoutputonly="true">
<cfprocessingdirective SUPPRESSWHITESPACE="true">
<!--- POST BASED PROCESSING --->
<cfif #CGI.REQUEST_METHOD# EQ "POST">  
	<cfif isDefined("form")>
		<cfif NOT isDefined("form.method")><cfabort></cfif>
		<cfswitch expression="#Trim(form.method)#"> 
		<cfcase value="client_checkin_base">
			<cftry>
            	<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
                    <cfhttpparam type="header" name="charset" value="utf-8">
                    <cfhttpparam type="formfield" name="method" value="client_checkin_base">
                    <cfhttpparam type="formfield" name="data" value="#form.data#">
                    <cfhttpparam type="formfield" name="type" value="#form.type#">
                </cfhttp>

                <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
                    <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [client_checkin_base][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
                    <cfabort>
                </cfif>
		        <cfoutput>#cfhttp.fileContent#</cfoutput>
		        <cfabort>
				<cfcatch>
					<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [client_checkin_base][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
					<cfabort>
				</cfcatch>
			</cftry>
		</cfcase> 
		<cfcase value="client_checkin_plist"> 
			<cftry>    
				<cfhttp url="#wsURL#" method="POST" resolveurl="NO">
		            <cfhttpparam type="header" name="charset" value="utf-8">
		            <cfhttpparam type="formfield" name="method" value="client_checkin_plist">
		            <cfhttpparam type="formfield" name="data" value="#form.data#">
		            <cfhttpparam type="formfield" name="type" value="#form.type#">
	            </cfhttp>
                
                <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
                    <cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [client_checkin_plist][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
                    <cfabort>
                </cfif>
		        <cfoutput>#cfhttp.fileContent#</cfoutput>
				<cfabort>
				<cfcatch>
					<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [client_checkin_plist][#CGI.REMOTE_HOST#]: #cfcatch.message# #cfcatch.detail#">
					<cfabort>
				</cfcatch>
			</cftry>
		</cfcase> 
		    <cfcase value="client_checkin_vers"> 
		        <!--- Not Done Yet, not sure I will do it --->
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
