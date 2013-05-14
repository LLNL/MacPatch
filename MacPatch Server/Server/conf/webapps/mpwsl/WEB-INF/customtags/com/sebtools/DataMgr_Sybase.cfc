<!--- 2.5 Beta 2 (Build 166) --->
<!--- Last Updated: 2010-12-12 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<cfcomponent extends="DataMgr" displayname="Data Manager for Sybase" hint="I manage data interactions with the Sybase database.">

<cffunction name="getDatabase" access="public" returntype="string" output="no" hint="I return the database platform being used (Access,MS SQL,MySQL etc).">
	<cfreturn "Sybase">
</cffunction>

<cffunction name="getDatabaseShortString" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "sqlserver">
</cffunction>

<cffunction name="getDatabaseDriver" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "MSSQLServer">
</cffunction>

<cffunction name="sqlCreateColumn" access="public" returntype="any" output="false" hint="">
	<cfargument name="field" type="struct" required="yes">
	
	<cfset var sField = adjustColumnArgs(arguments.field)>
	<cfset var type = getDBDataType(sField.CF_DataType)>
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>#escape(sField.ColumnName)# #type#<cfif isStringType(type)> (#sField.Length#)<cfelseif getTypeOfCFType(sField.CF_DataType) EQ "numeric" AND StructKeyExists(sField,"scale") AND StructKeyExists(sField,"precision")>(#Val(sField.precision)#,#Val(sField.scale)#)</cfif><cfif sField.Increment> IDENTITY (1, 1)</cfif><cfif Len(Trim(sField.Default))> DEFAULT #sField.Default#<cfelseif sField.PrimaryKey AND sField.CF_DataType EQ "CF_SQL_IDSTAMP"> DEFAULT (newid())</cfif> <cfif sField.PrimaryKey OR NOT sField.AllowNulls>NOT </cfif>NULL</cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="getCreateSQL" access="public" returntype="string" output="no" hint="I return the SQL to create the given table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var ii = 0><!--- generic counter --->
	<cfset var arrFields = getFields(arguments.tablename)><!--- table structure --->
	<cfset var CreateSQL = ""><!--- holds sql to create table --->
	<cfset var pkfields = "">
	<cfset var thisField = "">
	
	<!--- Find Primary Key fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		<cfif arrFields[ii].PrimaryKey>
			<cfset pkfields = ListAppend(pkfields,arrFields[ii].ColumnName)>
		</cfif>
	</cfloop>
	
	<!--- create sql to create table --->
	<cfsavecontent variable="CreateSQL"><cfoutput>
	<!--- IF NOT EXISTS(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '#arguments.tablename#') --->
		CREATE TABLE #escape(arguments.tablename)# (<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
			#sqlCreateColumn(arrFields[ii])#,</cfloop>
			<cfif Len(pkfields)>
			CONSTRAINT [PK_#tablename#] PRIMARY KEY CLUSTERED 
			(<cfloop index="ii" from="1" to="#ListLen(pkfields)#" step="1"><cfset thisField = ListGetAt(pkfields,ii)>
				#thisField#<cfif ii LT ListLen(pkfields)>,</cfif></cfloop>
			)  ON [PRIMARY]
			</cfif>
		)<cfif Len(pkfields)> ON [PRIMARY]</cfif>
	<!--- GO --->
	</cfoutput></cfsavecontent>
	
	<cfreturn CreateSQL>
</cffunction>

