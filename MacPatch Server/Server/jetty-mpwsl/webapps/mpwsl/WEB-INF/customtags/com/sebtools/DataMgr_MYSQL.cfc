<!--- 2.5 Beta 2 (Build 166) --->
<!--- Last Updated: 2010-12-12 --->
<!--- Created by Steve Bryant 2004-12-08 --->
<cfcomponent extends="DataMgr" displayname="Data Manager for MySQL" hint="I manage data interactions with the MySQL database.">

<cffunction name="getDatabase" access="public" returntype="string" output="no" hint="I return the database platform being used (Access,MS SQL,MySQL etc).">
	<cfreturn "MySQL">
</cffunction>

<cffunction name="getDatabaseShortString" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "mysql">
</cffunction>

<cffunction name="getDatabaseDriver" access="public" returntype="string" output="no" hint="I return the string that can be found in the driver or JDBC URL for the database platform being used.">
	<cfreturn "MySQL">
</cffunction>

<cffunction name="sqlCreateColumn" access="public" returntype="any" output="false" hint="">
	<cfargument name="field" type="struct" required="yes">
	
	<cfset var sField = adjustColumnArgs(arguments.field)>
	<cfset var type = getDBDataType(sField.CF_DataType)>
	<cfset var result = "">
	
	<cfsavecontent variable="result"><cfoutput>#escape(sField.ColumnName)# #type#<cfif isStringType(type)>(#sField.Length#)<cfelseif getTypeOfCFType(sField.CF_DataType) EQ "numeric" AND StructKeyExists(sField,"scale") AND StructKeyExists(sField,"precision")>(#Val(sField.precision)#,#Val(sField.scale)#)</cfif><cfif sField.Increment> AUTO_INCREMENT</cfif><cfif Len(Trim(sField.Default)) AND sField.Default NEQ getNowSQL() AND NOT sField.Default CONTAINS "0000-00-00"> DEFAULT #sField.Default#</cfif> <cfif sField.PrimaryKey>NOT NULL</cfif></cfoutput></cfsavecontent>
	
	<cfreturn result>
</cffunction>

<cffunction name="getCreateSQL" access="public" returntype="string" output="no" hint="I return the SQL to create the given table.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfset var ii = 0><!--- generic counter --->
	<cfset var arrFields = getFields(arguments.tablename)><!--- table structure --->
	<cfset var CreateSQL = ""><!--- sql to create table --->
	<cfset var pkfields = "">
	<cfset var thisField = "">
	
	<!--- Find Primary Key fields --->
	<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		<cfif arrFields[ii].PrimaryKey>
			<cfset pkfields = ListAppend(pkfields,arrFields[ii].ColumnName)>
		</cfif>
	</cfloop>
	
	<!--- Create sql to create table --->
	<cfsavecontent variable="CreateSQL"><cfoutput>
	CREATE TABLE #escape(arguments.tablename)# (<cfloop index="ii" from="1" to="#ArrayLen(arrFields)#" step="1">
		#sqlCreateColumn(arrFields[ii])#<cfif ii LT ArrayLen(arrFields) OR Len(pkfields)>,</cfif></cfloop>
		<cfif Len(pkfields)>primary key (#pkfields#)</cfif>
	)
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
			<cfset result =  "#result#, '#arguments.delimeter#', #colname#">
		<cfelse>
			<cfset result = "#colname#">
		</cfif>
	</cfloop>
	<cfset result = "CONCAT(#result#)">
	
	<cfreturn result>
</cffunction>

