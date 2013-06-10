<div id="mpservices" class="yuimenubar yuimenubarnav">
    <div class="bd">
        <ul class="first-of-type">
            <li class="yuimenubaritem first-of-type">
                <a class="yuimenubaritemlabel" href="#">Patches</a>
                <div id="applepatches" class="yuimenu">
                    <div class="bd">
                        <ul>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Apple</a>
                                <div id="Apple" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
                                            <li class="yuimenuitem"><a href="index.cfm?patchlist_apple" class="yuimenuitemlabel">Available</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Custom</a>
                                <div id="Third" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
                            				<li class="yuimenuitem"><a href="index.cfm?mp_patch_list" class="yuimenuitemlabel">Available</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Patch Group(s)</a>
                                <div id="Groups" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
                                            <li class="yuimenuitem"><a href="index.cfm?listpatchgroups" class="yuimenuitemlabel">List</a></li>
                           					<li class="yuimenuitem"><a href="index.cfm?buildPatchGroup" class="yuimenuitemlabel">Build</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                        </ul>
                    </div>
                 </div>
            </li>

			 <li class="yuimenuitem">
			 	<a class="yuimenuitemlabel" href="#">Software</a>
                <div id="SoftwareDistManagment" class="yuimenu">
                    <div class="bd">
                        <ul class="first-of-type">
							<li class="yuimenuitem"><a href="#" class="yuimenuitemlabel"><b>- Groups -</b></a></li>
                            <li class="yuimenuitem"><a href="index.cfm?adm_sw_group_list" class="yuimenuitemlabel">List</a></li>
                        </ul>
						<ul>
							<li class="yuimenuitem"><a href="#" class="yuimenuitemlabel"><b>- Tasks -</b></a></li>
                            <li class="yuimenuitem"><a href="index.cfm?adm_sw_task_list" class="yuimenuitemlabel">List</a></li>
                        </ul>
                        <ul>
                        	<li class="yuimenuitem"><a href="#" class="yuimenuitemlabel"><b>- Packages -</b></a></li>
							<li class="yuimenuitem"><a href="index.cfm?adm_sw_dist_list" class="yuimenuitemlabel">List</a></li>
							<li class="yuimenuitem"><a href="index.cfm?adm_sw_dist_new" class="yuimenuitemlabel">Create</a></li>
						</ul>
                    </div>
                </div>
            </li>
			
            <li class="yuimenubaritem">
                <a class="yuimenubaritemlabel" href="index.cfm?installedpatches">Installed Patches</a>
            </li>
            <li class="yuimenubaritem">
                <a class="yuimenubaritemlabel" href="index.cfm?clientstatus">Client Patch Status</a>
            </li>
            <li class="yuimenubaritem">
                <a class="yuimenubaritemlabel" href="index.cfm?ClientGroups">Client Groups</a>
            </li>
            <li class="yuimenubaritem">
                <a class="yuimenubaritemlabel" href="index.cfm?dashboard">Dashboard</a>
            </li>
			<cfif IsDefined("session.IsAdmin") AND #session.IsAdmin# IS true>
			<li class="yuimenubaritem">
                <a class="yuimenubaritemlabel" href="#">Support</a>
				<div id="support" class="yuimenu">
                    <div class="bd">
                        <ul class="first-of-type">
							<li class="yuimenuitem"><a href="index.cfm?client_logs" class="yuimenuitemlabel">Client Logs</a></li>
                        </ul>
					</div>
				</div>
            </li>
			</cfif>
            <li class="yuimenubaritem first-of-type">
                <a class="yuimenubaritemlabel" href="#">Admin</a>
                <div id="admin" class="yuimenu">
                    <div class="bd">
                        <ul class="first-of-type">
							<li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Client Agents</a>
                                <div id="ClientAgentsManagment" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
											<li class="yuimenuitem"><a href="index.cfm?adm_mp_agents" class="yuimenuitemlabel">Upload and Deploy</a></li>
											<li class="yuimenuitem"><a href="index.cfm?agent_config" class="yuimenuitemlabel">Configure</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                        </ul>
						<ul>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Proxy Server</a>
                                <div id="ProxyServerManagment" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
											<li class="yuimenuitem"><a href="index.cfm?adm_mpp_settings" class="yuimenuitemlabel">Settings</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                        </ul>
                        <ul>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Patch Baseline</a>
                                <div id="AdminPatchBaseline" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
                                            <li class="yuimenuitem"><a href="index.cfm?patch_baseline" class="yuimenuitemlabel">List</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                        </ul>
                        <ul>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Accounts</a>
                                <div id="AdminUserManagment" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
                                            <li class="yuimenuitem"><a href="index.cfm?adm_mp_accounts" class="yuimenuitemlabel">List</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                        </ul>
                        <ul>
                            <li class="yuimenuitem"><a class="yuimenuitemlabel" href="#">Server</a>
                                <div id="AdminServerSettings" class="yuimenu">
                                    <div class="bd">
                                        <ul class="first-of-type">
                                            <li class="yuimenuitem"><a href="index.cfm?adm_mpsrv_conf" class="yuimenuitemlabel">MacPatch Servers</a></li>
											<li class="yuimenuitem"><a href="index.cfm?adm_asus_conf" class="yuimenuitemlabel">SoftwareUpdate Servers</a></li>
											<li class="yuimenuitem"><a href="index.cfm?adm_mp_db_conf" class="yuimenuitemlabel">Database</a></li>
                                            <li class="yuimenuitem"><a href="index.cfm?adm_server_jobs" class="yuimenuitemlabel">Jobs</a></li>
                                            <li class="yuimenuitem"><a href="index.cfm?adm_mp_logs" class="yuimenuitemlabel">Logs</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </li>
                        </ul>
                    </div>
                 </div>
            </li>
        </ul>
    </div>
</div>