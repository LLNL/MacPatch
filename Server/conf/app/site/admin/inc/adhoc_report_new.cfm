<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="stylesheet" href="/admin/js/tablesorter/themes/blue/style.css" type="text/css"/>
<link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />


<script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
<script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
<script type="text/javascript" src="/admin/js/tablesorter/jquery.tablesorter.js"></script>
<script type="text/javascript" src="/admin/js/tablesorter/pager/jquery.tablesorter.pager.js"></script>

<script type="text/javascript">
    $(function() {
        $("#rptTable").tablesorter({
            widgets: ['zebra']
        }).tablesorterPager({
            container: $("#pager")
        });
    });

    $('select.required').change(function() {
      var total = $('select.required').length;
      var selected = $('select.required option:selected').length;

      $('#submitIt').attr('disabled', (selected == total));
    });
</script>

<cfheader name="Expires" value="#GetHttpTimeString(Now())#">
<cfheader name="Pragma" value="no-cache">

<title></title>
</head>
<body>

<cfparam name="Submit" default="Default">
<cfparam name="theOrigQuery" default="Default">
<cfparam name="BuildQuery" default="Default">
<cfparam name="RunQuery" default="Default">
<cfparam name="form.RefineQuery" default="no">

<!--- ******* START Get TABLES START ******* --->
<cfif #Submit# EQ "Default" OR #Submit# EQ "Clear and Start Over">
	<cfcookie name="oTables" expires="#now()#">
    <cfcookie name="oColumns" expires="#now()#">
    <cfcookie name="origQuery" expires="#now()#">
	<cfset tables = getDBTables()>
	<form action="adhoc_report_new.cfm" method="post">
		<table>
			<tr>
				<th><div align="Left">Tables (<cfoutput>#listlen(tables)#</cfoutput>)</div></th>
			</tr>
			<tr>
				<td>
					<select name="tables" size="20" multiple="yes" style="min-width:300px;">
                    	<cfloop list="#tables#" index="table">
						<cfoutput><option>#table#</option></cfoutput>
                        </cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<input type="hidden" name="tables_required" value="WARNING: You must select a table(s).">
					<input type="submit" name="Submit" value="Get Columns" id="submitIt">
				</td>
			</tr>
		</table>
	</form>
<!--- ******* START Get Columns START ******* --->
<cfelseif #Submit# EQ "Get Columns">
	<!--- Filter Out Duplicate tables, can happen --->
	<cfset formTablesArr = createObject("java", "java.util.HashSet").init(ListToArray(form.tables)).toArray() />
    <cfset formTablesLst = #ArrayToList(formTablesArr)#/>

	<cfset _tables = getDBTables()>
    <cfset _columns = "">
    <cfloop list="#formTablesLst#" index="_table">
    	<cfset _tCols = getColumnsForTable(_table)>
    	<cfloop list="#_tCols#" index="_tCol">
    		<cfset _columns = ListAppend(_columns, _tCol ) />
        </cfloop>
    </cfloop>
	<form action="adhoc_report_new.cfm" method="post">
		<table>
			<tr>
				<th><div align="Left">Tables</div></th>
				<th><div align="Left"><cfif #Submit# is "Get Columns">Columns</cfif></div></th>
		  	</tr>
			<tr>
				<td>
					<select name="tables" size="20" multiple="yes" style="min-width:300px;">
						<cfloop list="#_tables#" index="table">
                        <cfoutput>
                        	<cfif ListContainsNoCase(formTablesLst,table) GTE 1>
                        		<option selected>#table#</option>
                            <cfelse>
                            	<option>#table#</option>
                            </cfif>
						</cfoutput>
                        </cfloop>
					</select>
				</td>
				<td>
					<select name="columns" size="20" multiple style="min-width:300px;">
						<cfloop list="#_columns#" index="col">
                        <cfoutput>
							<option value="#col#">#col#</option>
                        </cfoutput>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<input type="submit" name="Submit" value="Get Columns">
				</td>
				<td>
					<input type="hidden" name="columns_required" value="WARNING: You must select a column(s).">
					<input type="hidden" name="selectedTables" value="<cfoutput>#formTablesLst#</cfoutput>">
					<input type="submit" name="Submit" value="Define Query">
					<input type="submit" name="Submit" value="Run Query">
				</td>
			</tr>
		</table>
	</form>
<!--- ******* START BuildQuery START ******* --->
<cfelseif #submit# is "Define Query">
	<cfif #theOrigQuery# EQ "Default">
		<!--- Global vars --->
		<cfset columns = #form.columns#>
		<cfset tables =  #form.tables#>

		<cfcookie name="oTables" value="#tables#">
		<cfcookie name="oColumns" value="#columns#">
		<cfcookie name="origQuery" value="SELECT #columns# FROM #tables#">
		<cfset theQuery = "SELECT DISTINCT #columns# ">
	<cfelse>
		<cfset theQuery="#cookie.origQuery#">
	</cfif>

  <form action="adhoc_report_new.cfm" method="post" name="refine">
			<table id="rptTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
				<thead>
					<tr>
						<th><span class="white_plain_arial_12">Table.Column</span></th>
						<th><span class="white_plain_arial_12">Option</span></th>
						<th><span class="white_plain_arial_12">Value</span></th>
					</tr>
        </thead>
        <tbody>
					<cfoutput>
						<cfloop index="col" list="#columns#" delimiters=",">
							<tr>
								<td>
									<input name="#col#_foo" type="hidden" value="#col#">#col#
								</td>
								<td>
									<select name="#col#_opt">
										<option value="Contains">Contains</option>
										<option value="Is">Is</option>
										<option value="Bw">Begins With</option>
										<option value="Ew">Ends With</option>
									</select>
								</td>
								<td>
                  <!---
                  #evaluate("form." & col & "_val")#
                  <input name="#col#_val" type="text">
                  --->
                  <cfset colName = #col# & "_val" />
									<input name="#colName#" type="text">#colName#
								</td>
							</tr>
						</cfloop>
					</cfoutput>
        </tbody>
			</table>
      <hr align="left" size="1" noshade>
			<table id="rptTableBottom">
			<tr>
				<td>
					<input name="RefineQuery" type="hidden" value="Yes">
					<cfoutput>
						<input type="hidden" name="columns" value="#columns#">
						<input type="hidden" name="tables" value="#tables#">
					</cfoutput>
					<input type="submit" name="Submit" value="Run Query">
					<input type="submit" name="Submit" value="Clear and Start Over">
				</td>
			</tr>
      </table>
	</form>

<!--- ******* START RunQuery START ******* --->
<cfelseif #submit# is "Run Query">
	<!--- Global Varibales used by the if statements --->
    <cfif isDefined("Cookie.OCOLUMNS")>
      <cfset theSelect = "SELECT #Cookie.OCOLUMNS#">
    <cfelse>
      <cfset theSelect = "SELECT #FORM.COLUMNS#">
    </cfif>
    <cfif isDefined("Cookie.oTables")>
      <cfset theFrom = "FROM #cookie.oTables#">
    <cfelse>
      <cfset theFrom = "FROM #form.TABLES#">
    </cfif>
  	<cfset sqlWhere = "">
  	<cfset theWHERE = "">
  	<cfset theJoin = "">
    <cfset theQuery = #theSelect# & " " & theFrom>

	<!--- RefineQuery is set to yes, which means there are additional where clauses --->
    <cfif #form.RefineQuery# EQ "YES">
        <cfloop index="col" list="#cookie.oColumns#" delimiters=",">
        	<cfif IsDefined("form." & col & "_val")>
            <cfset col_val = #evaluate("form." & col & "_val")#>
            <cfif #Len(col_val)# GT 0>
                <cfswitch expression="#evaluate(col & "_opt")#">
                    <cfcase value="Contains">
                        <cfset c = "#col# LIKE '%#col_val#%'">
                        <cfset sqlWhere = ListAppend(sqlWhere,c,"@")>
                    </cfcase>
                    <cfcase value="Is">
                        <cfset i = "#col# = '#col_val#'">
                        <cfset sqlWhere = ListAppend(sqlWhere,i,"@")>
                    </cfcase>
                    <cfcase value="Bw">
                        <cfset b = "#col# LIKE '#col_val#%'">
                        <cfset sqlWhere = ListAppend(sqlWhere,b,"@")>
                    </cfcase>
                    <cfcase value="Ew">
                        <cfset e = "#col# LIKE '%#col_val#'">
                        <cfset sqlWhere = ListAppend(sqlWhere,e,"@")>
                    </cfcase>
                </cfswitch>
            </cfif>
            </cfif>
        </cfloop>
        <!--- If filtering on query results has been done, create the where for the columns --->
        <cfif #Len(sqlWhere)# GT 0>
            <cfset sqlWhere = Replace(sqlWhere,"@"," AND ","ALL")>
            <cfset sqlWhere = "WHERE #sqlWhere#">
            <cfset theQuery = #theQuery# & " " & sqlWhere>
        </cfif>
    </cfif>
<!--- The else means that the end user clicked on run query vs. Define query --->
<cfelse>
	<cfif IsDefined("form.columns")>
        <cfset columns = #form.columns#>
    <cfelseif IsDefined("Cookie.OCOLUMNS")>
        <cfset columns = #Cookie.OCOLUMNS#>
    </cfif>
    <cfif IsDefined("form.fTables")>
        <cfset tables =  #form.tables#>
    <cfelseif IsDefined("Cookie.OTABLES")>
        <cfset tables = #Cookie.OTABLES#>
    </cfif>
    <cfcookie name="origTables" value="#tables#">
    <cfcookie name="origColumns" value="#columns#">
    <cfcookie name="origQuery" value="SELECT #columns# ">
    <cfset theQuery = "SELECT #columns# ">
    <cfset theWHERE = " WHERE ">
</cfif>

<cfif #submit# is "Run Query">
	<!--- Run the query --->
	<cftry>
		<CFQUERY NAME="qRun" DATASOURCE="#session.dbsource#">
			<cfif NOT IsDefined("url.UseSessionQuery")>
				#PreserveSingleQuotes(theQuery)#
			<cfelse>
				#PreserveSingleQuotes(session.theQuery)#
			</cfif>
		</CFQUERY>
		<cfcatch type = "Any">
			<b>ERROR: There is an error in the query, please click on the back button and verify the query.</b>
			<p>Your Query:<br>
			<cfoutput><span class="query_error_small">#PreserveSingleQuotes(theQuery)#</span>
			</p>
			#cfcatch.Detail#
			</cfoutput>
			<cfabort>
		</cfcatch>
	</cftry>

	<!--- Display the Query Results --->

	<cfoutput>
	<p>#qRun.recordcount# Records found.</p>
	</cfoutput>
	<!--- #session.theQueryNoWhere# --->
    <div style="float: left;">
	<cfform action="adhoc_report_new.cfm" method="post">
        <cfinput type="submit" name="ClearAction" value="Clear and Start Over">
	</cfform>
    </div>
    <div style="float: right;">
    <cfform action="adhoc_report_save.cfm" method="post">
    	<cfset session.qHash = Hash(theQuery,'MD5') />
    	<cfinput type="hidden" name="theQuery" value="#theQuery#">
		<cfinput type="submit" name="ReportAction" value="Save Report">
	</cfform>
    </div>
    <br />
    <hr />
	<table id="rptTable" class="tablesorter" border="0" cellpadding="0" cellspacing="1" width="100%">
		<thead>
        <tr>
			<cfloop list="#qRun.columnlist#" index="i">
			<th><cfoutput>#i#</cfoutput></th>
			</cfloop>
		</tr>
        </thead>
        <tbody>
		<cfoutput query="qRun">
		<tr>
			<cfloop list="#qRun.columnlist#" index="i">
				<td>#evaluate(i)#</td>
			</cfloop>
		</tr>
        </cfoutput>
        </tbody>
	</table>

    <div id="pager" class="pager">
    <br />
    <cfoutput>
    <form>
        <img src="/admin/js/tablesorter/pager/icons/first.png" class="first"/>
        <img src="/admin/js/tablesorter/pager/icons/prev.png" class="prev"/>
        <input type="text" class="pagedisplay"/>
        <img src="/admin/js/tablesorter/pager/icons/next.png" class="next"/>
        <img src="/admin/js/tablesorter/pager/icons/last.png" class="last"/>
        <select class="pagesize">
            <option value="10">10</option>
            <option value="20">20</option>
            <option selected="selected" value="25">25</option>
            <option value="30">30</option>
            <option value="40">40</option>
            <option value="50">50</option>
            <option value="5000">All (MAX 5,000)</option>
        </select>
    </form>
    </cfoutput>
    </div>
</cfif>

</body>
</html>
<cffunction name="getDBTables" access="private" returntype="any">
	<cfset var _db = #application.settings.database.ro#>

	<cfif structKeyExists(_db,"databasename")>
    	<cfset _dbName = #_db.databasename#>
    <cfelseif structKeyExists(_db,"dbName")>
    	<cfset _dbName = #_db.dbName#>
    </cfif>

	<CFQUERY NAME="q_Tables" DATASOURCE="#_db.dsName#">
        SELECT TABLE_NAME as object_name, TABLE_TYPE as object_type
        FROM information_schema.`TABLES`
        WHERE TABLE_SCHEMA LIKE '#_dbName#'
        AND (TABLE_NAME like 'mpi_%' OR TABLE_NAME like 'mp_clients_view')
    </CFQUERY>

    <cfreturn ValueList(q_Tables.object_name)>
</cffunction>

<cffunction name="getColumnsForTable" access="private" returntype="any">
	<cfargument name="table" required="yes">

    <cfset var _db = #application.settings.database.ro#>
    <cfif structKeyExists(_db,"databasename")>
    	<cfset _dbName = #_db.databasename#>
    <cfelseif structKeyExists(_db,"dbName")>
    	<cfset _dbName = #_db.dbName#>
    </cfif>

	<cfset var colList = "">

    <CFQUERY NAME="q_Columns" DATASOURCE="#_db.dsName#">
		<cfoutput>
            SELECT TABLE_NAME, COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '#_dbName#' AND TABLE_NAME = '#arguments.table#'
        </cfoutput>
	</CFQUERY>

    <cfoutput query="q_Columns">
    	<cfset colList = ListAppend(colList, #arguments.table# & "." & #COLUMN_NAME# ) />
    </cfoutput>
    <cfreturn colList>
</cffunction>

<cffunction name="queryToJSON" returntype="string" access="public" output="yes">
  <cfargument name="q" type="query" required="yes" />
  <cfset var o=ArrayNew(1)>
  <cfset var i=0>
  <cfset var r=0>
  <cfloop query="Arguments.q">
    <cfset r=Currentrow>
    <cfloop index="i" list="#LCase(Arguments.q.columnList)#">
      <cfset o[r][i]=Evaluate(i)>
    </cfloop>
  </cfloop>
  <cfreturn SerializeJSON(o)>
</cffunction>
