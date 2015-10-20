<cfif isDefined("URL.type") AND isDefined("URL.cuuid")>
    <cfsilent>
    <cfquery datasource="#session.dbsource#" name="qGetColumns"> 
        Select *
        <cfif url.type EQ "systemoverview">
        from mpi_SPSystemOverview
        </cfif>
        <cfif url.type EQ "applications">
        from mpi_SPApplications
        </cfif>
		<cfif url.type EQ "applicationusage">
	    from mpi_AppUsage
	    </cfif>
        <cfif url.type EQ "hardwareoverview">
        from mpi_SPHardwareOverview
        </cfif>
        <cfif url.type EQ "networkoverview">
        from mpi_SINetworkInfo
        </cfif>
		<cfif url.type EQ "directoryoverview">
        from mpi_DirectoryServices
        </cfif>
		<cfif url.type EQ "frameworks">
	    from mpi_SPFrameworks
	    </cfif>
		<cfif url.type EQ "internetplugins">
	    from mpi_InternetPlugins
	    </cfif>
	    <cfif url.type EQ "clienttasks">
	    from mpi_ClientTasks
	    </cfif>
		<cfif url.type EQ "diskinfo">
	    from mpi_DiskInfo
	    </cfif>
        <cfif url.type EQ "batteryinfo">
        from mpi_DiskInfo
        </cfif>
        <cfif url.type EQ "powerinfo">
        from mpi_PowerManagment
        </cfif>
        <cfif url.type EQ "fileVault">
        from mpi_FileVault
        </cfif>
        Where cuuid = <cfqueryparam value="#url.cuuid#">
    </cfquery> 
    </cfsilent>
    <cfif qGetColumns.RecordCount NEQ 0>
	<cfset csvBlock = Csvwrite( qGetColumns, true )>
    <!--- Data to Export --->
    <cfheader name="Content-Disposition" value="inline; filename=#URL.type#.csv"> 
    <cfcontent type="application/csv">
    <cfoutput>#csvBlock#</cfoutput>
    <cfelse>
    	<cflocation url="#CGI.HTTP_REFERER#">
    </cfif>
<cfelse>
<cflocation url="#CGI.HTTP_REFERER#">
</cfif>

	
