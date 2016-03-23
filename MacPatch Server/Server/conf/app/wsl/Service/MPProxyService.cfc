<!--- **************************************************************************************** --->
<!---
        MPProxyService
        Database type is MySQL
        MacPatch Version 2.8.5.x
        Rev 1
--->
<!---   Notes:
--->
<!--- **************************************************************************************** --->
<cfcomponent extends="base">

    <!--- Configure Datasource --->
    <cfset this.ds = "mpds">
    <cfset this.debug = false>

    <cfset this.logName = "MPProxyService" />
    <cfset this.logLevel = "INF" />

    <cffunction name="init" returntype="MPProxyService" output="no">
        <cfreturn this>
    </cffunction>

	<cffunction name="PostProxyServerData" access="remote" returnType="struct" returnFormat="json" output="false">
		<cfargument name="proxyData">

		<cfset response = new response() />
		<cfset var xData = "">
		
		<cftry>
			<cfquery name="qGetKey" datasource="#this.ds#">
				Select proxy_key From mp_proxy_key
				Where type = '1'
			</cfquery>

			<cfset xData = decrypt(arguments.proxyData, qGetKey.proxy_key)>

			<cfquery name="qHasKey" datasource="#this.ds#">
				Select 1 From mp_proxy_key
				Where type = '0'
			</cfquery>

			<cfif qHasKey.RecordCount EQ "0">
				<cfquery name="qSetKey" datasource="#this.ds#">
					Insert Into mp_proxy_key (proxy_key, type)
					Values (<cfqueryparam value="#xData#">,<cfqueryparam value="0">)
				</cfquery>
			<cfelse>
				<cfquery name="qSetKey" datasource="#this.ds#">
					UPDATE mp_proxy_key
					SET proxy_key = <cfqueryparam value="#xData#">
					Where type = '0'
				</cfquery>
			</cfif>

			<cfreturn response.AsStruct()>

			<cfcatch type="any">
				<cfset l = lErr("PostProxyServerData", "#cfcatch.Message#", "#cfcatch.Detail#") />
				<cfset response.errorno = 10001 />
		        <cfset response.errormsg = "#cfcatch.Message#" />
		        <cfset response.result = "" />
                <cfreturn response.AsStruct()>
			</cfcatch>
		</cftry>

		<!--- Should not get here --->
		<cfset response.errorno = 10002 />
		<cfreturn response.AsStruct()>
	</cffunction>

</cfcomponent>