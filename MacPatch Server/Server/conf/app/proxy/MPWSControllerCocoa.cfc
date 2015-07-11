<!--- **************************************************************************************** --->
<!---
		MPWSControllerCocoa.cfc Proxy File
		MacPatch Version 1.8.6
		MacPatch Version 2.0.0
		Version 2.0
		Rev: 1
		
		Notes:
		Does not include:
		GetAgentUpdates
		GetAgentUpdaterUpdates
--->
<!--- **************************************************************************************** --->
<cfcomponent>
	<!--- Configure Datasource --->
	<cfparam name="mpDBSource" default="mpds">
	<cfparam name="logFile" default="MPWSControllerCocoa">
    <cfparam name="wsPort" default="2600">
    <cfparam name="wsURL" default="https://#server.mp.settings.proxyserver.primaryServer#:#server.mp.settings.proxyserver.primaryServerPort#/MPWSControllerCocoa.cfc?wsdl">

<!--- **************************************************************************************** --->
<!--- Begin Client WebServices Methods --->

<!--- #################################################### --->
<!--- Test / Client PING			 									   --->
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
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:ClientCheckIn soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <theData xsi:type="xsd:string">#arguments.theData#</theData>
                 <encoding xsi:type="xsd:string">#arguments.encoding#</encoding>
              </na:ClientCheckIn>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="ClientCheckIn"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("ClientCheckIn",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientCheckIn][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>

<!--- #################################################### --->
<!--- GetClientPatchState 								   --->
<!--- This Needs to be updated to test againts client patch group --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
	<cffunction name="ClientPatchStatus" access="remote" returntype="any" output="no">
        <cfargument name="cuuid" required="yes">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:ClientPatchStatus soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
              </na:ClientPatchStatus>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="ClientPatchStatus"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("ClientPatchStatus",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientPatchStatus][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>

<!--- #################################################### --->
<!--- GetPatchGroupPatches 								   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="GetPatchGroupPatches" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetPatchGroupPatches soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <PatchGroup xsi:type="xsd:string">#arguments.PatchGroup#</PatchGroup>
              </na:GetPatchGroupPatches>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetPatchGroupPatches"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetPatchGroupPatches",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatches][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn localscope.soapresponse>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetPatchGroupPatchesExtended - New For 1.8.6 		   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->   
    <cffunction name="GetPatchGroupPatchesExtended" access="remote" returntype="any" output="no">
        <cfargument name="PatchGroup" required="yes">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetPatchGroupPatchesExtended soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <PatchGroup xsi:type="xsd:string">#arguments.PatchGroup#</PatchGroup>
              </na:GetPatchGroupPatchesExtended>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetPatchGroupPatchesExtended"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetPatchGroupPatchesExtended",cfhttp.FileContent) />
        <cftry>
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatchesExtended][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
		<cfreturn false>
        </cfif>
	<cfcatch>
		<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetPatchGroupPatchesExtended][#CGI.REMOTE_HOST#]: #cfcatch.detail# #cfcatch.message#">
	</cfcatch>
        </cftry>
        <cfreturn localscope.soapresponse>
	</cffunction>

<!--- #################################################### --->
<!--- AddPatchesXML				 						   --->
<!--- #################################################### --->
    <cffunction name="AddPatchesXML" access="remote" returnType="any" output="no">
        <cfargument name="vXml">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:AddPatchesXML soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <vXml xsi:type="xsd:string">#arguments.vXml#</vXml>
              </na:AddPatchesXML>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="AddPatchesXML"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("AddPatchesXML",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddPatchesXML][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn true>
	</cffunction>
	
<!--- #################################################### --->
<!--- UpdateInstalledPatches	 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="UpdateInstalledPatches" access="remote" returntype="any" output="no">
		<cfargument name="cuuid" required="yes">
        <cfargument name="patch" required="yes">
        <cfargument name="type" required="yes">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:UpdateInstalledPatches soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
                 <patch xsi:type="xsd:string">#arguments.patch#</patch>
                 <type xsi:type="xsd:string">#arguments.type#</type>
              </na:UpdateInstalledPatches>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="UpdateInstalledPatches"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("UpdateInstalledPatches",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [UpdateInstalledPatches][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn true>
    </cffunction>
	
<!--- ######################################################### --->
<!--- AddInstalledPatches / Depricated as of 1.8 -- RM 1.8.5	--->
<!--- Good for MP 2.0                                           --->
<!--- ######################################################### --->
    <cffunction name="AddInstalledPatches" access="remote" returntype="any" output="no">
		<cfargument name="patchesXML64">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:AddInstalledPatches soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <patchesXML64 xsi:type="xsd:string">#arguments.patchesXML64#</patchesXML64>
              </na:AddInstalledPatches>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="AddInstalledPatches"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("AddInstalledPatches",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddInstalledPatches][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn true>
	</cffunction>
	
<!--- #################################################### --->
<!--- GetLastCheckIn	 		 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="GetLastCheckIn" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="cuuid">
		
		<cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetLastCheckIn soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
              </na:GetLastCheckIn>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetLastCheckIn"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetLastCheckIn",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetLastCheckIn][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>
<!--- #################################################### --->
<!--- GetAsusCatalogURLs 		 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="GetAsusCatalogURLs" access="remote" returntype="any" output="no">
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

		<cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetAsusCatalogURLs soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
                 <osminor xsi:type="xsd:string">#arguments.osminor#</osminor>
              </na:GetAsusCatalogURLs>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetAsusCatalogURLs"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetAsusCatalogURLs",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAsusCatalogURLs][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
	</cffunction>

    <cffunction name="GetAsusCatalogs" access="remote" returntype="any" output="no">
    	<!--- New For v1.8.5 --->
    	<cfargument name="cuuid" required="yes" type="string">
        <cfargument name="osminor" required="yes" type="string">

        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetAsusCatalogs soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
                 <osminor xsi:type="xsd:string">#arguments.osminor#</osminor>
              </na:GetAsusCatalogs>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetAsusCatalogs"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetAsusCatalogs",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetAsusCatalogs][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>

<!--- #################################################### --->
<!--- ProcessXML                                           --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="ProcessXML" access="remote" returntype="any" output="no">
        <cfargument name="encodedXML">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:ProcessXML soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <encodedXML xsi:type="xsd:string">#arguments.encodedXML#</encodedXML>
              </na:ProcessXML>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="ProcessXML"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("ProcessXML",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ProcessXML][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>
	
<!--- #################################################### --->
<!--- DataMgrXML                                           --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="DataMgrXML" access="remote" returntype="any" output="no">
        <cfargument name="cuuid">
        <cfargument name="encodedXML">

        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:DataMgrXML soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
                 <encodedXML xsi:type="xsd:string">#arguments.encodedXML#</encodedXML>
              </na:DataMgrXML>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="DataMgrXML"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("DataMgrXML",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [DataMgrXML][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfreturn false>
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>
	
<!--- #################################################### --->
<!--- GetScanList		 		 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="GetScanList" access="remote" returntype="any" output="yes">
    	<cfargument name="encode" required="no" default="true" type="string">
        <cfargument name="state" required="no" default="all" type="string">
        <cfargument name="active" required="no" default="1" type="string">

		<cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetScanList soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <encode xsi:type="xsd:string">#arguments.encode#</encode>
                 <state xsi:type="xsd:string">#arguments.state#</state>
                 <active xsi:type="xsd:string">#arguments.active#</active>
              </na:GetScanList>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetScanList"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetScanList",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetScanList][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
			<cfxml variable="root">
                    <root><patches/></root>
            </cfxml>
            <cfreturn #ToBinary(ToBase64(ToString(root)))#>
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>

<!--- #################################################### --->
<!--- ClientErrors		 		 						   --->
<!--- #################################################### --->
    <cffunction name="ClientErrors" access="remote" returntype="any" output="no">
        <cfargument name="cuuid">
        <cfargument name="error">

		<cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:ClientErrors soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
                 <error xsi:type="xsd:string">#arguments.error#</error>
              </na:ClientErrors>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="ClientErrors"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("ClientErrors",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [ClientErrors][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
            <cfreturn false>
        </cfif>
        
        <cfreturn true>
    </cffunction>

<!--- #################################################### --->
<!--- AddClientSAVData			 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### ---> 	
    <cffunction name="AddClientSAVData" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theXmlFile">

		<cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:AddClientSAVData soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <theXmlFile xsi:type="xsd:string">#arguments.theXmlFile#</theXmlFile>
              </na:AddClientSAVData>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="AddClientSAVData"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("AddClientSAVData",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddClientSAVData][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
            <cfreturn false>
        </cfif>
        
        <cfreturn localscope.soapresponse>
	</cffunction>

<!--- #################################################### --->
<!--- GetSavAvDefsDate			 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### ---> 	
    <cffunction name="GetSavAvDefsDate" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetSavAvDefsDate soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <theArch xsi:type="xsd:string">#arguments.theArch#</theArch>
              </na:GetSavAvDefsDate>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetSavAvDefsDate"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetSavAvDefsDate",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddClientSAVData][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
            <cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>

<!--- #################################################### --->
<!--- GetSavAvDefsFile			 						   --->
<!--- Good for MP 2.0                                      --->
<!--- #################################################### --->
    <cffunction name="GetSavAvDefsFile" access="remote" returnType="any" output="no">
		<!--- This Function Adds the Patches Collected from a local Software Update Server --->
		<cfargument name="theArch">

        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetSavAvDefsFile soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <theArch xsi:type="xsd:string">#arguments.theArch#</theArch>
              </na:GetSavAvDefsFile>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetSavAvDefsFile"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetSavAvDefsFile",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [AddClientSAVData][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
            <cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
    </cffunction>

<!--- #################################################### --->
<!--- GetSelfUpdates			 						   --->
<!--- #################################################### --->
	<cffunction name="GetSelfUpdates" access="remote" returntype="any" output="no">
		<cfargument name="swuaiVer">
        <cfargument name="swuadVer">
        <cfargument name="MPLogoutVer" required="no" default="0">
        <cfargument name="MPRebootVer" required="no" default="0">
        <cfargument name="cuuid" required="no">
		
        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetSelfUpdates soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <swuaiVer xsi:type="xsd:string">#arguments.swuaiVer#</swuaiVer>
                 <swuadVer xsi:type="xsd:string">#arguments.swuadVer#</swuadVer>
                 <MPLogoutVer xsi:type="xsd:string">#arguments.MPLogoutVer#</MPLogoutVer>
                 <MPRebootVer xsi:type="xsd:string">#arguments.MPRebootVer#</MPRebootVer>
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
              </na:GetSelfUpdates>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetSelfUpdates"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetSelfUpdates",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSelfUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
            <cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
	</cffunction>

<!--- #################################################### --->
<!--- GetSwupdUpdates			 						   --->
<!--- #################################################### --->
    <cffunction name="GetSwupdUpdates" access="remote" returntype="any" output="no">
    	<!--- New MacPatch 1.6 --->
		<cfargument name="swupdVer">
        <cfargument name="cuuid" required="no">

        <cfsavecontent variable="localscope.soapRequest">
		<cfoutput>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
           <soapenv:Header/>
           <soapenv:Body>
              <na:GetSwupdUpdates soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                 <swupdVer xsi:type="xsd:string">#arguments.swupdVer#</swupdVer>
                 <cuuid xsi:type="xsd:string">#arguments.cuuid#</cuuid>
              </na:GetSwupdUpdates>
           </soapenv:Body>
        </soapenv:Envelope>
        </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        	<cfhttpparam type="header" name="SOAPAction" value="GetSwupdUpdates"> 
        	<cfhttpparam type="header" name="content-type" value="text/xml">
	  		<cfhttpparam type="header" name="charset" value="utf-8">
        	<cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
        </cfhttp>
        <cfset localscope.soapresponse = ProxyResponse("GetSwupdUpdates",cfhttp.FileContent) />
        
        <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
        	<cflog type="error" file="#logFile#" text="#CreateODBCDateTime(now())# -- [GetSwupdUpdates][#CGI.REMOTE_HOST#]: #XMLParse(cfhttp.FileContent)#">
            <cfreturn "NA">
        </cfif>
        
        <cfreturn localscope.soapresponse>
	</cffunction>
    
    <cffunction name="ProxyResponse" access="public" returntype="any" output="no">
    	<cfargument name="methName" required="yes">
        <cfargument name="soapData" required="yes">
        
        <cfset var result = "">
        
        <cftry>
            <cfset var tr = #Trim(arguments.soapData)#>
            <cfset var xd = #XMLParse(tr)#>
        
            <!--- Check To Make Sure We Have A Properly Formed XML Object --->
            <cfif #isXmlDoc(xd)# EQ "Yes">
                <cfset theRoot = xd.XmlRoot>
                <cfset var searchString = "//*[local-name()='#arguments.methName#Return']">
                <cflog type="information" file="#logFile#" text="[ProxyResponse][#CGI.REMOTE_HOST#]: #searchString#">
                <cfset result = XmlSearch(xd, searchString).get(0).XmlText />
            <cfelse>
            	<cflog type="error" file="#logFile#" text="[ProxyResponse][#CGI.REMOTE_HOST#]: Bad XML">
                <cfset result = "Error, bad XML">
            </cfif>		
            <cfcatch type="any">
            	<cflog type="error" file="#logFile#" text="[ProxyResponse][#CGI.REMOTE_HOST#]: #wsURL#">
            	<cflog type="error" file="#logFile#" text="[ProxyResponse][#CGI.REMOTE_HOST#]: #cfcatch.Detail# -- #cfcatch.Message#">
                <cflog type="error" file="#logFile#" text="[ProxyResponse][#CGI.REMOTE_HOST#]: #arguments.soapData#">
                <cfset result = "Error, bad XML">
            </cfcatch>
        </cftry>
        
        
        <cfreturn result>
    </cffunction>
<!--- END Client WebServices Methods --->
</cfcomponent>