<cffunction name="concatFields" access="public" returntype="array" output="no" hint="I return the SQL to concatenate the given fields with the given delimeter.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="fields" type="string" required="yes">
	<cfargument name="delimeter" type="string" default=",">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var col = "">
	<cfset var aSQL = ArrayNew(1)>
	<cfset var aSQL2 = ArrayNew(1)>
	<cfset var fieldSQL = 0>
	
	<cfif NOT StructKeyExists(arguments,"tablealias")>
		<cfset arguments.tablealias = arguments.tablename>
	</cfif>
	
	<cfloop index="col" list="#arguments.fields#">
		<cfset fieldSQL = getFieldSelectSQL(tablename=arguments.tablename,field=col,tablealias=arguments.tablealias,useFieldAlias=false)>
		<cfif ArrayLen(aSQL)>
			<cfset ArrayAppend(aSQL,", '#arguments.delimeter#', ")>
		</cfif>
		<cfif isSimpleValue(fieldSQL)>
			<cfset ArrayAppend(aSQL,"#fieldSQL#")>
		<cfelse>
			<!--- <cfset ArrayAppend(aSQL,"CAST(")> --->
			<cfset ArrayAppend(aSQL,fieldSQL)>
			<!--- <cfset ArrayAppend(aSQL," AS varchar)")> --->
		</cfif>
	</cfloop>
	<cfset ArrayAppend(aSQL2,"CONCAT(")>
	<cfset ArrayAppend(aSQL2,aSQL)>
	<cfset ArrayAppend(aSQL2,")")>
	
	<cfreturn aSQL2>
</cffunction>

<cffunction name="escape" access="public" returntype="string" output="yes" hint="I return an escaped value for a table or field.">
	<cfargument name="name" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var item = "">
	
	<cfloop index="item" list="#arguments.name#" delimiters=".">
		<cfset result = ListAppend(result,"`#item#`",".")>
	</cfloop>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDatabaseTables" access="public" returntype="string" output="yes" hint="I get a list of all tables in the current database.">

	<cfset var qTables = runSQL("SHOW TABLES")>
	<cfset var tables = "">
	
	<cfoutput query="qTables">
		<cfset tables = ListAppend(tables,qTables[ListFirst(qTables.ColumnList)][CurrentRow])>
	</cfoutput>
	
	<cfreturn tables>
</cffunction>

<cffunction name="getDBTableStruct" access="public" returntype="array" output="no" hint="I return the structure of the given table in the database.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfscript>
	var qTable = runSQL("SHOW TABLES LIKE '#arguments.tablename#'");
	var qFields = 0;
	var qPrimaryKeys = 0;
	var PrimaryKeys = 0;
	var TableData = ArrayNew(1);
	var tmpStruct = StructNew();
	</cfscript>
	
	<cfif qTable.RecordCount eq 0>
		<cfthrow message="Data Manager: No such table. Trying to load a table that doesn't exist." type="DataMgr">
	</cfif>
	
	<cfset qFields = runSQL("SHOW COLUMNS FROM #arguments.tablename#")>
	
	<cfoutput query="qFields">
		<cfif Key eq "PRI">
			<cfset PrimaryKeys = ListAppend(PrimaryKeys,"field")>
		</cfif>
	</cfoutput>
	
	<cfoutput query="qFields">
		<cfset tmpStruct = StructNew()>
		<cfset tmpStruct["ColumnName"] = Field>
		<cfset tmpStruct["CF_DataType"] = getCFDataType(Trim(ListFirst(type,"(")))>
		<cfif Extra eq "auto_increment">
			<cfset tmpStruct["Increment"] = True>
		</cfif>
		<cfif Key eq "PRI">
			<cfset tmpStruct["PrimaryKey"] = true>
		</cfif>
		<cfif isStringType(type) AND NOT tmpStruct["CF_DataType"] eq "CF_SQL_LONGVARCHAR">
			<cfset tmpStruct["length"] = getLength(type)>
		</cfif>
		<cfif NULL eq "Yes">
			<cfset tmpStruct["AllowNulls"] = true>
		</cfif>
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
	<cfif FindNoCase(arguments.type,"(")>
		<cfset arguments.type = Left(arguments.type,FindNoCase(arguments.type,"("))>
	</cfif>
	
	<cfswitch expression="#arguments.type#">
		<cfcase value="bigint"><cfset result = "CF_SQL_BIGINT"></cfcase>
		<cfcase value="binary,image,sql_variant,sysname,varbinary"><cfset result = ""></cfcase>
		<cfcase value="bit"><cfset result = "CF_SQL_BIT"></cfcase>
		<cfcase value="char"><cfset result = "CF_SQL_CHAR"></cfcase>
		<cfcase value="date,datetime"><cfset result = "CF_SQL_DATE"></cfcase>
		<cfcase value="decimal"><cfset result = "CF_SQL_DECIMAL"></cfcase>
		<cfcase value="double"><cfset result = "CF_SQL_DOUBLE"></cfcase>
		<cfcase value="float"><cfset result = "CF_SQL_FLOAT"></cfcase>
		<cfcase value="int"><cfset result = "CF_SQL_INTEGER"></cfcase>
		<cfcase value="mediumint"><cfset result = "CF_SQL_INTEGER"></cfcase>
		<cfcase value="mediumtext"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
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
		<cfcase value="longtext"><cfset result = "CF_SQL_LONGVARCHAR"></cfcase>
		<cfcase value="timestamp"><cfset result = "CF_SQL_TIMESTAMP"></cfcase>
		<cfcase value="tinyint"><cfset result = "CF_SQL_BIT"></cfcase>
		<cfcase value="uniqueidentifier"><cfset result = "CF_SQL_IDSTAMP"></cfcase>
		<cfcase value="varchar"><cfset result = "CF_SQL_VARCHAR"></cfcase>
		<cfdefaultcase><cfset result = "UNKNOWN"></cfdefaultcase>
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDBDataType" access="public" returntype="string" output="no" hint="I return the database datatype from the cfqueryparam datatype.">
	<cfargument name="CF_Datatype" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.CF_Datatype#">
		<cfcase value="CF_SQL_BIGINT"><cfset result = "bigint"></cfcase>
		<cfcase value="CF_SQL_BIT"><cfset result = "tinyint"></cfcase>
		<cfcase value="CF_SQL_CHAR"><cfset result = "char"></cfcase>
		<cfcase value="CF_SQL_DATE"><cfset result = "datetime"></cfcase>
		<cfcase value="CF_SQL_DECIMAL"><cfset result = "decimal"></cfcase>
		<cfcase value="CF_SQL_DOUBLE"><cfset result = "double"></cfcase>
		<cfcase value="CF_SQL_FLOAT"><cfset result = "float"></cfcase>
		<cfcase value="CF_SQL_IDSTAMP"><cfset result = "varchar"></cfcase>
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

