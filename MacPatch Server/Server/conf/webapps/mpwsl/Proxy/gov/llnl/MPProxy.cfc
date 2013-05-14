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

       	<cflog type="error" file="#variables.logFile#" text="#CreateODBCDateTime(now())# --[#inet#][#aEventType#] #aEvent#">
    </cffunction>

	<cffunction name="getDistributionContent" access="public" returntype="any" output="no">
		
		<cfset var wsURL = "https://"&#variables.primaryServer#&":2600/MPDistribution.cfc?WSDL">
    	
		<cfinvoke webservice="#wsURL#" method="getDistributionContent" returnvariable="distContent">
			<cfinvokeargument name="returnType" value="xml">
			<cfinvokeargument name="encode" value="yes">
		</cfinvoke>   
		
		<cfset var contentRaw = "" />
		<cfset contentRaw = ToString(ToBinary(distContent)) />
		
		<cfif contentRaw EQ "ERR">
			<cfset log = logit("Error", "Trying to run getDistributionContent.")>
		</cfif>
		
		<cftry>
            <cfset var xmldoc = XmlParse(#contentRaw#)>
			<cfreturn xmldoc>
            <cfcatch type="any">
				<cfset log = logit("Error", "[getDistributionContent][XmlParse]: "&#cfcatch.Detail#&" -- "&#cfcatch.Message#)>
                <cfabort>
            </cfcatch>
        </cftry>
	</cffunction>
	
	<cffunction name="validateLocalContent" access="public" returntype="array" output="no">
		<cfargument name="xml">
		
		<cfset var patches = ArrayNew(1)>
		<cfset var itemNodes = xmlSearch(arguments.xml,"/Content/item") /> 
		
		<cfset var LocalContentDir = "/Library/MacPatch/Content/Web/patches">
		<cfset var l_patch = "">
		
		<cfoutput>
			<cfloop from="1" to="#arraylen(itemNodes)#" index="i">
				<cfset l_patch = #LocalContentDir# & "/" & #itemNodes[i].XmlAttributes['puuid']# & "/" & listlast(itemNodes[i].XmlAttributes['url'], "/")>
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
		
		<cfset var l_patch = "">
		<cfset var l_hash = "">
		<cfset var l_url = "">
		
		<cfoutput>
			<cfloop from="1" to="#arraylen(arguments.patches)#" index="i">
				<cfset l_patch = "#ListGetat(arguments.patches[i],"1","@")#">
				<cfset l_hash = "#ListGetat(arguments.patches[i],"2","@")#">
				<cfset l_url = "#ListGetat(arguments.patches[i],"3","@")#">
				
				
				<!--- File Is Ready to Be Downloaded from mpprod --->
				<cfset source = "http://"&#variables.primaryServer#&"/mp-content/"&#l_patch#&"/"&#listlast(url, "/")#>
				<cfset destination = "/Library/MacPatch/Content/Web/patches/"&#l_patch#>
				<cfset destinationFile = "/Library/MacPatch/Content/Web/patches/"&#l_patch#&"/"&#listlast(url, "/")#>
				<cftry>
					<cfif NOT DirectoryExists(destination)>
						<cfdirectory action="create" directory="#destination#" />
					</cfif>	
					<cfexecute name="/usr/bin/curl" arguments="-s -S -m 10 #source# -o #destinationFile#" variable="c_result" timeout="300" />
				<cfcatch>
					<cfset log = logit("Error","[downloadPatch] returned error " &#c_result#)>
					<cfcontinue>
				</cfcatch>
				</cftry>
					
				<cfif hashBinary(destinationFile,"MD5") NEQ #l_hash#>
					<cfset log = logit("Error","File hash did not match. File will be deleted.")>
					<cffile action="delete" file="#destinationFile#">
					<cfcontinue>
				</cfif>
			</cfloop>
		</cfoutput>
		
		<cfreturn true>
	</cffunction>
</cfcomponent>