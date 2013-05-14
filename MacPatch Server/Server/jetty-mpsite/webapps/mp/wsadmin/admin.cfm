<cfquery datasource="mpds" name="qGetClients">
	SELECT cuuid,agent_version,AllowClient,AllowServer
	FROM mp_clients_view
</cfquery>

<cfset arrSW = ArrayNew(1)>
<cfset strMsg = "">
<cfset strMsgType = "Success">

<cfloop from="1" to="#qGetClients.RecordCount#" index="row">
	<cfset arrtxt = ArrayNew(1)>
	<cfloop list="#qGetClients.ColumnList#" index="column" delimiters=",">
		<!---<cfset xData = """#column#"":""#qGetClients[column][row]#""">--->
		<cfset xData = "#column#:#qGetClients[column][row]#">
		<cfset tmp = #ArrayAppend(arrtxt,xData)#>
	</cfloop>
	<cfset arrSW[row] = [#ArrayToList(arrtxt,",")#]>
</cfloop>

<!------>
<cfset stcReturn = {total=#qGetClients.RecordCount#,results=#arrSW#}>
<cfdump var="#serializeJSON(stcReturn)#">