<cffunction name="concat" access="public" returntype="string" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default="">
	
	<cfset var colname = "">
	<cfset var result = "">
	
	<cfloop index="colname" list="#arguments.fields#">
		<cfif Len(result)>
			<cfset result =  "#result# + '#arguments.delimeter#' + CAST(#colname# AS varchar(500))">
		<cfelse>
			<cfset result = "CAST(#colname# AS varchar(500))">
		</cfif>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="concatFields" access="public" returntype="array" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default=",">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var col = "">
	<cfset var aSQL = ArrayNew(1)>
	<cfset var fieldSQL = 0>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfloop index="col" list="#arguments.fields#">
		<cfset fieldSQL = getFieldSelectSQL(tablename=arguments.tablename,field=col,tablealias=arguments.tablealias,useFieldAlias=false)>
		<cfif ArrayLen(aSQL)>
			<cfset ArrayAppend(aSQL," + '#arguments.delimeter#' + ")>
		</cfif>
		<cfif isSimpleValue(fieldSQL)>
			<cfset ArrayAppend(aSQL,"ISNULL(CAST(#fieldSQL# AS varchar(500)),'')")>
		<cfelse>
			<cfset ArrayAppend(aSQL,"ISNULL(CAST(")>
			<cfset ArrayAppend(aSQL,fieldSQL)>
			<cfset ArrayAppend(aSQL," AS varchar(500)),'')")>
		</cfif>
	</cfloop>
	
	<cfreturn aSQL>
</cffunction>

<cffunction name="escape" access="public" returntype="string" output="no" hint="I return an escaped value for a table or field.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var item = "">
	
	<cfloop index="item" list="#arguments.name#" delimiters=".">
		<cfset result = ListAppend(result,"[#item#]",".")>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDatabaseTables" access="public" returntype="string" output="no" hint="I get a list of all tables in the current database.">

	<cfset var qTables = 0>
	
	<cfset qTables = runSQL("SELECT Table_Name FROM INFORMATION_SCHEMA.TABLES WHERE Table_Type = 'BASE TABLE' AND Table_Name <> 'dtproperties'")>
	
	<cfreturn ValueList(qTables.Table_Name)>
</cffunction>

<cffunction name="getDBTableStruct" access="public" returntype="array" output="no" hint="I return the structure of the given table in the database.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfscript>
	var qStructure = 0;
	var qPrimaryKeys = 0;
	var qIndices = 0;
	var TableData = ArrayNew(1);
	var tmpStruct = StructNew();
	var PrimaryKeys = "";
	var sqlarray = ArrayNew(1);
	</cfscript>
	
	<cfset sqlarray = ArrayNew(1)>
	<cfset ArrayAppend(sqlarray,"SELECT")>
	<cfset ArrayAppend(sqlarray,"			COLUMN_NAME AS Field,")>
	<cfset ArrayAppend(sqlarray,"			DATA_TYPE AS Type,")>
	<cfset ArrayAppend(sqlarray,"			CHARACTER_MAXIMUM_LENGTH AS MaxLength,")>
	<cfset ArrayAppend(sqlarray,"			IS_NULLABLE AS AllowNulls,")>
	<cfset ArrayAppend(sqlarray,"			ColumnProperty( Object_ID('#arguments.tablename#'),COLUMN_NAME,'IsIdentity') AS IsIdentity,")>
	<cfset ArrayAppend(sqlarray,"			Column_Default as #escape("Default")#,")>
	<cfset ArrayAppend(sqlarray,"			NUMERIC_PRECISION AS [Precision],")>
	<cfset ArrayAppend(sqlarray,"			NUMERIC_SCALE AS Scale")>
	<cfset ArrayAppend(sqlarray,"FROM		INFORMATION_SCHEMA.COLUMNS")>
	<cfset ArrayAppend(sqlarray,"WHERE		table_name = '#arguments.tablename#'")>
	<cfset ArrayAppend(sqlarray,"ORDER BY	Ordinal_Position")>
	<cfset qStructure = runSQLArray(sqlarray)>
	
	<cfif qStructure.RecordCount eq 0>
		<cfthrow message="Data Manager: No such table (#arguments.tablename#). Trying to load a table that doesn't exist." type="DataMgr">
	</cfif>
	
	<cfset sqlarray = ArrayNew(1)>
	<cfset ArrayAppend(sqlarray,"SELECT		Column_Name")>
	<cfset ArrayAppend(sqlarray,"FROM		INFORMATION_SCHEMA.TABLE_CONSTRAINTS")>
	<cfset ArrayAppend(sqlarray,"INNER JOIN	INFORMATION_SCHEMA.KEY_COLUMN_USAGE")>
	<cfset ArrayAppend(sqlarray,"	ON		INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.KEY_COLUMN_USAGE.CONSTRAINT_NAME")>
	<cfset ArrayAppend(sqlarray,"WHERE		INFORMATION_SCHEMA.TABLE_CONSTRAINTS.Table_Name = '#arguments.tablename#'")>
	<cfset ArrayAppend(sqlarray,"	AND		CONSTRAINT_TYPE = 'PRIMARY KEY'")>
	<cfset qPrimaryKeys = runSQLArray(sqlarray)>
	
	<cfif qPrimaryKeys.RecordCount>
		<cfset PrimaryKeys = ValueList(qPrimaryKeys.Column_Name)>
	</cfif>
	
	<cfoutput query="qStructure">
		<cfset tmpStruct = StructNew()>
		<cfset tmpStruct["ColumnName"] = Field>
		<cfset tmpStruct["CF_DataType"] = getCFDataType(Type)>
		<cfif ListFindNoCase(PrimaryKeys,Field)>
			<cfset tmpStruct["PrimaryKey"] = true>
		</cfif>
		<cfif isBoolean(Trim(IsIdentity))>
			<cfset tmpStruct["Increment"] = IsIdentity>
		</cfif>
		<cfif Len(MaxLength) AND isNumeric(MaxLength) AND NOT tmpStruct["CF_DataType"] eq "CF_SQL_LONGVARCHAR">
			<cfset tmpStruct["length"] = MaxLength>
		</cfif>
		<cfif isBoolean(Trim(AllowNulls))>
			<cfset tmpStruct["AllowNulls"] = Trim(AllowNulls)>
		</cfif>
		<cfset tmpStruct["Precision"] = Precision>
		<cfset tmpStruct["Scale"] = Scale>
		<cfif Len(Default)>
			<cfset tmpStruct["Default"] = Default>
		</cfif>
		
		<cfif Len(tmpStruct.CF_DataType)>
			<cfset ArrayAppend(TableData,adjustColumnArgs(tmpStruct))>
		</cfif>
	</cfoutput>
	
	<cfreturn TableData>
