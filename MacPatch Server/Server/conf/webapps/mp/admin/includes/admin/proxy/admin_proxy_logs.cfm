<cfset logData = "">
<cftry>
	<cfquery name="qGetInfos" datasource="#session.dbsource#" result="res1">
		select *
		From mp_proxy_conf
		WHERE active = '1'
	</cfquery>
	<cfcatch type="any">
		<cfoutput>
			Error running MacPatch proxy content synchronization.<br>
			#cfcatch.Detail# #cfcatch.message#
		</cfoutput>
		<cfabort>
	</cfcatch>
</cftry>
<cfsavecontent variable="soapRequest">
<cfoutput>
<soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
   <soapenv:Header/>
   <soapenv:Body>
      <na:ReadLogFile soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
         <logFile xsi:type="xsd:string">#url.id#</logFile>
      </na:ReadLogFile>
   </soapenv:Body>
</soapenv:Envelope>
</cfoutput>
</cfsavecontent>
<cftry>
	<cfset wsURL = "https://#qGetInfos.address#:#qGetInfos.port#/MPProxyLogs.cfc?wsdl">
	<cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1" throwonerror="true">
	<cfhttpparam type="header" name="SOAPAction" value="ReadLogFile">
	<cfhttpparam type="xml" name="body" value="#soapRequest#">
	</cfhttp>
	<cfset logData = cfhttp.FileContent />
	<cfcatch type="any">
		<cfoutput>
			Error getting MacPatch proxy log.<br>
			#cfcatch.Detail# #cfcatch.message#
		</cfoutput>
		<cfabort>
	</cfcatch>
</cftry>
<cfoutput>#logData#</cfoutput>