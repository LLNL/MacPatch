<cfcomponent>
	<cfparam name="mpDBSource" default="myMacPatch">
	<cffunction name="postProxyData" output="true" returntype="string" access="remote">
   
   		<!--- For now we are going to specify the location of the keys, they will com out of
		the database later and get written to a tmp location and deleted after each use --->
   		<cfargument name="priKey" required="yes">
        <cfargument name="pubKey" required="yes">
        
        <cfargument name="proxyServerAddr" required="no">
        <cfargument name="proxyServerUsr" required="no">
        <cfargument name="proxyServerPas" required="no">

        <cfquery datasource="#mpDBSource#" name="qListPatchGroups">
            Select Distinct name
            From patch_groups
        </cfquery>
        
        <!--- Loop through the query results and build an array of structs with the results --->
        <cfset groups=arraynew(1)>
        <cfoutput query="qListPatchGroups">

            <cfset fileName=#Trim(name)# &".xml">
            <cfset tmpFile="/tmp/MPP.tmp/gxml/" & #fileName#> 
            
            <cfscript>
                group = StructNew();
                StructInsert(group, "name", Trim(name));
                StructInsert(group, "file", fileName);
                StructInsert(group, "tfile", tmpFile);
                StructInsert(group, "checksum", "NA");
                
                AddIt = ArrayAppend(groups, group);
            </cfscript>
        
        </cfoutput>
        
        <!--- Create tmp dir if missing --->
        <cfif DirectoryExists("/tmp/MPP.tmp") EQ True >
           <!--- If FALSE, create the directory. --->
           Delete Dir<br />
           <cfdirectory action="delete" directory="/tmp/MPP.tmp" recurse="yes">
        </cfif>
        <!--- Create tmp dir if missing --->
        <cfif DirectoryExists("/tmp/MPP.tmp") EQ FALSE >
           <!--- If FALSE, create the directory. --->
           Create Dir<br />
           <cfdirectory action="create" directory="/tmp/MPP.tmp/gxml">
        </cfif>
        
        
        <!--- Loop Through an array of structs --->
        <cfsilent>
            <!--- Create the xml files --->
            <cfloop index="lGroup" from="1" to="#ArrayLen(groups)#">
                <cfset patchContent = #GetPatchGroupPatches(groups[lGroup].name)#>                
                <cffile action="Write" charset="utf-8" file="#groups[lGroup].tfile#" output="#patchContent#"> 
            </cfloop>
            
            <!--- Get the Checksums for the xml files --->
            <cfloop index="lGroup" from="1" to="#ArrayLen(groups)#">
                <cffile action="read" file="#tmpFile#" variable="myTextFile">
                <cfset groups[lGroup].checksum = #hash(myTextFile,"SHA1")#>
            </cfloop>
        </cfsilent>
        
        <!--- Create the base.xml file xml data --->
        <cfxml variable="root">
        <root><cfloop index="lGroup" from="1" to="#ArrayLen(groups)#"><cfoutput>
            <group>
            	<name>#groups[lGroup].name#</name>
                <file>#groups[lGroup].file#</file>
                <checksum>#groups[lGroup].checksum#</checksum>
            </group></cfoutput></cfloop>    
        </root>
        </cfxml>
        
        <!--- Write out the base.xml file to the tmp dir --->
        <!--- This will overwrite the previous if it exists --->
        <cffile action="Write" charset="utf-8" file="/tmp/MPP.tmp/base.xml" output="#root#">
        
        
        <!--- Sign the XML File --->
        <cfset argsSignText = "dgst -sha1 -sign " & #priKey# & " -out /tmp/MPP.tmp/base.sig /tmp/MPP.tmp/base.xml">
        <cfoutput>
        <cfexecute name = "/usr/bin/openssl" arguments="#argsSignText#" variable="signit" timeout = "5" />
        </cfoutput>
        <cflog file="MPPLog" application="no" text="Notice: Signed base.xml and created base.sig">
        <cflog file="MPPLog" application="no" text="Results: #signit#">
        
        <!--- Verify the sig exists and veriy it's signature --->
        <cfif FileExists("/tmp/MPP.tmp/base.sig")>
        	<cfset argsVrfyText = "dgst -sha1 -verify  " & #pubKey# & " -signature /tmp/MPP.tmp/base.sig /tmp/MPP.tmp/base.xml">
            <cfoutput>
            <cfexecute name = "/usr/bin/openssl"arguments = "#argsVrfyText#" variable="verifyit" timeout = "5" />
            </cfoutput>
            <cfif trim(verifyit) NEQ "Verified OK">
                <br>Signature was not verified!
				<!--- Need to log and email issue --->
                <cflog file="MPPLog" type="error" application="no" text="Error: Verifying base.sig against the public key.">
                <cflog file="MPPLog" type="error" application="no" text="Results: #verifyit#">
            <cfelse>
            	<br>Signature was verified!
                <!--- Need to Log the success --->
                <!--- Need to use CURL to post data to proxy server --->
                <cfexecute name = "/usr/bin/zip" arguments = "-q -r /tmp/MPP.tmp.zip /tmp/MPP.tmp" variable="verifyZip" timeout = "10" />
                <cflog file="MPPLog" application="no" text="Notice: ran cfexecute to create /tmp/MPP.tmp.zip">
                <cflog file="MPPLog" application="no" text="Results: #verifyZip#">
                
                <!--- Upload the file to the proxy server --->
				<cfset res = #postToProxyServer("/tmp/MPP.tmp.zip")# />
                <cfreturn res>
            </cfif>
        <cfelse>
            <cflog file="MPPLog" type="error" application="no" text="Error: base.sig was not found.">
            <cflog file="MPPLog" type="error" application="no" text="Error: Possible that base.xml was unable to be signed due to error.">
            <cfreturn "NO">
        </cfif>
		
	</cffunction>
    
    <cffunction name="genNewKeys" output="false" returntype="any" access="remote">
    
    	<cfset args01Text = "genrsa -out mppri.pem"> <!--- Gen Private Key --->
        <cfset args02Text = "rsa -in mppri.pem -out mppub.pem -outform PEM -pubout"> <!--- Gen Public Key --->
    
    </cffunction>
    
    <cffunction name="GetPatchGroupPatches" access="public" returntype="any" output="no">
    	<cfargument name="PatchGroup" required="yes">
    	<cftry>				  
            <cfquery datasource="#mpDBSource#" name="qGetPatches">
            	Select Distinct patch
                From patch_groups
                Where name like '#arguments.PatchGroup#'
            </cfquery>
            <cfcatch type="any">
            	<!--- the message to display --->
            	<cflog type="Error" file="MPPLog_Errors" text="[GetPatchGroupPatches][qGetPatches]: #cfcatch.Detail# -- #cfcatch.Message#">
            </cfcatch>
        </cftry>
		
        <!--- Create PatchGroup Patches XML --->
        <cfxml variable="root">
        <root>
            <AppleUpdates><cfoutput query="qGetPatches"><cfif #Right(Trim(patch),1)# NEQ "-">
                <update>#Trim(patch)#</update></cfif></cfoutput>
            </AppleUpdates>
        </root>
        </cfxml>
        
    	<cfreturn root>
    </cffunction>
    
    <cffunction name="GetProxyUsrPass" access="public" returntype="any" output="no">
   		<cfset genPassArgs = "hexdump -n 16 -e '16/1 ""%02X"" ""\n""' /dev/random" />
    </cffunction>
    
    <cffunction name="postToProxyServer" access="public" returntype="any" output="no">
        <cfargument name="zipFile" required="yes">
        
        <cfquery datasource="#mpDBSource#" name="qGetConfig">
            Select Distinct *
            From proxy_config
        </cfquery>
        
		<cfset argsCurlText = "-k --user """& #qGetConfig.proxy_user# & ": " & #qGetConfig.proxy_pass# & """ -T " & #arguments.zipFile# & " " & #qGetConfig.proxy_address# &"/MPP.tmp/">
        <cfexecute name = "/usr/bin/curl" arguments="#argsCurlText#" variable="verifyCurl" timeout = "10" />
        
        <cflog file="MPPLog" application="no" text="Notice: Posted #arguments.zipFile# to #qGetConfig.proxy_address#/MPP.tmp/">
        <cflog file="MPPLog" application="no" text="Results: #verifyCurl#">
        <cftry>
                <cffile action = "delete" file = "#arguments.zipFile#" variable="verifyDelete">
                <cflog file="MPPLog" application="no" text="Notice: Deleted #arguments.zipFile# using cffile.">
                <cfreturn "OK">
            <cfcatch type="any">
                <cflog file="MPPLog" type="error" application="no" text="Error: #cfcatch.message#">
                <cfreturn "NO">
            </cfcatch>
        </cftry>
    </cffunction>
</cfcomponent>    