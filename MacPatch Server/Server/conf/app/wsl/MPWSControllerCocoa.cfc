<!--- **************************************************************************************** --->
<!---
		MPWSControllerCocoa is new to support Cocoa Client Code
	 	Database type is MySQL
		MacPatch Version 2.1.0
--->
<!---	Notes:
        This file is included with MacPatch 2.2.0 release, only for older client support.
        This file will be removed in the next release.
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfset this.ds = "mpds">

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

<!--- **************************************************************************************** --->
<!--- Begin Client WebServices Methods --->

<!--- #################################################### --->
<!--- Test			 									   --->
<!--- #################################################### --->
	<cffunction name="WSLTest" access="remote" returntype="string" returnFormat="plain" output="no">
        <cfreturn #CreateODBCDateTime(now())#>
    </cffunction>

<!--- #################################################### --->
<!--- ClientCheckIn 									   --->
<!--- #################################################### --->
    <cffunction name="ClientCheckIn" access="remote" returntype="any" output="no">
    	<cfargument name="theData">
        <cfargument name="encoding">
		
        <cfset log = logit("Error","ClientCheckIn is not supported anymore.",CGI.REMOTE_HOST)>
        <cfreturn false>
    </cffunction>

<!--- #################################################### --->
<!--- GetClientPatchState 								   --->
<!--- This Needs to be updated to test againts client patch group --->
<!--- No Caching                                           --->
<!--- #################################################### --->
	<cffunction name="ClientPatchStatus" access="remote" returntype="any" output="no">
        <cfargument name="cuuid" required="yes">

        <cftry>
    	<cfquery datasource="#this.ds#" name="qGetClientPatchGroup">
			select id from mp_patch_group
			Where name = (	select PatchGroup from mp_clients_view
            				Where cuuid = <cfqueryparam value="#arguments.cuuid#">)
        </cfquery>

		<cfset var l_PatchGroupID = #qGetClientPatchGroup.id#>

        <cfquery datasource="#this.ds#" name="qGetClientPatchState" result="res">
            select * from client_patch_status_view
            Where
            	cuuid = <cfqueryparam value="#arguments.cuuid#">
			AND patch_id in (
				select patch_id
				from mp_patch_group_patches
				where mp_patch_group_patches.patch_group_id = <cfqueryparam value="#l_PatchGroupID#"> )
            Order By date Desc
        </cfquery>
        <cfcatch type="any">
            <!--- the message to display --->
            <cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Error">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[ClientPatchStatus][qGetClientPatchState]: #cfcatch.Detail# -- #cfcatch.Message#">
            </cfinvoke>
        </cfcatch>
        </cftry>
        <cfsavecontent variable="thePlist">
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            	<key>totalPatchesNeeded</key>
                <string><cfoutput>#qGetClientPatchState.RecordCount#</cfoutput></string>
                <key>patches</key>
                <array>
                	<cfoutput query="qGetClientPatchState">
                    <dict>
                    <cfloop list="#qGetClientPatchState.ColumnList#" index="col">
                    <key>#col#</key>
                    <string>#qGetClientPatchState[col][CurrentRow]#</string>
                    </cfloop>
                    </dict>
                    </cfoutput>
                </array>
            </dict>
            </plist>
        </cfsavecontent>

        <cfreturn #thePlist#>
    </cffunction>

<!--- #################################################### --->
<!--- GetPatchGroupPatches 								   --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatches" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">

        <cfreturn GetPatchGroupPatchesExtended(arguments.PatchGroup)>
	</cffunction>

<!--- #################################################### --->
<!--- GetPatchGroupPatchesExtended - New For 1.8.6 		   --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatchesExtended" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">
    	
        <cfset _data = "">
        <cftry>
        	<cfquery datasource="#this.ds#" name="qGetGroupID">
                Select id from mp_patch_group
                Where name = <cfqueryparam value="#arguments.PatchGroup#">
            </cfquery>
        	<cfif qGetGroupID.RecordCount NEQ 1>
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatchesExtended][qGetGroupID]: No group was found for #arguments.PatchGroup#">
                </cfinvoke>
                <cfreturn "">
        	</cfif>
            <cfcatch>
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatchesExtended]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
                <cfreturn "">
            </cfcatch>
        </cftry>
        
        <cftry>
        	<cfquery datasource="#this.ds#" name="qGetGroupData">
                Select data from mp_patch_group_data
                Where pid = <cfqueryparam value="#qGetGroupID.id#">
                AND data_type = 'SOAP'
            </cfquery>
            <cfif qGetGroupID.RecordCount NEQ 1>
            	<cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatchesExtended][qGetGroupData]: No group data was found for id #qGetGroupID.id#">
                </cfinvoke>
                <cfreturn "">
            </cfif>
            <cfset _data = #qGetGroupData.data#>    
            <cfcatch>
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetPatchGroupPatchesExtended]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
                <cfreturn "">
            </cfcatch>
        </cftry>

        <cfreturn #_data#>
	</cffunction>

<!--- #################################################### --->
<!--- AddPatchesXML				 						   --->
<!--- Not Needed with MPv2.0, just log					   --->
<!--- #################################################### --->
    <cffunction name="AddPatchesXML" access="remote" returnType="boolean" output="no">
        <cfargument name="vXml">

		<cfinvoke component="ws_logger" method="LogEvent">
            <cfinvokeargument name="aEventType" value="Error">
            <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
            <cfinvokeargument name="aEvent" value="[AddPatchesXML]: Client needs upgrade.">
        </cfinvoke>

		<cfreturn False>
	</cffunction>
