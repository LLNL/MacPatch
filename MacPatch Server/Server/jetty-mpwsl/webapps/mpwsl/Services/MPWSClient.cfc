<!--- **************************************************************************************** --->
<!---
		MPWSControllerCocoa - JSON Based Web Services
	 	Database type is MySQL
		MacPatch Version 2.1.0
		Version 1.0
		Rev: 1
		Last Modified:	3/20/2012
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">
	<cfset this.cacheDirName = "cacheIt">

	<cffunction name="init" returntype="MPWSControllerCocoa" output="no">
		<cfreturn this>
	</cffunction>

    <!--- Used to make xml look pretty --->
    <cfsavecontent variable="myXSLT">
   		<?xml version="1.0" encoding="UTF-8"?>
    	<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
		<xsl:output method="xml" indent="yes" />
		<xsl:strip-space elements="*" />
		<xsl:template match="/">
			<xsl:copy-of select="." />
		</xsl:template>
		</xsl:transform>
	</cfsavecontent>

    <!--- Logging function, replaces need for ws_logger (Same Code) --->
    <cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">

        <cfscript>
			try {
				inet = CreateObject("java", "java.net.InetAddress");
				inet = inet.getLocalHost();
			} catch (any e) {
				inet = "localhost";
			}
		</cfscript>

    	<cfquery datasource="#this.ds#" name="qGet">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, <cfqueryparam value="#aEventType#">, <cfqueryparam value="#aEvent#">, <cfqueryparam value="#CGI.REMOTE_HOST#">, <cfqueryparam value="#CGI.SCRIPT_NAME#">, <cfqueryparam value="#CGI.PATH_TRANSLATED#">,<cfqueryparam value="#CGI.SERVER_NAME#">,<cfqueryparam value="#CGI.SERVER_SOFTWARE#">, <cfqueryparam value="#inet#">)
        </cfquery>
    </cffunction>

<!--- ********************************************************************* --->
<!---  Methods																--->
<!--- ********************************************************************* ---> 
	<!--- Helper --->
	<cffunction name="getGroupID" access="private" returntype="any" output="no">
		<cfargument name="groupName" required="true" />

		<cfquery datasource="#this.ds#" name="qGet" maxrows="1">
			Select * from mp_software_groups
			Where gName = <cfqueryparam value="#arguments.groupName#">
		</cfquery>
		<cfif qGet.RecordCount EQ 1>
			<cfreturn qGet.gid>
		<cfelse>
			<cfreturn "NA">
		</cfif>
	</cffunction>
    
<!--- ********************************************************************* --->
<!--- Start --- Client Methods - for MacPatch 2.1.0							--->
<!--- ********************************************************************* ---> 

<!--- #################################################### --->
<!--- Test			 									   --->
<!--- #################################################### --->
	<cffunction name="WSLTest" access="remote" returnType="struct" returnFormat="json" output="false">
    
    	<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = #CreateODBCDateTime(now())# />
		
        <cfreturn response>
    </cffunction>

