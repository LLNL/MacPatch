<cfoutput>
<link rel="stylesheet" href="./_assets/css/tablesorter/themes/blue/style.css" type="text/css" />
<script type="text/javascript" src="/admin/_assets/js/jquery/addons/jquery.tablesorter.js"></script>
</cfoutput>
<script type="text/javascript">	
	$(function() {
		$("#genericTable").tablesorter({
			widgets: ['zebra']
		});
	});	
</script>
<cfset logData = "">
<cfif ISDefined("url.id") AND #url.id# EQ "MPProxy">
	<cfquery name="qGetLogData" datasource="#session.dbsource#" maxrows="20">
		select *
		From mp_proxy_logs
		Order By rid DESC
	</cfquery>
	<table id="genericTable" class="tablesorter" border="0" cellpadding="0" cellspacing="0" width="100%"> 
	    <thead>
	    <tr>
	    	<th>Log Data</th>
			<th>Date-Time</th>
	    </tr>
	    </thead>
	    <tbody>
	    	<cfoutput query="qGetLogData">
	    		<tr>
	    			<td><pre>#log_data#</pre></td>
					<td>#mdate#</td> 
	    		</tr>	
	    	</cfoutput>
	    </tbody>
	</table>
<cfelse>
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
				https://#qGetInfos.address#:#qGetInfos.port#/MPProxyLogs.cfc?wsdl<br>
				#cfcatch.Detail# #cfcatch.message#<br>
				<pre>
				#soapRequest#
				</pre>
			</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>
	<cfoutput><pre>#logData#</pre></cfoutput>
</cfif>	