<!--- #################################################### --->
<!--- UpdateInstalledPatches	 						   --->
<!--- #################################################### --->
    <!--- New for v1.8 --->
    <cffunction name="UpdateInstalledPatches" access="remote" returntype="boolean">
		<cfargument name="cuuid" required="yes">
        <cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">
		
		<cfset inet = CreateObject("java", "java.net.InetAddress")>
		<cfset inet = inet.getLocalHost()>
        
        <cftry>
			<cfquery datasource="#this.ds#" name="qAddPatchInstall">
				INSERT INTO mp_installed_patches_new
				Set
				cuuid = <cfqueryparam value="#arguments.cuuid#">,
				patch = <cfqueryparam value="#arguments.patch#">,
				patch_name = <cfqueryparam value="#getPatchName(arguments.patch, arguments.type)#">,
				type = <cfqueryparam value="#arguments.type#">,
				server_name = '#inet.getHostName()#',
				date = #CreateODBCDateTime(now())#
			</cfquery>

            <cfcatch type="any">
            	<cfinvoke component="ws_logger" method="LogEvent">
					<cfinvokeargument name="aEventType" value="Error">
					<cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
					<cfinvokeargument name="aEvent" value="[UpdateInstalledPatches]: #cfcatch.Detail# -- #cfcatch.Message#">
				</cfinvoke>
            </cfcatch>
        </cftry>
		
        <cfif arguments.type EQ "Apple">
            <cfquery datasource="#this.ds#" name="qGet">
                Select patch From mp_client_patches_apple
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
                Select patch_id From mp_client_patches_third
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
    <!--- Helper --->
	<cffunction name="getPatchName" access="private" returntype="any">
		<cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">

		<cfif UCase(arguments.type) EQ "APPLE">
			<cfreturn arguments.patch>
		<cfelse>
			<cftry>
				<cfquery datasource="#this.ds#" name="qGet">
                	Select patch_name, patch_ver From mp_patches
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
<!--- ######################################################### --->
<!--- AddInstalledPatches / Depricated as of 1.8 -- RM 1.8.5	--->
<!--- ######################################################### --->
    <cffunction name="AddInstalledPatches" access="remote" returntype="boolean">
		<cfargument name="patchesXML64">
		<cfset var theXML = ToString(ToBinary(arguments.patchesXML64))>

		<!--- Parse the XML File --->
		<cfset var xmldoc = XmlParse(#theXML#)>
		<cfset var XMLRoot = xmldoc.XmlRoot>

        <cfparam name="l_hostname" default="NA" />
		<cfif IsDefined("XMLRoot.hostname")>
        	<cfset l_hostname = trim(XMLRoot.hostname.xmltext)>
        </cfif>

        <cfparam name="l_ip" default="NA" />
        <cfif IsDefined("XMLRoot.ipaddr")>
        	<cfset l_ip = trim(XMLRoot.ipaddr.xmltext)>
        </cfif>

		<cfset InstallDate = trim(XMLRoot.idate.xmltext)>
        <cfset l_CUUID = trim(XMLRoot.cuuid.xmltext)>

		<!--- Retrieve the number of patch items in the xml doc --->
		<cfset Patch_Length = arraylen(XMLRoot.patch)>

		<!--- Loop through all the items --->
		<cfloop index="itms" from="1" to="#Patch_Length#">
			<cfoutput>
				<cfset vPatch = #XMLRoot.patch[itms].xmltext#>
                <cftry>
                		<!--- INSERT IGNORE INTO installed_patches --->
                        <cfquery datasource="#this.ds#" name="qPut">
                        	INSERT INTO installed_patches
                            Set
                            patch = <cfqueryparam value="#vPatch#">,
                            hostname = <cfqueryparam value="#l_hostname#">,
                            ipaddr = <cfqueryparam value="#l_ip#">,
                            idate = #CreateODBCDateTime(InstallDate)#,
                            cuuid = <cfqueryparam value="#l_cuuid#">
                            ON DUPLICATE KEY UPDATE
                            	idate = #CreateODBCDateTime(InstallDate)#
                        </cfquery>
                        <cfcatch type = "Database">
                            <cfinvoke component="ws_logger" method="LogEvent">
                                <cfinvokeargument name="aEventType" value="Error">
                                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                                <cfinvokeargument name="aEvent" value="[AddInstalledPatches][qPut][#l_CUUID#]: #cfcatch.Detail# -- #cfcatch.Message#">
                            </cfinvoke>
                        </cfcatch>
                   </cftry>
			</cfoutput>
		</cfloop>
		<cfreturn True>
	</cffunction>
<!--- #################################################### --->
<!--- GetLastCheckIn	 		 						   --->
<!--- #################################################### --->
    <cffunction name="GetLastCheckIn" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="cuuid">

        <cfquery datasource="#this.ds#" name="qGet">
            SELECT mdate
            FROM mp_clients_view
			WHERE cuuid = <cfqueryparam value="#arguments.cuuid#">
        </cfquery>

        <cfif qGet.RecordCount EQ 1>
            <cfreturn "#DateFormat(qGet.mdate, "mm/dd/yyyy")# #TimeFormat(qGet.mdate, "HH:mm:ss")#">
        <cfelse>
        	<cfreturn "NA">
        </cfif>
    </cffunction>
<!--- #################################################### --->
<!--- GetAsusCatalogURLs 		 						   --->
<!--- Not Needed for MacPatch 2.1.0						   --->
<!--- #################################################### --->
    <cffunction name="GetAsusCatalogURLs" access="remote" returntype="any" output="no">
    	<!--- New For v1.8 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetCatalogs" result="res1">
                select catalog_url, proxy
                from mp_asus_catalogs
                Where os_minor = <cfqueryparam value="#arguments.osminor#">
                Order By c_order ASC
            </cfquery>
            <cfcatch type="any">
				<!--- the message to display --->
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetAsusCatalogURLs][qGetCatalogs]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
            </cfcatch>
        </cftry>

        <cfxml variable="root">
        <root>
            <catalogs>
			<cfoutput query="qGetCatalogs"><catalog isProxy="#proxy#">#catalog_url#</catalog></cfoutput>
            </catalogs>
        </root>
        </cfxml>

        <cfset datax = #ToBase64(ToString(root))#>
        <cfset data = #ToBinary(datax)#>
        <cfreturn data>
    </cffunction>

    <cffunction name="GetAsusCatalogs" access="remote" returntype="any" output="no">
    	<!--- New For v1.8.5 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

        <cftry>
            <cfquery datasource="#this.ds#" name="qGetCatalogs" result="res1">
                select catalog_url, proxy
                from mp_asus_catalogs
                Where os_minor = <cfqueryparam value="#arguments.osminor#">
                Order By c_order ASC
            </cfquery>
            <cfcatch type="any">
		<!--- the message to display --->
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetAsusCatalogURLs][qGetCatalogs]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
            </cfcatch>
        </cftry>
		<cfsavecontent variable="thePlist">
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            	<key>CatalogURLS</key>
                <array>
			<cfoutput query="qGetCatalogs"><cfif #proxy# EQ "0"><string>#catalog_url#</string></cfif></cfoutput>
                </array>
                <key>ProxyCatalogURLS</key>
                <array>
                    <cfoutput query="qGetCatalogs"><cfif #proxy# EQ "1"><string>#catalog_url#</string></cfif></cfoutput>
                </array>
            </dict>
            </plist>
        </cfsavecontent>

        <cfreturn thePlist>
    </cffunction>
