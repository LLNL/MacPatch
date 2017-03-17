<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<cfset message = "" />
<cfif Not StructIsEmpty(form)>
    <cfset cancelURL = '#form.goBackTo#'/>
    <cfif Len(form.importFile) GTE 4>
        <cftry>
            <cfset jData = Deserializejson(file=form.importFile) />    
            <!--- <cfdump var="#jData#"> --->
            <cfcatch>
                <cfset message = #cfcatch.message# & ":" & #cfcatch.detail# />
             </cfcatch>
        </cftry>
        
        <cfset _exists = swExists(jData['sw']['sName'], jData['sw']['sVersion']) />
        <cfif form.allowDuplicate EQ 1>
            <cfset _exists = false>
        </cfif>

        <cfif _exists EQ false >

            <cfif form.genNewID EQ 1>
                <!--- Gen New ID's --->
                <cfset suuid = CreateUuid() />
                <cfset tuuid = CreateUuid() />
                <cfset jData['sw']['suuid'] = suuid />
                <cfset jData['sw']['sw_path'] = "/opt/MacPatch/Content/Web/sw/"&suuid&"/"&jData['file']['name'] />
                <cfset jData['sw']['sw_url'] = "/sw/"&suuid&"/"&jData['file']['name'] />

                <cfloop index="cri" from="1" to="#arraylen( jData['sw']['criteria'] )#">
                    <cfset jData['sw']['criteria'][cri]['suuid'] = suuid />
                </cfloop>

                <cfset jData['task']['tuuid'] = tuuid />
                <cfset jData['task']['primary_suuid'] = suuid />
            </cfif>
            
            
            <cfset _suuid = jData['sw']['suuid'] />
            <cfset _sw = jData['sw'] />
            <cfset _swCri = jData['sw']['criteria'] />
            <cfset _task = jData['task'] />
            <cfset _file = jData['file'] />


            <cfset _sw['sState'] = "1" />
            <cfset tm = ImportSWData(_sw) />
            <cfset tm = ImportSWCriteria(_swCri) />
            
            <cfset _task['active'] = "0" />
            <cfset tm = ImportTaskData(_task) />
            <!--- --->
            <cfif form.noPackage EQ 0>
                <cfthread action="run" name="dlFile" timeout="2800" taskD="#_task#" swD="#_sw#" fileD="#_file#">
                    <cflog log="Application" type="information" text="Thread Started">

                    <cfset sid = #swD['suuid']# />
                    <cfset tid = #taskD['tuuid']# />
                    <cfset name1 = #swD['sName']# />
                    <cfset name1t = #taskD['name']# />
                    <cfset name2 = #swD['sName']# & " - *** Uploading ***" />
                    <cfset name2t = #taskD['name']# & " - *** Uploading ***" />
                    
                    <cfquery name="qName1" datasource="#session.dbsource#">
                        UPDATE mp_software
                        Set sName = <cfqueryparam value="#name2#">
                        Where suuid = '#sid#'
                    </cfquery>

                    <cfquery name="qName2" datasource="#session.dbsource#">
                        UPDATE mp_software_task
                        Set name = <cfqueryparam value="#name2t#">
                        Where suuid = '#tid#'
                    </cfquery>

                    <!---
                    <cfset tm = downloadSWPackage(fileD,swD['suuid']) />

                    <cfif tm EQ "NA">
                        <cflog log="Application" type="information" text="Software was not downloaded properly. Try uploading package manually." />
                        <cfset message = "Software was not downloaded properly. Try uploading package manually." />
                    <cfelseif tm EQ swD['sw_hash']>
                        <cflog log="Application" type="information" text="Package hash did not match. Please verify that the package is complete." />
                        <cfset message = "Package hash did not match. Please verify that the package is complete." />
                    </cfif>    
                    --->

                    <cfset var fileURL = fileD.url />
                    <cfset var filePath = application.settings.paths.content & "/sw/" & sid />

                    <cfif Not DirectoryExists(filePath)>
                        <cfset tmp = DirectoryCreate(filePath) />
                    </cfif>

                    <cfif fileExists("/bin/curl")>
                        <cfset curlBin = "/bin/curl">
                    <cfelseif fileExists("/usr/bin/curl")>
                        <cfset curlBin = "/usr/bin/curl">
                    <cfelse>
                        <cflog log="Application" text="curl binary not found.">
                        <cflocation url="#cancelURL#">
                        <cfreturn>
                    </cfif>

                    <!--- Using this method due to cfhttp not working right --->
                    <cfset fullFilePath = filePath & "/" & fileD.name />
                    <cfset args = "-k --max-time 1800 -o " & fullFilePath & " --connect-timeout 0 --keepalive-time 30 " & fileURL />
                    <cfexecute name="#curlBin#" arguments="#args#" timeout="32000" errorVariable="foo" />

                    <cfif fileExists("/bin/curl")>
                        <cfset _hash = Hashbinary(fullFilePath, "MD5") />
                    </cfif>


                    <cfquery name="qAddSW" datasource="#session.dbsource#">
                        UPDATE mp_software
                        Set sName = <cfqueryparam value="#name1#">
                        Where suuid = '#sid#'
                    </cfquery>

                    <cfquery name="qName2" datasource="#session.dbsource#">
                        UPDATE mp_software_task
                        Set name = <cfqueryparam value="#name1t#">
                        Where suuid = '#tid#'
                    </cfquery>

                    <cflog log="Application" type="information" text="Thread Ended">
                </cfthread>
            </cfif>

            <cflocation url="#cancelURL#">
            
            <cfabort>
        <cfelse>
            <cfset message = "Sorry, software already exists. This task can not be added." />
        </cfif>
        
    </cfif>
