<!---
    Name: settings.cfc
    Version: 1.2.0
    History: 
    - Intial Creatation read .xml 
    - Added JSON support
    - Removed XML Support
--->
<cfcomponent>
    <cffunction name="getJSONAppSettings" access="public" returntype="struct">
        <cfargument name="cFile" required="true">

        <cfset appConf.settings = structNew()>    
        <cfset jData = DeserializeJSON(file=arguments.cFile)>

        <!--- main settings --->
        <cfif not structKeyExists(jData,"settings")>
           <cfreturn appConf.settings>
        <cfelse>
            <cfset appConf.settings = jData.settings>    
        </cfif>

        <!--- Set J2EE Server type (Legacy) --->
        <cfset appConf.settings.j2eeType = "TOMCAT">

        <!--- Admin user settings, hash the password--->
        <cfif structKeyExists(jData.settings.users,"admin")>
            <cfif structKeyExists(jData.settings.users.admin,"enabled")>
                <cfif jData.settings.users.admin["enabled"] EQ "YES">
                  <cfif structKeyExists(jData.settings.users.admin,"pass")>
                    <cfset appConf.settings.users.admin.pass = Hash(jData.settings.users.admin.pass,'MD5')>
                  </cfif>
                <cfelse>
                  <cfset appConf.settings.users.enabled = "NO">
                  <cfset rc = StructDelete(appConf.settings.users.admin, "name", "False")>
                  <cfset rc = StructDelete(appConf.settings.users.admin, "pass", "False")>
                </cfif>
            </cfif>    
        </cfif>

        <cfreturn appConf.settings> 
    </cffunction>
</cfcomponent>