<!--- #################################################### --->
<!--- ProcessXML                                           --->
<!--- #################################################### --->
    <cffunction name="PostDataMgrXML" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID">
		<cfargument name="encodedXML">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

        <!--- Clean a bit of the XML char before parsing --->
        <cfset var theXML = ToString(ToBinary(Trim(arguments.encodedXML)))>

        <cftry>
			<cfset jvmObj = CreateObject("java","java.lang.System").getProperties() />
			<!--- Figureout if Jetty Or Tomcat --->
			<cfif IsDefined("jvmObj.catalina.base")>
				<cfset _InvData = #jvmObj.catalina.base# & "/InvData">
			<cfelseif IsDefined("jvmObj.jetty.home")>
				<cfset _InvData = #jvmObj.jetty.home# & "/InvData">
			</cfif>
			<!--- Create Nessasary Dirs --->
            <cfif DirectoryExists(_InvData) EQ False>
                <cfset tmpD = DirectoryCreate(_InvData)>
            </cfif>

            <cfset _InvFiles = #_InvData# &"/Files">
            <cfif DirectoryExists(_InvFiles) EQ False>
                <cfset tmpD = DirectoryCreate(_InvFiles)>
            </cfif>

            <cfset dirF = #_InvFiles# & "/mpi_" & #CreateUuid()# & ".txt">
            <cffile action="write" NAMECONFLICT="makeunique" file="#dirF#" output="#theXML#">

            <cfcatch type="any">
				<cfinvoke component="ws_logger" method="LogEvent">
              		<cfinvokeargument name="aEventType" value="Error">
              		<cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
              		<cfinvokeargument name="aEvent" value="[PostDataMgrXML][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
          		</cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[PostDataMgrXML][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
        </cftry>
		
		<cfreturn response>
    </cffunction>

<!--- #################################################### --->
<!--- MPHostsListVersionIsCurrent	 		 			   --->
<!--- #################################################### --->
	<cffunction name="MPHostsListVersionIsCurrent" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="ListID" required="false" default="0" />
		<cfargument name="Version" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "1" />
		
		<cfif arguments.clientID EQ 0 OR arguments.ListID EQ 0 OR arguments.Version EQ 0>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = "Bad or missing args.">
            <cfset l = logit("Error","[MPHostsListVersionIsCurrent]: Bad or missing args.")>
			<cfreturn #response#>
		</cfif>
		
		<cftry>
			<cfquery datasource="#this.ds#" name="qGetListVersion">
				SELECT
					version
				FROM 
					mp_server_list
				WHERE
					listid = <cfqueryparam value="#arguments.ListID#">
            </cfquery>
			
			<cfif qGetListVersion.RecordCount NEQ 1>
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "No List Found">
				<cfset response[ "result" ] = "0" />
				<cfreturn #response#>
			<cfelse>
				<cfif qGetListVersion.Version EQ arguments.Version>
					<cfset response[ "result" ] = "1" />
				<cfelseif qGetListVersion.Version GT arguments.Version>	
					<cfset response[ "result" ] = "0" />
				</cfif>
			</cfif>
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = cfcatch.Message>
            <cfset l = logit("Error","[MPHostsListVersionIsCurrent]: #cfcatch.Detail# -- #cfcatch.Message#")>
		</cfcatch>
		</cftry>

		<cfreturn #response#>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetMPHostsList		 		 					   --->
<!--- #################################################### --->
	<cffunction name="GetMPHostsList" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<cftry>
			<cfquery datasource="#this.ds#" name="qGetHosts">
				SELECT
					ms.*, msl.version, msl.name
				FROM
					mp_servers ms
				LEFT JOIN mp_server_list msl ON ms.listid = msl.listid
				WHERE
					ms.listid = <cfqueryparam value="1">
				AND ms.active = <cfqueryparam value="1">
				ORDER BY
					ms.isProxy, ms.isMaster ASC
            </cfquery>
			
			<cfset _Hosts = arrayNew(1)>

			<cfset _result = {} />
			<cfset _result[ "List" ] = "#qGetHosts.name#" />
			<cfset _result[ "ListID" ] = "#qGetHosts.listid#" />
			<cfset _result[ "Version" ] = "#qGetHosts.version#" />
			<cfset _result[ "Hosts" ] = {} />

			<cfoutput query="qGetHosts">
				<cfset _tmpHost = {} />
				<cfset _tmpHost[ "Host" ] = "#server#" />
				<cfset _tmpHost[ "Port" ] = "#port#" />
				<cfset _tmpHost[ "isMaster" ] = "#isMaster#" />
				<cfset _tmpHost[ "isProxy" ] = "#isProxy#" />
				<cfset _tmpHost[ "useSSL" ] = "#useSSL#" />
				<cfset _tmpHost[ "useSSLAuth" ] = "#useSSLAuth#" />
				<cfset a = ArrayAppend(_Hosts,_tmpHost)>
			</cfoutput>
			
			<cfset _result.Hosts = _Hosts />
			<cfset response.result = serializeJSON(_result)>
			
            <cfcatch>
                <cfset response.errorNo = "1">
                <cfset response.errorMsg = cfcatch.Message>
                <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
		</cftry>

		<cfreturn #response#>
	</cffunction>	
	
<!--- #################################################### --->
<!--- GetSWDistGroups		 		 					   --->
<!--- #################################################### --->
	<cffunction name="GetSWDistGroups" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<cftry>
			<cfquery datasource="#this.ds#" name="qGetHosts">
				SELECT *
				FROM
					mp_software_groups
				Where state = '1'	
            </cfquery>
			
			<cfset _Groups = arrayNew(1)>

			<cfoutput query="qGetHosts">
				<cfset _result = {} />
				<cfset _result[ "Name" ] = "#qGetHosts.gName#" />
				<cfset _result[ "Desc" ] = "#qGetHosts.gDescription#" />
				<cfset a = ArrayAppend(_Groups,_result)>
			</cfoutput>

			<cfset response.result = serializeJSON(_Groups)>
			
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = cfcatch.Message>
            <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
		</cfcatch>
		</cftry>

		<cfreturn #response#>
	</cffunction>		

<!--- #################################################### --->
<!--- GetScanList										   --->
<!--- Tested, YES		 		 						   --->
<!--- #################################################### --->
	<cffunction name="GetScanList" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no" default="0" type="string">
		<cfargument name="state" required="no" default="all" type="string">
        <cfargument name="active" required="no" default="1" type="string">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
		
		<cfset var jData = "">
        <cftry>
        	<cfset var myObj = CreateObject("component","gov.llnl.PatchScanManifest").init(this.ds)>
			<cfset jData = myObj.createScanListJSON(arguments.state,arguments.active)>
			<cfset response.result = DeserializeJSON(jData) />
            
	        <cfcatch type="any">
		        <cfset l = logit("Error","[GetScanList][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#")>
                <cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[GetScanList][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#" />
            </cfcatch>
        </cftry>
	
        <cfreturn response>
    </cffunction>

<!--- #################################################### --->
<!--- GetPatchGroupPatches						 		   --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatches" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="no" default="0" type="string">
        <cfargument name="PatchGroup" required="yes">
    	<cfargument name="DataType" required="no" default="JSON" type="string">
	
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
	
        <cftry>
        	<cfquery datasource="#this.ds#" name="qGetGroupID">
                Select id from mp_patch_group
                Where name = <cfqueryparam value="#arguments.PatchGroup#">
            </cfquery>
        	<cfif qGetGroupID.RecordCount NEQ 1>
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatches][qGetGroupID]: No group was found for #arguments.PatchGroup#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[GetPatchGroupPatches][qGetGroupID][#qGetGroupID.RecordCount#][#arguments.ClientID#][#arguments.PatchGroup#]: No group was found for #arguments.PatchGroup#" />
                <cfreturn response>
        	</cfif>
            <cfcatch>
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatches]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[GetPatchGroupPatches][qGetGroupID]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
            </cfcatch>
        </cftry>
        
        <cftry>
        	<cfquery datasource="#this.ds#" name="qGetGroupData">
                Select data from mp_patch_group_data
                Where pid = <cfqueryparam value="#qGetGroupID.id#">
				AND data_type = <cfqueryparam value="#arguments.DataType#">
            </cfquery>
            <cfif qGetGroupID.RecordCount NEQ 1>
            	<cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatches][qGetGroupData]: No group data was found for id #qGetGroupID.id#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[GetPatchGroupPatches][qGetGroupData]: No group data was found for id #qGetGroupID.id#" />
                <cfreturn response>
            </cfif>
			<cfset response.result  =  #qGetGroupData.data#> />
			
            <cfcatch>
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatches]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[GetPatchGroupPatches][qGetGroupData]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
            </cfcatch>
        </cftry>

        <cfreturn response>
	</cffunction>

<!--- #################################################### --->
<!--- GetClientPatchState 								   --->
<!--- This Needs to be updated to test againts client patch group --->
<!--- #################################################### --->
	<cffunction name="ClientPatchStatus" access="remote" returnType="struct" returnFormat="json" output="false">
        <cfargument name="clientID" required="no" default="0" type="string">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = {} />
        
        <cfset response.result["totalPatchesNeeded"] = "-1" />
		<cfset response.result["patches"] = "" />

        <cftry>
        	<!--- Get the Client's patch group ID --->
	    	<cfquery datasource="#this.ds#" name="qGetClientPatchGroup">
				select id from mp_patch_group
				Where name = (	select PatchGroup from mp_clients_view
	            				Where cuuid = <cfqueryparam value="#arguments.clientID#">)
	        </cfquery>
			<cfset var l_PatchGroupID = #qGetClientPatchGroup.id#>
	
    		<!--- Get the Clients patches which are in the patch group --->
	        <cfquery datasource="#this.ds#" name="qGetClientPatchState" result="res">
	            select * from client_patch_status_view
	            Where
	            	cuuid = <cfqueryparam value="#arguments.clientID#">
				AND patch_id in (
					select patch_id
					from mp_patch_group_patches
					where mp_patch_group_patches.patch_group_id = <cfqueryparam value="#l_PatchGroupID#"> )
	            Order By date Desc
	        </cfquery>
            
			<!--- Create the patches array --->            
            <cfset PatchesArr = arrayNew(1)>
			<cfoutput query="qGetClientPatchState">
                <cfset _patch = {} />
                <cfloop list="#qGetClientPatchState.ColumnList#" index="col">
                    <cfset _patch[ col ] = qGetClientPatchState[col][CurrentRow] />
                </cfloop>
                <cfset a = ArrayAppend(PatchesArr,_patch)>
            </cfoutput>
            
            <cfset response.result["totalPatchesNeeded"] = #ArrayLen(PatchesArr)# />
            <cfset response.result["patches"] = PatchesArr />
            
	        <cfcatch type="any">
	            <!--- the message to display --->
	            <cfinvoke component="ws_logger" method="LogEvent">
	                <cfinvokeargument name="aEventType" value="Error">
	                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
	                <cfinvokeargument name="aEvent" value="[ClientPatchStatus][qGetClientPatchState]: #cfcatch.Detail# -- #cfcatch.Message#">
	            </cfinvoke>
	            <cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[ClientPatchStatus]: #cfcatch.Detail# -- #cfcatch.Message#" />
                <cfreturn response>
	        </cfcatch>
        </cftry>
        
        <cfreturn response>
    </cffunction>

