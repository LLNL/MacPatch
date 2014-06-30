<!--- **************************************************************************************** --->
<!--- This WebService is used by iLoad to help configure the MacPatch Client   				   --->
<!--- **************************************************************************************** --->
<cfcomponent>

	<cfset this.ds = "mpds">

	<cffunction name="init" returntype="MPWSControllerCocoa" output="no">
		<cfreturn this>
	</cffunction>

<!--- **************************************************************************************** --->
<!--- Begin Other WebServices Methods --->

    <cffunction name="GetMPPatchGroups" access="remote" returntype="any" output="no">

        <cfquery datasource="#this.ds#" name="qGet">
            Select Distinct name AS PatchGroup
            From mp_patch_group
        </cfquery>
        <cfxml variable="XMLResults">
        <root>
        	<cfoutput query="qGet">
            <group>#PatchGroup#</group>
            </cfoutput>
        </root>
        </cfxml>

        <cfreturn #XMLResults#>
    </cffunction>

    <cffunction name="GetMPClientGroups" access="remote" returntype="any" output="no">

        <cfquery datasource="#this.ds#" name="qGet">
        	Select Distinct Domain AS ClientGroup
        	From mp_clients_plist
        </cfquery>
        <cfxml variable="XMLResults">
        <root>
        	<cfoutput query="qGet">
            <group>#ClientGroup#</group>
            </cfoutput>
        </root>
        </cfxml>

        <cfreturn #XMLResults#>
    </cffunction>

<!--- End Other WebServices Methods --->
<!--- **************************************************************************************** --->
</cfcomponent>
