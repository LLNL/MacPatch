<cfcomponent output="false">

    <!--- Define properties. --->
    <cfset this.errorno = 0 />
    <cfset this.errormsg = "" />
    <cfset this.result = "" />
	<cfset this.mpserver = "" />

	<cffunction name="init" returntype="response" output="no">

        <cfset jObj = createObject("java", "java.net.InetAddress") />
        <!---
        <cfset this.machineName = jObj.localhost.getCanonicalHostName() />
        --->
        <cfset this.mpserver = jObj.localhost.getHostAddress() />

        <cfreturn this>
    </cffunction>

	<cffunction name="SerializeJSON" returntype="Any" output="false">
		
		<cfset s = structNew()>
		<cfset s.errorno = this.errorno>
		<cfset s.errormsg = this.errormsg>
		<cfset s.result = this.result>
		<cfset s.mpserver = this.mpserver>

		<cfreturn SerializeJSON(s) />
	</cffunction>

	<cffunction name="AsStruct" returntype="Any" output="false">
		
		<cfset s = structNew()>
		<cfset s.errorno = this.errorno>
		<cfset s.errormsg = this.errormsg>
		<cfset s.result = this.result>
		<cfset s.mpserver = this.mpserver>

		<cfreturn s />
	</cffunction>

</cfcomponent>