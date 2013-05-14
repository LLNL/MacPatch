<cfsilent><cfparam name="url.q" default="">
<!--- // 
Developer's Note
I don't like the fact that I can't talk directly to a CFC, *but* this presents some additional security options / layer.
I think when I get a little better versed in jQuery / cfajaxproxy, I could bypass the need for this page.
--->
<cfsetting showdebugoutput="no">
<cfset oSample = createObject('component','qGet')>
<cfset data = oSample.getData(url.q)>
</cfsilent>
<cfprocessingdirective suppresswhitespace="yes"><cfoutput query="data">#data.bundle_id#|#chr(10)#</cfoutput></cfprocessingdirective>