<!--- #################################################### --->
<!--- getAsusCatalogs	 		 						   --->
<!--- #################################################### --->
	<cffunction name="getAsusCatalogs" access="remote" returnType="struct" returnFormat="json" output="false" JSONCASE="upper">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="osminor" required="yes" type="string">
		<cfargument name="clientKey" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = {} />

		<cftry>
			<cfquery datasource="#this.ds#" name="qGetCatalogs">
                select catalog_url, proxy
                from mp_asus_catalogs
                Where os_minor = <cfqueryparam value="#arguments.osminor#">
                Order By c_order ASC
            </cfquery>
			
			<cfset _CatalogURLS = arrayNew(1)>
			<cfset _ProxyCatalogURLS = arrayNew(1)>
			
			<cfoutput query="qGetCatalogs">
				<cfif #proxy# EQ "0"><cfset ArrayAppend(_CatalogURLS, Trim(catalog_url))></cfif>
			</cfoutput>
			<cfoutput query="qGetCatalogs">
				<cfif #proxy# EQ "1"><cfset ArrayAppend(_ProxyCatalogURLS, Trim(catalog_url))></cfif>
			</cfoutput>

			<cfset catalogs = {} />
			<cfset catalogs[ "CatalogURLS" ] = {} />
			<cfset catalogs[ "ProxyCatalogURLS" ] = {} />

			<cfset catalogs = {} />
			<cfset catalogs[ "CatalogURLS" ] = "#_CatalogURLS#" />
			<cfset catalogs[ "ProxyCatalogURLS" ] = "#_ProxyCatalogURLS#" />
			
			<cfset result = catalogs />
			<cfset response.result = serializeJSON(result)>
			
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = cfcatch.Message>
            <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
		</cfcatch>
		</cftry>

		<cfreturn #response#>
	</cffunction>

<!--- #################################################### --->
<!--- GetLastCheckIn	 		 						   --->
<!--- #################################################### --->
	<cffunction name="getLastCheckIn" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<cfset _result = {} />
		<cfset _result[ "mdate" ] = "NA" />

		<cftry>
        	<cfquery datasource="#this.ds#" name="qGet">
                SELECT mdate
                FROM mp_clients_view
                WHERE cuuid = <cfqueryparam value="#arguments.clientID#">
            </cfquery>

            <cfset _result[ "mdate" ] = "#DateFormat(qGet.mdate, "mm/dd/yyyy")# #TimeFormat(qGet.mdate, "HH:mm:ss")#" />
			<cfset response.result = serializeJSON(_result)>

		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = cfcatch.Message>
            <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
		</cfcatch>
		</cftry>

		<cfreturn #response#>
	</cffunction>

<!--- #################################################### --->
<!--- AddClientSAVData	 		 						   --->
<!--- #################################################### --->
	<cffunction name="PostClientAVData" access="remote" returnType="struct" returnformat="json" output="false">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="avAgent" required="true">
		<cfargument name="jsonData" required="true">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = {} />

		<cfif Trim(arguments.avAgent) NEQ "SEP" AND Trim(arguments.avAgent) NEQ "SAV">
			<cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Warning">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[PostClientAVData]: Unknown avAgent config. Schema may be out of date.">
            </cfinvoke>
			<cfset response[ "errorNo" ] = "1" />
			<cfset response[ "errorMsg" ] = "[PostClientAVData]: Unknown avAgent #arguments.avAgent# config. Schema may be out of date." />
			<cfreturn response>
		</cfif>

        <cftry>
			<cfset var avData = DeserializeJSON(arguments.jsonData)>
         	<cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[PostClientAVData][Deserializejson]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "0" />
				<cfset response[ "errorMsg" ] = "[PostClientAVData][Deserializejson]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
        	</cfcatch>
        </cftry>
		
		<cftry>
			<cfparam name="l_CFBundleExecutable" default="NA" />
			<cfparam name="l_NSBundleResolvedPath" default="NA" />
			<cfparam name="l_CFBundleVersion" default="NA" />
			<cfparam name="l_CFBundleShortVersionString" default="NA" />
	        <cfparam name="l_LastFullScan" default="NA" />
			<cfparam name="l_DefsDate" default="NA" />
	
	        <cfif structkeyexists(avData,"CFBundleExecutable")>
				<cfset l_CFBundleExecutable = trim(avData.CFBundleExecutable)>
			</cfif>
	        <cfif structkeyexists(avData,"NSBundleResolvedPath")>
	        	<cfset l_NSBundleResolvedPath = trim(avData.NSBundleResolvedPath)>
	        </cfif>
	        <cfif structkeyexists(avData,"CFBundleVersion")>
	        	<cfset l_CFBundleVersion = trim(avData.CFBundleVersion)>
	        </cfif>
	        <cfif structkeyexists(avData,"CFBundleShortVersionString")>
	        	<cfset l_CFBundleShortVersionString = trim(avData.CFBundleShortVersionString)>
	        </cfif>
	        <cfif structkeyexists(avData,"DefsDate")>
	        	<cfset l_DefsDate = trim(avData.DefsDate)>
	        </cfif>
	
	        <!--- Client Data Does not Exist, if there remove it --->
	        <cfif l_CFBundleExecutable EQ "NA" AND l_CFBundleVersion EQ "NA">
	        	<cfquery datasource="#this.ds#" name="qGetClient">
	                Select cuuid From savav_info
	                Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
	            </cfquery>
	
	        	<cfif qGetClient.RecordCount GTE 1>
	                <cfquery datasource="#this.ds#" name="qRmClient">
	                    Delete From savav_info
	                    Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
	                </cfquery>
	        	</cfif>
	        	<cfreturn response>
	        </cfif>
		
			<cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[PostClientAVData]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "2" />
				<cfset response[ "errorMsg" ] = "[PostClientAVData]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
        	</cfcatch>
        </cftry>

        <!--- Query the table to see if we need a update or a insert --->
        <cfquery datasource="#this.ds#" name="qGet">
            Select * From savav_info
            Where cuuid = <cfqueryparam value="#trim(arguments.clientID)#">
        </cfquery>

        <cfif qGet.RecordCount EQ 0>
            <cftry>
            <cfquery datasource="#this.ds#" name="qPut">
                Insert Into savav_info
                    (cuuid,
					defsDate,
					savShortVersion,
					savBundleVersion,
					appPath,
					lastFullScan,
					savAppName,
					mdate
					)
                Values
                    (<cfqueryparam value="#arguments.clientID#">,
					<cfqueryparam value="#l_DefsDate#">,
					<cfqueryparam value="#l_CFBundleShortVersionString#">,
					<cfqueryparam value="#l_CFBundleVersion#">,
					<cfqueryparam value="#l_NSBundleResolvedPath#">,
					<cfqueryparam value="#l_LastFullScan#">,
					<cfqueryparam value="#l_CFBundleExecutable#">,
					#CreateODBCDateTime(now())#
                    )
            </cfquery>
            <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddClientSAVData][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[PostClientAVData][qPut]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
            </cftry>
        <cfelse>
            <cftry>
            <cfquery datasource="#this.ds#" name="qPut">
                UPDATE savav_info
                SET defsDate = 				<cfqueryparam value="#l_DefsDate#">,
                    savShortVersion = 		<cfqueryparam value="#l_CFBundleShortVersionString#">,
                    savBundleVersion =  	<cfqueryparam value="#l_CFBundleVersion#">,
                    appPath =  				<cfqueryparam value="#l_NSBundleResolvedPath#">,
                    lastFullScan =  		<cfqueryparam value="#l_LastFullScan#">,
                    savAppName = 			<cfqueryparam value="#l_CFBundleExecutable#">,
                    mdate = 			#CreateODBCDateTime(now())#
                Where cuuid = <cfqueryparam value="#l_CUUID#">
            </cfquery>
            <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddClientSAVData][Update]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
				<cfset response[ "errorNo" ] = "1" />
				<cfset response[ "errorMsg" ] = "[PostClientAVData][qPut]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#" />
                <cfreturn response>
            </cfcatch>
            </cftry>
        </cfif>

        <cfreturn response>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetSavAvDefsDate      	 		 				   --->
