<cfcomponent name="softwareDistribution">

    <cfset this.ds = "mpds">
    <cfset this.logTable = "ws_srv_logs">
    <cfset this.swGroupName = "Default">

    <cffunction name="init" returntype="softwareDistribution" output="no">
        <cfargument name="aGroupName" required="no" default="Default">
        <cfargument name="aLogTable" required="no" default="ws_log">

        <cfset this.swGroupName = arguments.aGroupName>
        <cfset this.logTable = arguments.aLogTable>
        <cfreturn this>
    </cffunction>

    <cffunction name="GetSoftwareGroupData" access="public" returnType="any" output="false">
        <cfargument name="aOSVersion" required="no" default="*">

        <cfset var swGroupID = getSoftwareGroupID(this.swGroupName) />

        <!--- Response Struct --->
        <cfset response = {} />
        <cfset response[ "errorno" ] = "0" />
        <cfset response[ "errormsg" ] = "#arguments.aOSVersion#" />
        <cfset response[ "result" ] = {} />
        <cfset response.result[ "Tasks" ] = "" />

        <!--- If no group ID is found, error id is 0 --->
        <cfif swGroupID EQ 0>
            <cfset response[ "errorno" ] = "1" />
            <cfset response[ "errormsg" ] = "No group ID for for #this.swGroupName#." />
            <cfreturn response>
        </cfif>

        <cfset tasksArray = ArrayNew(1) />

        <cfquery datasource="#this.ds#" name="qGetGroupTasksDataID" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
            Select rid From mp_software_tasks_data
            Where gid = '#swGroupID#'
        </cfquery>

        <cfquery datasource="#this.ds#" name="qGetGroupTasks" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
            Select sw_task_id From mp_software_group_tasks
            Where sw_group_id = '#swGroupID#'
            AND selected = '1'
        </cfquery>

        <cfif qGetGroupTasks.RecordCount GTE 1>
            <cfloop query="qGetGroupTasks">
                <cfset swTaskQuery = getSoftwareTaskFromID(qGetGroupTasks.sw_task_id)>

                <cfif swTaskQuery.RecordCount EQ 0>
                    <!--- Log An Error, Maybe --->
                    <cfcontinue>
                </cfif>
                <cfif swTaskQuery.active EQ "0">
                    <!--- Log An Error, Maybe --->
                    <cfcontinue>
                </cfif>

                <cfset task = {} />
                <cfset task[ "name" ] = "#Trim(swTaskQuery.name)#" />
                <cfset task[ "id" ] = "#Trim(swTaskQuery.tuuid)#" />
                <cfset task[ "sw_task_type" ] = "#Trim(swTaskQuery.sw_task_type)#" />
                <cfset task[ "sw_task_privs" ] = "#Trim(swTaskQuery.sw_task_privs)#" />
                <cfset task[ "sw_start_datetime" ] = "#DateFormat(swTaskQuery.sw_start_datetime,'yyyy-mm-dd')# #TimeFormat(swTaskQuery.sw_start_datetime,'HH:mm:ss')#" />
                <cfset task[ "sw_end_datetime" ] = "#DateFormat(swTaskQuery.sw_end_datetime,'yyyy-mm-dd')# #TimeFormat(swTaskQuery.sw_end_datetime,'HH:mm:ss')#" />
                <cfset task[ "active" ] = "#swTaskQuery.active#" />
                <!--- Get Software Info For SUUID --->

                <cfset swDataForSuuid = getSoftwareDistFromSUUID(swTaskQuery.primary_suuid)>
                <cfset task[ "Software" ] = {} />
                    <cfset task.software[ "name" ] = "#Trim(swDataForSuuid.sName)#" />
                    <cfset task.software[ "vendor" ] = "#Trim(swDataForSuuid.sVendor)#" />
                    <cfset task.software[ "vendorUrl" ] = "#Trim(swDataForSuuid.sVendorURL)#" />
                    <cfset task.software[ "version" ] = "#Trim(swDataForSuuid.sVersion)#" />
                    <cfset task.software[ "description" ] = "#Trim(swDataForSuuid.sDescription)#" />
                    <cfset task.software[ "reboot" ] = "#Trim(swDataForSuuid.sReboot)#" />
                    <cfset task.software[ "sw_type" ] = "#Trim(swDataForSuuid.sw_type)#" />
                    <cfset task.software[ "sw_url" ] = "#Trim(swDataForSuuid.sw_url)#" />
                    <cfset task.software[ "sw_hash" ] = "#Trim(swDataForSuuid.sw_hash)#" />
                    <cfset task.software[ "sw_size" ] = "#Trim(swDataForSuuid.sw_size)#" />
                    <cfset task.software[ "sw_pre_install" ] = "#ToBase64(Trim(swDataForSuuid.sw_pre_install_script))#" />
                    <cfset task.software[ "sw_post_install" ] = "#ToBase64(Trim(swDataForSuuid.sw_post_install_script))#" />
                    <cfset task.software[ "sw_uninstall" ] = "#ToBase64(Trim(swDataForSuuid.sw_uninstall_script))#" />
                    <cfset task.software[ "sw_env_var" ] = "#Trim(swDataForSuuid.sw_env_var)#" />
                    <cfset task.software[ "auto_patch" ] = "#Trim(swDataForSuuid.auto_patch)#" />
                    <cfset task.software[ "patch_bundle_id" ] = "#Trim(swDataForSuuid.patch_bundle_id)#" />
                    <cfset task.software[ "state" ] = "#Trim(swDataForSuuid.sState)#" />
                    <cfset task.software[ "sid" ] = "#Trim(swTaskQuery.primary_suuid)#" />
                <cfset task[ "SoftwareCriteria" ] = {} />
                    <cfset task.SoftwareCriteria = "#getSoftwareCriteriaFromSUUID(swTaskQuery.primary_suuid)#" />
                <cfset task[ "SoftwareRequisistsPre" ] = {} />
                    <!--- <cfset reqs = ArrayNew(1) /> --->
                    <cfset _preStruct = RequisistsForID("pre","ID")>
                    <cfset task.SoftwareRequisistsPre = _preStruct />
                <cfset task[ "SoftwareRequisistsPost" ] = {} />
                    <!--- <cfset reqs = ArrayNew(1) /> --->
                    <cfset _postStruct = RequisistsForID("post","ID")>
                    <cfset task.SoftwareRequisistsPost = _postStruct />


                <!--- Add Task To Array --->
                <cfif arguments.aOSVersion EQ "*">
                    <cfset response[ "debug" ] = "arguments.aOSVersion = *">
                    <cfset _addTask = Arrayappend(tasksArray,task)>
                <cfelse>
                    <cfset osVers = arguments.aOSVersion>
                    <cfif NOT StructKeyExists(task.SoftwareCriteria,"os_vers")>
                        <cfset response[ "errormsg" ] = "Missing Data for #task['name']#" />
                        <cfcontinue>
                    </cfif>

                    <cfset osList = task.SoftwareCriteria['os_vers']>

                    <cfloop index="item" list="#osList#" delimiters = ",">
                        <cfset isValidOSVer = mpVersionCheckListToOS(item,osVers)>
                        <cfif isValidOSVer EQ true>
                            <cfset _addTask = Arrayappend(tasksArray,task)>
                            <cfbreak>
                        </cfif>
                    </cfloop>
                </cfif>

            </cfloop>
            <!--- Add the Tasks Array to the Struct --->
            <cfset response.result.Tasks = tasksArray>
        </cfif>

        <cfreturn #response#>
    </cffunction>

    <cffunction name="getSoftwareGroupID" access="private" returntype="any" output="no">
        <cfargument name="GroupName">

        <cfquery datasource="#this.ds#" name="qGetID" cachedwithin="#CreateTimeSpan(0,0,30,0)#">
            Select gid from mp_software_groups
            Where gName = '#arguments.GroupName#'
        </cfquery>

        <cfif qGetID.RecordCount EQ 1>
            <cfreturn #qGetID.gid#>
        <cfelse>
            <cfreturn "0">
        </cfif>
    </cffunction>

    <cffunction name="getSoftwareTaskFromID" access="private" returntype="any" output="no">
        <cfargument name="TaskID">

        <cfquery datasource="#this.ds#" name="qGetTask" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
            Select name, tuuid, primary_suuid, sw_task_type, sw_task_privs,
                sw_start_datetime, sw_end_datetime, active
            From mp_software_task
            Where tuuid = '#arguments.TaskID#'
        </cfquery>

        <cfif qGetTask.RecordCount EQ 1>
            <cfreturn #qGetTask#>
        <cfelse>
            <cfset myQuery = QueryNew("name, primary_suuid, sw_task_type, sw_task_privs, sw_start_datetime, sw_end_datetime, active")>
            <cfreturn #myQuery#>
        </cfif>
    </cffunction>

    <cffunction name="getSoftwareDistFromSUUID" access="private" returntype="query" output="no">
        <cfargument name="suuid">

        <cfquery datasource="#this.ds#" name="qGetTask" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
            Select sName,sVendor,sVendorURL,sVersion,sDescription,sReboot,sw_type,sw_url,sw_hash,sw_size,sw_pre_install_script
                ,sw_post_install_script,sw_uninstall_script,sw_env_var,auto_patch,patch_bundle_id,sState
            From mp_software
            Where suuid = '#arguments.suuid#'
        </cfquery>

        <cfif qGetTask.RecordCount EQ 1>
            <cfreturn #qGetTask#>
        <cfelse>
            <cfset myQuery = QueryNew("sName,sVendor,sVendorURL,sVersion,sDescription,sReboot,sw_type,sw_url,sw_hash,sw_size,sw_pre_install_script
                ,sw_post_install_script,sw_uninstall_script,sw_env_var,auto_patch,patch_bundle_id,sState")>
            <cfreturn #myQuery#>
        </cfif>
    </cffunction>

    <cffunction name="getSoftwareCriteriaFromSUUID" access="private" returntype="struct" output="no">
        <cfargument name="suuid">

        <cfquery datasource="#this.ds#" name="qGetCrit" cachedwithin="#CreateTimeSpan(0,0,30,0)#">
            Select *
            From mp_software_criteria
            Where suuid = '#arguments.suuid#'
            Order By type_order Asc
        </cfquery>

        <cfset criteria = {} />
        <cfloop query="qGetCrit">
            <cfif qGetCrit.type EQ "OSType">
                <cfset criteria[ "os_type" ] = "#qGetCrit.type_data#" />
            </cfif>
            <cfif qGetCrit.type EQ "OSVersion">
                <cfset criteria[ "os_vers" ] = "#qGetCrit.type_data#" />
            </cfif>
            <cfif qGetCrit.type EQ "OSArch">
                <cfset criteria[ "arch_type" ] = "#qGetCrit.type_data#" />
            </cfif>
        </cfloop>

        <cfreturn criteria>
    </cffunction>

    <cffunction name="RequisistsForID" access="private" returntype="struct" output="no">
        <cfargument name="ReqType">
        <cfargument name="TaskID">

        <cfset criteria = {} />
        <cfreturn criteria>
    </cffunction>

    <cffunction name="mpVersionCheckListToOS" access="public" returntype="boolean" output="no">
        <!--- It returns 1 when argument 1 is greater, -1 when argument 2 is greater, and 0 when they are exact matches. --->
        <cfargument name="listVersion" required="yes" default="0">
        <cfargument name="osVersion" required="yes" default="0">

        <cfset var result = true>
        <!--- Check to see if we are the same --->
        <cfif arguments.listVersion EQ arguments.osVersion>
            <cfreturn true>
        </cfif>

        <!--- Get Arguments Version Lengths --->
        <cfset listPartLen = #listLen(arguments.listVersion, '.')#>
        <cfset osPartLen = #listLen(arguments.osVersion, '.')#>

        <!--- Equalize Version String Lengths --->
        <cfif listPartLen GT osPartLen>
            <cfset arguments.osVersion = arguments.osVersion & repeatString('.0', listPartLen-osPartLen)>
        <cfelse>
            <cfset arguments.listVersion = arguments.listVersion & repeatString('.0', osPartLen-listPartLen)>
        </cfif>

        <cfloop index = "i" from="1" to=#listLen(arguments.listVersion, '.')#>
            <cfset listPart = listGetAt(arguments.listVersion, i, '.')>
            <cfset osPart = listGetAt(arguments.osVersion, i, '.')>

            <!--- If Any Part Contains it's all true --->
            <cfif FindNoCase("*", listPart) GTE 1>
                <cfset oct = ReplaceNoCase(listPart,"*","","All")>
                <cfif oct EQ "">
                    <!--- If Empty Assign Value --->
                    <cfset oct = 0>
                </cfif>
                <cfif osPart GTE oct>
                    <cfbreak>
                <cfelse>
                    <cfset result = false>
                    <cfbreak>
                </cfif>
            <cfelse>
                <cfif osPart NEQ listPart>
                    <cfset result = false>
                    <cfbreak>
                </cfif>
            </cfif>
        </cfloop>

        <cfreturn result>
    </cffunction>

    <cffunction name="versionCompare" access="private" returntype="numeric" output="no">
        <!--- It returns 1 when argument 1 is greater, -1 when argument 2 is greater, and 0 when they are exact matches. --->
        <cfargument name="leftVersion" required="yes" default="0">
        <cfargument name="rightVersion" required="yes" default="0">

        <cfset var len1 = listLen(arguments.leftVersion, '.')>
        <cfset var len2 = listLen(arguments.rightVersion, '.')>
        <cfset var piece1 = "">
        <cfset var piece2 = "">

        <cfif len1 GT len2>
            <cfset arguments.rightVersion = arguments.rightVersion & repeatString('.0', len1-len2)>
        <cfelse>
            <cfset arguments.leftVersion = arguments.leftVersion & repeatString('.0', len2-len1)>
        </cfif>

        <cfloop index = "i" from="1" to="#listLen(arguments.leftVersion, '.')#">
            <cfset piece1 = listGetAt(arguments.leftVersion, i, '.')>
            <cfset piece2 = listGetAt(arguments.rightVersion, i, '.')>

            <cfif piece1 NEQ piece2>
                <cfif piece1 GT piece2>
                    <cfreturn 1>
                <cfelse>
                    <cfreturn -1>
                </cfif>
            </cfif>
        </cfloop>

        <cfreturn 0>
    </cffunction>

</cfcomponent>