<cfcomponent output="false" extends="jqGrid">

	<cfset this.logName = "software_tasks" />

	<cffunction name="getClientsForGroup" access="remote" returnformat="json">
		<cfargument name="page" required="no" default="1" hint="Page user is on">
	    <cfargument name="rows" required="no" default="10" hint="Number of Rows to display per page">
	    <cfargument name="sidx" required="no" default="" hint="Sort Column">
	    <cfargument name="sord" required="no" default="ASC" hint="Sort Order">
	    <cfargument name="nd" required="no" default="0">
        <cfargument name="orderedCols" required="no" default="">
	    <cfargument name="_search" required="no" default="false">
	    <cfargument name="filters" required="no" default="">
		
        <cfargument name="clientgroup" required="yes" default="" hint="patchgroup">
        <cfif Arguments.clientgroup EQ "All">
			<cfset Arguments.clientgroup = "">
        </cfif>
        <cfif IsDefined("Arguments.clientgroup") AND Len(Arguments.clientgroup) GTE 2>
        	<cfset cGroup = #Arguments.clientgroup#>
        <cfelse>
        	<cfset cGroup = "%">
        </cfif>   
        
		<cfset var arrResults = ArrayNew(1)>
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var records = "">
		<cfset var blnSearch = Arguments._search>
		<cfset var strSearch = "">	
        <cfset var hasHWData = false>
		
		<cfif Arguments.filters NEQ "" AND blnSearch>
			<cfset stcSearch = DeserializeJSON(Arguments.filters)>
            <cfif isDefined("stcSearch.groupOp")>
            	<cfset strSearch = buildSearch(stcSearch)>
            </cfif>            
        </cfif>
        
        <cftry>
            <cfquery name="hasHW" datasource="#session.dbsource#">
                SELECT hw.mpa_Model_Name, hw.mpa_Model_Identifier FROM mpi_SPHardwareOverview hw LIMIT 0,1
            </cfquery>
            <cfcatch type="any">
                <cfset hasHWData = false>				
            </cfcatch>		
        </cftry>
        <cfif #hasHW.RecordCount# EQ 1>
        	<cfset hasHWData = true>
        </cfif>
        
        <cftry>
            <cfquery name="qGetClients" datasource="#session.dbsource#" result="res">
                SELECT Distinct	cci.*, sav.defsDate
                <cfif hasHWData EQ true>
                    , hw.mpa_Model_Name, hw.mpa_Model_Identifier
                </cfif>
                FROM	mp_clients_view cci
                LEFT 	JOIN savav_info sav 
                ON 		cci.cuuid = sav.cuuid
                <cfif hasHWData EQ true>
                    LEFT JOIN mpi_SPHardwareOverview hw ON
                    cci.cuuid = hw.cuuid
                </cfif>   
                
                <cfif blnSearch AND strSearch NEQ "">
                    #PreserveSingleQuotes(strSearch)#
                    AND
                    cci.Domain like '#cGroup#'
                <cfelse>
                WHERE 
                    cci.Domain like '#cGroup#' 
            	</cfif>
                
				ORDER BY #sidx# #sord#
            </cfquery>
            
            <cfcatch type="any">
                <cfset blnSearch = false>					
                <cfset strMsgType = "Error">
                <cfset strMsg = "There was an issue with the Search. An Error Report has been submitted to Support.">					
            </cfcatch>		
        </cftry>
        
		<cfset records = qGetClients>
		<cfset start = ((arguments.page-1)*arguments.rows)+1>
		<cfset end = (start-1) + arguments.rows>
		<cfset i = 1>

		<cfloop query="qGetClients" startrow="#start#" endrow="#end#">
			<cfset _dataArr = ArrayNew(1)>
			<cfloop list="#arguments.orderedCols#" index="col" delimiters=",">
            	<cfif col EQ "cdate" OR col EQ "mdate" OR col EQ "sdate" OR col EQ "date"> 
					<cfset _dts = #DateTimeFormat( evaluate(col), "yyyy-MM-dd HH:mm:ss" )#>
					<cfset x = ArrayAppend(_dataArr,_dts)>
				<cfelse>
					<cfset _x = ArrayAppend(_dataArr,evaluate(col))>
				</cfif>
			</cfloop>

            <cfif hasHWData EQ true>
				<cfset _arr = ArrayAppend(arrResults,_dataArr)>	
			<cfelse>
				<cfset _arr = ArrayAppend(arrResults,_dataArr)>
            </cfif>  
			<cfset i = i + 1>			
		</cfloop>
		
		<cfset totalPages = Ceiling(qGetClients.recordcount/arguments.rows)>
		<cfset stcReturn = {total=#totalPages#,page=#Arguments.page#,records=#qGetClients.recordcount#,rows=#arrResults#}>
		<cfreturn stcReturn>
	</cffunction>
    
    <cffunction name="editClientsForGroup" access="remote" hint="Add or Edit" returnformat="json" output="no">
		<cfargument name="id" required="no" hint="Field that was editted">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
		<cfset var userdata = "">
        
		<cfif oper EQ "edit">
			<cfset strMsgType = "Edit">
			<cfset strMsg = "Notice, MP edit."> 
		<cfelseif oper EQ "add">
			<cfset strMsgType = "Add">
			<cfset strMsg = "Notice, MP add."> 
        <cfelseif oper EQ "del">    
            <cfset strReturn = delMPPatch(Arguments.id)>
            <cfreturn strReturn>
		</cfif>
        
		<cfset userdata  = {type='#strMsgType#',msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		<cfreturn strReturn>
	</cffunction>
    
    <cffunction name="delMPPatch" access="private" hint="Delete Selected MP Client" returntype="struct">		
		<cfargument name="id" required="yes" hint="id to delete">
		
		<cfset var strMsg = "">
		<cfset var strMsgType = "Success">
        <cfset var userdata = "">
        
		<cfloop index="index_name" list="#Arguments.id#" delimiters=",">
		
	        <cfquery name="ClientInfo" datasource="#session.dbsource#">
	            Select * FROM mp_clients_view WHERE cuuid = '#index_name#'
	        </cfquery>
	        
	        <cfset strMsg = "Delete MP Client">
	            <cflog type="Error" file="MPDeleteClient" text="DELETE FROM mp_clients_view WHERE cuuid = #index_name#">
	            <cfinvoke component="ws_logger" method="LogEvent">
	                <cfinvokeargument name="aEventType" value="Info">
	                <cfinvokeargument name="aHost" value="#CGI.REMOTE_HOST#">
	                <cfinvokeargument name="aEvent" value="[Delete Client]: #Session.Username# deleted client (#index_name#, #ClientInfo.hostname#, #ClientInfo.ipaddr#)">
	            </cfinvoke>
			
			<cftry>
            	<cfset rmc = removeClient(index_name) />
                <!---
	            <cfinvoke component="remove_Client" method="removeClient">
	                <cfinvokeargument name="id" value="#index_name#">
	            </cfinvoke>
				--->
			<cfcatch type="any">
				<!--- Error, return message --->
				<cfset strMsgType = "Error">
				<cfset strMsg = "Error occured when Deleting MP client (#index_name# -- #session.dbsource#). An error report has been submitted to support. #cfcatch.Detail# -- #cfcatch.Message#">
			</cfcatch>
			</cftry>
		
		</cfloop>
		
		<cfset userdata  = {type='#strMsgType#', msg='#strMsg#'}>
		<cfset strReturn = {userdata=#userdata#}>
		
		<cfreturn strReturn>
	</cffunction>
    
    <!--- Remove Client --->
    
    <cffunction name="getDBTables" output="no" returntype="any">
        <cftry>
	        <cfquery datasource="#session.dbsource#" name="qGet" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
	            SELECT DISTINCT TABLE_NAME 
	            FROM INFORMATION_SCHEMA.TABLES 
	            WHERE table_schema='MacPatchDB'
	            AND TABLE_TYPE = 'BASE TABLE' 
	        </cfquery> 
	        <cfcatch type="any">
	            <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[getDBTables]: #cfcatch.Detail# -- #cfcatch.Message# #cfcatch.ExtendedInfo#")>
	        </cfcatch>
        </cftry>
        <cfset tablesRaw = ValueList(qGet.TABLE_NAME)>
        
        <cfreturn #tablesRaw#>
    </cffunction>
    
    <cffunction name="deleteClient" access="public" output="no" returntype="void">
        <cfargument name="cuuid" required="yes">
        <cfargument	name="table" required="yes">
		
        <cftry>
            <cfquery datasource="#session.dbsource#" name="qGetPatches">
                Delete
                FROM #arguments.table#
                Where cuuid = '#arguments.cuuid#'
            </cfquery> 
            <cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"[Delete][#arguments.table#][#arguments.cuuid#]: #cfcatch.Detail# -- #cfcatch.Message#")>
            </cfcatch>
        </cftry>
    </cffunction> 
	
	<cffunction name="tableContainsColumn" access="public" output="no" returntype="any">
        <cfargument	name="table" required="yes">
        <cftry>
            <cfquery datasource="#session.dbsource#" name="qGetCol" cachedwithin="#CreateTimeSpan(2, 0, 0, 0)#">
				SELECT * FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_SCHEMA = 'MacPatchDB' AND TABLE_NAME = <cfqueryparam value="#arguments.table#"> AND COLUMN_NAME = 'cuuid'
            </cfquery> 
				<cfif qGetCol.RecordCount EQ 1>
					<cfreturn true>
				<cfelse>
					<cfreturn false>
				</cfif>
            <cfcatch type="any">
                <cfreturn false>
            </cfcatch>
        </cftry>
		
		<cfreturn false>
    </cffunction> 
    
    <cffunction name="removeClient" access="public" returntype="any" output="no">
    	<cfargument name="id" required="yes">
	
		<cftry>
			<cfquery name="getClientInfo" datasource="#session.dbsource#">
	            Select * From mp_clients
	            Where cuuid = '#Arguments.id#'
	        </cfquery>
	        <cfif getClientInfo.RecordCount LTE 0>
	        	<!--- No Client, nothing to delete --->
	            <cfreturn true> 
	        </cfif>
			<cfcatch type="any">
                <cfset log = logit("Error",#CGI.REMOTE_HOST#,"#Session.Username# removed client,(#getClientInfo.hostname#,#getClientInfo.ipaddr#,#Arguments.id#). #cfcatch.Message#")>
				<cfreturn false> 
            </cfcatch>
		</cftry>

        <!--- MacPatch Database Tables --->
        <cfset tableList = #getDBTables()#>
        <cfif ListLen(tableList,",") EQ 0>
        	<cfset log = logit("Warning",#CGI.REMOTE_HOST#,"[Delete]: No tables to remove client id from.")>
            <cfset log = logit("Warning",#CGI.REMOTE_HOST#,"[Delete]: Client was not removed, #getClientInfo.hostname# (#Arguments.id#)")>
            <cfreturn false>
        </cfif>
        
        <!--- Delete the client --->
        <cfloop list="#tablesRaw#" index="table" delimiters=",">
			<cfif #tableContainsColumn(table)# EQ true>
				<cfset tmp = deleteClient(Arguments.id,table)>
				<cfset log = logit("Warning",#CGI.REMOTE_HOST#,"#Session.Username# removed client,(#getClientInfo.hostname#, #getClientInfo.ipaddr#, #Arguments.id#, #table#)")>
			</cfif>
        </cfloop>

		<cfreturn true>        
	</cffunction> 	
	
	<cffunction name="logit" access="public" returntype="void" output="no">
        <cfargument name="aEventType">
        <cfargument name="aHost" required="no">
        <cfargument name="aEvent">
        <cfargument name="aScriptName" required="no">
        <cfargument name="aPathInfo" required="no">
        
        <cflog type="Error" file="MPDeleteClient_DEV" text="[Delete]:[logit] #aEvent#">
        
        <cfscript>
            try {
                inet = CreateObject("java", "java.net.InetAddress");
                inet = inet.getLocalHost();
            } catch (any e) {
                inet = "localhost";
            }
        </cfscript>
        <cftry>
            <cfquery datasource="#session.dbsource#" name="qGet">
                Insert Into ws_log (cdate, event_type, event, host, scriptName, pathInfo, serverName, serverType, serverHost)
                Values (#CreateODBCDateTime(now())#, '#aEventType#', '#aEvent#', '#CGI.REMOTE_HOST#', '#CGI.SCRIPT_NAME#', '#CGI.PATH_TRANSLATED#','#CGI.SERVER_NAME#','#CGI.SERVER_SOFTWARE#', '#inet#') 
            </cfquery>
            <cfcatch type="any">
                <cflog type="Error" file="MPDeleteClient" text="[Delete]:[logit] #cfcatch.Detail# -- #cfcatch.Message#">
            </cfcatch>
        </cftry>
	</cffunction>
    
</cfcomponent>	