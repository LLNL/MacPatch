<!--- **************************************************************************************** --->
<!--- **************************************************************************************** --->
<!--- **************************************************************************************** --->
<!--- **************************************************************************************** --->

<!--- All For MySQL --->
<!--- MacPatch Version 1.8 WebServices --->
<!--- Updated to support MacPatch Client v1.8.4 --->
<cfcomponent>
	<!--- Logging Info --->
	<cfset this.ds = "mpds">

	<cffunction name="init" returntype="MPWSController" output="no">
		<cfreturn this>
	</cffunction>

<!--- **************************************************************************************** --->
<!--- Begin Client WebServices Methods --->
    <cffunction name="ClientCheckInXML" access="remote" returntype="boolean" output="no">
        <cfargument name="theEncXML">
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[ClientCheckInXML]: #CGI.REMOTE_HOST#">
        <cfreturn False>
    </cffunction>
<!--- #################################################### --->
<!--- GetAppHash 										   --->
<!--- #################################################### --->
    <cffunction name="GetAppHash" access="remote" returntype="string" output="no">
        <cfargument name="app">
        <cfargument name="ver">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetAppHash]: #CGI.REMOTE_HOST#">
        <cfreturn "">
    </cffunction>
<!--- #################################################### --->
<!--- GetPatchGroupPatches 								   --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatches" access="remote" returntype="binary" output="no">
        <cfargument name="PatchGroup" required="yes">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetPatchGroupPatches]: #CGI.REMOTE_HOST#">
        <cfreturn "">
	</cffunction>

<!--- #################################################### --->
<!--- GetPatchGroupPatchesExtended - New For 1.8.6 				   --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatchesExtended" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetPatchGroupPatchesExtended]: #CGI.REMOTE_HOST#">
        <cfreturn "">
	</cffunction>
<!--- #################################################### --->
<!--- AddPatchesXML				 						   --->
<!--- Log to file           	 						   --->
<!--- #################################################### --->
    <cffunction name="AddPatchesXML" access="remote" returnType="boolean" output="no">
        <cfargument name="vXml">

		<cflog type="Error" file="MPWSController_CleanUp" text="[AddPatchesXML]: #CGI.REMOTE_HOST#">
		<cfreturn False>
	</cffunction>
<!--- #################################################### --->
<!--- GetLastCheckIn	 		 						   --->
<!--- #################################################### --->
    <cffunction name="GetLastCheckIn" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="cuuid">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetLastCheckIn]: #CGI.REMOTE_HOST#">
        <cfreturn "NA">
    </cffunction>
<!--- #################################################### --->
<!--- GetAsusCatalogURLs 		 						   --->
<!--- #################################################### --->
	<cffunction name="GetAsusCatalogURLsRaw" access="remote" returntype="any" output="no">
		<!--- New For v1.8 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetAsusCatalogURLsRaw]: #CGI.REMOTE_HOST#">
        <cfreturn "NA">
	</cffunction>
    
	<cffunction name="GetAsusCatalogURLs" access="remote" returntype="any" output="no">
    	<!--- New For v1.8 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetAsusCatalogURLs]: #CGI.REMOTE_HOST#">
        <cfreturn "NA">
	</cffunction>
<!--- #################################################### --->
<!--- PreProcessXML                                        --->
<!--- #################################################### --->
    <!--- New for 1.8.5 --->
    <cffunction name="PreProcessXML" access="remote" returntype="boolean" output="no">
        <cfargument name="cuuid">
        <cfargument name="table">
        <cfargument name="action">
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[PreProcessXML]: #CGI.REMOTE_HOST#">
        <cfreturn false>
    </cffunction>
<!--- #################################################### --->
<!--- ProcessXML                                           --->
<!--- #################################################### --->
    <cffunction name="ProcessXML" access="remote" returntype="boolean" output="no">
        <cfargument name="encodedXML">

        <cflog type="Error" file="MPWSController_CleanUp" text="[ProcessXML]: #CGI.REMOTE_HOST#">
        <cfreturn false>
    </cffunction>
