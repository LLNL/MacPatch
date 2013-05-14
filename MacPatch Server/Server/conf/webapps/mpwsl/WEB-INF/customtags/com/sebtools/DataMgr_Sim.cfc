<!--- 2.5 Beta 2 (Build 166) --->
<!--- Last Updated: 2010-12-12 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<cfcomponent extends="DataMgr" displayname="Data Manager for Simulated Database" hint="I manage simulated data interactions with a database.">

<cffunction name="init" access="public" returntype="DataMgr" output="no" hint="I instantiate and return this object.">
	<cfargument name="datasource" type="string" required="yes">
	<cfargument name="database" type="string" required="no">
	<cfargument name="username" type="string" required="no">
	<cfargument name="password" type="string" required="no">
	<cfargument name="rows" type="numeric" default="50">
	
	<cfset variables.datasource = arguments.datasource>
	
	<cfset variables.rows = arguments.rows>
	<cfset variables.tables = StructNew()><!--- Used to internally keep track of tables used by DataMgr --->
	<cfset variables.tableprops = StructNew()><!--- Used to internally keep track of tables properties used by DataMgr --->
	<cfset setCacheDate()><!--- Used to internally keep track caching --->
	
	<cfset variables.nocomparetypes = "CF_SQL_LONGVARCHAR"><!--- Don't run comparisons against fields of these cf_datatypes for queries --->
	<cfset variables.dectypes = "CF_SQL_DECIMAL"><!--- Decimal types (shouldn't be rounded by DataMgr) --->
	<cfset variables.aggregates = "avg,count,max,min,sum">
	
	<cfset variables.simdata = StructNew()>
	<cfset variables.simrows = StructNew()>
	
<cfsavecontent variable="variables.greek">Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.</cfsavecontent>
	
	<cfreturn this>
</cffunction>

<cffunction name="addColumn" access="public" returntype="any" output="no" hint="I add a column to the given table">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to which a column will be added.">
	<cfargument name="columnname" type="string" required="yes" hint="The name of the column to add.">
	<cfargument name="CF_Datatype" type="string" required="yes" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Length" type="numeric" default="50" hint="The ColdFusion SQL Datatype of the column.">
	<cfargument name="Default" type="string" required="no" hint="The default value for the column.">
	
	<!--- <cfset var type = getDBDataType(arguments.CF_Datatype)>
	
	<cfif arguments.Length eq 0>
		<cfset arguments.Length = 50>
	</cfif> --->
	
</cffunction>

<cffunction name="concat" access="public" returntype="string" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default="">
	
	<cfset var colname = "">
	<cfset var result = "">
	
	<cfloop index="colname" list="#arguments.fields#">
		<cfif Len(result)>
			<cfset result =  "#result# + '#arguments.delimeter#' + #colname#">
		<cfelse>
			<cfset result = colname>
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="concatFields" access="public" returntype="array" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default=",">
	<cfargument name="tablealias" type="string" required="no">
	
	<!--- %%TODO: Add concatFields --->
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="createTable" access="public" returntype="string" output="no" hint="I take a table for which the structure has been loaded, and create the table in the database.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var CreateSQL = getCreateSQL(arguments.tablename)>
	
	<cfreturn CreateSQL>
</cffunction>

<cffunction name="CreateTables" access="public" returntype="void" output="no" hint="I create any tables that I know should exist in the database but don't.">
	<cfargument name="tables" type="string" default="#variables.tables#" hint="I am a list of tables to create. If I am not provided createTables will try to create any table that has been loaded into it but does not exist in the database.">

</cffunction>

<cffunction name="deleteRecord" access="public" returntype="void" output="no" hint="I delete the record with the given Primary Key(s).">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table from which to delete a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure indicating the record to delete. A key indicates a field. The structure should have a key for each primary key in the table.">
	
</cffunction>

<cffunction name="getCreateSQL" access="public" returntype="string" output="no" hint="I return the SQL to create the given table.">
	<cfargument name="tablename" type="string" required="yes" hint="The name of the table to create.">
	
	<cfset var CreateSQL = ""><!--- holds sql used for creation, allows us to return it in an error --->
	
	<cfreturn CreateSQL>
</cffunction>

<cffunction name="getDatabase" access="public" returntype="string" output="no" hint="I return the database platform being used (Access,MS SQL,MySQL etc).">
	<cfreturn "Sim">
</cffunction>

<cffunction name="getDatabaseShortString" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "Sim Database">
</cffunction>

<cffunction name="getDatabaseTables" access="public" returntype="string" output="yes" hint="I get a list of all tables in the current database.">

	<cfreturn StructKeyList(variables.tables)>
</cffunction>

<cffunction name="getDatasource" access="public" returntype="string" output="no" hint="I return the datasource used by this Data Manager.">
	<cfreturn variables.datasource>
</cffunction>

<cffunction name="getDBFieldList" access="public" returntype="string" output="no" hint="I return a list of fields in the database for the given table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfreturn getFieldList(arguments.tablename)>
</cffunction>

<cffunction name="getDBTableStruct" access="public" returntype="array" output="no" hint="I return the structure of the given table in the database.">
	<cfargument name="tablename" type="string" required="yes">

	<cfreturn variables.tables[arguments.tablename]>
</cffunction>

<cffunction name="getNewSortNum" access="public" returntype="numeric" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="sortfield" type="string" required="yes" hint="The field holding the sort order.">
	
	<cfreturn (variables.rows + 1)>
</cffunction>

<cffunction name="getNowSQL" access="public" returntype="string" output="no" hint="I return the SQL for the current date/time.">
	<cfreturn "">
</cffunction>

<cffunction name="getPKFromData" access="public" returntype="string" output="no" hint="I get the primary key of the record matching the given data.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a primary key.">
	<cfargument name="fielddata" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	
	<cfreturn RandRange(1,variables.rows)>
</cffunction>

<cffunction name="getRecord" access="public" returntype="query" output="no" hint="I get a recordset based on the primary key value(s) given.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key. Every primary key field should be included.">
	
	<cfset var fields = getUpdateableFields(arguments.tablename)>
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var i = 0><!--- A generic counter --->
	<cfset var in = arguments.data>
	<cfset var totalfields = 0><!--- count of fields --->
	<cfset var qRecord = 0><!--- The record to return --->
	<cfset var maxrows = 1>
	
	<!--- Figure count of fields --->
	<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif StructKeyExists(in,pkfields[i].ColumnName) AND in[pkfields[i].ColumnName] NEQ 0>
			<cfset totalfields = totalfields + 1>
		</cfif>
	</cfloop>
	<cfloop index="i" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif StructKeyExists(in,fields[i].ColumnName)>
			<cfset totalfields = totalfields + 1>
		</cfif>
	</cfloop>
	
	<!--- Make sure at least one field is passed in --->
	<cfif totalfields eq 0>
		<!--- <cfthrow message="The data argument of getRecord must contain at least one field from the #arguments.tablename# table. To get all records, use the getRecords method." type="DataMgr" errorcode="NeedWhereFields"> --->
		<cfset maxrows = 0>
	</cfif>
	
	<cfset qRecord = getRecords(tablename=arguments.tablename,data=arguments.data,maxrows=maxrows)><!--- The record to return --->
	
	<cfreturn qRecord>
</cffunction>

<cffunction name="getRecords" access="public" returntype="query" output="no" hint="I get a recordset based on the data given.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	
	<cfset var qRecords = 0><!--- The recordset to return --->
	<cfset var fields = getUpdateableFields(arguments.tablename)><!--- non primary-key fields in table --->
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- primary key fields in table --->
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var i = 0><!--- Generic counter --->
	<cfset var columnlist = "">
	<cfset var row = 0><!--- Generic counter --->
	<cfset var qSimData = 0>
	<cfset var col = "">
	<cfset var field = 0>
	<cfset var isMatch = true>
	<cfset var rowdata = StructNew()>
	
	<!--- Set a value for maxrows if none is given --->
	<cfif NOT StructKeyExists(arguments,"maxrows")>
		<cfif StructKeyExists(variables.simrows,arguments.tablename)>
			<cfset arguments.maxrows = variables.simrows[arguments.tablename]>
		<cfelse>
			<cfset arguments.maxrows = variables.rows>
		</cfif>
	</cfif>
	
	<cfif StructKeyExists(variables.simrows,arguments.tablename) AND arguments.maxrows GT variables.simrows[arguments.tablename]>
		<cfset arguments.maxrows = variables.simrows[arguments.tablename]>
	</cfif>
	
	<!--- Create column list --->
	<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif Len(arguments.fieldlist) eq 0 OR ListFindNoCase(arguments.fieldlist, pkfields[i].ColumnName)>
			<cfset columnlist = ListAppend(columnlist,pkfields[i]["ColumnName"])>
		</cfif>
	</cfloop>
	<cfloop index="i" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif Len(arguments.fieldlist) eq 0 OR ListFindNoCase(arguments.fieldlist, fields[i].ColumnName)>
			<cfset columnlist = ListAppend(columnlist,fields[i]["ColumnName"])>
		</cfif>
	</cfloop>
	<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif Len(arguments.fieldlist) eq 0 OR ListFindNoCase(arguments.fieldlist, rfields[i].ColumnName)>
			<cfset columnlist = ListAppend(columnlist,rfields[i]["ColumnName"])>
		</cfif>
	</cfloop>
	
	<!--- If we have simulated data for this table --->
	<cfif StructKeyExists(variables.simdata,arguments.tablename) AND isQuery(variables.simdata[arguments.tablename]) AND variables.simdata[arguments.tablename].RecordCount>
		
		<cfset qSimData = variables.simdata[arguments.tablename]>
		
		<!--- Set relation field values --->
		<cfloop index="col" list="#columnlist#">
			<cfset field = getField(arguments.tablename,col)>
			<!--- If the field is a relation field, loop over the query and set the value --->
			<cfif StructKeyExists(field,"Relation")>
				<cfloop query="qSimData">
					<cfset rowdata = QueryRowToStruct(qSimData,CurrentRow)>
					<cfset QuerySetCell(qSimData, col, getRelatedData(arguments.tablename,field,rowdata),CurrentRow)>
				</cfloop>
			</cfif>
		</cfloop>
		
	<cfelse>
		<cfset qSimData = getSimRecords(argumentCollection=arguments)>
	</cfif>
	
	<cfif Len(arguments.orderby)>
		<cfset qRecords = QueryNew(ListAppend(columnlist,"DataMgrOrderField"))>
	<cfelse>
		<cfset qRecords = QueryNew(columnlist)>
	</cfif>
	
	<!--- Build record from simulated data --->
	<cfloop query="qSimData">
		<!--- Check for matching data --->
		<cfset isMatch = true>
		<cfif StructKeyExists(arguments,"data")>
			<cfloop collection="#arguments.data#" item="col">
				<cfif ListFindNoCase(qSimData.ColumnList,col) AND arguments.data[col] neq qSimData[col][CurrentRow]>
					<cfset isMatch = false>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>
		<!--- If row matches data, add row to result --->
		<cfif isMatch>
			<cfset QueryAddRow(qRecords)>
			<!--- Set value for each field --->
			<cfloop index="col" list="#columnlist#">
				<cfif ListFindNoCase(qSimData.ColumnList,col)>
					<!--- If field is in query, set its value --->
					<cfset QuerySetCell(qRecords, col, qSimData[col][CurrentRow])>
				<cfelse>
					<!--- If field is not in query, try to set a value --->
					<cfif StructKeyExists(variables.tables,arguments.tablename)>
						<cfset field = getField(arguments.tablename,col)>
						<!--- set to a default value (if one exists) --->
						<cfif StructKeyExists(field,"Default")>
							<cfset QuerySetCell(qRecords, col, field["Default"])>
						</cfif>
						<!--- If this is a relation, get the value --->
						<cfif StructKeyExists(field,"Relation")>
							<cfset rowdata = QueryRowToStruct(qRecords,CurrentRow)>
							<cfset QuerySetCell(qRecords, col, getRelatedData(arguments.tablename,field,rowdata))>
						</cfif>
					</cfif>
				</cfif>
				<!--- Add order by field for proper sorting --->
				<cfif Len(arguments.orderby)>
					<cfif ListFindNoCase(qRecords.ColumnList,arguments.orderby)>
						<cfset QuerySetCell(qRecords, "DataMgrOrderField", qRecords[arguments.orderby][qRecords.RecordCount])>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
	</cfloop>
	
	<cfif Len(arguments.orderby)>
		<cfquery name="qRecords" dbtype="query">
		SELECT		#columnlist#
		FROM		qRecords
		ORDER BY	DataMgrOrderField
		</cfquery>
	</cfif>
	
	<cfreturn qRecords>
</cffunction>

<cffunction name="getSimData" access="public" returntype="any" output="no">
	<cfreturn variables.simdata>
</cffunction>

<cffunction name="getStringTypes" access="public" returntype="string" output="no" hint="I return a list of datypes that hold strings / character values."><cfreturn ""></cffunction>

<cffunction name="loadXML" access="public" returntype="void" output="no" hint="I add table/tables from XML and optionally create tables/columns as needed (I can also load data to a table upon its creation).">
	<cfargument name="xmldata" type="string" required="yes" hint="XML data of tables to load into DataMgr follows. Schema: http://www.bryantwebconsulting.com/cfc/DataMgr.xsd">
	<cfargument name="docreate" type="boolean" default="false" hint="I indicate if the table should be created in the database if it doesn't already exist.">
	<cfargument name="addcolumns" type="boolean" default="false" hint="I indicate if missing columns should be be created.">
	
	<!--- Get simrows --->
	<cfscript>
	var varXML = XmlParse(arguments.xmldata,"no");
	var arrTables = varXML.XmlRoot.XmlChildren;
	var i = 0;
	
	//  Loop over all root elements in XML
	for (i=1; i lte ArrayLen(arrTables);i=i+1) {
		//  If element is a table and has a name, add it to the data
		if ( arrTables[i].XmlName eq "table" AND StructKeyExists(arrTables[i].XmlAttributes,"name") AND StructKeyExists(arrTables[i].XmlAttributes,"simrows") ) {
			if ( isNumeric(arrTables[i].XmlAttributes["simrows"]) ) {
				variables.simrows[arrTables[i].XmlAttributes["name"]] = Val(arrTables[i].XmlAttributes["simrows"]);
			}
		}
	}
	</cfscript>
	
	<cfset super.loadXml(xmldata,docreate,addcolumns)>
	
</cffunction>

<cffunction name="insertRecord" access="public" returntype="string" output="no" hint="I insert a record into the given table with the provided data and do my best to return the primary key of the inserted record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table in which to insert data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="OnExists" type="string" default="insert" hint="The action to take if a record with the given values exists. Possible values: insert (inserts another record), error (throws an error), update (updates the matching record), skip (performs no action).">
	
	<cfreturn variables.rows + 1>	
</cffunction>

<cffunction name="saveRecord" access="public" returntype="string" output="no" hint="I insert or update a record in the given table (update if a matching record is found) with the provided data and return the primary key of the updated record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	
	<cfreturn insertRecord(arguments.tablename,arguments.data,"update")>
</cffunction>

<cffunction name="saveRelationList" access="public" returntype="void" output="no" hint="">
	<cfargument name="tablename" type="string" required="yes" hint="The table holding the many-to-many relationships.">
	<cfargument name="keyfield" type="string" required="yes" hint="The field holding our key value for relationships.">
	<cfargument name="keyvalue" type="string" required="yes" hint="The value of out primary field.">
	<cfargument name="multifield" type="string" required="yes" hint="The field holding our many relationships for the given key.">
	<cfargument name="multilist" type="string" required="yes" hint="The list of related values for our key.">
	
</cffunction>

<cffunction name="saveSortOrder" access="public" returntype="void" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="sortfield" type="string" required="yes" hint="The field holding the sort order.">
	<cfargument name="sortlist" type="string" required="yes" hint="The list of primary key field values in sort order.">
	<cfargument name="PrecedingRecords" type="numeric" default="0" hint="The number of records preceding those being sorted.">
	
</cffunction>

<cffunction name="updateRecord" access="public" returntype="string" output="no" hint="I update a record in the given table with the provided data and return the primary key of the updated record.">
	<cfargument name="tablename" type="string" required="yes" hint="The table on which to update data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	
	<cfreturn RandRange(1,variables.rows)>
</cffunction>

<cffunction name="getCFDataType" access="public" returntype="string" output="no" hint="I return the cfqueryparam datatype from the database datatype.">
	<cfargument name="type" type="string" required="yes" hint="The database data type.">
	
	<cfreturn arguments.type>
</cffunction>

<cffunction name="getDBDataType" access="public" returntype="string" output="no" hint="I return the database datatype from the cfqueryparam datatype.">
	<cfargument name="CF_Datatype" type="string" required="yes">
	
	<cfreturn arguments.CF_Datatype>
</cffunction>

<cffunction name="getPreSeedRecords" access="private" returntype="query" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="#variables.rows#">
	
	<cfreturn QueryNew(getFieldList(arguments.tablename))>
</cffunction>

<cffunction name="getInsertedIdentity" access="private" returntype="numeric" output="no" hint="I get the value of the identity field that was just inserted into the given table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="identfield" type="string" required="yes">
	
	<cfreturn RandRange(1,variables.rows)>
</cffunction>

<cffunction name="getRelatedData" access="private" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table for which to return a record.">
	<cfargument name="field" type="struct" required="yes">
	<cfargument name="rowdata" type="struct" required="yes">
	
	<cfset var qRelatedRecords = 0>
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- primary key fields in table --->
	<cfset var data = StructNew()>
	<cfset var joindata = "">
	<cfset var temp = "">
	<cfset var result = "">
	
	<cfif StructKeyExists(field,"Default")>
		<cfset result = field.Default>
	</cfif>
	
	<cfswitch expression="#field.Relation.type#">
	<cfcase value="concat">
		<cfloop index="temp" list="#field.Relation['fields']#">
			<cfif Len(result)>
				<cfset result = "#result##field.Relation['delimiter']##rowdata[temp]#">
			<cfelse>
				<cfset result = rowdata[temp]>
			</cfif>
			<!--- <cfset result = ListAppend(result,rowdata[temp],"#field.Relation['delimiter']#")> --->
		</cfloop>
	</cfcase>
	<cfcase value="label">
		<!--- get label from table where join field values match --->
		<cftry>
			<cfset data[field.Relation["join-field-remote"]] = rowdata[field.Relation["join-field-local"]]>
			<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"],maxrows=1)>
			<cfset result = qRelatedRecords[field.Relation["field"]][1]>
			<cfcatch>
				<cfif StructKeyExists(field,"CF_Datatype")>
					<cfset result = getSimValue(field.CF_Datatype)>
				<cfelse>
					<cfset result = ProperCase(Mid(variables.greek,RandRange(1,(Len(variables.greek)-40)),40))>
				</cfif>
			</cfcatch>
		</cftry>
	</cfcase>
	<cfcase value="list">
		<cfif StructKeyExists(field.Relation,"join-table")>
			<!--- Get data from join table --->
			<cfset data[field.Relation["join-table-field-local"]] = rowdata[field.Relation["local-table-join-field"]]>
			<cfset qRelatedRecords = getRecords(tablename=field.Relation["join-table"],data=data,fieldlist=field.Relation["join-table-field-remote"])>
			<cfdump var="#qRelatedRecords#">
			<cfloop query="qRelatedRecords">
				<cfset joindata = ListAppend(joindata,qRelatedRecords[field.Relation["join-table-field-remote"]][CurrentRow])>
			</cfloop>
			<!--- Using data from join table, get data from table --->
			<cfloop index="temp" list="#joindata#">
				<cfset data[field.Relation["remote-table-join-field"]] = rowdata[field.Relation["local-table-join-field"]]>
				<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"],maxrows=1)>
				<cfset result = ListAppend(result,qRelatedRecords[field.Relation["field"]][1])>
			</cfloop>
		<cfelse>
			<cfset data[field.Relation["join-field-remote"]] = rowdata[field.Relation["join-field-local"]]>
			<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"])>
			<cfloop query="qRelatedRecords">
				<cfset result = ListAppend(result,qRelatedRecords[field.Relation["field"]][CurrentRow])>
			</cfloop>
		</cfif>
	</cfcase>
	<cfcase value="count">
		<!--- get count from table where join field values match --->
		<cfset data[field.Relation["join-field"]] = rowdata[field.Relation["join-field"]]>
		<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"])>
		<cfset result = qRelatedRecords.RecordCount>
	</cfcase>
	<cfcase value="max">
		<!--- get the max value from table where join field values match --->
		<cfset data[field.Relation["join-field"]] = rowdata[field.Relation["join-field"]]>
		<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"])>
		<cfset result = 0>
		<cfloop query="qRelatedRecords">
			<cfif qRelatedRecords[field.Relation["field"]][CurrentRow] gt result>
				<cfset result = qRelatedRecords[field.Relation["field"]][CurrentRow]>
			</cfif>
		</cfloop>
	</cfcase>
	<cfcase value="min">
		<!--- get the min value from table where join field values match --->
		<cfset data[field.Relation["join-field"]] = rowdata[field.Relation["join-field"]]>
		<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"])>
		<cfset result = "">
		
		<cfloop query="qRelatedRecords">
			<cfif qRelatedRecords[field.Relation["field"]][CurrentRow] lt result OR NOT Len(result)>
				<cfset result = qRelatedRecords[field.Relation["field"]][CurrentRow]>
			</cfif>
		</cfloop>
	</cfcase>
	<cfcase value="has">
		<cfset result = true>
	</cfcase>
	<cfcase value="hasnot">
		<cfset result = false>
	</cfcase>
	<cfcase value="now">
		<cfset result = now()>
	</cfcase>
	<cfcase value="sum">
		<!--- get the max value from table where join field values match --->
		<cfset data[field.Relation["join-field"]] = rowdata[field.Relation["join-field"]]>
		<cfset qRelatedRecords = getRecords(tablename=field.Relation["table"],data=data,fieldlist=field.Relation["field"])>
		<cfset result = 0>
		<cfloop query="qRelatedRecords">
			<cfif isNumeric(qRelatedRecords[field.Relation["field"]][CurrentRow])>
				<cfset result = result + qRelatedRecords[field.Relation["field"]][CurrentRow]>
			</cfif>
		</cfloop>
	</cfcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSimRecords" access="private" returntype="query" output="no" hint="I get a recordset based on the data given.">
	<cfargument name="tablename" type="string" required="yes" hint="The table from which to return a record.">
	<cfargument name="data" type="struct" required="no" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="orderBy" type="string" default="">
	<cfargument name="maxrows" type="numeric" default="#variables.rows#">
	<cfargument name="fieldlist" type="string" default="" hint="A list of fields to return. If left blank, all fields will be returned.">
	
	<cfset var qRecords = 0><!--- The recordset to return --->
	<cfset var fields = getUpdateableFields(arguments.tablename)><!--- non primary-key fields in table --->
	<cfset var pkfields = getPKFields(arguments.tablename)><!--- primary key fields in table --->
	<cfset var rfields = getRelationFields(arguments.tablename)><!--- relation fields in table --->
	<cfset var i = 0><!--- Generic counter --->
	<cfset var columnlist = "">
	<cfset var row = 0><!--- Generic counter --->
	<cfset var rowdata = 0>
	
	<!--- Create column list --->
	<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif Len(arguments.fieldlist) eq 0 OR ListFindNoCase(arguments.fieldlist, pkfields[i].ColumnName)>
			<cfset columnlist = ListAppend(columnlist,pkfields[i]["ColumnName"])>
		</cfif>
	</cfloop>
	<cfloop index="i" from="1" to="#ArrayLen(fields)#" step="1">
		<cfif Len(arguments.fieldlist) eq 0 OR ListFindNoCase(arguments.fieldlist, fields[i].ColumnName)>
			<cfset columnlist = ListAppend(columnlist,fields[i]["ColumnName"])>
		</cfif>
	</cfloop>
	<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
		<cfif Len(arguments.fieldlist) eq 0 OR ListFindNoCase(arguments.fieldlist, rfields[i].ColumnName)>
			<cfset columnlist = ListAppend(columnlist,rfields[i]["ColumnName"])>
		</cfif>
	</cfloop>
	
	<!--- Create data --->
	<cfset qRecords = QueryNew("#columnlist#,DataMgrOrderField")>
	
	<cfloop index="row" from="1" to="#Min(arguments.maxrows,variables.rows)#" step="1">
		<cfset QueryAddRow(qRecords)>
		<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
			<cfif ListFindNoCase(columnlist,pkfields[i]["ColumnName"])>
				<cfset QuerySetCell(qRecords, pkfields[i]["ColumnName"], getSimValue(pkfields[i]))>
			</cfif>
		</cfloop>
		<cfloop index="i" from="1" to="#ArrayLen(fields)#" step="1">
			<cfif ListFindNoCase(columnlist,fields[i]["ColumnName"])>
				<cfset QuerySetCell(qRecords, fields[i]["ColumnName"], getSimValue(fields[i]))>
			</cfif>
		</cfloop>
		<cfloop index="i" from="1" to="#ArrayLen(rfields)#" step="1">
			<cfif ListFindNoCase(columnlist,rfields[i]["ColumnName"])>
				<cfset rowdata = QueryRowToStruct(qRecords,row)>
				<cfset QuerySetCell(qRecords, rfields[i]["ColumnName"], getRelatedData(arguments.tablename,rfields[i],rowdata))>
			</cfif>
		</cfloop>
		
		<cfif Len(arguments.orderby)>
			<cfset QuerySetCell(qRecords, "DataMgrOrderField", UCase(qRecords[ListFirst(arguments.orderby," ")][row]))>
		</cfif>
	</cfloop>
	
	<cfif Len(arguments.orderby)>
		<cfquery name="qRecords" dbtype="query">
		SELECT		#ListDeleteAt(columnlist,ListLen(columnlist))#
		FROM		qRecords
		ORDER BY	DataMgrOrderField
		</cfquery>
	</cfif>
	
	<cfreturn qRecords>
</cffunction>

<cffunction name="getSimValue" access="private" returntype="string" output="no">
	<cfargument name="field" type="struct" required="yes">
	
	<cfset var result = "">
	<cfset var mylength = Min(field.Length,RandRange(10,field.Length))>
	<cfset var SpecialFormats = "email,phone,ssn">
	
	<cfswitch expression="#arguments.field.CF_DataType#">
	<cfcase value="CF_SQL_BIGINT">
		<cfset result = RandRange(1,1024)>
	</cfcase>
	<cfcase value="CF_SQL_BIT">
		<cfset result = RandRange(0,1)>
	</cfcase>
	<cfcase value="CF_SQL_CHAR">
		<cfset result = "char">
	</cfcase>
	<cfcase value="CF_SQL_DATE">
		<cfset result = DateAdd("d",RandRange(1,730),DateAdd("yyyy",-1,now()))>
	</cfcase>
	<cfcase value="CF_SQL_DECIMAL">
		<cfset result = (RandRange(100,102400)/100)>
	</cfcase>
	<cfcase value="CF_SQL_FLOAT,CF_SQL_DOUBLE">
		<cfset result = (RandRange(100,102400)/100)>
	</cfcase>
	<cfcase value="CF_SQL_IDSTAMP">
		<cfset result = CreateUUID()>
	</cfcase>
	<cfcase value="CF_SQL_INTEGER">
		<cfset result = RandRange(1,variables.rows)>
	</cfcase>
	<cfcase value="CF_SQL_CLOB,CF_SQL_LONGVARCHAR">
		<cfset result = Left(variables.greek,RandRange(500,2500))>
	</cfcase>
	<cfcase value="CF_SQL_MONEY">
		<cfset result = (RandRange(100,102400)/100)>
	</cfcase>
	<cfcase value="CF_SQL_MONEY4">
		<cfset result = (RandRange(100,102400)/100)>
	</cfcase>
	<cfcase value="CF_SQL_NUMERIC">
		<cfset result = RandRange(1,512)>
	</cfcase>
	<cfcase value="CF_SQL_REAL">
	<cfset result = "real">
		<cfset result = RandRange(1,1048576)>
	</cfcase>
	<cfcase value="CF_SQL_SMALLINT">
	<cfset result = "smallint">
		<cfset result = RandRange(1,64)>
	</cfcase>
	<cfcase value="CF_SQL_TINYINT">
		<cfset result = RandRange(1,8)>
	</cfcase>
	<cfcase value="CF_SQL_VARCHAR">
		<cfset result = ProperCase(Mid(variables.greek,RandRange(1,(Len(variables.greek)-mylength)),mylength))>
	</cfcase>
	<cfdefaultcase><cfthrow message="DataMgr object cannot handle this data type." type="DataMgr" detail="DataMgr cannot handle data type '#arguments.field.CF_Datatype#'" errorcode="InvalidDataType"></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="isStringType" access="private" returntype="boolean" output="no" hint="I indicate if the given datatype is valid for string data.">
	<cfargument name="type" type="string">

	<cfset var strtypes = "CF_SQL_CHAR,CF_SQL_VARCHAR">
	<cfset var result = false>
	<cfif ListFindNoCase(strtypes,arguments.type)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="ProperCase" access="private" returntype="string" output="no">
	<cfargument name="string" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var word = "">
	<cfset var myword = "">
	
	<cfloop index="word" list="#arguments.string#" delimiters=" ">
		<cfset myword = UCase(Left(word,1)) & LCase(Mid(word,2,Len(word)))>
		<cfset result = ListAppend(result,myword," ")>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="seedRecord" access="private" returntype="string" output="no">
	<cfargument name="tablename" type="string" required="yes" hint="The table in which to insert data.">
	<cfargument name="data" type="struct" required="yes" hint="A structure with the data for the desired record. Each key/value indicates a value for the field matching that key.">
	<cfargument name="OnExists" type="string" default="insert" hint="The action to take if a record with the given values exists. Possible values: insert (inserts another record), error (throws an error), update (updates the matching record), skip (performs no action).">
	
	<cfset var pkfields = getPKFields(arguments.tablename)>
	<cfset var i = 0>
	<cfset var fieldlist = getFieldList(arguments.tablename)>
	<cfset var col = "">
	<cfset var field = 0>
	
	<cfif NOT StructKeyExists(variables.simdata,arguments.tablename)>
		<cfset variables.simdata[arguments.tablename] = QueryNew(fieldlist)>
	</cfif>
	
	<!--- Set primary key values that increment --->
	<cfloop index="i" from="1" to="#ArrayLen(pkfields)#" step="1">
		<cfif StructKeyExists(pkfields[i],"Increment")>
			<cfif StructKeyExists(pkfields[i],"CF_DataType") AND pkfields[i]["CF_DataType"] eq "IDSTAMP">
				<cfset data[pkfields[i]["ColumnName"]] = CreateUUID()>
			<cfelse>
				<!--- Increment value --->
				<cfset data[pkfields[i]["ColumnName"]] = variables.simdata[arguments.tablename].RecordCount + 1>
			</cfif>
		</cfif>
	</cfloop>
	
	<!--- Set default values --->
	<cfloop index="col" list="#fieldlist#">
		<cfif NOT StructKeyExists(data,col)>
			<cfset field = getField(arguments.tablename,col)>
			<cfif StructKeyExists(field,"Special") AND Len(field["Special"])>
				<cfswitch expression="#field.Special#">
				<cfcase value="CreationDate,LastUpdatedDate">
					<cfset data[col] = now()>
				</cfcase>
				</cfswitch>
			<cfelseif StructKeyExists(field,"Default") AND Len(field["Default"])>
				<cfset data[col] = field["Default"]>
			</cfif>
		</cfif>
	</cfloop>
	
	<!--- Add the record --->
	<cfset QueryAddRow(variables.simdata[arguments.tablename])>
	<cfloop collection="#data#" item="col">
		<cfif ListFindNoCase(variables.simdata[arguments.tablename].ColumnList,col)>
			<cfset QuerySetCell(variables.simdata[arguments.tablename], col, data[col])>
		</cfif>
	</cfloop>
	
	<cfreturn insertRecord(argumentCollection=arguments)>
</cffunction>
<cfscript>
/**
 * Makes a row of a query into a structure.
 * 
 * @param query 	 The query to work with. 
 * @param row 	 Row number to check. Defaults to row 1. 
 * @return Returns a structure. 
 * @author Nathan Dintenfass (nathan@changemedia.com) 
 * @version 1, December 11, 2001 
 */
function queryRowToStruct(query){
	//by default, do this to the first row of the query
	var row = 1;
	//a var for looping
	var ii = 1;
	//the cols to loop over
	var cols = listToArray(query.columnList);
	//the struct to return
	var stReturn = structnew();
	//if there is a second argument, use that for the row number
	if(arrayLen(arguments) GT 1)
		row = arguments[2];
	//loop over the cols and build the struct from the query row
	for(ii = 1; ii lte arraylen(cols); ii = ii + 1){
		stReturn[cols[ii]] = query[cols[ii]][row];
	}		
	//return the struct
	return stReturn;
}
</cfscript>

</cfcomponent>