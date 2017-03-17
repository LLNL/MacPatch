<cfloop item="name" collection="#cookie#">
    <cfcookie name="#name#" value="" expires="now" />
</cfloop>
 
<!--- Redirect back to index page. --->
<cfset structClear( session ) />
<cflocation url="/" addtoken="false"/>