<!--- #################################################### --->
<!--- GetScanList		 			   					   --->
<!--- #################################################### --->
    <cffunction name="GetScanList" access="remote" returntype="any" output="yes">
    	<cfargument name="encode" required="no" default="true" type="string">
        <cfargument name="state" required="no" default="all" type="string">
        <cfargument name="active" required="no" default="1" type="string">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetScanList]: #CGI.REMOTE_HOST#">
        <cfreturn false>
    </cffunction>
<!--- #################################################### --->
<!--- ClientErrors                                         --->
<!--- #################################################### --->
    <cffunction name="ClientErrors" access="remote" returntype="boolean" output="no">
        <cfargument name="cuuid">
        <cfargument name="error">
		<cfset var theErr = ToString(ToBinary(arguments.error))>

        <cflog type="Error" file="MPWSController_CleanUp" text="[ClientErrors]: #CGI.REMOTE_HOST#">
        <cfreturn false>
    </cffunction>
    
<!--- #################################################### --->
<!--- AV Info                                              --->
<!--- #################################################### --->    
    <cffunction name="AddClientSAVData" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[AddClientSAVData]: #CGI.REMOTE_HOST#">
        <cfreturn false>
	</cffunction>

    <cffunction name="GetSavAvDefsDate" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetSavAvDefsDate]: #CGI.REMOTE_HOST#">
        <cfreturn false>
    </cffunction>

    <cffunction name="GetSavAvDefsFile" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">

        <cflog type="Error" file="MPWSController_CleanUp" text="[GetSavAvDefsFile]: #CGI.REMOTE_HOST#">
        <cfreturn false>
    </cffunction>
    
<!--- END Client WebServices Methods --->
<!--- **************************************************************************************** --->

<!--- **************************************************************************************** --->
<!--- Start MPLoader WebServices Methods --->
<!--- **************************************************************************************** --->
	
	<!--- Private Function called by AddSWUServerPatches function --->
    <cffunction name="ApplePatchExists" access="public" returntype="boolean" output="no">
    	<cfargument name="theKey">
        <cfargument name="thePName">
    	<cfquery datasource="#this.ds#" name="qGet" >
            Select akey, patchname
            From apple_patches
            Where akey = <cfqueryparam value="#theKey#">
        </cfquery>
        <cfif qGet.RecordCount EQ 0>
        	<cfreturn False>
        <cfelse>
        	<cfreturn True>
        </cfif>
    </cffunction>

    <cffunction name="AddSWUServerPatches" access="remote" returnType="boolean" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile" required="true">

		<cflog type="Error" file="MPWSController_CleanUp" text="[AddSWUServerPatches]: #CGI.REMOTE_HOST#">
        
		<cfset var vTheXML = ToString(ToBinary(arguments.theXmlFile))>
        <!--- <cflog type="Error" file="ApplePatchExists" text="[ApplePatchExists] -- vTheXML, #vTheXML#"> --->
		<!--- Parse the XML File--->
        <cftry>
			<cfset xmldoc = XmlParse(vTheXML)>
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

		<cfset var vKey = "">
        <cfset var vPostdate = "">
        <cfset var vVersion = "">
        <cfset var vRestartaction = "">
        <cfset var vPatchname = "">
        <cfset var vSupatchname = "">
        <cfset var vTitle = "">
        <cfset var vDescription = "">
        <cfset var vDescription64 = "">

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
					<cfelse>
						<cfquery datasource="#this.ds#" name="qUpdate">
			                UPDATE apple_patches
			                SET postdate =		#CreateODBCDateTime(vPostdate)#,
			                    version = 		<cfqueryparam value="#vVersion#">,
			                    restartaction = <cfqueryparam value="#vRestartaction#">,
			                    patchname =  	<cfqueryparam value="#vPatchname#">,
			                    supatchname =  	<cfqueryparam value="#vSupatchname#">,
			                    title = 		<cfqueryparam value="#vTitle#">,
			                    description = 	<cfqueryparam value="#vDescription#">,
			                    description64 = <cfqueryparam value="#vDescription64#">
			                Where akey = '#vKey#'
			            </cfquery>	
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
<!--- **************************************************************************************** --->
<!--- END MPLoader WebServices Methods --->
<!--- **************************************************************************************** --->