<cffunction name="getMaxRowsPrefix" access="public" returntype="string" output="no" hint="I get the SQL before the field list in the select statement to limit the number of rows.">
	<cfargument name="maxrows" type="numeric" required="yes">
	<cfargument name="offset" type="numeric" default="0">
	
	<cfreturn "">
</cffunction>

<cffunction name="getMaxRowsSuffix" access="public" returntype="string" output="no" hint="I get the SQL before the field list in the select statement to limit the number of rows.">
	<cfargument name="maxrows" type="numeric" required="yes">
	<cfargument name="offset" type="numeric" default="0">
	
	<cfset var result = " LIMIT #arguments.maxrows#">
	
	<cfif arguments.offset>
		<cfset result = "#result# OFFSET #arguments.offset#">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getFieldSQL_Has" access="private" returntype="any" output="no">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="field" type="string" required="yes">
	<cfargument name="tablealias" type="string" required="no">
	
	<cfset var sField = getField(arguments.tablename,arguments.field)>
	<cfset var dtype = getEffectiveDataType(arguments.tablename,sField.Relation.field)>
	<cfset var aSQL = ArrayNew(1)>
	
	<cfswitch expression="#dtype#">
	<cfcase value="numeric">
		<cfset ArrayAppend(aSQL,"IFNULL(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL," > 0,0)")>
	</cfcase>
	<cfcase value="string">
		<cfset ArrayAppend(aSQL,"IFNULL(LENGTH(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,"),0) > 0")>
	</cfcase>
	<cfcase value="date">
		<cfset ArrayAppend(aSQL,"IF(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL," IS NULL,0,1)")>
	</cfcase>
	<cfcase value="boolean">
		<cfset ArrayAppend(aSQL,"IFNULL(")>
		<cfset ArrayAppend(aSQL, getFieldSelectSQL(tablename=arguments.tablename,field=sField.Relation['field'],tablealias=arguments.tablealias,useFieldAlias=false) )>
		<cfset ArrayAppend(aSQL,",0)")>
	</cfcase>
	</cfswitch>
	

	
	<cfreturn aSQL>	
</cffunction>

<cffunction name="getNowSQL" access="public" returntype="string" output="no" hint="I return the SQL for the current date/time.">
	<cfreturn "CURRENT_TIMESTAMP()">
</cffunction>