<!--- #################################################### --->	
	<cffunction name="GetAVDefsDate"  access="remote" returnType="struct" returnFormat="json" output="false">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="avAgent" required="true">
		<cfargument name="theArch" required="false" default="x86">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
		
		<cfif arguments.avAgent NEQ "SEP" AND arguments.avAgent NEQ "SAV">
			<cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Warning">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[GetAVDefsDate]: Unknown avAgent config. Schema may de out of date.">
            </cfinvoke>
			<cfset response[ "errorNo" ] = "1" />
			<cfset response[ "errorMsg" ] = "[GetAVDefsDate]: Unknown avAgent config. Schema may de out of date." />
			<cfreturn response>
		</cfif>
		
		<cftry>
            <cfquery datasource="#this.ds#" name="qGet">
	        	Select defdate from savav_defs
	            Where arch = <cfqueryparam value="#Trim(arguments.theArch)#">
	            AND current = 'YES'
	        </cfquery>
	        
	        <cfif qGet.RecordCount EQ 1>
		        <cfset response.result = "#qGet.defdate#">
	        <cfelse>
	        	<cfset response.result = "NA">
	        </cfif>

            <cfcatch type="any">
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = cfcatch.Message>
                <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
                
		<cfreturn response>
    </cffunction>
	
<!--- #################################################### --->
<!--- GetSavAvDefsFile      	 		 				   --->
<!--- #################################################### --->	
	<cffunction name="GetAVDefsFile" access="remote" returnType="struct" returnFormat="json" output="false">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="avAgent" required="true">
		<cfargument name="theArch" required="false" default="x86">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
		
		<cfif arguments.avAgent NEQ "SEP" AND arguments.avAgent NEQ "SAV">
			<cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Warning">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[GetAVDefsFile]: Unknown avAgent config. Schema may de out of date.">
            </cfinvoke>
			<cfset response[ "errorNo" ] = "1" />
			<cfset response[ "errorMsg" ] = "[GetAVDefsFile]: Unknown avAgent config. Schema may de out of date." />
			<cfreturn response>
		</cfif>
		
		<cftry>
            <cfquery datasource="#this.ds#" name="qGet">
	        	Select file from savav_defs
	            Where arch = <cfqueryparam value="#Trim(arguments.theArch)#">
	            AND current = 'YES'
	        </cfquery>
	        
	        <cfif qGet.RecordCount EQ 1>
		        <cfset response.result = "#qGet.defdate#">
	        <cfelse>
	        	<cfset response.result = "NA">
	        </cfif>

            <cfcatch type="any">
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = cfcatch.Message>
                <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
                
		<cfreturn response>
    </cffunction>	

