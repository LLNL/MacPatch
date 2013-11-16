<!--- 1.0.1 --->
<!--- Last Updated: 2011-01-07 --->
<!--- Created by Charles Heizer 2010-09-23 --->
<cfcomponent>
	<cffunction name="init" access="public" returntype="any" output="no">
        <cfargument name="datasource" type="string" required="yes">

        <cfset var me = 0>
        <cfset variables.datasource = arguments.datasource>
        <cfset variables.logToFile = false>
        <cfset me = this>
        
        <cfreturn me>
    </cffunction>
    
    <cffunction name="logToFile" access="public" returntype="void" output="no">
    	<cfargument name="enable" type="boolean" required="yes">
    	<cfset variables.logToFile = arguments.enable>
    </cffunction>
    
    <cffunction name="logit" access="private" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aHost" required="no">
        <cfargument name="aEvent">
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
        
    	<cfquery datasource="#variables.datasource#" name="qGet">
            Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
            Values (#CreateODBCDateTime(now())#, '#aEventType#', '#aEvent#', '#CGI.REMOTE_HOST#', '#CGI.SCRIPT_NAME#', '#CGI.PATH_TRANSLATED#','#CGI.SERVER_NAME#','#CGI.SERVER_SOFTWARE#', '#inet#') 
        </cfquery>
        
        <cfif #variables.logToFile# EQ true>
			<cflog type="Error" file="PatchScanManifest" text="#aEventType# -- #aEvent# -- #CGI.REMOTE_HOST#">
        </cfif>
    </cffunction>
    
	<!--- This Function will pad the version numbers --->
    <cffunction name="padIt" returntype="any" access="private" output="no">
        <cfargument name="appVer" required="yes">
        
        <cfset var myArray=ArrayNew(1)>
        <cfloop from="1" to="#ListLen(arguments.appVer,".")#" index="i" step="1">
            <cfif i EQ 1>
                <cfset y = #ListGetAt(appVer,i,".")#>
            <cfelse>
                <cfset y = #NumberFormat(ListGetAt(appVer,i,"."),"0000")#>
            </cfif>
            <cfset tmp = ArrayAppend(myArray,y)>
        </cfloop>
        <cfset var myAlphaList = ArrayToList(myArray, "0")>
        
        <cfreturn myAlphaList>    
    </cffunction>
    
    <cffunction name="GetBundleIDList" returntype="query" access="private" output="no">
        <cfset var qGet = QueryNew("Error", "VarChar")>
		<cftry>
            <cfquery datasource="#variables.datasource#" name="qGet" cachedwithin="#CreateTimeSpan(0,0,0,30)#">
                Select distinct bundle_id From mp_patches
                Order By bundle_id Desc
            </cfquery>
            <cfcatch type="any">
                <cfset log = logit("Error",CGI.REMOTE_HOST,"[PatchScanManifest][GetBundleIDList]: #cfcatch.Detail# -- #cfcatch.Message#")>
        	</cfcatch> 
		</cftry>
        
        <cfreturn qGet>    
    </cffunction>
    
    <cffunction name="GetBundleIDData" returntype="query" access="private" output="no">
        <cfargument name="bundleID" required="yes">
        <cfargument name="state" required="no" default="Production">
        <cfargument name="active" required="no" default="1">

        <cfset var qGet = QueryNew("Error", "VarChar")>
        <cftry>
            <cfquery datasource="#variables.datasource#" name="qGet" cachedwithin="#CreateTimeSpan(0,0,0,30)#">
                Select * From mp_patches
                Where bundle_id = '#arguments.bundleID#'
                AND active = '#arguments.active#'
                <cfif #arguments.state# EQ "All">
                AND patch_state IN('Production', 'QA')
                <cfelse>
                AND patch_state = '#arguments.state#'
                </cfif>
            </cfquery>
        	<cfcatch type="any">
        		<cfset log = logit("Error",CGI.REMOTE_HOST,"[PatchScanManifest][GetBundleIDData]: #cfcatch.Detail# -- #cfcatch.Message#")>
        	</cfcatch> 
        </cftry>

		<cfreturn qGet>    
    </cffunction>
    
    <cffunction name="GetScanCriteria" access="public" returntype="query" output="no">
        <cfargument name="id" required="yes">
        
        <cfset qGetPatchCriteria = QueryNew("Error", "VarChar")>
        <cftry>				  
            <cfquery datasource="#variables.datasource#" name="qGetPatchCriteria" cachedwithin="#CreateTimeSpan(0,0,0,30)#">
                select *
                from mp_patches_criteria
                Where puuid = '#arguments.id#'
                Order By type_order Asc
            </cfquery>
            <cfcatch type="any">
            	<cfset log = logit("Error",CGI.REMOTE_HOST,"[PatchScanManifest][GetScanCriteria]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
    
        <cfreturn qGetPatchCriteria>
    </cffunction>
    
    <cffunction name="getCurrentPatchStruct" access="public" returntype="any" output="no">
    	<cfargument name="state" required="no" default="Production">
        <cfargument name="active" required="no" default="1">
        
        <!--- Define variables --->
        <cfset var theXML = "">
        <cfset var uniqueIDStructArray = StructNew()>
        <cfset structArray = ArrayNew(1)>
        
        <!--- Get the Query List of All of the Unique Bundle IDs --->
        <cfset var bundleDList = GetBundleIDList()>
        
        <cfif bundleDList.RecordCount GTE 1>
            <cfloop query="bundleDList">
                <!--- Build Master Struct for the individual bundle_ids, so we can sort this and return 1 vstruct from it ---> 
                <cfset allBundleIDStruct = StructNew()>
                
				<!--- Get all of the bundle_id rows from the bundle_id --->
                <cfset bundleIDQuery = GetBundleIDData(bundle_id,arguments.state,arguments.active)>
                <cfif bundleIDQuery.RecordCount EQ 0>
                    <CFCONTINUE>
                </cfif>
                
				<!--- Loop over the rows and add each row, with the padded ver to a struct, and add that row struct to master struct --->
                <cfloop query="bundleIDQuery">
                    <cfset rowStruct = StructNew()>
                    <cfset rowStruct.patch_name = "#patch_name#">
                    <cfset rowStruct.patch_ver = "#patch_ver#">
                    <cfset rowStruct.patch_ver_pad = #padIt(patch_ver)#>
                    <cfset rowStruct.puuid = "#puuid#">
                    <cfset rowStruct.patch_reboot = #patch_reboot#>
                    <cfset rowStruct.bundle_id = #bundle_id#>
                    <cfset rowStruct.patch_state = #patch_state#>
                    <cfset rowStruct.active = #active#>
                    <cfset rowStruct.rid = #rid#>
                    <cfset allBundleIDStruct[padIt(bundleIDQuery.patch_ver)] = rowStruct>
                </cfloop>
                
				<!--- Sort the new struct array based on the patch_ver_pad --->
                <cfset sortedKeys = StructSort(allBundleIDStruct, "numeric", "DESC","patch_ver_pad")>
                
				<!--- Make sure the item is an array and that it has items in it --->
                <cfif IsArray(sortedKeys) AND ArrayLen(sortedKeys) GTE 1>	
                    <cfset currStruct = allBundleIDStruct[sortedKeys[1]]>
                    <cfset tmp = ArrayAppend(structArray,currStruct)>
                </cfif>
            </cfloop>
        <cfelse>
        	<cfset log = logit("Error",CGI.REMOTE_HOST,"[PatchScanManifest][getCurrentPatchStruct]: GetBundleIDList() result was empty.")>
        </cfif>
        
        <cfreturn structArray>
    </cffunction>
    
    <cffunction name="createScanListXML" access="public" returntype="any" output="no">
        <cfargument name="state" required="no" default="Production">
        <cfargument name="active" required="no" default="1">

        <!--- Define variables --->
        <cfset var theXML = "">
        <cfset var uniqueIDStructArray = StructNew()>
        <cfset structArray = ArrayNew(1)>
        
        <!--- Get the Query List of All of the Unique Bundle IDs --->
        <cfset var bundleDList = GetBundleIDList()>
        
        <cfif bundleDList.RecordCount GTE 1>
        	<cfloop query="bundleDList">
                <!--- Build Master Struct for the individual bundle_ids, so we can sort this and return 1 struct from it ---> 
                <cfset allBundleIDStruct = StructNew()>
                
				<!--- Get all of the bundle_id rows from the bundle_id --->
                <cfset bundleIDQuery = GetBundleIDData(bundle_id,arguments.state,arguments.active)>
                <cfif bundleIDQuery.RecordCount EQ 0>
                    <CFCONTINUE>
                </cfif>
                
				<!--- Loop over the rows and add each row, with the padded ver to a struct, and add that row struct to master struct --->
                <cfloop query="bundleIDQuery">
					<cfset rowStruct = StructNew()>
                    <cfset rowStruct.patch_name = "#patch_name#">
                    <cfset rowStruct.patch_ver = "#patch_ver#">
                    <cfset rowStruct.patch_ver_pad = #padIt(patch_ver)#>
                    <cfset rowStruct.puuid = "#puuid#">
                    <cfset rowStruct.patch_reboot = #patch_reboot#>
                    <cfset rowStruct.bundle_id = #bundle_id#>
                    <cfset rowStruct.patch_state = #patch_state#>
                    <cfset rowStruct.active = #active#>
                    <cfset rowStruct.rid = #rid#>
                    <cfset allBundleIDStruct[padIt(bundleIDQuery.patch_ver)] = rowStruct>
                </cfloop>
                
				<!--- Sort the new struct array based on the patch_ver_pad --->
                <cfset sortedKeys = StructSort(allBundleIDStruct, "numeric", "DESC","patch_ver_pad")>
                
				<!--- Make sure the item is an array and that it has items in it --->
                <cfif IsArray(sortedKeys) AND ArrayLen(sortedKeys) GTE 1>	
                    <cfset currStruct = allBundleIDStruct[sortedKeys[1]]>
                    <cfset tmp = ArrayAppend(structArray,currStruct)>
                </cfif>
            </cfloop>
        <cfelse>
        	<cfset log = logit("Error",CGI.REMOTE_HOST,"[PatchScanManifest][createScanListXML]: GetBundleIDList() result was empty.")>
        </cfif>
        
        <!--- Create the XML to be returned to the client --->
        <cfoutput>
        <cfsavecontent variable="XMLString">
        <cfprocessingdirective suppressWhiteSpace="true">
            <root>
                <patches>
                    <cfloop from="1" to="#ArrayLen(structArray)#" index="i">
                    <cfset currStruct = structArray[i]>
                    <cfset x = GetScanCriteria(currStruct.puuid)>
                    <patch pname="#currStruct.patch_name#" pversion="#currStruct.patch_ver#" puuid="#currStruct.puuid#" reboot="#currStruct.patch_reboot#" bundleID="#currStruct.bundle_id#">
                        <cfif x.RecordCount GTE 1>
                        <cfloop query="x">
                        <cfif #Trim(x.type)# EQ "Script">
							<query id="#x.type_order#"><![CDATA[#Trim(x.type)#@#Trim(x.type_data)#]]></query>
						<cfelse>		
                        	<query id="#x.type_order#">#Trim(x.type)#@#Trim(x.type_data)#</query>
						</cfif>
                        </cfloop>
                        </cfif>
                    </patch>
                    </cfloop>            	
                </patches>
            </root>
        </cfprocessingdirective>    
        </cfsavecontent>
        </cfoutput>
        
        <cfxml variable="theXML"><cfoutput>#XMLString#</cfoutput></cfxml>
        <cfreturn theXML>
    </cffunction>
	
	<cffunction name="createScanListJSON" access="public" returntype="any" output="no">
        <cfargument name="state" required="no" default="Production">
        <cfargument name="active" required="no" default="1">

        <!--- Define variables --->
        <cfset var theXML = "">
        <cfset var uniqueIDStructArray = StructNew()>
        <cfset structArray = ArrayNew(1)>
        
        <!--- Get the Query List of All of the Unique Bundle IDs --->
        <cfset var bundleDList = GetBundleIDList()>
        
        <cfif bundleDList.RecordCount GTE 1>
        	<cfloop query="bundleDList">
                <!--- Build Master Struct for the individual bundle_ids, so we can sort this and return 1 struct from it ---> 
                <cfset allBundleIDStruct = StructNew()>
                
				<!--- Get all of the bundle_id rows from the bundle_id --->
                <cfset bundleIDQuery = GetBundleIDData(bundle_id,arguments.state,arguments.active)>
                <cfif bundleIDQuery.RecordCount EQ 0>
                    <CFCONTINUE>
                </cfif>
                
				<!--- Loop over the rows and add each row, with the padded ver to a struct, and add that row struct to master struct --->
                <cfloop query="bundleIDQuery">
					<cfset rowStruct = StructNew()>
                    <cfset rowStruct.patch_name = "#patch_name#">
                    <cfset rowStruct.patch_ver = "#patch_ver#">
                    <cfset rowStruct.patch_ver_pad = #padIt(patch_ver)#>
                    <cfset rowStruct.puuid = "#puuid#">
                    <cfset rowStruct.patch_reboot = #patch_reboot#>
                    <cfset rowStruct.bundle_id = #bundle_id#>
                    <cfset rowStruct.patch_state = #patch_state#>
                    <cfset rowStruct.active = #active#>
                    <cfset rowStruct.rid = #rid#>
                    <cfset allBundleIDStruct[padIt(bundleIDQuery.patch_ver)] = rowStruct>
                </cfloop>
                
				<!--- Sort the new struct array based on the patch_ver_pad --->
                <cfset sortedKeys = StructSort(allBundleIDStruct, "numeric", "DESC","patch_ver_pad")>
                
				<!--- Make sure the item is an array and that it has items in it --->
                <cfif IsArray(sortedKeys) AND ArrayLen(sortedKeys) GTE 1>	
                    <cfset currStruct = allBundleIDStruct[sortedKeys[1]]>
                    <cfset tmp = ArrayAppend(structArray,currStruct)>
                </cfif>
            </cfloop>
        <cfelse>
        	<cfset log = logit("Error",CGI.REMOTE_HOST,"[PatchScanManifest][createScanListXML]: GetBundleIDList() result was empty.")>
        </cfif>
        
		<cfset _Patches = arrayNew(1)>
		<cfloop from="1" to="#ArrayLen(structArray)#" index="i">
			<cfset currStruct = structArray[i]>
            <cfset x = GetScanCriteria(currStruct.puuid)>
			
			<cfset _patch = {} />
			<cfset _patch[ "pname" ]	= "#currStruct.patch_name#" />
			<cfset _patch[ "bundleID" ] = "#currStruct.bundle_id#" />
			<cfset _patch[ "pversion" ] = "#currStruct.patch_ver#" />
			<cfset _patch[ "puuid" ] 	= "#currStruct.puuid#" />
			<cfset _patch[ "reboot" ] 	= "#currStruct.patch_reboot#" />
			<cfset _patch[ "query" ] 	= "" />
			
			<cfset _Queries = arrayNew(1)>
			<cfloop query="x">
				<cfset _query = {} />
				<cfset _query[ "id" ]	= "#x.type_order#" />
				<cfset _query[ "qStr" ] = "#Trim(x.type)#@#Trim(x.type_data)#" />
				<cfset a = ArrayAppend(_Queries,_query)>
			</cfloop>
		
			<cfset _patch.query = _Queries />
			<cfset a = ArrayAppend(_Patches,_patch)>		
		</cfloop>
		
		<cfset result = serializeJSON(_Patches)>
        <cfreturn result>
    </cffunction>
</cfcomponent>