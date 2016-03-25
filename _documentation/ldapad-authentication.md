---
layout: default
title: "LDAP/AD Authentication"
---


To enable LDAP/Active Directory Authentication in MacPatch is a very simple task but may require tweaking for your specific environment.

First, lets start with the basic understanding on how the LDAP authentication works. In MacPatch, authentication against your directory server is done with your directory user name and password. If the user successfully authenticates, the user is granted access. However, by default all directory users in MacPatch are considers user accounts (least privileged) and not admin accounts.

## Configuration
To configure the MacPatch Admin Console to use the ldap authentication a script on the master server needs to run. Run the `DataBaseLDAPSetup.py` script located in `/Library/MacPatch/Server/conf/scripts/Setup` directory. The script will walk you through setting up the database and then the LDAP authentication. You will need to know the following items in order to properly configure the ldap authentication.

* Active Directory/LDAP Server Hostname
* Active Directory/LDAP Server Port Number
* Active Directory/LDAP Use SSL
* Active Directory/LDAP Search Base
* Active Directory/LDAP Login Attribute (default is userPrincipalName)
* Active Directory/LDAP Login User Name Prefix (optional)
	* This item is used to pre populate a domain for samAccountName auth as an example (e.g. myDomain\).
* Active Directory/LDAP Login User Name Suffix (optional)
	* This item is used to pre populate suffix string if using “userPrincipalName”

If you choose to use SSL, which is highly recommended then you will need to run the `addRemoteCert.py` script located in `/Library/MacPatch/Server/conf/scripts` directory. This script will download the directory servers certificate and add it to a trusted store only used by the MacPatch server.

**Usage:**

	sudo addRemoteCert.py –c “dc1.example.com:3269”
	
## Advanced Configuration
While most LDAP/Active Directory environments have many similar configuration settings each environment has it’s own tweaks. In order to do better filtering on the LDAP queries you might need to modify the ldap filter to achieve what you want. Once example of this could be to narrow the scope of allowed users by requiring that they belong to a group. To do this you need to edit the “Application.cfc” file located in `/Library/MacPatch /Server/tomcat-mpsite/webapps/ROOT/admin/Application.cfc`. The “filter” string should be located on or around line 299 in the file.

**Default:**

	filter="(&(objectClass=*)(#application.settings.ldap.loginAttr#=#arguments.username##application.settings.ldap.loginUsrSufix#))"

**With Group:**

	filter="(&(objectClass=*)(#application.settings.ldap.loginAttr#=#arguments.username##application.settings.ldap.loginUsrSufix#)(memberOf=CN=MacPatch-Admins,OU=Groups,DC=example,DC=com))"
	
The LDAP settings may also be edited without the use of the `DataBaseLDAPSetup.py` script. To edit these settings open the `/Library/MacPatch/Server/conf/etc/siteconfig.json` file.

Attribute | Default Value | Description | Notes
---|---|---|---
server | None | LDAP/AD Server to query	| 
searchbase | None | Query Search Base | Another way to filter the search
port | None | LDAP/AD Service Port | LDAP: 389 or 636 <br>AD: 3268 or 3269
secure | None | Use SSL transport | If using SSL the required value is **CFSSL_BASIC**
loginAttr | userPrincipalName | User to verify | 
loginUsrPrefix | userPrincipalName | Prefix for logins (e.g. **domain**\username) | Usually used if using samAccountName not required
loginUsrSufix | None | <span></span> | Usually used when using userPrincipalName not required