<!--- #################################################### --->
<!--- Pre	XML                                        --->
<!--- #################################################### --->
    <!--- New for 1.8.5 --->
    <cffunction name="PreProcessXML" access="remote" returntype="boolean" output="no">
        <cfargument name="cuuid">
        <cfargument name="table">
        <cfargument name="action">

        <cfif findNoCase("mpi_", arguments.table) EQ 0>
            <cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Error">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[PreProcessXML][#arguments.cuuid#]: Table type was not of inventory type. #arguments.table#">
            </cfinvoke>
            <cfreturn false>
        </cfif>
        <cftry>
            <cfquery datasource="#this.ds#" name="qDel" result="res">
                Delete from #arguments.table#
                Where
                #cuuid# = <cfqueryparam value="#arguments.cuuid#">
            </cfquery>
            <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[PreProcessXML]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn false>
            </cfcatch>
        </cftry>
        <cfreturn true>
    </cffunction>

<!--- #################################################### --->
<!--- ProcessXML                                           --->
<!--- #################################################### --->
    <cffunction name="ProcessXML" access="remote" returntype="boolean" output="no">
        <cfargument name="encodedXML">

        <!--- Clean a bit of the XML char before parsing --->
        <cfset var theXML = ToString(ToBinary(Trim(arguments.encodedXML)))>

		<!--- Parse the XML File--->
        <cftry>
            <cfset var xmldoc = XmlParse(theXML)>
            <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[ProcessXML][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn False>
            </cfcatch>
        </cftry>

        <!--- Check to see if the table is a mpi table (inventory) --->
        <!--- If it is a mpi_ table, then write out a inventory file --->
        <cfif #IsXmlNode(xmldoc.tables.table)#>
            <cfif findNoCase("mpi_", xmldoc.tables.table.XmlAttributes.name) NEQ 0 OR findNoCase("mp_", xmldoc.tables.table.XmlAttributes.name) NEQ 0>
                <cftry>
					<!--- Clean Up XML Doc to send theough DataMgr --->
	                <cfif findNoCase("mp_client_patches_", xmldoc.tables.table.XmlAttributes.name) EQ 1>
	
	                    <cfset var arrDelNodes = XmlSearch(xmldoc,"//tables/removerows") />
	                    <cfif ArrayLen(arrDelNodes) GTE 1>
	                        <cfif #IsXmlNode(xmldoc.tables.removerows)#>
	                            <cfset aTable = #xmldoc.tables.removerows.XmlAttributes.table#>
	
	                            <cfset bCol = #xmldoc.tables.remove.XmlAttributes.column#>
	                            <cfset bColVal = #xmldoc.tables.remove.XmlAttributes.valueEQ#>
	
	                            <cfset aCol = #xmldoc.tables.removerows.XmlAttributes.column#>
	                            <cfset aColVal = #xmldoc.tables.removerows.XmlAttributes.value#>
	
	
	                            <cfquery datasource="#this.ds#" name="qDel" result="res">
	                                Delete from #aTable#
	                                Where
	                                #bCol# = <cfqueryparam value="#bColVal#">
	                                AND
	                                #aCol# = <cfqueryparam value="#aColVal#">
	                            </cfquery>
	                            <cfreturn True>
	                        <cfelse>
	                            <cfreturn False>
	                        </cfif>
	                    </cfif>
	
	                    <cfset var arrNodes = XmlSearch(xmldoc,"//tables/remove") />
	                    <cfif ArrayLen(arrNodes) GTE 1>
	                        <cfif #IsXmlNode(xmldoc.tables.remove)#>
	                            <cfset aTable = #xmldoc.tables.data.XmlAttributes.table#>
	                            <cfset aCuuid = "NA">
	                            <cfif isDefined("xmldoc.tables.data.row[1].field[1].XmlAttributes.name")>
	                                <cfif #xmldoc.tables.data.row[1].field[1].XmlAttributes.name# EQ "cuuid">
	                                    <cfset aCuuid = #xmldoc.tables.data.row[1].field[1].XmlAttributes.value#>
	                                </cfif>
	                            </cfif>

	                            <cfset xmldoc.tables.remove.XmlAttributes.column = "cuuid">
	                            <cfset xmldoc.tables.remove.XmlAttributes.valueEQ = #aCuuid#>
	                        </cfif>
	                    </cfif>
	                    <cfset theXML = ToString(xmlDoc)>
	                </cfif>
					
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

                    <cfset dirDebug = #_InvData# &"/Debug">
                    <cfif DirectoryExists(dirDebug) EQ False>
                        <cfset tmpDebug = DirectoryCreate(dirDebug)>
                    </cfif>

                    <cfset _InvFiles = #_InvData# &"/Files">
                    <cfif DirectoryExists(_InvFiles) EQ False>
                        <cfset tmpD = DirectoryCreate(_InvFiles)>
                    </cfif>

                    <cfset dirF = #_InvFiles# & "/mpi_" & #CreateUuid()# & ".txt">
                    <cffile action="write" NAMECONFLICT="makeunique" file="#dirF#" output="#theXML#">

                    <cfreturn true>

                    <cfcatch type="any">
				    	<cfinvoke component="ws_logger" method="LogEvent">
		                    <cfinvokeargument name="aEventType" value="Error">
		                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
		                    <cfinvokeargument name="aEvent" value="[ProcessXML][WriteFile]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
		                </cfinvoke>
                        <cfreturn false>
                    </cfcatch>
                </cftry>
            </cfif>
        </cfif>
		
		<cfreturn false>
    </cffunction>

<!--- #################################################### --->
<!--- DataMgrXML                                           --->
<!--- #################################################### --->
    <cffunction name="DataMgrXML" access="remote" returntype="boolean" output="no">
        <cfargument name="cuuid">
        <cfargument name="encodedXML">

        <!--- Clean a bit of the XML char before parsing --->
        <cfset var theXML = ToString(ToBinary(Trim(arguments.encodedXML)))>

        <!--- Parse the XML File--->
        <cftry>
            <cfset xmldoc = XmlParse(theXML)>
            <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[DataMgrXML][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn False>
            </cfcatch>
        </cftry>

        <!--- Check to see if the table is a mpi table (inventory) --->
        <!--- If it is a mpi_ table, then write out a inventory file --->
        <cfif #IsXmlNode(xmldoc.tables.table)#>
                <cftry>
					<!--- Clean Up XML Doc to send theough DataMgr --->
	                <cfif findNoCase("mp_client_patches_", xmldoc.tables.table.XmlAttributes.name) EQ 1>
	
	                    <cfset var arrDelNodes = XmlSearch(xmldoc,"//tables/removerows") />
	                    <cfif ArrayLen(arrDelNodes) GTE 1>
	                        <cfif #IsXmlNode(xmldoc.tables.removerows)#>
	                            <cfset aTable = #xmldoc.tables.removerows.XmlAttributes.table#>
	
	                            <cfset bCol = #xmldoc.tables.remove.XmlAttributes.column#>
	                            <cfset bColVal = #xmldoc.tables.remove.XmlAttributes.valueEQ#>
	
	                            <cfset aCol = #xmldoc.tables.removerows.XmlAttributes.column#>
	                            <cfset aColVal = #xmldoc.tables.removerows.XmlAttributes.value#>
	
	
	                            <cfquery datasource="#this.ds#" name="qDel" result="res">
	                                Delete from #aTable#
	                                Where
	                                #bCol# = <cfqueryparam value="#bColVal#">
	                                AND
	                                #aCol# = <cfqueryparam value="#aColVal#">
	                            </cfquery>
	                            <cfreturn True>
	                        <cfelse>
	                            <cfreturn False>
	                        </cfif>
	                    </cfif>
	
	                    <cfset var arrNodes = XmlSearch(xmldoc,"//tables/remove") />
	                    <cfif ArrayLen(arrNodes) GTE 1>
	                        <cfif #IsXmlNode(xmldoc.tables.remove)#>
	                            <cfset aTable = #xmldoc.tables.data.XmlAttributes.table#>
	                            <cfset aCuuid = "NA">
	                            <cfif isDefined("xmldoc.tables.data.row[1].field[1].XmlAttributes.name")>
	                                <cfif #xmldoc.tables.data.row[1].field[1].XmlAttributes.name# EQ "cuuid">
	                                    <cfset aCuuid = #xmldoc.tables.data.row[1].field[1].XmlAttributes.value#>
	                                </cfif>
	                            </cfif>

	                            <cfset xmldoc.tables.remove.XmlAttributes.column = "cuuid">
	                            <cfset xmldoc.tables.remove.XmlAttributes.valueEQ = #aCuuid#>
	                        </cfif>
	                    </cfif>
	                    <cfset theXML = ToString(xmlDoc)>
	                </cfif>
			
					<cfset srvRoot = CreateObject("java","java.lang.System").getProperties() />
                    <cfset dirP = #srvRoot.jetty.home# & "/InvData">
                    <cfif DirectoryExists(dirP) EQ False>
                        <cfset tmpD = DirectoryCreate(dirP)>
                    </cfif>

                    <cfset dirDebug = #srvRoot.jetty.home# &"/InvData/Debug">
                    <cfif DirectoryExists(dirDebug) EQ False>
                        <cfset tmpDebug = DirectoryCreate(dirDebug)>
                    </cfif>

                    <cfset dirP = #srvRoot.jetty.home# &"/InvData/Files">
                    <cfif DirectoryExists(dirP) EQ False>
                        <cfset tmpD = DirectoryCreate(dirP)>
                    </cfif>

                    <cfset dirF = #dirP# & "/mpi_" & #CreateUuid()# & ".txt">
                    <cffile action="write" NAMECONFLICT="makeunique" file="#dirF#" output="#theXML#">
                    <cfreturn true>

                    <cfcatch type="any">
						<cfinvoke component="ws_logger" method="LogEvent">
		                    <cfinvokeargument name="aEventType" value="Error">
		                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
		                    <cfinvokeargument name="aEvent" value="[ProcessXML][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
		                </cfinvoke>
                        <cfreturn false>
                    </cfcatch>
                </cftry>
            <!--- </cfif> --->
        </cfif>
    </cffunction>

<!--- #################################################### --->
<!--- GetScanList		 		 						   --->
<!--- #################################################### --->
	<cffunction name="GetScanList" access="remote" returntype="any" output="yes">
    	<cfargument name="encode" required="no" default="true" type="string">
        <cfargument name="state" required="no" default="all" type="string">
        <cfargument name="active" required="no" default="1" type="string">

        <cftry>
        	<cfset var myObj = CreateObject("component","gov.llnl.PatchScanManifest").init(this.ds)>
			<cfset var root = myObj.createScanListXML(arguments.state,arguments.active)>

	        <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetScanList][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
                <cfxml variable="root">
                    <root>
                        <patches></patches>
                    </root>
                </cfxml>
            </cfcatch>
        </cftry>

		<cfset var datax = "">
		<cfset var data = "">
		<cfif #arguments.encode# EQ "true">
        	<cfset datax = #ToBase64(ToString(root))#>
            <cfset data = #ToBinary(datax)#>
        <cfelse>
        	<cfset data = #ToString(root)#>
        </cfif>
        <cfreturn data>
    </cffunction>

    <!--- Helper to GetScanList --->
    <cffunction name="GetScanCriteria" access="public" returntype="query" output="no">
    	<cfargument name="id" required="yes">
    	<cftry>
            <cfquery datasource="#this.ds#" name="qGetPatchCriteria">
                select *
                from mp_patches_criteria
            	Where puuid = '#arguments.id#'
                Order By type_order Asc
            </cfquery>
            <cfcatch type="any">
            <cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Error">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[GetScanList][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#">
            </cfinvoke>
            </cfcatch>
        </cftry>

    	<cfreturn qGetPatchCriteria>
    </cffunction>

<!--- END Client WebServices Methods --->
<!--- **************************************************************************************** --->
<!--- Start MPLoader WebServices Methods --->

	<!--- Private Function called by AddSWUServerPatches function --->
    <cffunction name="ApplePatchExists" access="public" returntype="boolean" output="no">
    	<cfargument name="theKey">
        <cfargument name="thePName">

    	<cfquery datasource="#this.ds#" name="qGet">
            Select akey, patchname
            From apple_patches
            Where akey = <cfqueryparam value="#theKey#"> AND patchname = <cfqueryparam value="#thePName#">
        </cfquery>

        <cfif qGet.RecordCount EQ 0>
        	<cfreturn False>
        <cfelse>
        	<cfreturn True>
        </cfif>
    </cffunction>

    <cffunction name="AddSWUServerPatches" access="remote" returnType="boolean" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">

		<cfset var vTheXML = ToString(ToBinary(arguments.theXmlFile))>

		<!--- Parse the XML File--->
        <cftry>
			<cfset var xmldoc = XmlParse(vTheXML)>
         	<cfcatch type="any">
				<!--- the message to display --->
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddSWUServerPatches][XmlParse]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
                <cfreturn False>
        	</cfcatch>
        </cftry>

		<cfset var XMLRoot = xmldoc.XmlRoot>
        <cfset var Patch_Length = arraylen(XMLRoot.item)>
        <cfset var patchesAdded = 0>

        <cfquery datasource="#this.ds#" name="qPut_Del">
            Delete from apple_patches_real
        </cfquery>

        <!--- Loop through the patches in the xml and insert them into the database --->
        <cfloop index="itms" from="1" to="#Patch_Length#">
			<cfoutput>
				<cfset vKey = #XMLRoot.item[itms].key.xmltext#>
                <cfset vPostdate = #XMLRoot.item[itms].postdate.xmltext#>
                <cfset vVersion = #XMLRoot.item[itms].version.xmltext#>
                <cfset vRestartaction = #XMLRoot.item[itms].restartaction.xmltext#>
                <cfset vPatchname = #XMLRoot.item[itms].patchname.xmltext#>
                <cfset vSupatchname = #XMLRoot.item[itms].supatchname.xmltext#>
                <cfset vTitle = #XMLRoot.item[itms].title.xmltext#>
                <cfset vDescription = #XMLRoot.item[itms].description.XmlCdata#>
                <cfset vDescription64 = #XMLRoot.item[itms].description64.xmltext#>

                <cfinvoke method="ApplePatchExists" returnVariable="res">
   					<cfinvokeargument name="theKey" value="#vKey#">
                    <cfinvokeargument name="thePName" value="#vPatchname#">
				</cfinvoke>

                <!--- Always Insert --->
                <cfquery datasource="#this.ds#" name="qPut_Real">
                    Insert Into apple_patches_real (akey, postdate, version, restartaction, patchname, supatchname, title, description, description64)
                    Values (<cfqueryparam value="#vKey#">, #CreateODBCDateTime(vPostdate)#, <cfqueryparam value="#vVersion#">, <cfqueryparam value="#vRestartaction#">, <cfqueryparam value="#vPatchname#">, <cfqueryparam value="#vSupatchname#">, <cfqueryparam value="#vTitle#">, <cfqueryparam value="#vDescription#">, <cfqueryparam value="#vDescription64#">)
                </cfquery>

                <cftry>
                	<cfif #res# EQ False>
                        <cfquery datasource="#this.ds#" name="qPut">
                            Insert Into apple_patches (akey, postdate, version, restartaction, patchname, supatchname, title, description, description64)
                            Values (<cfqueryparam value="#vKey#">, #CreateODBCDateTime(vPostdate)#, <cfqueryparam value="#vVersion#">, <cfqueryparam value="#vRestartaction#">, <cfqueryparam value="#vPatchname#">, <cfqueryparam value="#vSupatchname#">, <cfqueryparam value="#vTitle#">, <cfqueryparam value="#vDescription#">, <cfqueryparam value="#vDescription64#">)
                        </cfquery>
                        <cfquery datasource="#this.ds#" name="qPut_Real">
                            Insert Into apple_patches_real (akey, postdate, version, restartaction, patchname, supatchname, title, description, description64)
                            Values (<cfqueryparam value="#vKey#">, #CreateODBCDateTime(vPostdate)#, <cfqueryparam value="#vVersion#">, <cfqueryparam value="#vRestartaction#">, <cfqueryparam value="#vPatchname#">, <cfqueryparam value="#vSupatchname#">, <cfqueryparam value="#vTitle#">, <cfqueryparam value="#vDescription#">, <cfqueryparam value="#vDescription64#">)
                        </cfquery>
                        <cfset patchesAdded = patchesAdded + 1>
                    </cfif>
                    <cfcatch type = "Database">
                        <cfinvoke component="ws_logger" method="LogEvent">
                            <cfinvokeargument name="aEventType" value="Error">
                            <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                            <cfinvokeargument name="aEvent" value="[AddSWUServerPatches][Insert]: #cfcatch.Detail# -- #cfcatch.Message#">
                        </cfinvoke>
                   </cfcatch>
               </cftry>
            </cfoutput>
        </cfloop>

        <cfinvoke component="ws_logger" method="LogEvent">
            <cfinvokeargument name="aEventType" value="Info">
            <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
            <cfinvokeargument name="aEvent" value="[AddSWUServerPatches]: Number of patches added to apple patches database = #patchesAdded#">
        </cfinvoke>
        <cfreturn True>
	</cffunction>

<!--- END MPLoader WebServices Methods --->
<!--- **************************************************************************************** --->
<!--- Start AVDefs WebServices Methods --->
 	<cffunction name="AddSavAvDefs" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">

        <cfset var vTheXML = #Trim(arguments.theXmlFile)#>
        <cfset vTheXML = ToString(ToBinary(vTheXML))>

		<!--- Parse the XML File--->
        <cftry>
			<cfset var xmldoc = XmlParse(vTheXML)>
         	<cfcatch type="any">
				<!--- the message to display --->
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddSavAvDefs][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn False>
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
                    <cfreturn False>
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
                <cfreturn False>
           </cfcatch>
           </cftry>
        </cfoutput>

        <cfreturn True>
	</cffunction>

    <cffunction name="AddClientSAVData" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">

        <cfset var vTheXML = #Trim(arguments.theXmlFile)#>
        <cfset vTheXML = ToString(ToBinary(vTheXML))>
		<!--- Parse the XML File--->
        <cftry>
			<cfset var xmldoc = XmlParse(vTheXML)>
         	<cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[AddClientSAVData][XmlParse]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cfreturn False>
        	</cfcatch>
        </cftry>

		<cfparam name="l_CUUID" default="NA" />
		<cfparam name="l_CFBundleExecutable" default="NA" />
		<cfparam name="l_NSBundleResolvedPath" default="NA" />
		<cfparam name="l_CFBundleVersion" default="NA" />
		<cfparam name="l_CFBundleShortVersionString" default="NA" />
        <cfparam name="l_LastFullScan" default="NA" />
		<cfparam name="l_DefsDate" default="NA" />


        <cfset XMLRoot = xmldoc.XmlRoot>
        <cfset l_CUUID = trim(XMLRoot.cuuid.xmltext)>
        <cfif IsDefined("XMLRoot.CFBundleExecutable")>
        	<cfset l_CFBundleExecutable = trim(XMLRoot.CFBundleExecutable.xmltext)>
        </cfif>
        <cfif IsDefined("XMLRoot.NSBundleResolvedPath")>
        	<cfset l_NSBundleResolvedPath = trim(XMLRoot.NSBundleResolvedPath.xmltext)>
        </cfif>
        <cfif IsDefined("XMLRoot.CFBundleVersion")>
        	<cfset l_CFBundleVersion = trim(XMLRoot.CFBundleVersion.xmltext)>
        </cfif>
        <cfif IsDefined("XMLRoot.CFBundleShortVersionString")>
        	<cfset l_CFBundleShortVersionString = trim(XMLRoot.CFBundleShortVersionString.xmltext)>
        </cfif>
        <cfif IsDefined("XMLRoot.DefsDate")>
        	<cfset l_DefsDate = trim(XMLRoot.DefsDate.xmltext)>
        </cfif>

        <!--- Client Data Does not Exist, if there remove it --->
        <cfif l_CFBundleExecutable EQ "NA" AND l_CFBundleVersion EQ "NA">
        	<cfquery datasource="#this.ds#" name="qGetClient">
                Select cuuid From savav_info
                Where cuuid = <cfqueryparam value="#trim(l_CUUID)#">
            </cfquery>

        	<cfif qGetClient.RecordCount GTE 1>
                <cfquery datasource="#this.ds#" name="qRmClient">
                    Delete From savav_info
                    Where cuuid = <cfqueryparam value="#trim(l_CUUID)#">
                </cfquery>
        	</cfif>
        	<cfreturn True>
        </cfif>

        <!--- Query the table to see if we need a update or a insert --->
        <cfquery datasource="#this.ds#" name="qGet">
            Select cuuid From savav_info
            Where cuuid = <cfqueryparam value="#trim(l_CUUID)#">
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
                    (<cfqueryparam value="#l_CUUID#">,
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
                <cfreturn False>
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
                <cfreturn False>
            </cfcatch>
            </cftry>
        </cfif>

        <cfreturn True>
	</cffunction>

    <cffunction name="GetSavAvDefsDate" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">

        <cfquery datasource="#this.ds#" name="qGet">
        	Select defdate from savav_defs
            Where arch = <cfqueryparam value="#Trim(arguments.theArch)#">
            AND current = 'YES'
        </cfquery>

        <cfif qGet.RecordCount EQ 1>
        	<cfreturn "#qGet.defdate#">
        <cfelse>
        	<cfreturn "NA">
        </cfif>
    </cffunction>

    <cffunction name="GetSavAvDefsFile" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">

        <cfquery datasource="#this.ds#" name="qGet">
        	Select file from savav_defs
            Where arch = <cfqueryparam value="#Trim(arguments.theArch)#">
            AND current = 'YES'
        </cfquery>

        <cfif qGet.RecordCount EQ 1>
        	<cfreturn "#qGet.file#">
        <cfelse>
        	<cfreturn "NA">
        </cfif>
    </cffunction>
<!--- END AVDefs WebServices Methods --->

<!--- **************************************************************************************** --->
<!--- Start SWUPD (Self Patch) WebServices Methods --->
	<!--- New MacPatch 1.8.9 --->
	<!--- Added the clientVer argument --->
	<cffunction name="GetAgentUpdates" access="remote" returntype="string" output="no">
		<cfargument name="cuuid" required="no">
		<cfargument name="agentVersion">
		<cfargument name="agentBuild">
		<cfargument name="agentFramework">

		<cftry>
            <cfquery datasource="#this.ds#" name="qGetLatestVersion" maxrows="1">
            	Select agent_ver as agent_version, version, framework as agent_framework, build as agent_build,
                pkg_Hash, pkg_Url, puuid, pkg_name, osver
                From mp_client_agents
                Where type = 'app'
                AND active = '1'
                ORDER BY
                INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
				INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC
            </cfquery>
            <cfcatch type="any">
	            <cfinvoke component="ws_logger" method="LogEvent">
	                <cfinvokeargument name="aEventType" value="Error">
	                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetAgentUpdates]: #cfcatch.Detail# -- #cfcatch.Message#">
	            </cfinvoke>
            </cfcatch>
        </cftry>

        <cfset var count = 0>
		<cfset var agentVerReq = "10.5.8">
        <cfif qGetLatestVersion.RecordCount EQ 1>
			<cfset agentVerReq = #replacenocase(qGetLatestVersion.osver,"+","", "All")#>
			<cfoutput query="qGetLatestVersion">
				<cfif versionCompare(agent_version,agentVersion) NEQ -1>
	                <cfif versionCompare(agent_version,arguments.agentVersion) EQ 1>
	                    <cfset count = count + 1>
	                </cfif>
					<cfif versionCompare(agent_build,arguments.agentBuild) EQ 1 AND #arguments.agentBuild# NEQ "0">
	                    <cfset count = count + 1>
	                </cfif>
					<cfif versionCompare(agent_framework,arguments.agentFramework) EQ 1 AND #arguments.agentFramework# NEQ "0">
	                    <cfset count = count + 1>
	                </cfif>
				</cfif>
            </cfoutput>
		<cfelse>
			<cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Error">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[GetSelfUpdates][qGetLatestVersion][#arguments.cuuid#]: Found #qGetLatestVersion.RecordCount# records. Should only find 1.">
            </cfinvoke>
        </cfif>

		<!--- If a Version Number is Higher check filter --->
		<cfif count GTE 1>
	        <cfif Len(Trim(arguments.cuuid)) EQ 0>
	        	<!--- No CUUID Info --->
	        	<cfset count = 0>
	        <cfelse>
	        	<!--- CUUID is found --->
	            <cfquery datasource="#this.ds#" name="qGetClientGroup">
	            	Select cuuid, ipaddr, hostname, Domain, ostype, osver
	                From mp_clients_view
	                Where cuuid = <cfqueryparam value="#arguments.cuuid#">
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

		<cfsavecontent variable="thePlist">
		<cfprocessingdirective suppressWhiteSpace="true">
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            	<key>updateAvailable</key>
				<cfif count GTE 1>
				<true/>
				<key>SelfUpdate</key>
				<dict>
				<cfoutput query="qGetLatestVersion">
				<cfloop list="#qGetLatestVersion.ColumnList#" index="column">
					<key>#column#</key>
					<string><cfif len(Evaluate(column)) GTE 1>#Trim(Evaluate(column))#<cfelse>Null</cfif></string>
				</cfloop>
				</cfoutput>
				</dict>
				<cfelse>
				<false/>
				</cfif>
            </dict>
            </plist>
		</cfprocessingdirective>
        </cfsavecontent>
		<cfset data64 = #toBase64(toString(thePlist))#>
		<cfreturn #data64#>
	</cffunction>

    <cffunction name="GetAgentUpdaterUpdates" access="remote" returntype="any" output="no">
    	<!--- New MacPatch 2.0 --->
		<cfargument name="agentUp2DateVer">
        <cfargument name="cuuid">

		<cftry>
            <cfquery datasource="#this.ds#" name="qGetLatestVersion">
            	Select agent_ver as agent_version, version, framework as agent_framework, build as agent_build,
                pkg_Hash, pkg_Url, puuid, pkg_name, osver
                From mp_client_agents
                Where type = 'update'
                AND active = '1'
                ORDER BY
                INET_ATON(SUBSTRING_INDEX(CONCAT(agent_ver,'.0.0.0.0.0'),'.',6)) DESC,
				INET_ATON(SUBSTRING_INDEX(CONCAT(build,'.0.0.0.0.0'),'.',6)) DESC
            </cfquery>

            <cfcatch type="any">
                <cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[GetAgentUpdaterUpdates][qGetLatestVersion]: #cfcatch.Detail# -- #cfcatch.Message#">
                </cfinvoke>
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
	        <cfif Len(Trim(arguments.cuuid)) EQ 0>
	        	<!--- No CUUID Info --->
	        	<cfset count = 0>
	        <cfelse>
	        	<!--- CUUID is found --->
	            <cfquery datasource="#this.ds#" name="qGetClientGroup">
	            	Select cuuid, ipaddr, hostname, Domain, ostype, osver
	                From mp_clients_view
	                Where cuuid = <cfqueryparam value="#arguments.cuuid#">
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

        <cfsavecontent variable="thePlist">
		<cfprocessingdirective suppressWhiteSpace="true">
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            	<key>updateAvailable</key>
				<cfif count GTE 1>
				<true/>
				<key>SelfUpdate</key>
				<dict>
				<cfoutput query="qGetLatestVersion">
				<cfloop list="#qGetLatestVersion.ColumnList#" index="column">
					<key>#column#</key>
					<string><cfif len(Evaluate(column)) GTE 1>#Trim(Evaluate(column))#<cfelse>Null</cfif></string>
				</cfloop>
				</cfoutput>
				</dict>
				<cfelse>
				<false/>
				</cfif>
            </dict>
            </plist>
		</cfprocessingdirective>
        </cfsavecontent>
		<cfset data64 = #toBase64(toString(thePlist))#>
		<cfreturn #data64#>
	</cffunction>

<!--- #################################################### --->
<!--- HELPER - versionCompare 		 		 			   --->
<!--- #################################################### --->
    <cffunction name="versionCompare" access="public" returntype="numeric" output="no">
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

	<cffunction name="SelfUpdateFilter" access="public" returntype="string" output="no">
		<cfargument name="aType">
		<cftry>
			<cfquery datasource="#this.ds#" name="qGet">
				Select attribute, attribute_oper, attribute_filter, attribute_condition
                From mp_client_agents_filters
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
			<cfinvoke component="ws_logger" method="LogEvent">
                <cfinvokeargument name="aEventType" value="Error">
                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                <cfinvokeargument name="aEvent" value="[SelfUpdateFilter][Set Result to No]: #cfcatch.Detail#, #cfcatch.message#, #cfcatch.ExtendedInfo#">
            </cfinvoke>
			<cfset result = """All"" EQ ""NO""">
		</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>
</cfcomponent>
