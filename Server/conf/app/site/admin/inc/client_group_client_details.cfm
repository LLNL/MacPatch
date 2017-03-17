<cfquery datasource="#session.dbsource#" name="qGetClientInfo" maxrows="1">
    SELECT	cuuid         as _Client_ID,
    		agent_version as Agent_Version,
            client_version as Client_Version,
            computername  as ComputerName,
            consoleUser   as Console_User,
            hostname      as HostName,
            ipaddr        as IP_Address,
            macaddr       as MAC_Address,
            mdate         as Last_Checkin,
            needsreboot   as Needs_Reboot,
            ostype        as OS_Type,
            osver         as OS_Version,
            serialNo  	  as Serial_No
    FROM	mp_clients
    Where	cuuid = '#url.cuuid#'
</cfquery>
<cfquery datasource="#session.dbsource#" name="qGetClientPlist">
    SELECT	*
    FROM	mp_clients_plist
    Where	cuuid = '#url.cuuid#'
</cfquery>

<html>
<head>
<title><cfoutput query="qGetClientInfo">#hostname# Info...</cfoutput></title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">

<style type="text/css">
    table.table1 {
        background-color:#000000;
        border-spacing: 1px;
    }

    table.table1 th {
        background-color: #DEDEDE;
        padding: 4px;
        text-align:left;
        font-size:12px;
        font-family: Arial, Helvetica, sans-serif;
        width: 36%;
    }

    table.table1 td {
        background-color: #FFF;
        padding: 4px;
        text-align:left;
        font-size:11px;
        font-family: Arial, Helvetica, sans-serif;
    }

    h3 {
        font-family: Arial, Helvetica, sans-serif;
    }
</style>
</head>

<body>
	<cfif IsDefined("url.cuuid")>
    <h3>Client Properties</h3>
    <table border="0" cellpadding="0" cellspacing="0" width="100%" class="table1">
    <cfloop index="col" list="#qGetClientInfo.columnList#" delimiters=",">
    <cfoutput>
	<tr>
    	<th>#Replace(col,"_"," ","All")#</th>
        <td>#Evaluate("qGetClientInfo."&col)#</td>
	</tr>
	</cfoutput>
    </cfloop>
    </table>
    <cfset plistCols = #qGetClientPlist.columnList#>
    <cfset plistCols = ListDeleteValue(plistCols,"rid",",")>
    <cfset plistCols = ListDeleteValue(plistCols,"cuuid",",")>
    <cfset plistCols = ListDeleteValue(plistCols,"rhash",",")>
    <cfset plistCols = ListDeleteValue(plistCols,"mdate",",")>
    <cfset plistCols = ListDeleteValue(plistCols,"cdate",",")>

    <h3>Client Agent Plist</h3>
    <table border="0" cellpadding="0" cellspacing="0" width="100%">
    <cfloop index="col" list="#plistCols#" delimiters=",">
    <cfoutput>
    <cfif #Evaluate("qGetClientPlist."&col)# NEQ "NA">
	<tr>
    	<th>#Replace(col,"_"," ","All")#</th>
        <td><cfif #Evaluate("qGetClientPlist."&col)# EQ "NA">&nbsp;<cfelse>#Evaluate("qGetClientPlist."&col)#</cfif></td>
	</tr>
	</cfif>
	</cfoutput>
    </cfloop>
    </table>
    </cfif>
</body>
</html>

<cffunction
	name="ListDeleteValue"
	access="public"
	returntype="string"
	output="false"
	hint="Deletes a given value (or list of values) from a list. This is not case sensitive.">

	<!--- Define arguments. --->
	<cfargument
		name="List"
		type="string"
		required="true"
		hint="The list from which we want to delete values."
		/>

	<cfargument
		name="Value"
		type="string"
		required="true"
		hint="The value or list of values that we want to delete from the first list."
		/>

	<cfargument
		name="Delimiters"
		type="string"
		required="false"
		default=","
		hint="The delimiting characters used in the given lists."
		/>


	<!--- Define the local scope. --->
	<cfset var LOCAL = StructNew() />

	<!---
		Create an array in which we will store our new list.
		This will be faster than building a list via string
		concatenation.
	--->
	<cfset LOCAL.Result = ArrayNew( 1 ) />

	<!---
		Convert the target list into an array for faster
		list iteration.
	--->
	<cfset LOCAL.ListArray = ListToArray(
		ARGUMENTS.List,
		ARGUMENTS.Delimiters
		) />

	<!---
		Convert our value list into struct. This will allow us
		to do super fast value look ups to see if we have a
		value requires deletion. We aren't going to bother
		converting this list to an array first (as we did above)
		because the likely scenario is that we won't have many
		values (and generally only one).
	--->
	<cfset LOCAL.ValueLookup = StructNew() />

	<!--- Loop over value list to create index. --->
	<cfloop
		index="LOCAL.ValueItem"
		list="#ARGUMENTS.Value#"
		delimiters="#ARGUMENTS.Delimiters#">

		<!--- Create index entry. --->
		<cfset LOCAL.ValueLookup[ LOCAL.ValueItem ] = true />

	</cfloop>


	<!---
		Now that we have our index in place, it's time to start
		looping over the target list and looking for target
		values in our index. NOTE: Since our index is a struct,
		the lookups will NOT be case sensisitve.
	--->
	<cfloop
		index="LOCAL.ValueIndex"
		from="1"
		to="#ArrayLen( LOCAL.ListArray )#"
		step="1">

		<!--- Get a short hand to the current list value. --->
		<cfset LOCAL.Value = LOCAL.ListArray[ LOCAL.ValueIndex ] />

		<!--- Check to see if this value is in the index. --->
		<cfif NOT StructKeyExists(
			LOCAL.ValueLookup,
			LOCAL.Value
			)>

			<!---
				We are not deleting this value so add it to
				the taret array.
			--->
			<cfset ArrayAppend(
				LOCAL.Result,
				LOCAL.Value
				) />

		</cfif>

	</cfloop>


	<!---
		At this point, our target list has been trimmed and
		stored in the results array. Now, we have to convert
		the array back to a list. This poses a little bit of
		complication: we can only use one delimiter. Therefore,
		we might lose some meaningful delimiters. This has been
		done in the tradeoff for faster processing.
	--->
	<cfreturn ArrayToList(
		LOCAL.Result,
		Left( ARGUMENTS.Delimiters, 1 )
		) />
</cffunction>