<!--- #################################################### --->
<!--- AddSavAvDefs				 		 				   --->
<!--- #################################################### --->	
	<cffunction name="PostSavAVDefs" access="remote" returnType="struct" returnFormat="json" output="false">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="xml" required="true">
		<cfargument name="encoded" required="false" default="true">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<!--- Clean a bit of the XML char before parsing --->
		<cfset var theXML = "">
		<cfif arguments.encoded EQ true>
        	<cfset theXML = ToString(ToBinary(Trim(arguments.xml)))>
		<cfelse>
			<cfset theXML = ToString(arguments.xml)>
		</cfif>

		<!--- Parse the XML File--->
        <cftry>
			<cfset var xmldoc = XmlParse(theXML)>
         	<cfcatch type="any">
				<!--- the message to display --->
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddSavAvDefs][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "[AddSavAvDefs][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                <cfreturn response>
        	</cfcatch>
        </cftry>

		<cfset var XMLRoot = xmldoc.XmlRoot>
        <cfset var arrNodes1 = XmlSearch(xmldoc,"//sav/arch[ @type = 'ppc' ]/def") />
        <cfset var arrNodes2 = XmlSearch(xmldoc,"//sav/arch[ @type = 'x86' ]/def") />
        <cfset var vMdate = #CreateODBCDateTime(now())#>

		<!--- Check to make sure the XMLSearch has values before clearing the DB --->
		<cfif #ArrayLen(arrNodes1)# GTE 1 AND #ArrayLen(arrNodes2)# GTE 1>
        	<cfquery datasource="#this.ds#" name="qPut">
                Delete from savav_defs
            </cfquery>
        </cfif>

        <cfoutput>
        <!--- Loop Over the PPC Defs --->
        	<cftry>
            <cfloop index="i" from="1" to="#ArrayLen(arrNodes1)#">
            	<cfquery datasource="#this.ds#" name="qPut">
                    Insert Into savav_defs (arch, file, defdate, current, mdate)
                    Values ('ppc', <cfqueryparam value="#arrNodes1[i].XmlText#">, <cfqueryparam value="#arrNodes1[i].XmlAttributes.date#">, <cfqueryparam value="#arrNodes1[i].XmlAttributes.current#">, #vMdate#)
                </cfquery>
            </cfloop>
            	<cfcatch type = "Database">
                    <cfinvoke component="ws_logger" method="LogEvent">
                        <cfinvokeargument name="aEventType" value="Error">
                        <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                        <cfinvokeargument name="aEvent" value="[AddSavAvDefs][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                    </cfinvoke>
                    <cfset response.errorNo = "1">
					<cfset response.errorMsg = "[AddSavAvDefs][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                	<cfreturn response>
               </cfcatch>
           </cftry>
        <!--- Loop Over the x86 Defs --->
        	<cftry>
            <cfloop index="i" from="1" to="#ArrayLen(arrNodes2)#">
                <cfquery datasource="#this.ds#" name="qPut">
                    Insert Into savav_defs (arch, file, defdate, current, mdate)
                    Values ('x86', <cfqueryparam value="#arrNodes2[i].XmlText#">, <cfqueryparam value="#arrNodes2[i].XmlAttributes.date#">, <cfqueryparam value="#arrNodes2[i].XmlAttributes.current#">, #vMdate#)
                </cfquery>
            </cfloop>
            <cfcatch type = "Database">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddSavAvDefs][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "[AddSavAvDefs][Insert]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
               	<cfreturn response>
           </cfcatch>
           </cftry>
        </cfoutput>

        <cfreturn response>
	</cffunction>

<!--- #################################################### --->
<!--- getClientPatchStatusCount	 		 				   --->
<!--- #################################################### --->
    <cffunction name="getClientPatchStatusCount" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<cfset _result = {} />
		<cfset _result[ "totalPatchesNeeded" ] = "NA" />

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetClientPatchGroup">
                select id from mp_patch_group
                Where name = (	select PatchGroup from mp_clients_view
                                Where cuuid = <cfqueryparam value="#arguments.clientID#">)
            </cfquery>
			<cfset var l_PatchGroupID = #qGetClientPatchGroup.id#>

            <cfquery datasource="#this.ds#" name="qGetClientPatchState">
                select 1 from client_patch_status_view
                Where
                    cuuid = <cfqueryparam value="#arguments.clientID#">
                AND patch_id in (
                    select patch_id
                    from mp_patch_group_patches
                    where mp_patch_group_patches.patch_group_id = <cfqueryparam value="#l_PatchGroupID#"> )
                Order By date Desc
            </cfquery>

			<cfset _result[ "totalPatchesNeeded" ] = "#qGetClientPatchState.RecordCount#" />
			<cfset response.result = serializeJSON(_result)>

            <cfcatch type="any">
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = cfcatch.Message>
                <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>

		<cfreturn #response#>
	</cffunction>

<!--- #################################################### --->
<!--- PostPatchesFound	 		 				   		   --->
<!--- #################################################### --->
	<cffunction name="PostPatchesFound" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="true" default="0" />
		<cfargument name="type" required="true" default="None" />
		<cfargument name="jsonData" required="true" type="any">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
		
		<cfif isJson(arguments.jsonData)>
	        <cfset arguments.data = deserializeJSON(arguments.jsonData) />
	    <cfelse>
	    	<cfset response[ "errorNo" ] = "1" />
			<cfset response[ "errorMsg" ] = "Data provided was not of JSON type." /> 
			<cfreturn #response#>
	    </cfif>
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />
		<cftry>
			<cfif #arguments.type# EQ "apple">
				<cfquery datasource="#this.ds#" name="qRmCurPatchData">
					Delete from mp_client_patches_apple
					Where cuuid = <cfqueryparam value="#arguments.clientID#">
		       	</cfquery>
		       	
		       	<cfloop index="i" from="1" to="#ArrayLen(arguments.data.patches)#">
					<cfquery datasource="#this.ds#" name="qInCurPatchData">
				       	Insert Into mp_client_patches_apple (cuuid, date, patch, type, description, size, recommended, restart, version, mdate)
				       	Values (<cfqueryparam value="#arguments.clientID#">,#CreateODBCDateTime(now())#,<cfqueryparam value="#arguments.data.patches[i]['patch']#">,
				       			<cfqueryparam value="#arguments.data.patches[i]['type']#">,<cfqueryparam value="#arguments.data.patches[i]['description']#">,<cfqueryparam value="#arguments.data.patches[i]['size']#">,
								<cfqueryparam value="#arguments.data.patches[i]['recommended']#">,<cfqueryparam value="#arguments.data.patches[i]['restart']#">,
								<cfqueryparam value="#arguments.data.patches[i]['version']#">,#CreateODBCDateTime(now())#)
					</cfquery>			
				</cfloop>
			</cfif>
			<cfif #arguments.type# EQ "third">
				<cfquery datasource="#this.ds#" name="qRmCurPatchData">
					Delete from mp_client_patches_third
					Where cuuid = <cfqueryparam value="#arguments.clientID#">
		       	</cfquery>

		       	<cfloop index="i" from="1" to="#ArrayLen(arguments.data.patches)#">
					<cfquery datasource="#this.ds#" name="qInCurPatchData">
				       	Insert Into mp_client_patches_third (cuuid, date, patch, type, description, size, recommended, restart, patch_id, version, mdate, bundleID)
				       	Values (<cfqueryparam value="#arguments.clientID#">,#CreateODBCDateTime(now())#,<cfqueryparam value="#arguments.data.patches[i]['patch']#">,
				       			<cfqueryparam value="#arguments.data.patches[i]['type']#">,<cfqueryparam value="#arguments.data.patches[i]['description']#">,<cfqueryparam value="#arguments.data.patches[i]['size']#">,
								<cfqueryparam value="#arguments.data.patches[i]['recommended']#">,<cfqueryparam value="#arguments.data.patches[i]['restart']#">,<cfqueryparam value="#arguments.data.patches[i]['patch_id']#">,
								<cfqueryparam value="#arguments.data.patches[i]['version']#">,#CreateODBCDateTime(now())#,<cfqueryparam value="#arguments.data.patches[i]['bundleID']#">)
					</cfquery>			
				</cfloop>
			</cfif>
		<cfcatch>
			<cfset response.errorNo = "1">
			<cfset response.errorMsg = "cfcatch.Message and #arguments.data.cuuid#">
		</cfcatch>
		</cftry>
		<cfreturn #response#>
	</cffunction>

<!--- #################################################### --->
<!--- Installed Patches     	 		 				   --->
<!--- #################################################### --->
    <cffunction name="PostInstalledPatch" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="false" default="0" />
		<cfargument name="clientKey" required="false" default="0" />
		<cfargument name="patch" required="false" default="0" />
		<cfargument name="patchType" required="false" default="0" />

		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
		<cfset response[ "errorMsg" ] = "" />
		<cfset response[ "result" ] = "" />

		<cftry>
			<cfquery datasource="#this.ds#" name="qAddPatchInstall">
				INSERT INTO mp_installed_patches
				Set
				cuuid = <cfqueryparam value="#arguments.clientID#">,
				patch = <cfqueryparam value="#arguments.patch#">,
				patch_name = <cfqueryparam value="#getPatchName(arguments.patch, arguments.patchType)#">,
				type = <cfqueryparam value="#arguments.patchType#">,
				date = #CreateODBCDateTime(now())#
			</cfquery>

			<cfset _updateIt = #updateInstalledPatchStatus(arguments.clientID, arguments.patch, arguments.patchType)#>
			<cfif _updateIt EQ false>
				<cfset l = logit("Error","[addInstalledPatch][updateInstalledPatchStatus]: Returned false for #arguments.clientID#, #arguments.patch#, #arguments.patchType#")>
			</cfif>

            <cfcatch type="any">
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = cfcatch.Message>
                <cfset l = logit("Error","[getLastCheckIn]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>

		<cfreturn #response#>
	</cffunction>

	<!--- Helper methods for addInstalledPatch --->
	<cffunction name="updateInstalledPatchStatus" access="private" returntype="boolean">
		<cfargument name="cuuid" required="yes">
        <cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">

        <cfif arguments.type EQ "Apple">
            <cfquery datasource="#this.ds#" name="qGet">
                Select * From mp_client_patches_apple
                Where patch = <cfqueryparam value="#arguments.patch#">
                AND
                cuuid = <cfqueryparam value="#Trim(arguments.cuuid)#">
            </cfquery>
            <cfif qGet.RecordCount EQ 1>
                <cfquery datasource="#this.ds#" name="qDel">
                    Delete from mp_client_patches_apple
                    Where rid = <cfqueryparam value="#qGet.rid#">
                </cfquery>
            </cfif>
        </cfif>
        <cfif arguments.type EQ "Third">
            <cfquery datasource="#this.ds#" name="qGet">
                Select * From mp_client_patches_third
                Where patch_id = <cfqueryparam value="#arguments.patch#">
                AND
                cuuid = <cfqueryparam value="#Trim(arguments.cuuid)#">
            </cfquery>
            <cfif qGet.RecordCount EQ 1>
                <cfquery datasource="#this.ds#" name="qDel">
                    Delete from mp_client_patches_third
                    Where rid = <cfqueryparam value="#qGet.rid#">
                </cfquery>
            </cfif>
        </cfif>

    	<cfreturn true>
    </cffunction>

	<cffunction name="getPatchName" access="private" returntype="boolean">
		<cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">

		<cfif UCase(arguments.type) EQ "APPLE">
			<cfreturn arguments.patch>
		<cfelse>
			<cftry>
				<cfquery datasource="#this.ds#" name="qGet">
                	Select * From mp_patches
                	Where puuid = <cfqueryparam value="#arguments.patch#">
            	</cfquery>
				<cfset result = "#qGet.patch_name#-#qGet.patch_ver#">
				<cfreturn result>
			<cfcatch>
				<cfreturn arguments.patch>
			</cfcatch>
			</cftry>
		</cfif>

		<!--- Should Not Get Here --->
		<cfreturn arguments.patch>
	</cffunction>

<!--- #################################################### --->
<!--- GetSoftwareForGroup -> GetSoftwareTasksForGroup	   --->
<!--- #################################################### --->	
    <cffunction name="GetSoftwareForGroup" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="GroupName">

		<cfset var x = GetSoftwareTasksForGroup(arguments.GroupName)>
		<cfreturn x>
	</cffunction>
    
<!--- #################################################### --->
<!--- GetSoftwareTasksForGroup	   						   --->
<!--- #################################################### --->	    
    <cffunction name="GetSoftwareTasksForGroup" access="remote" returnType="any" returnFormat="plain" output="false">
    	<cfargument name="GroupName">
        
        <cfset gid = getSoftwareGroupID(arguments.GroupName)>
        <cfquery datasource="#this.ds#" name="qGetGroupTasksData">
			Select gData From mp_software_tasks_data
			Where gid = '#gid#'
		</cfquery>
        
        <cfif qGetGroupTasksData.RecordCount EQ 1>
        	<cfreturn #qGetGroupTasksData.gData#>
        <cfelse>
        	<cfset response = {} />
			<cfset response[ "errorNo" ] = "1" />
            <cfset response[ "errorMsg" ] = "No task group data found for #arguments.GroupName#." />
            <cfset response[ "result" ] = {} />
            <cfreturn SerializeJson(response)>
        </cfif>    
    </cffunction>
    
<!--- #################################################### --->
<!--- ValidateSoftwareGroupHash	   						   --->
<!--- #################################################### --->	 
	<cffunction name="ValidateSoftwareGroupHash" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="GroupName">
		<cfargument name="GroupHash">
		
        <cfset gid = getSoftwareGroupID(arguments.GroupName)>
        <cfquery datasource="#this.ds#" name="qGetGroupTasksData">
			Select gDataHash From mp_software_tasks_data
			Where gid = '#gid#'
            AND gDataHash = '#arguments.GroupHash#'
		</cfquery>
        
        <cfset response = {} />
        
        <cfif qGetGroupTasksData.RecordCount EQ 1>
			<cfset response[ "errorNo" ] = "0" />
            <cfset response[ "errorMsg" ] = "" />
            <cfset response[ "result" ] = "Yes" />
        <cfelse>
			<cfset response[ "errorNo" ] = "1" />
            <cfset response[ "errorMsg" ] = "No task group data found for #arguments.GroupName#." />
            <cfset response[ "result" ] = "No" />
        </cfif>
		
        <cfreturn SerializeJson(response)>
	</cffunction>

<!--- #################################################### --->
<!--- GetSoftwareTasksForGroupHash 						   --->
<!--- #################################################### --->	 
    <cffunction name="GetSoftwareTasksForGroupHash" access="remote" returnType="struct" returnFormat="json" output="false">
    	<cfargument name="GroupName">
    	
        <cfset gid = getSoftwareGroupID(arguments.GroupName)>
        <cfquery datasource="#this.ds#" name="qGetGroupTasksHash">
			Select gDataHash From mp_software_tasks_data
			Where gid = '#gid#'
		</cfquery>
        
        <cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
        
        <cfif qGetGroupTasksHash.RecordCount EQ 1>
        	<cfset response.result[ "hash" ] = "#qGetGroupTasksHash.gDataHash#" />
        <cfelse>
        	<cfset response[ "errorNo" ] = "1" />
        	<cfset response[ "errorMsg" ] = "No hash value found for #qGetGroupTasksHash.gDataHash#" />
        </cfif> 
    	<cfreturn response>
    </cffunction>
    
<!--- #################################################### --->
<!--- PostSoftwareInstallResults 						   --->
<!--- #################################################### --->	    
    <cffunction name="PostSoftwareInstallResults" access="remote" returnType="struct" returnFormat="json" output="false">
    	<cfargument name="ClientID">
        <cfargument name="SWTaskID">
        <cfargument name="SWDistID">
        <cfargument name="ResultNo">
        <cfargument name="ResultString">
		<cfargument name="Action">
        
        <cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />
        
        <cfif NOT validClientID(arguments.ClientID)>
        	<cfset response[ "errorNo" ] = "1000" />
        	<cfset response[ "errorMsg" ] = "Unable to add software install results for #arguments.ClientID#" />
            <cfreturn response>
        </cfif>
    	
        <cftry>
        	<cfquery datasource="#this.ds#" name="qSWInstall">
            	Insert Into mp_software_installs (cuuid, tuuid, suuid, result, resultString, action)
           		Values (<cfqueryparam value="#arguments.ClientID#">, <cfqueryparam value="#arguments.SWTaskID#">, 
            			<cfqueryparam value="#arguments.SWDistID#">, <cfqueryparam value="#arguments.ResultNo#">, 
                    	<cfqueryparam value="#arguments.ResultString#">, <cfqueryparam value="#arguments.Action#">)
        	</cfquery>
        	<cfcatch type="any">
            	<cfset response[ "errorNo" ] = "1001" />
        		<cfset response[ "errorMsg" ] = "Error inserting results for #arguments.ClientID#" />
            	<cfset l = logit("Error","Error inserting results for #arguments.ClientID#. Message[#cfcatch.ErrNumber#]: #cfcatch.Detail# #cfcatch.Message#")>
            </cfcatch>
        </cftry>

    	<cfreturn response>
    </cffunction>

<!--- ********************************************************************* --->
<!--- Helpers 																--->
<!--- ********************************************************************* --->

	<!--- Callers: PostSoftwareInstallResults --->
	<cffunction name="validClientID" access="private" returntype="any" output="no">
		<cfargument name="ClientID">
	
		<cfquery datasource="#this.ds#" name="qGetID">
			Select cuuid from mp_clients
			Where cuuid = '#arguments.ClientID#'
		</cfquery>

		<cfif qGetID.RecordCount EQ 1>
			<cfreturn true>
		<cfelse>
			<cfreturn flase>
		</cfif>
	</cffunction>
    
    <!--- Callers: GetSoftwareTasksForGroup; ValidateSoftwareGroupHash; GetSoftwareTasksForGroupHash --->
    <cffunction name="getSoftwareGroupID" access="private" returntype="any" output="no">
		<cfargument name="GroupName">

		<cfquery datasource="#this.ds#" name="qGetID">
			Select gid from mp_software_groups
			Where gName = '#arguments.GroupName#'
		</cfquery>

		<cfif qGetID.RecordCount EQ 1>
			<cfreturn #qGetID.gid#>
		<cfelse>
			<cfreturn "0">
		</cfif>
	</cffunction>
	
    <!--- Callers:  --->
	<cffunction name="getSoftwareTaskFromID" access="private" returntype="any" output="no">
		<cfargument name="TaskID">

		<cfquery datasource="#this.ds#" name="qGetTask">
			Select name, tuuid, primary_suuid, sw_task_type, sw_task_privs,
				sw_start_datetime, sw_end_datetime, active
			From mp_software_task
			Where tuuid = '#arguments.TaskID#'
		</cfquery>

		<cfif qGetTask.RecordCount EQ 1>
			<cfreturn #qGetTask#>
		<cfelse>
			<cfset myQuery = QueryNew("name, primary_suuid, sw_task_type, sw_task_privs, sw_start_datetime, sw_end_datetime, active")>
			<cfreturn #myQuery#>
		</cfif>
	</cffunction>

	<!--- Callers:  --->
	<cffunction name="getSoftwareDistFromSUUID" access="private" returntype="query" output="no">
		<cfargument name="suuid">

		<cfquery datasource="#this.ds#" name="qGetTask">
			Select sName,sVendor,sVendorURL,sVersion,sDescription,sReboot,sw_type,sw_url,sw_hash,sw_pre_install_script
				,sw_post_install_script,sw_uninstall_script,auto_patch,patch_bundle_id,sState
			From mp_software
			Where suuid = '#arguments.suuid#'
		</cfquery>

		<cfif qGetTask.RecordCount EQ 1>
			<cfreturn #qGetTask#>
		<cfelse>
			<cfset myQuery = QueryNew("sName,sVendor,sVendorURL,sVersion,sDescription,sReboot,sw_type,sw_url,sw_hash,sw_pre_install_script
				,sw_post_install_script,sw_uninstall_script,auto_patch,patch_bundle_id,sState")>
			<cfreturn #myQuery#>
		</cfif>
	</cffunction>

	<!--- Callers:  --->
	<cffunction name="getSoftwareCriteriaFromSUUID" access="private" returntype="struct" output="no">
		<cfargument name="suuid">

		<cfquery datasource="#this.ds#" name="qGetCrit">
			Select *
			From mp_software_criteria
			Where suuid = '#arguments.suuid#'
			Order By type_order Asc
		</cfquery>

		<cfset criteria = {} />
		<cfloop query="qGetCrit">
			<cfif qGetCrit.type EQ "OSType">
				<cfset criteria[ "os_type" ] = "#qGetCrit.type_data#" />
			</cfif>
			<cfif qGetCrit.type EQ "OSVersion">
				<cfset criteria[ "os_vers" ] = "#qGetCrit.type_data#" />
			</cfif>
			<cfif qGetCrit.type EQ "OSArch">
				<cfset criteria[ "arch_type" ] = "#qGetCrit.type_data#" />
			</cfif>
		</cfloop>

		<cfreturn criteria>
	</cffunction>

	<!--- Callers:  --->
	<cffunction name="RequisistsForID" access="private" returntype="struct" output="no">
		<cfargument name="ReqType">
		<cfargument name="TaskID">

		<cfset criteria = {} />
		<!---
		<cfset criteria[ "suuid" ] = #arguments.order# />
		<cfset criteria[ "order" ] = #arguments.data# />
		--->
		<cfreturn criteria>
	</cffunction>   
<!--- ********************************************************************* --->
<!--- End --- Client Methods - for MacPatch 2.1.0							--->
<!--- ********************************************************************* ---> 

<!--- ********************************************************************* --->
<!--- Start --- Agent Update Methods - for MacPatch 2.1.0					--->
<!--- ********************************************************************* ---> 

<!--- #################################################### --->
<!--- CheckForAgentUpdates    	 						   --->
<!--- #################################################### --->	   
	<cffunction name="GetAgentUpdates" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID" required="no">
		<cfargument name="agentVersion">
		<cfargument name="agentBuild">
		
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />

		<cftry>
            <cfquery datasource="#this.ds#" name="qGetLatestVersion" maxrows="1">
            	Select agent_ver as agent_version, version, framework as agent_framework, build as agent_build,
                pkg_Hash, pkg_Url, puuid, pkg_name, osver
                From mp_client_agents
                Where type = 'app'
                AND
                active = '1'
                ORDER BY
                INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
				INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC
            </cfquery>
            <cfcatch type="any">
				<cfset l = logit("Error","[GetAgentUpdates]: #cfcatch.Detail# -- #cfcatch.Message#")>
	            <cfset response.errorNo = "1">
				<cfset response.errorMsg = "[GetAgentUpdates]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cfreturn response>
            </cfcatch>
        </cftry>

        <cfset var count = 0>
		<cfset var agentVerReq = "10.5.8">
        <cfif qGetLatestVersion.RecordCount EQ 1>
			<cfset agentVerReq = #replacenocase(qGetLatestVersion.osver,"+","", "All")#>
			<cfoutput query="qGetLatestVersion">
                <cfif versionCompare(agent_version,arguments.agentVersion) EQ 1>
                    <cfset count = count + 1>
                </cfif>
				<cfif versionCompare(agent_build,arguments.agentBuild) EQ 1 AND #arguments.agentBuild# NEQ "0">
                    <cfset count = count + 1>
                </cfif>
            </cfoutput>
		<cfelse>
			<cfset l = logit("Error","[GetSelfUpdates][qGetLatestVersion][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
			<cfset response.errorNo = "2">
			<cfset response.errorMsg = "[GetAgentUpdates]: Found #qGetLatestVersion.RecordCount# records. Should only find 1.">
			<cfreturn response>
        </cfif>

		<!--- If a Version Number is Higher check filter --->
		<cfif count GTE 1>
	        <cfif Len(Trim(arguments.clientID)) EQ 0>
	        	<!--- No CUUID Info --->
	        	<cfset count = 0>
	        <cfelse>
	        	<!--- CUUID is found --->
	            <cfquery datasource="#this.ds#" name="qGetClientGroup">
	            	Select cuuid, ipaddr, hostname, Domain, ostype, osver
	                From mp_clients_view
	                Where cuuid = <cfqueryparam value="#arguments.clientID#">
	            </cfquery>

	            <cfif qGetClientGroup.RecordCount NEQ 0>
	            	<!--- This is for testing Update only certain clients. based on cuuid return data --->
	            	<cfif versionCompare(agentVerReq,qGetClientGroup.osver) EQ 1>
	            		<cfset count = 0>
	            	<cfelse>
		            	<cfoutput query="qGetClientGroup">
				    		<cfset x = SelfUpdateFilter("app")>
		  					<cfif evaluate(x)>
		                    	<cfset count = 1>
		                    <cfelse>
		                    	<cfset count = 0>
		                    </cfif>
		                </cfoutput>
		           </cfif>     
	            <cfelse>
	            	<cfset count = 0>
	            </cfif>
	        </cfif>
		</cfif>
		
		<cfset update = {} />
		<cfset update[ "updateAvailable" ] = #IIF(count GTE 1,DE('true'),DE('false'))# />
		<cfif count GTE 1>
			<cfset update[ "SelfUpdate" ] = {} />
			<cfset SelfUpdate = {} />
			<cfoutput query="qGetLatestVersion">
				<cfloop list="#qGetLatestVersion.ColumnList#" index="column">
					<cfset SelfUpdate[ column ] = #iif(len(Evaluate(column)) GTE 1,DE(Trim(Evaluate(column))),DE('Null'))# />
				</cfloop>
			</cfoutput>
			<cfset update[ "SelfUpdate" ] = #SelfUpdate# />
		</cfif>

		<cfset response[ "result" ] = #update# />
		<cfreturn response>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetAgentUpdaterUpdates   	 						   --->
<!--- #################################################### --->
    <cffunction name="GetAgentUpdaterUpdates" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="clientID">
		<cfargument name="agentUp2DateVer">
        
		<cfset response = {} />
		<cfset response[ "errorNo" ] = "0" />
        <cfset response[ "errorMsg" ] = "" />
        <cfset response[ "result" ] = {} />

		<cftry>
            <cfquery datasource="#this.ds#" name="qGetLatestVersion">
            	Select agent_ver as agent_version, version, framework as agent_framework, build as agent_build,
                pkg_Hash, pkg_Url, puuid, pkg_name, osver
                From mp_client_agents
                Where type = 'update'
                AND
                active = '1'
                ORDER BY
                INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
				INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC
            </cfquery>

            <cfcatch type="any">
				<cfset l = logit("Error","[GetAgentUpdaterUpdates][qGetLatestVersion]: #cfcatch.Detail# -- #cfcatch.Message#")>
				<cfset response.errorNo = "1">
				<cfset response.errorMsg = "[GetAgentUpdaterUpdates][qGetLatestVersion]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cfreturn response>
            </cfcatch>
        </cftry>

        <cfset var count = 0>
		<cfset var agentVerReq = "10.5.8">
        <cfif qGetLatestVersion.RecordCount EQ 1>
			<cfset agentVerReq = #replacenocase(qGetLatestVersion.osver,"+","", "All")#>
			<cfoutput query="qGetLatestVersion">
                <cfif versionCompare(version,arguments.agentUp2DateVer) EQ 1>
                    <cfset count = count + 1>
                </cfif>
            </cfoutput>
        </cfif>

       <!--- If a Version Number is Higher check filter --->
		<cfif count GTE 1>
	        <cfif Len(Trim(arguments.clientID)) EQ 0>
	        	<!--- No CUUID Info --->
	        	<cfset count = 0>
	        <cfelse>
	        	<!--- CUUID is found --->
	            <cfquery datasource="#this.ds#" name="qGetClientGroup">
	            	Select cuuid, ipaddr, hostname, Domain, ostype, osver
	                From mp_clients_view
	                Where cuuid = <cfqueryparam value="#arguments.clientID#">
	            </cfquery>

	            <cfif qGetClientGroup.RecordCount NEQ 0>
	            	<!--- This is for testing Update only certain clients. based on cuuid return data --->
	            	<cfif versionCompare(agentVerReq,qGetClientGroup.osver) EQ 1>
	            		<cfset count = 0>
	            	<cfelse>
		            	<cfoutput query="qGetClientGroup">
				    		<cfset x = SelfUpdateFilter("app")>
				    		<cfif Len(x) GTE 1>
			  					<cfif evaluate(x)>
			                    	<cfset count = 1>
			                    <cfelse>
			                    	<cfset count = 0>
			                    </cfif>
		                    <cfelse>
			                    <cfset count = 0>
		                    </cfif>
		                </cfoutput>
		            </cfif>    
	            <cfelse>
	            	<cfset count = 0>
	            </cfif>
	        </cfif>
		</cfif>
		
		<cfset update = {} />
		<cfset update[ "updateAvailable" ] = #IIF(count GTE 1,DE('true'),DE('false'))# />
		<cfif count GTE 1>
			<cfset update[ "SelfUpdate" ] = {} />
			<cfset SelfUpdate = {} />
			<cfoutput query="qGetLatestVersion">
				<cfloop list="#qGetLatestVersion.ColumnList#" index="column">
					<cfset SelfUpdate[ column ] = #iif(len(Evaluate(column)) GTE 1,DE(Trim(Evaluate(column))),DE('Null'))# />
				</cfloop>
			</cfoutput>
			<cfset update[ "SelfUpdate" ] = #SelfUpdate# />
		</cfif>

		<cfset response[ "result" ] = #update# />
		<cfreturn response>
	</cffunction>

<!--- ********************************************************************* --->
<!--- Helpers 																--->
<!--- ********************************************************************* --->
    <cffunction name="versionCompare" access="private" returntype="numeric" output="no">
		<!--- It returns 1 when argument 1 is greater, -1 when argument 2 is greater, and 0 when they are exact matches. --->
        <cfargument name="leftVersion" required="yes" default="0">
        <cfargument name="rightVersion" required="yes" default="0">

        <cfset var len1 = listLen(arguments.leftVersion, '.')>
        <cfset var len2 = listLen(arguments.rightVersion, '.')>
        <cfset var piece1 = "">
        <cfset var piece2 = "">

        <cfif len1 GT len2>
            <cfset arguments.rightVersion = arguments.rightVersion & repeatString('.0', len1-len2)>
        <cfelse>
            <cfset arguments.leftVersion = arguments.leftVersion & repeatString('.0', len2-len1)>
        </cfif>

        <cfloop index = "i" from="1" to=#listLen(arguments.leftVersion, '.')#>
            <cfset piece1 = listGetAt(arguments.leftVersion, i, '.')>
            <cfset piece2 = listGetAt(arguments.rightVersion, i, '.')>

            <cfif piece1 NEQ piece2>
                <cfif piece1 GT piece2>
                    <cfreturn 1>
                <cfelse>
                    <cfreturn -1>
                </cfif>
            </cfif>
        </cfloop>

        <cfreturn 0>
    </cffunction>

	<cffunction name="SelfUpdateFilter" access="private" returntype="string" output="no">
		<cfargument name="aType">
		<cftry>
			<cfquery datasource="#this.ds#" name="qGet">
				Select * From mp_client_agents_filters
				Where type = <cfqueryparam value="#arguments.aType#">
				Order By rid ASC
			</cfquery>
			<cfset var result = "">
			<cfoutput query="qGet">
				<cfset result = listAppend(result,IIF(attribute EQ "All",DE("""All"""),DE(attribute)))>
				<cfset result = listAppend(result,attribute_oper)>
				<cfset result = listAppend(result,""""&attribute_filter&"""")>
				<cfset result = listAppend(result,attribute_condition)>
			</cfoutput>
			<cfset result = ListDeleteAt(result, ListLen(result))>
			<cfset result = Replace(result,","," ","All")>
		<cfcatch>
			<!--- If Error, default to none --->
			<cfset l = logit("Error","[SelfUpdateFilter][Set Result to No]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#")>
			<cfset result = """All"" EQ ""NO""">
		</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>


<!--- ********************************************************************* --->
<!--- End --- Agent Update Methods - for MacPatch 2.1.0				    	--->
<!--- ********************************************************************* ---> 
</cfcomponent>