</cffunction>

<cffunction name="getCFDataType" access="public" returntype="string" output="no" hint="I return the cfqueryparam datatype from the database datatype.">
	<cfargument name="type" type="string" required="yes" hint="The database data type.">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.type#">
		<cfcase value="bigint"><cfset result = "CF_SQL_BIGINT"></cfcase>
		<cfcase value="binary,image,sql_variant,sysname,varbinary"><cfset result = ""></cfcase>
		<cfcase value="bit"><cfset result = "CF_SQL_BIT"></cfcase>
		<cfcase value="char"><cfset result = "CF_SQL_CHAR"></cfcase>
		<cfcase value="datetime"><cfset result = "CF_SQL_DATE"></cfcase>
		<cfcase value="decimal"><cfset result = "CF_SQL_DECIMAL"></cfcase>
		<cfcase value="float"><cfset result = "CF_SQL_FLOAT"></cfcase>
		<cfcase value="int"><cfset result = "CF_SQL_INTEGER"></cfcase>
		<cfcase value="money"><cfset result = "CF_SQL_MONEY"></cfcase>
		<cfcase value="nchar"><cfset result = "CF_SQL_CHAR"></cfcase>
		<cfcase value="ntext"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
		<cfcase value="numeric"><cfset result = "CF_SQL_NUMERIC"></cfcase>
		<cfcase value="nvarchar"><cfset result = "CF_SQL_VARCHAR"></cfcase>
		<cfcase value="real"><cfset result = "CF_SQL_REAL"></cfcase>
		<cfcase value="smalldatetime"><cfset result = "CF_SQL_DATE"></cfcase>
		<cfcase value="smallint"><cfset result = "CF_SQL_SMALLINT"></cfcase>
		<cfcase value="smallmoney"><cfset result = "CF_SQL_MONEY4"></cfcase>
		<cfcase value="text"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
		<cfcase value="timestamp"><cfset result = "CF_SQL_TIMESTAMP"></cfcase>
		<cfcase value="tinyint"><cfset result = "CF_SQL_TINYINT"></cfcase>
		<cfcase value="uniqueidentifier"><cfset result = "CF_SQL_IDSTAMP"></cfcase>
		<cfcase value="varchar"><cfset result = "CF_SQL_VARCHAR"></cfcase>
		<cfdefaultcase><cfset result = ""></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDBDataType" access="public" returntype="string" output="no" hint="I return the database datatype from the cfqueryparam datatype.">
	<cfargument name="CF_Datatype" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.CF_Datatype#">
		<cfcase value="CF_SQL_BIGINT"><cfset result = "bigint"></cfcase>
		<cfcase value="CF_SQL_BIT"><cfset result = "bit"></cfcase>
		<cfcase value="CF_SQL_CHAR"><cfset result = "char"></cfcase>
		<cfcase value="CF_SQL_DATE"><cfset result = "datetime"></cfcase>
		<cfcase value="CF_SQL_DECIMAL"><cfset result = "decimal"></cfcase>
		<cfcase value="CF_SQL_DOUBLE"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_FLOAT"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_IDSTAMP"><cfset result = "uniqueidentifier"></cfcase>
		<cfcase value="CF_SQL_INTEGER"><cfset result = "int"></cfcase>
		<cfcase value="CF_SQL_LONGVARCHAR"><cfset result = "text"></cfcase>
		<cfcase value="CF_SQL_MONEY"><cfset result = "money"></cfcase>
		<cfcase value="CF_SQL_MONEY4"><cfset result = "smallmoney"></cfcase>
		<cfcase value="CF_SQL_NUMERIC"><cfset result = "numeric"></cfcase>
		<cfcase value="CF_SQL_REAL"><cfset result = "real"></cfcase>
		<cfcase value="CF_SQL_SMALLINT"><cfset result = "smallint"></cfcase>
		<cfcase value="CF_SQL_TIMESTAMP"><cfset result = "timestamp"></cfcase>
		<cfcase value="CF_SQL_TINYINT"><cfset result = "tinyint"></cfcase>
		<cfcase value="CF_SQL_VARCHAR"><cfset result = "varchar"></cfcase>
		<cfdefaultcase><cfthrow message="DataMgr object cannot handle this data type." type="DataMgr" detail="DataMgr cannot handle data type '#arguments.CF_Datatype#'" errorcode="InvalidDataType"></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldSQL_Has" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var sField = getField(arguments.tablename,arguments.field)>
	<cfset var dtype = getEffectiveDataType(arguments.tablename,sField.Relation.field)>
	<cfset var aSQL = ArrayNew(1)>
	<cfset var sAdvSQL = StructNew()>
	<cfset var sJoin = StructNew()>
	<cfset var sArgs = StructNew()>
	<cfset var temp = "">
	
	<cfswitch expression="#dtype#">
	<cfcase value="numeric">
		<cfset ArrayAppend(aSQL,"CASE WHEN (")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") > 0 THEN 1 ELSE 0 END")>
	</cfcase>
	<cfcase value="string">
		<cfset ArrayAppend(aSQL,"CASE WHEN ( isnull(len(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,"),0) ) > 0 THEN 1 ELSE 0 END")>
	</cfcase>
	<cfcase value="date">
		<cfset ArrayAppend(aSQL,"CASE WHEN (")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,") IS NULL THEN 0 ELSE 1 END")>
	</cfcase>
	<cfcase value="boolean">
		<cfset ArrayAppend(aSQL,"isnull(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,",0)")>
	</cfcase>
	</cfswitch>
	
	<cfreturn aSQL>	
