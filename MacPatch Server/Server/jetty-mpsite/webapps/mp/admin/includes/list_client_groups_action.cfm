<!---
<cfquery datasource="#session.dbsource#" name="qGet">
    Delete
    FROM	ClientCheckIn
    Where 	cuuid = '#cgi.
</cfquery>
--->
<cfloop list="application,session,variables,client,url,form,request,server,cgi" index="i">
    <cfdump var=#evaluate(i)# label="#i#">
</cfloop>