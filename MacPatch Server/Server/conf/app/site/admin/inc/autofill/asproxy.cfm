<!---<cfsilent><cfparam name="url.q" default="">
 // 
Developer's Note
I don't like the fact that I can't talk directly to a CFC, *but* this presents some additional security options / layer.
I think when I get a little better versed in jQuery / cfajaxproxy, I could bypass the need for this page.

<cfsetting showdebugoutput="no">
<cfset oSample = createObject('component','qGet')>
<cfset data = oSample.getData(url.q)>
</cfsilent>
<cfoutput query="data">#data.bundle_id#|#chr(10)#</cfoutput>
--->
<cfsilent>
<cfset returnArray = ArrayNew(1) />
<cfquery name="qFindStuff" datasource="#session.dbsource#">
    SELECT Distinct bundle_id AS bundle_id
    FROM mp_patches
    WHERE bundle_id LIKE <cfqueryparam value="%#URL.term#%" cfsqltype="cf_sql_varchar" />
</cfquery>
 
<cfloop query="qFindStuff">
    <cfset bid = StructNew() />
    <cfset bid["id"] = bundle_id />
    <cfset bid["value"] = bundle_id />
    <cfset bid["label"] = bundle_id />
    <cfset ArrayAppend(returnArray,bid) />
</cfloop>
</cfsilent>
<cfprocessingdirective suppresswhitespace="yes">
<cfoutput>
#serializeJSON(returnArray)#
</cfoutput>
</cfprocessingdirective>