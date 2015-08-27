<cfcomponent output="false">
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
	
	<cffunction name="init" access="public" returntype="any" output="no" hint="I instantiate and return this object.">
        	<cfargument name="primaryServer" type="string" required="yes">
		<cfargument name="logFile" type="boolean" required="no" default="MPProxy">

        	<cfset var me = 0>
        	<cfset variables.primaryServer = arguments.primaryServer>
			<cfset variables.logFile = arguments.logFile>
            <cfset variables.patchErrors = ArrayNew(1)>
        	<cfset me = this>
        
        	<cfreturn me>
	</cffunction>

	<!--- Logging function, replaces need for ws_logger (Same Code) --->
    <cffunction name="logit" access="private" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aEvent">
        <cfargument name="aHost" required="no">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">

        <cfscript>
            inet = CreateObject("java", "java.net.InetAddress");
            inet = inet.getLocalHost();
            //writeOutput(inet);
        </cfscript>

       	<cflog type="error" file="#variables.logFile#" text="--[#inet#][#aEventType#] #aEvent#">
    </cffunction>

	<cffunction name="getDistributionContent" access="public" returntype="any" output="no">
	<cfset var wsURL = "https://"&#variables.primaryServer#&":2600/MPDistribution.cfc?WSDL">
    <!---
    <cfinvoke webservice="#wsURL#" method="getDistributionContent" returnvariable="distContent">
        <cfinvokeargument name="returnType" value="xml">
        <cfinvokeargument name="encode" value="yes">
    </cfinvoke>   
    --->
    
    <cfsavecontent variable="localscope.soapRequest">
    <cfoutput>
    <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:na="http://na_svr">
       <soapenv:Header/>
       <soapenv:Body>
          <na:getDistributionContent soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
             <returnType xsi:type="xsd:string">xml</returnType>
             <encode xsi:type="xsd:string">yes</encode>
          </na:getDistributionContent>
       </soapenv:Body>
    </soapenv:Envelope>
    </cfoutput>
    </cfsavecontent>
    
    <cfhttp url="#wsURL#" method="POST" resolveurl="NO" useragent="Axis/1.1">
        <cfhttpparam type="header" name="SOAPAction" value="getDistributionContent"> 
    	<cfhttpparam type="header" name="content-type" value="text/xml">
    	<cfhttpparam type="header" name="charset" value="utf-8">
        <cfhttpparam type="xml" name="body" value="#trim(localscope.soapRequest)#">
    </cfhttp>
    
    <cfif cfhttp.responseheader.STATUS_CODE NEQ "200">
    	<cfset log = logit("Error", "[getDistributionContent]: "&#cfcatch.Detail#&" -- "&#cfcatch.Message#)>
    	<cfabort>
    </cfif>
    <cftry>
    	<cfset var tr = #Trim(cfhttp.FileContent)#>
    	<cfset var xd = #XMLParse(tr)#>
    
		<!--- Check To Make Sure We Have A Properly Formed XML Object --->
        <cfif #isXmlDoc(xd)# EQ 'Yes'>
            <cfset theRoot = xd.XmlRoot>
            <cfset foo = XmlSearch(xd, "//*[local-name()='getDistributionContentReturn']").get(0).XmlText />
	    <cfset res = ToString(ToBinary(foo))>	
	    <cfreturn Trim(res)>	
        <cfelse>
            <cfset log = logit("Error","Bad XML")>
        </cfif>		
        <cfcatch type="any">
    		<cfset log = logit("Error", "[getDistributionContent][XmlParse]: "&#cfcatch.Detail#&" -- "&#cfcatch.Message#)>
            <cfabort>
        </cfcatch>
    </cftry>
</cffunction>
	
	<cffunction name="validateLocalContent" access="public" returntype="array" output="no">
		<cfargument name="xml">
		
		<cfset var patches = ArrayNew(1)>
		<cfset var xdoc = xmlParse(arguments.xml)>
		<cfset var itemNodes = xmlSearch(xdoc,"//item") /> 
		<cfset log = logit("Info","Validating #arraylen(itemNodes)# patches.")>

		<cfset var LocalContentDir = "/Library/MacPatch/Content/Web">
		<cfset var l_patch = "">

		<cfoutput>
			<cfloop from="1" to="#arraylen(itemNodes)#" index="i">
				<!--- <cfset l_patch = #LocalContentDir# & "/" & #itemNodes[i].XmlAttributes['puuid']# & "/" & listlast(itemNodes[i].XmlAttributes['url'], "/")> --->
				<cfset l_patch = #LocalContentDir# & "" & itemNodes[i].XmlAttributes['url']>
				<cfif NOT fileExists(l_patch)>
					#ArrayAppend(patches, "#itemNodes[i].XmlAttributes['puuid']#@#itemNodes[i].XmlAttributes['hash']#@#itemNodes[i].XmlAttributes['url']#")#
					<cfcontinue>
				</cfif>
				<cfif hashBinary(l_patch,"MD5") NEQ  #itemNodes[i].XmlAttributes['hash']#>
					#ArrayAppend(patches, "#itemNodes[i].XmlAttributes['puuid']#@#itemNodes[i].XmlAttributes['hash']#@#itemNodes[i].XmlAttributes['url']#")#
					<cfcontinue>
				</cfif>
			</cfloop>
		</cfoutput>
		
		<cfreturn patches>
	</cffunction>
	
	<cffunction name="getContentFromArray" access="public" returntype="boolean" output="no">
		<cfargument name="patches">	
        
        <cfset log = logit("Info","#arraylen(arguments.patches)# patches need replicating.")>
		
		<cfset var l_patch = "">
		<cfset var l_hash = "">
		<cfset var l_url = "">
        <cfset var l_FileName = "">
		
		<cfoutput>
			<cfloop from="1" to="#arraylen(arguments.patches)#" index="i">
				<cfset l_patch = "#ListGetat(arguments.patches[i],"1","@")#">
				<cfset l_hash = "#ListGetat(arguments.patches[i],"2","@")#">
				<cfset l_url = "#ListGetat(arguments.patches[i],"3","@")#">
                <cfset l_FileName = #listlast(l_url, "/")#>
				<cfset log = logit("Info","[l_FileName]: #l_FileName#")>
				
				
				<!--- File Is Ready to Be Downloaded from mpprod --->
                <!---
				<cfset source = "http://#variables.primaryServer#/mp-content/patches/#l_patch#/#URLEncodedFormat(listlast(l_url, "/"))#">
				--->
                <cfset sourceStr = replace(l_url," ","%20","All")>
                <cfset source = "http://#variables.primaryServer#/mp-content#sourceStr#">
				<cfset destination = "/Library/MacPatch/Content/Web/patches/#ListFirst(ListRest(l_url,"/"),"/")#">
				<cfset destinationFile = "/Library/MacPatch/Content/Web#replace(l_url," ","","All")#">
				<cftry>
					<cfif NOT DirectoryExists(destination)>
						<cfdirectory action="create" directory="#destination#" />
					</cfif>	
					<cfset log = logit("Info","[downloadPatch]: -s -S -m 300 #source# -o #destinationFile#")>
                    <cfexecute name="/usr/bin/curl" arguments="-s -S -m 300 #source# -o #destinationFile#" variable="c_result" timeout="300" ERRORFILE="c_err.log" />
				<cfcatch>
                	<cfset a_err = #ArrayAppend(variables.patchErrors, "Downloading: #destinationFile#")#>
					<cfset log = logit("Error","[downloadPatch] returned error " &#c_result#)>
					<cfcontinue>
				</cfcatch>
				</cftry>
                
				<cftry>	
					<cfif hashBinary(replace(destinationFile," ","\ ","All"),"MD5") NEQ #l_hash#>
                        <cfset log = logit("Error","File (#destinationFile#) hash did not match. File will be deleted.")>
                        <cfset a_err = #ArrayAppend(variables.patchErrors, "Hash Check: #destinationFile#")#>
                        <cffile action="delete" file="#destinationFile#">
                        <cfcontinue>
                    <cfelse>
						<cfset df = #destination# & "/" & #l_FileName#>
						<cffile action="rename" source="#destinationFile#" destination="#df#" attributes="normal"> 
                    </cfif>
                    <cfcatch>
                        <cfset log = logit("Error","[hashBinary][#cfcatch.ErrNumber#]: #cfcatch.Message#")>
                        <cfcontinue>
                    </cfcatch>
				</cftry>
			</cfloop>
		</cfoutput>
		
		<cfreturn true>
	</cffunction>
    
    <cffunction name="sendResults" access="public" returntype="any" output="no">
    	<!--- This still needs to be completed --->
    	<cfreturn />
    </cffunction>
</cfcomponent>