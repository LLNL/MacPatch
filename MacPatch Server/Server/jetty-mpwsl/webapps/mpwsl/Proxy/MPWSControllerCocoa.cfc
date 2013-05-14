<!--- **************************************************************************************** --->
<!---
		MPWSControllerCocoa.cfc Proxy File
		MacPatch Version 1.8.6
		Version 1.0
		Rev: 1
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfparam name="mpDBSource" default="mpds">
	<cfparam name="logFile" default="MPWSControllerCocoa">
	<cfparam name="wsURL" default="https://"&#srvconf.settings.proxyserver.primaryServer#&"/MPWSControllerCocoa.cfc?wsdl">

<!--- **************************************************************************************** --->
<!--- Begin Client WebServices Methods --->

<!--- #################################################### --->
<!--- ClientCheckIn 									   --->
<!--- #################################################### --->
    <cffunction name="ClientCheckIn" access="remote" returntype="any" output="no">
    	<cfargument name="theData">
        <cfargument name="encoding">
		
		<cftry>
			<cfinvoke webservice="#wsURL#" method="ClientCheckIn" returnvariable="res">
	    		<cfinvokeargument name="theData" value="#arguments.theData#"/>
	    		<cfinvokeargument name="encoding" value="#arguments.encoding#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientCheckIn][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientCheckIn][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>

