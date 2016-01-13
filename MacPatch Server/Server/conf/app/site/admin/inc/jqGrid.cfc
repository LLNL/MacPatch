<cfcomponent output="false" extends="base">

	<!--- Default logName --->
	<cfset this.logName = "console" />

	<cffunction name="Init" access="public" output="false">
        <!--- Return This reference. --->
        <cfreturn THIS />
    </cffunction>

<!--- jqGrid --->
    <cffunction name="buildSearch" access="private" hint="Build our Search Parameters">
		<cfargument name="stcSearch" required="true">
		
		<!--- strOp will be either AND or OR based on user selection --->
		<cfset var strGrpOp = stcSearch.groupOp>
		<cfset var arrFilter = stcSearch.rules>
		<cfset var strSearch = "">
		<cfset var strSearchVal = "">
		
		<!--- Loop over array of passed in search filter rules to build our query string --->
		<cfloop array="#arrFilter#" index="arrIndex">
			<cfset strField = arrIndex["field"]>
			<cfset strOp = arrIndex["op"]>
			<cfset strValue = arrIndex["data"]>
			
			<cfset strSearchVal = buildSearchArgument(strField,strOp,strValue)>
			
			<cfif strSearchVal NEQ "">
				<cfif strSearch EQ "">
					<cfset strSearch = "HAVING (#PreserveSingleQuotes(strSearchVal)#)">
				<cfelse>
					<cfset strSearch = strSearch & "#strGrpOp# (#PreserveSingleQuotes(strSearchVal)#)">				
				</cfif>
			</cfif>
			
		</cfloop>
		
		<cfreturn strSearch>
	</cffunction>
	
    <cffunction name="buildSearchArgument" access="private" hint="Build our Search Argument based on parameters">
		<cfargument name="strField" required="true" hint="The Field which will be searched on">
		<cfargument name="strOp" required="true" hint="Operator for the search criteria">
		<cfargument name="strValue" required="true" hint="Value that will be searched for">
		
		<cfset var searchVal = "">
		
		<cfif Arguments.strValue EQ "">
			<cfreturn "">
		</cfif>
		
		<cfscript>
			switch(Arguments.strOp)
			{
				case "eq":
					//ID is numeric so we will check for that
					if(Arguments.strField EQ "id")
					{
						searchVal = "#Arguments.strField# = #Arguments.strValue#";
					}else{
						searchVal = "#Arguments.strField# = '#Arguments.strValue#'";
					}
					break;				
				case "lt":
					searchVal = "#Arguments.strField# < #Arguments.strValue#";
					break;
				case "le":
					searchVal = "#Arguments.strField# <= #Arguments.strValue#";
					break;
				case "gt":
					searchVal = "#Arguments.strField# > #Arguments.strValue#";
					break;
				case "ge":
					searchVal = "#Arguments.strField# >= #Arguments.strValue#";
					break;
				case "bw":
					searchVal = "#Arguments.strField# LIKE '#Arguments.strValue#%'";
					break;
				case "ew":					
					searchVal = "#Arguments.strField# LIKE '%#Arguments.strValue#'";
					break;
				case "cn":
					searchVal = "#Arguments.strField# LIKE '%#Arguments.strValue#%'";
					break;
			}			
		</cfscript>
		<cfreturn searchVal>
	</cffunction>

	<!--- Used for Non Top of Column Based Search --->
	<cffunction name="buildSearchString" access="private" hint="Returns the Search Opeator based on Short Form Value">
		<cfargument name="searchField" required="no" default="" hint="Field to perform Search on">
	    <cfargument name="searchOper" required="no" default="" hint="Search Operator Short Form">
	    <cfargument name="searchString" required="no" default="" hint="Search Text">

		<cfset var searchVal = "">
        <cfscript>
            switch(Arguments.searchOper)
            {
                case "eq":
                    searchVal = "#Arguments.searchField# = '#Arguments.searchString#'";
                    break;
                case "ne":
                    searchVal = "#Arguments.searchField# <> '#Arguments.searchString#'";
                    break;
                case "lt":
                    searchVal = "#Arguments.searchField# < '#Arguments.searchString#'";
                    break;
                case "le":
                    searchVal = "#Arguments.searchField# <= '#Arguments.searchString#'";
                    break;
                case "gt":
                    searchVal = "#Arguments.searchField# > '#Arguments.searchString#'";
                    break;
                case "ge":
                    searchVal = "#Arguments.searchField# >= '#Arguments.searchString#'";
                    break;
                case "bw":
                    searchVal = "#Arguments.searchField# LIKE '#Arguments.searchString#%'";
                    break;
                case "ew":
                    //Purposefully breaking ends with operator (no leading ')
                    searchVal = "#Arguments.searchField# LIKE %#Arguments.searchString#'";
                    break;
                case "cn":
                    searchVal = "#Arguments.searchField# LIKE '%#Arguments.searchString#%'";
                    break;
            }
        </cfscript>
		<cfreturn searchVal>
	</cffunction>
	
</cfcomponent>