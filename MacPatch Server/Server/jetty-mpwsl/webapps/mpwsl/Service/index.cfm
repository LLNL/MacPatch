<cfset username = "heizer1">
<cfset password = "Ur12SrvMe!">
<cfset settings = server.mpsettings.settings>

<cfdump var="#settings#" />

<cfldap
      server="#settings.ldap.server#"
      action="QUERY"
      name="qry"
      start="#settings.ldap.searchbase#"
      attributes="#settings.ldap.attributes#"
      filter="(&(objectClass=*)(userPrincipalName=#username##settings.ldap.loginUsrSufix#))"
      scope="SUBTREE"
      port="#settings.ldap.port#"
      username="#username##settings.ldap.loginUsrSufix#"
      password="#password#"
      secure="#settings.ldap.secure#"
>

<cfdump var="#qry#" />