<!--- **************************************************************************************** --->
<!--- Start AVDefs WebServices Methods --->
<!--- **************************************************************************************** --->

 	<cffunction name="AddSavAvDefs" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[AddSavAvDefs]: #CGI.REMOTE_HOST#">

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
<!--- END AVDefs WebServices Methods --->

<!--- **************************************************************************************** --->
<!--- Start SWUPD (Self Patch) WebServices Methods --->
	
	<cffunction name="GetAgentUpdates" access="remote" returntype="string" output="no">
		<cfargument name="swuaiVer">
        <cfargument name="swuadVer">
        <cfargument name="MPLogoutVer" required="no" default="0">
        <cfargument name="MPRebootVer" required="no" default="0">
        <cfargument name="cuuid" required="no">
		<cfargument name="clientVer" required="no" default="0">
		
		<cflog type="Error" file="MPWSController_CleanUp" text="[GetAgentUpdates]: #CGI.REMOTE_HOST#">
        <cfreturn "">
	</cffunction>
	
<!--- #################################################### --->
<!--- HELPER - versionCompare 		 		 			   --->
<!--- #################################################### --->
    <cffunction name="versionCompare" access="public" returntype="numeric" output="no">
		<!--- It returns 1 when argument 1 is greater, -1 when argument 2 is greater, and 0 when they are exact matches. --->
        <cfargument name="leftVersion" required="yes" default="0">
        <cfargument name="rightVersion" required="yes" default="0">
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[versionCompare]: #CGI.REMOTE_HOST#">

		<cfset var leftOne = Trim(arguments.leftVersion)>
		<cfset var rightOne = Trim(arguments.rightVersion)>

        <cfset var len1 = listLen(leftOne, '.')>
        <cfset var len2 = listLen(rightOne, '.')>
        <cfset var piece1 = "">
        <cfset var piece2 = "">

        <cfif len1 GT len2>
            <cfset rightOne = rightOne & repeatString('.0', len1-len2)>
        <cfelse>
            <cfset leftOne = leftOne & repeatString('.0', len2-len1)>
        </cfif>

        <cfloop index = "i" from="1" to=#listLen(leftOne, '.')#>
            <cfset piece1 = listGetAt(leftOne, i, '.')>
            <cfset piece2 = listGetAt(rightOne, i, '.')>

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
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[SelfUpdateFilter]: #CGI.REMOTE_HOST#">
        
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
<!--- END SWUPD WebServices Methods --->
<!--- **************************************************************************************** --->

