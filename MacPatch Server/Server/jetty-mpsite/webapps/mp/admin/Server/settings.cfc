<cfcomponent>
	<cffunction name="getAppSettings" access="public" returntype="struct" output="yes">
    	
        <cfset jvmObj = CreateObject("java","java.lang.System").getProperties() />
        <cfset _localConf = "#jvmObj.jetty.home#/app_conf/siteconfig.xml">
        
		<cfif fileExists(_localConf)>
        	<cfset _confFile = #_localConf#>
        <cfelse>
        	<cfset _confFile = "/Library/MacPatch/Server/conf/etc/siteconfig.xml">
        </cfif>
  
        <cffile action="read" file="#_confFile#" variable="xml">
		<cfxml variable="xmlData"><cfoutput>#xml#</cfoutput></cfxml>
    	
        <!--- main settings --->
		<cfset appConf.settings = structNew()>
        
        <cfif not structKeyExists(xmlData,"settings")>
           <cfreturn appConf.settings>
        </cfif>
        
        <cfloop item="key" collection="#xmlData.settings#">
           <cfif len(trim(xmlData.settings[key].xmlText))>
              <cfset appConf.settings[key] = xmlData.settings[key].xmlText>
           </cfif>
        </cfloop>
        
        <!--- admin user settings - user --->
		<cfset appConf.settings.users.admin = structNew()>
        <cfif not structKeyExists(xmlData.settings.users,"admin")>
           <cfset appConf.settings.users.admin.enabled = "NO">
        <cfelse>
           <cfset appConf.settings.users.admin.enabled = "YES">
           <cfloop item="key" collection="#xmlData.settings.users.admin#">
			   <cfif len(trim(xmlData.settings.users.admin[key].xmlText))>
                  <cfif xmlData.settings.users.admin[key].XmlName EQ "pass">
                    <cfset appConf.settings.users.admin[key] = Hash(xmlData.settings.users.admin[key].xmlText,'MD5')>
                  <cfelse>
                    <cfset appConf.settings.users.admin[key] = xmlData.settings.users.admin[key].xmlText>
                  </cfif>
               </cfif>
            </cfloop>
        </cfif>
                
        <!--- LDAP settings - prod --->
		<cfset appConf.settings.ldap = structNew()>
        <cfif not structKeyExists(xmlData.settings,"ldap")>
        	<cfset appConf.settings.ldap.enabled = "NO">
        <cfelse>
            <cfset appConf.settings.ldap.enabled = "YES">
            <cfloop item="key" collection="#xmlData.settings.ldap#">
			   <cfif len(trim(xmlData.settings.ldap[key].xmlText))>
                  <cfset appConf.settings.ldap[key] = xmlData.settings.ldap[key].xmlText>
               </cfif>
            </cfloop>
        </cfif>
        
        <!--- database settings - prod 
        <cfdump var="#xmlData.settings.database#"> --->
		<cfset appConf.settings.database.prod = structNew()>
        <cfif structKeyExists(xmlData.settings,"database")>
			<cfif not structKeyExists(xmlData.settings.database,"prod")>
            	<cfset appConf.settings.database.prod.enabled = "NO"> 
            <cfelse>
        		<cfset appConf.settings.database.prod.enabled = "YES">  
                <cfloop item="key" collection="#xmlData.settings.database.prod#">
                	<cfif key NEQ "password">
						<cfif len(trim(xmlData.settings.database.prod[key].xmlText))>
                        	<cfset appConf.settings.database.prod[key] = xmlData.settings.database.prod[key].xmlText>
                        </cfif>
                    </cfif>    
                </cfloop>
            </cfif>
        <cfelse>
        	<cfset appConf.settings.database.prod.enabled = "NO">    
        </cfif>
        
        <!--- mail server settings --->
		<cfset srvconf.settings.mailserver = structNew()>
        <cfif not structKeyExists(xmlData.settings,"mailserver")>
        	<cfset appConf.settings.mailserver.enabled = "NO">
        <cfelse>
        	<cfset appConf.settings.mailserver.enabled = "YES">    
            <cfloop item="key" collection="#xmlData.settings.mailserver#">
			   <cfif len(trim(xmlData.settings.mailserver[key].xmlText))>
                  <cfset appConf.settings.mailserver[key] = xmlData.settings.mailserver[key].xmlText>
               </cfif>
            </cfloop>
        </cfif>

        <cfreturn appConf.settings>	
	</cffunction>
</cfcomponent>