</cffunction>

<cffunction name="getNowSQL" access="public" returntype="string" output="no" hint="I return the SQL for the current date/time.">
	<cfreturn "getDate()">
</cffunction>

<cffunction name="isValidDate" access="public" returntype="boolean" output="no">
	<cfargument name="value" type="string" required="yes">
	
	<cfreturn isDate(arguments.value) AND Year(arguments.value) GTE 1753 AND arguments.value LT CreateDate(2079,6,7)>
</cffunction>

<cffunction name="checkTable" access="private" returntype="boolean" output="no" hint="I check to see if the given table exists in the Datamgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfif NOT StructKeyExists(variables.tables,arguments.tablename)>
		<cfset loadTable(arguments.tablename)>
	</cfif>
	
	<cfreturn true>
</cffunction>

<cffunction name="getDBTableIndexes" access="public" returntype="query" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="no">
	
	<cfset var sql = "">
	<cfset var fields = "">
	<cfset var qRawIndexes = 0>
	<cfset var qIndexes = QueryNew("tablename,indexname,fields,unique,clustered")>
	
	<cfsavecontent variable="sql"><cfoutput>
	SELECT		object_name(i.id) AS table_name,
				col_name(i.id, ik.colid) AS column_name,
				i.name AS index_name,
				indexproperty(i.id, i.name, 'IsClustered') AS isclustered,
				ik.keyno AS index_order,
				INDEXPROPERTY( i.id , i.name , 'IsUnique' ) AS isunique
	FROM		sysindexes i
	JOIN		sysindexkeys ik
		ON		i.id = ik.id
		AND		i.indid = ik.indid
	WHERE		i.indid BETWEEN 1 AND 254
		AND 	indexproperty(i.id, name, 'IsHypothetical') = 0
		AND 	indexproperty(i.id, name, 'IsStatistics') = 0
		AND 	indexproperty(i.id, name, 'IsAutoStatistics') = 0
		AND 	objectproperty(i.id, 'IsMsShipped') = 0
		AND		object_name(i.id) = '#arguments.tablename#'
		<cfif StructKeyExists(arguments,"indexname")>
		AND 	i.name = '#arguments.indexname#'
		</cfif>
		AND		NOT i.name LIKE 'PK_%'
	ORDER BY	table_name, i.id, ik.colid, isclustered DESC, ik.keyno
	</cfoutput></cfsavecontent>
	
	<cfset qRawIndexes = runSQL(sql)>
	
	<cfoutput query="qRawIndexes" group="index_name">
		<cfset fields = "">
		<cfset QueryAddRow(qIndexes)>
		<cfset QuerySetCell(qIndexes,"tablename",table_name)>
		<cfset QuerySetCell(qIndexes,"indexname",index_name)>
		<cfset QuerySetCell(qIndexes,"unique",isunique)>
		<cfset QuerySetCell(qIndexes,"clustered",isclustered)>
		<cfoutput>
			<cfset fields = ListAppend(fields,column_name)>
		</cfoutput>
		<cfset QuerySetCell(qIndexes,"fields",fields)>
	</cfoutput>
	
	<cfreturn qIndexes>
</cffunction>

<cffunction name="getInsertedIdentity" access="private" returntype="string" output="no" hint="I get the value of the identity field that was just inserted into the given table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="identfield" type="string" required="yes">
	
	<cfset var qCheckKey = 0>
	<cfset var result = 0>
	
	<cfset qCheckKey = runSQL("SELECT	IDENT_CURRENT ('#arguments.tablename#') AS NewID")>
	
	<cfset result = qCheckKey.NewID>
	
	<cfreturn result>
</cffunction>

<cffunction name="hasIndex" access="private" returntype="boolean" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="yes">
	
	<cfset var result = false>
	<cfset var qIndexes = RunSQL("
	SELECT	1
	FROM	sysindexes
	WHERE	name = '#arguments.indexname#'
	")>
	
	<cfif qIndexes.RecordCount>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isStringType" access="private" returntype="boolean" output="no" hint="I indicate if the given datatype is valid for string data.">
	<cfargument name="type" type="string">

	<cfset var strtypes = "char,nchar,nvarchar,varchar">
	<cfset var result = false>
	<cfif ListFindNoCase(strtypes,arguments.type)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

</cfcomponent>