<cffunction name="isValidDate" access="public" returntype="boolean" output="no">
	<cfargument name="value" type="string" required="yes">
	
	<cfreturn isDate(arguments.value) AND Year(arguments.value) GTE 1000 AND Year(arguments.value) LTE 9999>
</cffunction>

<cffunction name="checkTable" access="private" returntype="boolean" output="no" hint="I check to see if the given table exists in the Datamgr.">
	<cfargument name="tablename" type="string" required="yes">
	
	<cfif NOT StructKeyExists(variables.tables,arguments.tablename)>
		<cfset loadTable(arguments.tablename)>
	</cfif>
	
	<cfreturn true>
</cffunction>

<cffunction name="dbHasOffset" access="private" returntype="boolean" output="no">
	<cfreturn true>
</cffunction>

<cffunction name="getInsertedIdentity" access="private" returntype="string" output="no" hint="I get the value of the identity field that was just inserted into the given table.">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="identfield" type="string" required="yes">
	
	<cfset var qCheckKey = runSQL("SELECT	LAST_INSERT_ID() AS NewID")>
	<cfset var result = 0>
	
	<cfset result = qCheckKey.NewID>
	
	<cfreturn result>
</cffunction>

<cffunction name="getLength" access="private" returntype="string" output="no">
	<cfargument name="type" type="string" required="yes">
	
	<cfset var result = "">
	<cfset var parens1 = "(">
	<cfset var parens2 = ")">
	<cfset var fparens1 = FindNoCase(parens1,arguments.type)>
	<cfset var fparens2 = FindNoCase(parens2,arguments.type)>
	
	<cfif fparens1 AND fparens2>
		<cfset result = Mid(arguments.type,fparens1+1,fparens2-(fparens1+1))>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getDBTableIndexes" access="public" returntype="query" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="no">
	
	<cfset var fields = "">
	<cfset var qRawIndexes = 0>
	<cfset var qIndexes = QueryNew("tablename,indexname,fields,unique,clustered")>
	
	<cfset qRawIndexes = runSQL("show index from #escape(arguments.tablename)#")>
	
	<cfoutput query="qRawIndexes" group="key_name">
		<cfif ( NOT StructKeyExists(arguments,"indexname") ) OR key_name EQ arguments.indexname>
			<cfset fields = "">
			<cfset QueryAddRow(qIndexes)>
			<cfset QuerySetCell(qIndexes,"tablename",Table)>
			<cfset QuerySetCell(qIndexes,"indexname",key_name)>
			<cfset QuerySetCell(qIndexes,"unique","#NOT non_unique#")>
			<cfset QuerySetCell(qIndexes,"clustered",false)>
			<cfoutput>
				<cfset fields = ListAppend(fields,column_name)>
			</cfoutput>
			<cfset QuerySetCell(qIndexes,"fields",fields)>
		</cfif>
	</cfoutput>
	
	<cfreturn qIndexes>
</cffunction>

<cffunction name="hasIndex" access="private" returntype="boolean" output="false" hint="">
	<cfargument name="tablename" type="string" required="yes">
	<cfargument name="indexname" type="string" required="yes">
	
	<cfset var result = false>
	<cfset var qIndexes = RunSQL("show index from #escape(arguments.tablename)#")>
	
	<cfif qIndexes.RecordCount AND ListFindNoCase(ValueList(qIndexes.key_name),arguments.indexname)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isStringType" access="private" returntype="boolean" output="no" hint="I indicate if the given datatype is valid for string data.">
	<cfargument name="type" type="string">

	<cfset var strtypes = "char,nchar,nvarchar,varchar">
	<cfset var result = false>
	
	<cfset arguments.type = Trim(ListFirst(arguments.type,"("))>
	
	<cfif ListFindNoCase(strtypes,arguments.type)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="makeDefaultValue" access="private" returntype="string" output="no" hint="I return the value of the default for the given datatype and raw value.">
	<cfargument name="value" type="string" required="yes">
	<cfargument name="CF_DataType" type="string" required="yes">
	
	<cfset var result = super.makeDefaultValue(value=arguments.value,CF_DataType=arguments.CF_DataType)>
	
	<cfif isDate(result)>
		<cfset result = "'#result#'">
	</cfif>
	
	<cfreturn result>
</cffunction>

</cfcomponent>