<!--- #################################################### --->
<!--- GetClientPatchState 								   --->
<!--- This Needs to be updated to test againts client patch group --->
<!--- #################################################### --->
	<cffunction name="ClientPatchStatus" access="remote" returntype="any" output="no">
        <cfargument name="cuuid" required="yes">
		<cftry>
			<cfinvoke webservice="#wsURL#" method="ClientPatchStatus" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientPatchStatus][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientPatchStatus][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>

<!--- #################################################### --->
<!--- GetPatchGroupPatches 								   --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatches" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">
		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetPatchGroupPatches" returnvariable="res">
	    		<cfinvokeargument name="PatchGroup" value="#arguments.PatchGroup#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetPatchGroupPatchesExtended - New For 1.8.6 		   --->
<!--- #################################################### --->   
    <cffunction name="GetPatchGroupPatchesExtended" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">
		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetPatchGroupPatchesExtended" returnvariable="res">
	    		<cfinvokeargument name="PatchGroup" value="#arguments.PatchGroup#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatchesExtended][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatchesExtended][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
	</cffunction>

<!--- #################################################### --->
<!--- AddPatchesXML				 						   --->
<!--- #################################################### --->
    <cffunction name="AddPatchesXML" access="remote" returnType="boolean" output="no">
        <cfargument name="vXml">
		<cftry>
			<cfinvoke webservice="#wsURL#" method="AddPatchesXML" returnvariable="res">
	    		<cfinvokeargument name="vXml" value="#arguments.vXml#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddPatchesXML][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddPatchesXML][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
	</cffunction>
	
<!--- #################################################### --->
<!--- UpdateInstalledPatches	 						   --->
<!--- #################################################### --->
    <!--- New for v1.8 --->
    <cffunction name="UpdateInstalledPatches" access="remote" returntype="boolean">
		<cfargument name="cuuid" required="yes">
        <cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">

        <cftry>
			<cfinvoke webservice="#wsURL#" method="UpdateInstalledPatches" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
	    		<cfinvokeargument name="patch" value="#arguments.patch#"/>
	    		<cfinvokeargument name="type" value="#arguments.type#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [UpdateInstalledPatches][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [UpdateInstalledPatches][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>
	
<!--- ######################################################### --->
<!--- AddInstalledPatches / Depricated as of 1.8 -- RM 1.8.5	--->
<!--- ######################################################### --->
    <cffunction name="AddInstalledPatches" access="remote" returntype="boolean">
		<cfargument name="patchesXML64">
		<cftry>
			<cfinvoke webservice="#wsURL#" method="AddInstalledPatches" returnvariable="res">
	    		<cfinvokeargument name="patchesXML64" value="#arguments.patchesXML64#"/>
			</cfinvoke>
			<cfreturn "#res#">
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddInstalledPatches][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddInstalledPatches][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetLastCheckIn	 		 						   --->
<!--- #################################################### --->
    <cffunction name="GetLastCheckIn" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="cuuid">
		
		<cftry>
			<cfinvoke webservice="#wsURL#" method="UpdateInstalledPatches" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetLastCheckIn][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetLastCheckIn][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>

    </cffunction>
<!--- #################################################### --->
<!--- GetAsusCatalogURLs 		 						   --->
<!--- #################################################### --->
    <cffunction name="GetAsusCatalogURLs" access="remote" returntype="any" output="no">
    	<!--- New For v1.8 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetAsusCatalogURLs" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
	    		<cfinvokeargument name="osminor" value="#arguments.osminor#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAsusCatalogURLs][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAsusCatalogURLs][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>
       
	</cffunction>

    <cffunction name="GetAsusCatalogs" access="remote" returntype="any" output="no">
    	<!--- New For v1.8.5 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

        <cftry>
			<cfinvoke webservice="#wsURL#" method="GetAsusCatalogs" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
	    		<cfinvokeargument name="osminor" value="#arguments.osminor#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAsusCatalogs][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAsusCatalogs][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>
    </cffunction>

<!--- #################################################### --->
<!--- ProcessXML                                           --->
<!--- #################################################### --->
    <cffunction name="ProcessXML" access="remote" returntype="boolean" output="no">
        <cfargument name="encodedXML">
		
		<cftry>
			<cfinvoke webservice="#wsURL#" method="ProcessXML" returnvariable="res">
	    		<cfinvokeargument name="encodedXML" value="#arguments.encodedXML#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ProcessXML][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ProcessXML][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>
	
<!--- #################################################### --->
<!--- DataMgrXML                                           --->
<!--- #################################################### --->
    <cffunction name="DataMgrXML" access="remote" returntype="boolean" output="no">
        <cfargument name="cuuid">
        <cfargument name="encodedXML">

        <cftry>
			<cfinvoke webservice="#wsURL#" method="DataMgrXML" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
	    		<cfinvokeargument name="encodedXML" value="#arguments.encodedXML#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [DataMgrXML][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [DataMgrXML][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>
	
<!--- #################################################### --->
<!--- GetScanList		 		 						   --->
<!--- #################################################### --->
    <cffunction name="GetScanList" access="remote" returntype="any" output="yes">

    	<cfargument name="encode" required="no" default="true" type="string">
        <cfargument name="state" required="no" default="all" type="string">
        <cfargument name="active" required="no" default="1" type="string">

		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetScanList" returnvariable="res">
	    		<cfinvokeargument name="encode" value="#arguments.encode#"/>
	    		<cfinvokeargument name="state" value="#arguments.state#"/>
	    		<cfinvokeargument name="active" value="#arguments.active#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetScanList][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetScanList][returnvariable]: #res#">
				<cfxml variable="root">
                    <root><patches/></root>
                </cfxml>
				<cfreturn #ToBinary(ToBase64(ToString(root)))#>
            </cfcatch>
        </cftry>
    </cffunction>

<!--- #################################################### --->
<!--- ClientErrors		 		 						   --->
<!--- #################################################### --->
    <cffunction name="ClientErrors" access="remote" returntype="boolean" output="no">
        <cfargument name="cuuid">
        <cfargument name="error">

         <cftry>
			<cfinvoke webservice="#wsURL#" method="ClientErrors" returnvariable="res">
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
	    		<cfinvokeargument name="error" value="#arguments.error#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientErrors][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientErrors][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>
		
    </cffunction>

<!--- #################################################### --->
<!--- AddClientSAVData			 						   --->
<!--- #################################################### ---> 	
    <cffunction name="AddClientSAVData" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">

        <cftry>
			<cfinvoke webservice="#wsURL#" method="AddClientSAVData" returnvariable="res">
	    		<cfinvokeargument name="theXmlFile" value="#arguments.theXmlFile#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddClientSAVData][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddClientSAVData][returnvariable]: #res#">
				<cfreturn false>
            </cfcatch>
        </cftry>

	</cffunction>

<!--- #################################################### --->
<!--- GetSavAvDefsDate			 						   --->
<!--- #################################################### ---> 	
    <cffunction name="GetSavAvDefsDate" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">
		
		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetSavAvDefsDate" returnvariable="res">
	    		<cfinvokeargument name="theArch" value="#arguments.theArch#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSavAvDefsDate][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSavAvDefsDate][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>
    </cffunction>

<!--- #################################################### --->
<!--- GetSavAvDefsFile			 						   --->
<!--- #################################################### --->
    <cffunction name="GetSavAvDefsFile" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">

        <cftry>
			<cfinvoke webservice="#wsURL#" method="GetSavAvDefsDate" returnvariable="res">
	    		<cfinvokeargument name="theArch" value="#arguments.theArch#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSavAvDefsDate][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSavAvDefsDate][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>
    </cffunction>

<!--- #################################################### --->
<!--- GetSelfUpdates			 						   --->
<!--- #################################################### --->
	<cffunction name="GetSelfUpdates" access="remote" returntype="string" output="no">
		<cfargument name="swuaiVer">
        <cfargument name="swuadVer">
        <cfargument name="MPLogoutVer" required="no" default="0">
        <cfargument name="MPRebootVer" required="no" default="0">
        <cfargument name="cuuid" required="no">
		
		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetSelfUpdates" returnvariable="res">
	    		<cfinvokeargument name="swuaiVer" value="#arguments.swuaiVer#"/>
	    		<cfinvokeargument name="swuadVer" value="#arguments.swuadVer#"/>
	    		<cfinvokeargument name="MPLogoutVer" value="#arguments.MPLogoutVer#"/>
	    		<cfinvokeargument name="MPRebootVer" value="#arguments.MPRebootVer#"/>
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSelfUpdates][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSelfUpdates][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>
	</cffunction>

<!--- #################################################### --->
<!--- GetSwupdUpdates			 						   --->
<!--- #################################################### --->
    <cffunction name="GetSwupdUpdates" access="remote" returntype="string" output="no">
    	<!--- New MacPatch 1.6 --->
		<cfargument name="swupdVer">
        <cfargument name="cuuid" required="no">

		<cftry>
			<cfinvoke webservice="#wsURL#" method="GetSwupdUpdates" returnvariable="res">
	    		<cfinvokeargument name="swupdVer" value="#arguments.swupdVer#"/>
	    		<cfinvokeargument name="cuuid" value="#arguments.cuuid#"/>
			</cfinvoke>
			<cfreturn res>
			<cfcatch type="any">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSwupdUpdates][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
				<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSwupdUpdates][returnvariable]: #res#">
				<cfreturn "NA">
            </cfcatch>
        </cftry>
	</cffunction>
<!--- END Client WebServices Methods --->
</cfcomponent>