<cfelse>
    <cfset cancelURL = '#CGI.HTTP_REFERER#'/>
</cfif>


<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title></title>
    <link rel="stylesheet" href="/admin/js/smartwizard/css/bp_main.css" type="text/css">
    <link rel="stylesheet" type="text/css" media="screen" href="/admin/js/ui/Aristo-jQuery-UI-Theme/css/Aristo/Aristo.css" />
    
    <script type="text/javascript" src="/admin/js/jquery-latest.js"></script>
    <script type="text/javascript" src="/admin/js/jquery-ui-latest.js"></script>
    <script type="text/javascript">
        function required(inputtx) {
            if (inputtx.value.length == 0) { 
                alert("message");      
                return false; 
            }     
            return true; 
        } 
    </script>
    <style>
        fieldset {
            -moz-border-radius-bottomleft: 7px;
            -moz-border-radius-bottomright: 7px;
            -moz-border-radius-topleft: 5px;
            -moz-border-radius-topright: 7px;
            -webkit-border-radius: 7px;
            border-radius: 3px;
            border: solid 1px gray;
            padding: 4px;
            margin-bottom:10px;
            font-size: 12px;
            //text-align:right;
            //line-height: 30px;
            width: 600px;
        }
        legend {
            color: black;
            padding: 4px;
            font-weight:bold;
        }
        #container {
            display: table;
            width: 100%;
            margin-bottom: 10px;
        }

        #row  {
            display: table-row;
            border-bottom: 1px solid black;
        }

        #left {
            display: table-cell;
            font-size: 12px;
            text-align:left;
            margin-bottom:10px;
            border-bottom: 1px solid black;
        }

        #right {
            display: table-cell;
            font-size: 12px;
            text-align:right;
            margin-bottom:10px;
            border-bottom: 1px solid black;
        }
        
        /* gray */
        .gray {
            color: #e9e9e9;
            border: solid 1px #555;
            background: #6e6e6e;
            background: -webkit-gradient(linear, left top, left bottom, from(#888), to(#575757));
            background: -moz-linear-gradient(top,  #888,  #575757);
            filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#888888', endColorstr='#575757');
        }
        .gray:hover {
            background: #616161;
            background: -webkit-gradient(linear, left top, left bottom, from(#757575), to(#4b4b4b));
            background: -moz-linear-gradient(top,  #757575,  #4b4b4b);
            filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#757575', endColorstr='#4b4b4b');
        }
        .gray:active {
            color: #afafaf;
            background: -webkit-gradient(linear, left top, left bottom, from(#575757), to(#888));
            background: -moz-linear-gradient(top,  #575757,  #888);
            filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#575757', endColorstr='#888888');
        }
      
        .btn 
        {
            padding: 6px 12px;
            color: #FFF;
            -webkit-border-radius: 4px;
            -moz-border-radius: 4px;
            border-radius: 4px;
            text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.4);
            -webkit-transition-duration: 0.2s;
            -moz-transition-duration: 0.2s;
            transition-duration: 0.2s;
            -webkit-user-select:none;
            -moz-user-select:none;
            -ms-user-select:none;
            user-select:none;
            display:inline-block;
            vertical-align:middle;
            margin-top: 6px;
        }
        .btn:hover {
            //background: #356094;
            //border: solid 1px #2A4E77;
            text-decoration: none;
        }
        .btn:active {
            position: relative;
            top: 1px;
        }

        .table {
            display: table;
            width: 100%;
        }

        .row {
            display: table-row;
        }

        .cell {
            font-weight:bold;
            display: table-cell;
            border-bottom: 1px solid black;
            padding-top: 8px;
            padding-bottom: 6px;
            padding-right: 4px;
            padding-left: 4px;
            width: 30%;
        }
        .cellLrg {
            display: table-cell;
            border-bottom: 1px solid black;
            padding-top: 8px;
            padding-bottom: 6px;
            width: 75%;
        }

        .lastcell {
            font-weight:bold;
            display: table-cell;
            padding-top: 8px;
            padding-bottom: 6px;
            padding-right: 4px;
            padding-left: 4px;
        }

        .lastcellLrg {
            display: table-cell;
            padding-top: 8px;
            padding-bottom: 6px;
            width: 75%;
        }
    </style>
</head>
<cfoutput>
<body>
    <!---
    <fieldset></fieldset>
    --->
    <h2>Import Software Task</h2>
    <h5>#message#</h5>

    <cfform name="importTask" method="post" action="software_task_import.cfm" enctype="multipart/form-data">
        <div class="table">
            <fieldset>
            <div class="row">
                <div class="cell">
                    Import File
                </div>
                <div class="cellLrg">
                    <input type="file" name="importFile" required="true" message="Error [Patch File]: A patch package name is required." required="required">
                </div>
            </div>
            <div class="row">
                <div class="cell">
                    Generate New ID's 
                </div>
                <div class="cellLrg">
                    <cfselect name="genNewID" size="1">
                        <option value="1" selected>Yes</option>
                        <option value="0">No</option>
                    </cfselect>
                </div>
            </div>
            <div class="row">
                <div class="cell">
                    Upload Software Package Seperatly
                </div>
                <div class="cellLrg">
                    <cfselect name="noPackage" size="1">
                        <option value="1">Yes</option>
                        <option value="0" selected>No</option>
                    </cfselect>
                </div>
            </div>
            <div class="row">
                <div class="lastcell">
                    Import if already exists
                </div>
                <div class="lastcellLrg">
                    <cfselect name="allowDuplicate" size="1">
                        <option value="1">Yes</option>
                        <option value="0" selected>No</option>
                    </cfselect>
                </div>
            </div>
            </fieldset>
            <div class="row">
                    <input name="goBackTo" type="hidden" value="#cancelURL#">
                    <input class="button medium gray" type="button" value="Cancel" onclick="location.href='#cancelURL#';return false;">
                    <input class="button medium gray" type="button" value="Save" onclick="this.form.submit();">
            </div>
        </div>
        
    </cfform>
    <!---
    <cfform name="importTask" method="post" action="software_task_import.cfm" enctype="multipart/form-data">
        <fieldset>
        <div id="container">
            
            <div id="row">
                <div id="left">
                Import File
                </div>
                
                <input type="file" name="importFile" required="true" message="Error [Patch File]: A patch package name is required." required="required">
            </div>
            <div id="row">
                <div id="left">
                Generate New ID's
                </div>
                <cfselect name="genNewID" size="1">
                    <option value="1" selected>Yes</option>
                    <option value="0">No</option>
                </cfselect>
            </div>
            <div id="row">
                <div id="left">
                Upload Software Package Seperatly
                </div>
                <cfselect name="noPackage" size="1">
                    <option value="1">Yes</option>
                    <option value="0" selected>No</option>
                </cfselect>
            </div>
            <div id="row">
                <div id="left">
                Import if already exists
                </div>
                <cfselect name="allowDuplicate" size="1">
                    <option value="1">Yes</option>
                    <option value="0" selected>No</option>
                </cfselect>
            </div>
            
            <div id="row">
                <br>
                <div id="right">
                <input name="goBackTo" type="hidden" value="#cancelURL#">
                <input class="button medium gray" type="button" value="Cancel" onclick="location.href='#cancelURL#';return false;">
                <input class="button medium gray" type="button" value="Save" onclick="this.form.submit();">
                </div>
            </div>
        </div>
    </fieldset>
    </cfform>
    --->
</body>
</cfoutput>
</html>

<cffunction name="swExists" access="private">
    <cfargument name="swName" required="yes">
    <cfargument name="swVersion" required="yes">

    <cfquery name="qExists" datasource="#session.dbsource#">
        Select suuid From mp_software
        Where sName = <cfqueryparam value="#arguments.swName#">
        AND sVersion = <cfqueryparam value="#arguments.swVersion#">
    </cfquery>

    <cfif qExists.RecordCount GTE 1>
        <cfreturn true>
    <cfelse>
        <cfreturn false>
    </cfif>
</cffunction>    

<cffunction name="ImportSWData" access="private">
    <cfargument name="swData" required="yes">

    <cfset var sw = arguments.swData />

    <cfset rc = StructDelete(sw, 'criteria') />
    <cfset rc = StructDelete(sw, 'cdate') />
    <cfset rc = StructDelete(sw, 'mdate') />
    <cfset rc = StructDelete(sw, 'rid') />

    <cfset keys = StructKeylist(sw) />
    <cfloop index="key" list="#keys#">
        <cfif len(sw[key]) EQ 0>
            <cfset rc = StructDelete(sw, key) />
        </cfif>
    </cfloop>

    <cfset keys = StructKeylist(sw) />

    <cfquery name="qAddSW" datasource="#session.dbsource#">
        INSERT INTO mp_software( #keys#, cdate, mdate ) 
        VALUES( <cfloop index="key" list="#keys#">
                <cfif ListLast(keys) EQ key>
                    <cfqueryparam value="#sw[key]#">
                <cfelse>
                    <cfqueryparam value="#sw[key]#">,
                </cfif>
                </cfloop>, #CreateODBCDateTime(now())#, #CreateODBCDateTime(now())# )
    </cfquery>

</cffunction>

<cffunction name="ImportSWCriteria" access="private">
    <cfargument name="swCriteria" required="yes">

    <cfset var criArray = arguments.swCriteria />
    <cfset criKeys = StructKeylist(criArray[1]) />
    
    <cfloop index="i" from="1" to="#arraylen( criArray )#">
        <cfquery name="qAddCri" datasource="#session.dbsource#">
            INSERT INTO mp_software_criteria( #criKeys# ) 
            VALUES(
                <cfloop index="key" list="#criKeys#">
                    <cfif ListLast(criKeys) EQ key>
                        <cfqueryparam value="#criArray[i][key]#">
                    <cfelse>
                        <cfqueryparam value="#criArray[i][key]#">,
                    </cfif>
                </cfloop> )
        </cfquery>
    </cfloop>

</cffunction>

<cffunction name="ImportTaskData" access="private">
    <cfargument name="taskData" required="yes">

    <cfset var task = arguments.taskData />
    <cfset keys = StructKeylist(task) />

    <cfloop index="key" list="#keys#">
        <cfif len(task[key]) EQ 0>
            <cfset rc = StructDelete(task, key) />
        </cfif>
    </cfloop>
    
    <cfset keys = StructKeylist(task) />
    <cfquery name="qAddTask" datasource="#session.dbsource#">
        INSERT INTO mp_software_task( #keys#, cdate, mdate ) 
        VALUES( <cfloop index="key" list="#keys#">
                <cfif ListLast(keys) EQ key>
                    <cfqueryparam value="#task[key]#">
                <cfelse>
                    <cfqueryparam value="#task[key]#">,
                </cfif>
                </cfloop>, #CreateODBCDateTime(now())#, #CreateODBCDateTime(now())#  )
    </cfquery>

</cffunction>

<cffunction name="downloadSWPackage" access="private">
    <cfargument name="fileData" required="yes">
    <cfargument name="suuid" required="yes">

    <cfset var fileURL = arguments.fileData.url />
    <cfset var filePath = application.settings.paths.content & "/sw/" & suuid />
    
    <cfif Not DirectoryExists(filePath)>
        <cfset tmp = DirectoryCreate(filePath) />
    </cfif>

    <cfif fileExists("/bin/curl")>
        <cfset curlBin = "/bin/curl">
    <cfelseif fileExists("/usr/bin/curl")>
        <cfset curlBin = "/usr/bin/curl">
    <cfelse>
        <cflog log="Application" text="curl binary not found.">
        <cfreturn>
    </cfif>

    <!--- Using this method due to cfhttp not working right --->
    <cfset fullFilePath = filePath & "/" & arguments.fileData.name />
    <cfset args = "-k -o " & fullFilePath & " " & fileURL />
    <cfexecute name="#curlBin#" arguments="#args#" timeout="600" errorVariable="foo" />
    
    <cflog log="Application" text="#foo#">

    <cfif fileExists("/bin/curl")>
        <cfset _hash = Hashbinary(fullFilePath, "MD5") />
        <cfreturn _hash>
    </cfif>
    
    <cfreturn "NA">
</cffunction>


<cffunction name="ImportTask" access="private">
    <cfargument name="taskData" required="yes">

    <cfset var res = {} />

    <!--- Get Task Info --->
    <cfquery name="qSWTask" datasource="#session.dbsource#">
        select * From mp_software_task
        Where tuuid = <cfqueryparam value="#Arguments.taskID#">
    </cfquery>

    <cfset res['task']['tuuid'] = "#Arguments.taskID#" />
    <cfset res['task']['primary_suuid'] = "#qSWTask.primary_suuid#" />
    <cfset res['task']['active'] = "#qSWTask.active#" />
    <cfset res['task']['sw_task_type'] = "#qSWTask.sw_task_type#" />
    <cfset res['task']['sw_task_privs'] = "#qSWTask.sw_task_privs#" />
    <cfset res['task']['sw_task_privs'] = "#qSWTask.sw_task_privs#" />
    <cfset res['task']['sw_start_datetime'] = "#qSWTask.sw_start_datetime#" />
    <cfset res['task']['sw_end_datetime'] = "#qSWTask.sw_end_datetime#" />
    <cfset res['task']['mdate'] = "#qSWTask.mdate#" />
    <cfset res['task']['cdate'] = "#qSWTask.cdate#" />

    <!--- Get Software Info --->
    <cfquery name="qSWData" datasource="#session.dbsource#">
        select * From mp_software
        Where suuid = <cfqueryparam value="#qSWTask.primary_suuid#">
    </cfquery>

    <cfset res['sw']['suuid'] = "#qSWData.suuid#" />
    <cfset cols = ArrayToList( qSWData.getColumnNames() ) />
    
    <cfloop list="#cols#" index="col">
        <cfoutput>
            <cfset res['sw'][col] = Evaluate("qSWData." & col) />
        </cfoutput>
    </cfloop>

    <!--- Get Software Criteria --->
    <cfquery name="qSWCri" datasource="#session.dbsource#">
        select * From mp_software_criteria
        Where suuid = <cfqueryparam value="#qSWTask.primary_suuid#">
    </cfquery>

    <cfset var criArray = ArrayNew(1) /> 
    <cfloop query="qSWCri">
        <cfset x = StructNew() />
        <cfloop list="#ArrayToList(qSWCri.getColumnNames())#" index="col">
            <cfset x[col] = qSWCri[col][currentrow] />
        </cfloop>
        <cfset arr = ArrayAppend(criArray,x) />
    </cfloop>
    <cfset res['sw']['criteria'] = criArray />

    <!--- Get Download Info --->
    <cfset res['file']['url'] = getMasterServerDLURL() & res['sw']['sw_url'] />
    <cfset res['file']['name'] = GetFileFromPath(res['sw']['sw_path']) />

    <cfreturn res>
</cffunction>