<!--- Start Misc Functions --->
	<cffunction name="PostProxyServerData" access="remote" returnType="any" output="no">
		<cfargument name="proxyData">
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[PostProxyServerData]: #CGI.REMOTE_HOST#">

		<cfset var xData = "">
		<cftry>
			<cfquery name="qGetKey" datasource="#this.ds#">
				Select proxy_key From mp_proxy_key
				Where type = '1'
			</cfquery>
			<cflog text="#xData#">
			<cfset xData = decrypt(arguments.proxyData, qGetKey.proxy_key)>
			<cflog text="#xData#">
			<cfcatch type="any">
				<cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[PostProxyServerData][qGetKey]: #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cflog text="[PostProxyServerData][qGetKey]: #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
                <cfreturn False>
			</cfcatch>
		</cftry>

		<cftry>
			<cfquery name="qHasKey" datasource="#this.ds#">
				Select 1 From mp_proxy_key
				Where type = '0'
			</cfquery>
			<cfcatch type="any">
				<cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[PostProxyServerData][qHasKey]: #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cflog text="[PostProxyServerData][qHasKey]: #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
                <cfreturn False>
			</cfcatch>
		</cftry>

		<cftry>
			<cfif qHasKey.RecordCount EQ "0">
				<cfquery name="qSetKey" datasource="#this.ds#">
					Insert Into mp_proxy_key (proxy_key, type)
					Values (<cfqueryparam value="#xData#">,<cfqueryparam value="0">)
				</cfquery>
			<cfelse>
				<cfquery name="qSetKey" datasource="#this.ds#">
					UPDATE mp_proxy_key
					SET proxy_key = <cfqueryparam value="#xData#">
					Where type = '0'
				</cfquery>
			</cfif>
			<cfcatch type="any">
				<cfinvoke component="ws_logger" method="LogEvent">
                    <cfinvokeargument name="aEventType" value="Error">
                    <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
                    <cfinvokeargument name="aEvent" value="[PostProxyServerData][qSetKey]: #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
                </cfinvoke>
                <cflog text="[PostProxyServerData][qSetKey]: #cfcatch.Detail# -- #cfcatch.Message# -- #cfcatch.ExtendedInfo#">
                <cfreturn False>
			</cfcatch>
		</cftry>

		<cfreturn true>
	</cffunction>

	<!--- --------------------------------------------------------------------------------------- ---
        Blog Entry:
        Deleting XML Node Arrays From A ColdFusion XML Document
        Code Snippet:        2
        Author:
        Ben Nadel / Kinky Solutions
        Link:
        http://www.bennadel.com/index.cfm?dax=blog:1236.view
        Date Posted:
        May 23, 2008 at 8:21 AM
    ---- --------------------------------------------------------------------------------------- --->

   <cffunction name="XmlDeleteNodes" access="public" returntype="void" output="false" hint="I remove a node or an array of nodes from the given XML document.">
        <!--- Define arugments. --->
        <cfargument name="XmlDocument" type="any" required="true" hint="I am a ColdFusion XML document object." />
        <cfargument name="Nodes" type="any" required="false" hint="I am the node or an array of nodes being removed from the given document." />
        
        <cflog type="Error" file="MPWSController_CleanUp" text="[XmlDeleteNodes]: #CGI.REMOTE_HOST#">

        <!--- Define the local scope. --->
        <cfset var LOCAL = StructNew() />
        <cfif NOT IsArray( ARGUMENTS.Nodes )>
            <cfset LOCAL.Node = ARGUMENTS.Nodes />
            <cfset ARGUMENTS.Nodes = ArrayNew(1) />
            <cfset ARGUMENTS.Nodes = LOCAL.Node />
        </cfif>

        <cfloop index="LOCAL.NodeIndex" from="#ArrayLen( ARGUMENTS.Nodes )#" to="1" step="-1">
            <!--- Get a node short-hand. --->
            <cfset LOCAL.Node = ARGUMENTS.Nodes[ LOCAL.NodeIndex ] />
            <cfif StructKeyExists( LOCAL.Node, "XmlChildren" )>
                <!--- Set delet flag. --->
                <cfset LOCAL.Node.XmlAttributes[ "delete-me-flag" ] = "true" />
            <cfelse>
                <cfset ArrayDeleteAt(ARGUMENTS.Nodes,LOCAL.NodeIndex) />
            </cfif>
        </cfloop>

        <cfloop index="LOCAL.Node" array="#ARGUMENTS.Nodes#">
            <!--- Get the parent node. --->
            <cfset LOCAL.ParentNodes = XmlSearch( LOCAL.Node, "../" ) />

            <cfif (ArrayLen( LOCAL.ParentNodes ) AND StructKeyExists( LOCAL.ParentNodes[ 1 ], "XmlChildren" ))>
                <!--- Get the parent node short-hand. --->
                <cfset LOCAL.ParentNode = LOCAL.ParentNodes[ 1 ] />
                <cfloop index="LOCAL.NodeIndex" from="#ArrayLen( LOCAL.ParentNode.XmlChildren )#" to="1" step="-1">
                    <!--- Get the current node shorthand. --->
                    <cfset LOCAL.Node = LOCAL.ParentNode.XmlChildren[ LOCAL.NodeIndex ] />
                    <cfif StructKeyExists( LOCAL.Node.XmlAttributes, "delete-me-flag" )>
                        <!--- Delete this node from parent. --->
                        <cfset ArrayDeleteAt(LOCAL.ParentNode.XmlChildren,LOCAL.NodeIndex) />
                        <cfset StructDelete(LOCAL.Node.XmlAttributes,"delete-me-flag") />
                    </cfif>
                </cfloop>
            </cfif>
        </cfloop>

        <!--- Return out. --->
        <cfreturn />
    </cffunction>
</cfcomponent>
