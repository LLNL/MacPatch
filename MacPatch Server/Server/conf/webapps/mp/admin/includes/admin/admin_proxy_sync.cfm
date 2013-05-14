<cfheader name="expires" value="#now()#"> 
<cfheader name="pragma" value="no-cache"> 
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate"> 

<div style="font-size:14px;">
<b>MacPatch Proxy Server synchronization result.</b>
<hr />
</div>
<cftry>
	<cfquery name="qGetInfo" datasource="#session.dbsource#" result="res1">
		select *
		From mp_proxy_conf
		WHERE rid = <cfqueryparam value="#url.id#">
	</cfquery>
	<cfquery name="qGetKey" datasource="#session.dbsource#" result="res2">
		Select * From mp_proxy_key
		Where type = <cfqueryparam value="0">
	</cfquery>
	<cfcatch type="any">
		<cfoutput>
			Error getting MacPatch proxy info.<br>
			#cfcatch.Detail# #cfcatch.message# 
		</cfoutput>
		<cfabort>
	</cfcatch>		
</cftry>
<cfif IsDefined("url.isTest") AND url.isTest EQ "1">
	<cfsavecontent variable="soapRequest">
	<cfoutput>
	<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
	   <soapenv:Header/>
	   <soapenv:Body>
	      <na:testMPProxy soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	         <contentKey xsi:type="xsd:string">#qGetKey.proxy_key#</contentKey>
	      </na:testMPProxy>
	   </soapenv:Body>
	</soapenv:Envelope>
	</cfoutput>
	</cfsavecontent>
	<cftry>    
	<cfset wsURL = "https://#qGetInfo.address#:#qGetInfo.port#/MPProxyController.cfc?wsdl">	  
	<cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1" throwonerror="true">
	<cfhttpparam type="header" name="SOAPAction" value="testMPProxyRequest"> 
	<cfhttpparam type="xml" name="body" value="#soapRequest#">
	</cfhttp>
		<cfcatch type="any">
			<cfoutput>
				Error running MacPatch proxy test.<br>
				#cfcatch.Detail# #cfcatch.message# <br>
				https://#qGetInfo.address#:#qGetInfo.port#/MPProxyController.cfc?wsdl<br>
				#wsURL#
			</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfoutput>#XMLParse(cfhttp.FileContent)#</cfoutput>	
<cfelse>
	<cfsavecontent variable="soapRequest">
	<cfoutput>
	<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
	   <soapenv:Header/>
	   <soapenv:Body>
	      <na:synchronizeContent soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	         <contentKey xsi:type="xsd:string">#qGetKey.proxy_key#</contentKey>
	      </na:synchronizeContent>
	   </soapenv:Body>
	</soapenv:Envelope>
	</cfoutput>
	</cfsavecontent>
	<cftry>    
	<cfset wsURL = "https://#qGetInfo.address#:#qGetInfo.port#/MPProxyController.cfc?wsdl">	  
	<cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1" throwonerror="true">
	<cfhttpparam type="header" name="SOAPAction" value="synchronizeContentData"> 
	<cfhttpparam type="xml" name="body" value="#soapRequest#">
	</cfhttp>
		<cfcatch type="any">
			<cfoutput>
				Error running MacPatch proxy content synchronization.<br>
				#cfcatch.Detail# #cfcatch.message# 
			</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfoutput>#XMLParse(cfhttp.FileContent)#</cfoutput>	
</cfif>
<!---
<cfsavecontent variable="soapRequest">
<cfoutput>
<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
   <soapenv:Header/>
   <soapenv:Body>
      <na:synchronizeContent soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <contentKey xsi:type="xsd:string">#qGetKey.proxy_key#</contentKey>
      </na:synchronizeContent>
   </soapenv:Body>
</soapenv:Envelope>
</cfoutput>
</cfsavecontent>
<cftry>    
<cfset wsURL = "https://#qGetInfo.address#:#qGetInfo.port#/MPProxyController.cfc?wsdl">	  
<cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1" throwonerror="true">
<cfhttpparam type="header" name="SOAPAction" value="synchronizeContentData"> 
<cfhttpparam type="xml" name="body" value="#soapRequest#">
</cfhttp>
	<cfcatch type="any">
		<cfoutput>
			Error running MacPatch proxy content synchronization.<br>
			#cfcatch.Detail# #cfcatch.message# 
		</cfoutput>
		<cfabort>
	</cfcatch>
</cftry>
--->	
<!---
<cfset soapresponse = cfhttp.FileContent />	
<cfoutput>#soapresponse#<br>#wsURL#</cfoutput>
--->