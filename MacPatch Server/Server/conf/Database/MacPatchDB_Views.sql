/*
	MacPatch Database Schema
	Main Views
	Version 2.1.0
*/

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  View structure for `baseline_prod_view`
-- ----------------------------
DROP VIEW IF EXISTS `baseline_prod_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `baseline_prod_view` AS select `a`.`baseline_id` AS `baseline_id`,`a`.`name` AS `name`,`b`.`p_id` AS `p_id`,`b`.`p_name` AS `p_name`,`b`.`p_version` AS `p_version`,`b`.`p_postdate` AS `p_postdate`,`b`.`p_title` AS `p_title`,`b`.`p_reboot` AS `p_reboot`,`b`.`p_type` AS `p_type`,`b`.`p_suname` AS `p_suname`,`b`.`p_active` AS `p_active`,`b`.`p_severity` AS `p_severity`,`b`.`p_patch_state` AS `p_patch_state` from (`mp_baseline` `a` join `mp_baseline_patches` `b` on((`a`.`baseline_id` = `b`.`baseline_id`))) where (`a`.`state` = _utf8'1');

-- ----------------------------
--  View structure for `baseline_qa_view`
-- ----------------------------
DROP VIEW IF EXISTS `baseline_qa_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `baseline_qa_view` AS select `a`.`baseline_id` AS `baseline_id`,`a`.`name` AS `name`,`b`.`p_id` AS `p_id`,`b`.`p_name` AS `p_name`,`b`.`p_version` AS `p_version`,`b`.`p_postdate` AS `p_postdate`,`b`.`p_title` AS `p_title`,`b`.`p_reboot` AS `p_reboot`,`b`.`p_type` AS `p_type`,`b`.`p_suname` AS `p_suname`,`b`.`p_active` AS `p_active`,`b`.`p_severity` AS `p_severity`,`b`.`p_patch_state` AS `p_patch_state` from (`mp_baseline` `a` join `mp_baseline_patches` `b` on((`a`.`baseline_id` = `b`.`baseline_id`))) where (`a`.`state` = _utf8'2');

-- ----------------------------
--  View structure for `mp_clients_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_clients_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_clients_view` AS select `mp_clients`.`cuuid` AS `cuuid`,`mp_clients`.`serialNo` AS `serialNo`,`mp_clients`.`hostname` AS `hostname`,`mp_clients`.`computername` AS `computername`,`mp_clients`.`ipaddr` AS `ipaddr`,`mp_clients`.`macaddr` AS `macaddr`,`mp_clients`.`osver` AS `osver`,`mp_clients`.`ostype` AS `ostype`,`mp_clients`.`consoleUser` AS `consoleUser`,`mp_clients`.`needsreboot` AS `needsreboot`,`mp_clients`.`agent_version` AS `agent_version`,`mp_clients`.`client_version` AS `client_version`,`mp_clients`.`mdate` AS `mdate`,`mp_clients`.`cdate` AS `cdate`,`mp_clients_plist`.`EnableASUS` AS `EnableASUS`,`mp_clients_plist`.`MPDLTimeout` AS `MPDLTimeout`,`mp_clients_plist`.`AllowClient` AS `AllowClient`,`mp_clients_plist`.`MPServerSSL` AS `MPServerSSL`,`mp_clients_plist`.`Domain` AS `Domain`,`mp_clients_plist`.`Name` AS `Name`,`mp_clients_plist`.`MPInstallTimeout` AS `MPInstallTimeout`,`mp_clients_plist`.`MPServerDLLimit` AS `MPServerDLLimit`,`mp_clients_plist`.`PatchGroup` AS `PatchGroup`,`mp_clients_plist`.`MPProxyEnabled` AS `MPProxyEnabled`,`mp_clients_plist`.`Description` AS `Description`,`mp_clients_plist`.`MPDLConTimeout` AS `MPDLConTimeout`,`mp_clients_plist`.`MPProxyServerPort` AS `MPProxyServerPort`,`mp_clients_plist`.`MPProxyServerAddress` AS `MPProxyServerAddress`,`mp_clients_plist`.`AllowServer` AS `AllowServer`,`mp_clients_plist`.`MPServerAddress` AS `MPServerAddress`,`mp_clients_plist`.`MPServerPort` AS `MPServerPort`,`mp_clients_plist`.`MPServerTimeout` AS `MPServerTimeout`,`mp_clients_plist`.`Reboot` AS `Reboot`,`mp_clients_plist`.`DialogText` AS `DialogText`,`mp_clients_plist`.`PatchState` AS `PatchState` from (`mp_clients` left join `mp_clients_plist` on((`mp_clients`.`cuuid` = `mp_clients_plist`.`cuuid`)));

-- ----------------------------
--  View structure for `combined_patches_view`
-- ----------------------------
DROP VIEW IF EXISTS `combined_patches_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `combined_patches_view` AS select distinct `ap`.`akey` AS `id`,`ap`.`patchname` AS `name`,`ap`.`version` AS `version`,`ap`.`postdate` AS `postdate`,`ap`.`title` AS `title`,(case when (`ap`.`restartaction` = _latin1'NoRestart') then _latin1'No' when (`ap`.`restartaction` = _latin1'RequireRestart') then _latin1'Yes' end) AS `reboot`,_latin1'Apple' AS `type`,`ap`.`supatchname` AS `suname`,1 AS `active`,`api`.`severity` AS `severity`,`api`.`patch_state` AS `patch_state`,0 AS `size` from (`apple_patches_real` `ap` left join `apple_patches` `api` on((`api`.`akey` = `ap`.`akey`))) union all select `mp_patches`.`puuid` AS `id`,`mp_patches`.`patch_name` AS `name`,`mp_patches`.`patch_ver` AS `version`,`mp_patches`.`cdate` AS `postdate`,`mp_patches`.`description` AS `title`,`mp_patches`.`patch_reboot` AS `reboot`,_latin1'Third' AS `type`,concat(`mp_patches`.`patch_name`,_latin1'-',`mp_patches`.`patch_ver`) AS `suname`,`mp_patches`.`active` AS `active`,`mp_patches`.`patch_severity` AS `severity`,`mp_patches`.`patch_state` AS `patch_state`,`mp_patches`.`pkg_size` AS `size` from `mp_patches`;

-- ----------------------------
--  View structure for `mp_client_patch_status_prequery_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_client_patch_status_prequery_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_client_patch_status_prequery_view` AS select `b1`.`cuuid` AS `cuuid`,`b1`.`date` AS `date`,`b1`.`patch` AS `patch`,`b1`.`description` AS `description`,`ap`.`akey` AS `pid` from (`mp_client_patches_apple` `b1` join `apple_patches` `ap` on((`b1`.`patch` = `ap`.`supatchname`))) union select `mp_client_patches_third`.`cuuid` AS `cuuid`,`mp_client_patches_third`.`date` AS `date`,`mp_client_patches_third`.`patch` AS `patch`,`mp_client_patches_third`.`description` AS `description`,`mp_client_patches_third`.`patch_id` AS `pid` from `mp_client_patches_third`;

-- ----------------------------
--  View structure for `mp_client_patches_apple_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_client_patches_apple_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_client_patches_apple_view` AS select `mpca`.`rid` AS `rid`,`mpca`.`cuuid` AS `cuuid`,`mpca`.`date` AS `date`,`mpca`.`patch` AS `patch`,`mpca`.`type` AS `type`,`mpca`.`description` AS `description`,`mpca`.`size` AS `size`,`mpca`.`recommended` AS `recommended`,`mpca`.`restart` AS `restart`,`ap`.`akey` AS `patch_id` from (`mp_client_patches_apple` `mpca` left join `apple_patches_real` `ap` on((`ap`.`supatchname` = `mpca`.`patch`)));

-- ----------------------------
--  View structure for `mp_client_patches_third_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_client_patches_third_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_client_patches_third_view` AS select `mpca`.`rid` AS `rid`,`mpca`.`cuuid` AS `cuuid`,`mpca`.`date` AS `date`,concat(`mpp`.`patch_name`,_latin1'-',`mpp`.`patch_ver`) AS `patch`,`mpca`.`type` AS `type`,`mpca`.`description` AS `description`,`mpca`.`size` AS `size`,`mpca`.`recommended` AS `recommended`,`mpca`.`restart` AS `restart`,`mpca`.`patch_id` AS `patch_id` from (`mp_client_patches_third` `mpca` join `mp_patches` `mpp` on((`mpp`.`puuid` = `mpca`.`patch_id`)));

-- ----------------------------
--  View structure for `mp_client_patches_full_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_client_patches_full_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_client_patches_full_view` AS select `mp_client_patches_apple_view`.`cuuid` AS `cuuid`,`mp_client_patches_apple_view`.`date` AS `date`,`mp_client_patches_apple_view`.`patch` AS `patch`,`mp_client_patches_apple_view`.`type` AS `type`,`mp_client_patches_apple_view`.`description` AS `description`,`mp_client_patches_apple_view`.`size` AS `size`,`mp_client_patches_apple_view`.`recommended` AS `recommended`,`mp_client_patches_apple_view`.`restart` AS `restart`,`mp_client_patches_apple_view`.`patch_id` AS `patch_id` from `mp_client_patches_apple_view` union select `mp_client_patches_third_view`.`cuuid` AS `cuuid`,`mp_client_patches_third_view`.`date` AS `date`,`mp_client_patches_third_view`.`patch` AS `patch`,`mp_client_patches_third_view`.`type` AS `type`,`mp_client_patches_third_view`.`description` AS `description`,`mp_client_patches_third_view`.`size` AS `size`,`mp_client_patches_third_view`.`recommended` AS `recommended`,`mp_client_patches_third_view`.`restart` AS `restart`,`mp_client_patches_third_view`.`patch_id` AS `patch_id` from `mp_client_patches_third_view`;

-- ----------------------------
--  View structure for `client_patch_status_view`
-- ----------------------------
DROP VIEW IF EXISTS `client_patch_status_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `client_patch_status_view` AS select `a`.`cuuid` AS `cuuid`,`a`.`date` AS `date`,`a`.`patch` AS `patch`,`a`.`type` AS `type`,`a`.`description` AS `description`,`a`.`size` AS `size`,`a`.`recommended` AS `recommended`,`a`.`restart` AS `restart`,`a`.`patch_id` AS `patch_id`,`cci`.`hostname` AS `hostname`,`cci`.`Domain` AS `ClientGroup`,`cci`.`ipaddr` AS `ipaddr`,(to_days(`a`.`date`) - to_days(`cpv`.`postdate`)) AS `DaysNeeded` from ((`mp_client_patches_full_view` `a` left join `combined_patches_view` `cpv` on((`cpv`.`id` = `a`.`patch_id`))) left join `mp_clients_view` `cci` on((`a`.`cuuid` = `cci`.`cuuid`))) where (`a`.`date` <> _utf8'0000-00-00 00:00:00');

-- ----------------------------
--  View structure for `mp_client_patch_status_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_client_patch_status_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_client_patch_status_view` AS select `a`.`cuuid` AS `cuuid`,`a`.`date` AS `date`,`a`.`patch` AS `patch`,`a`.`type` AS `type`,`a`.`description` AS `description`,`a`.`size` AS `size`,`a`.`recommended` AS `recommended`,`a`.`restart` AS `restart`,`a`.`patch_id` AS `patch_id`,`cci`.`hostname` AS `hostname`,`cci`.`Domain` AS `ClientGroup`,`cci`.`ipaddr` AS `ipaddr`,`cci`.`PatchGroup` AS `PatchGroup`,(to_days(`a`.`date`) - to_days(`cpv`.`postdate`)) AS `DaysNeeded` from ((`mp_client_patches_full_view` `a` left join `combined_patches_view` `cpv` on((`cpv`.`id` = `a`.`patch_id`))) left join `mp_clients_view` `cci` on((`a`.`cuuid` = `cci`.`cuuid`))) where (`a`.`date` <> _utf8'0000-00-00 00:00:00');

-- ----------------------------
--  View structure for `mp_installed_patches_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_installed_patches_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_installed_patches_view` AS select `mip`.`cuuid` AS `cuuid`,`mip`.`date` AS `idate`,`cpfv`.`suname` AS `patch`,`cci`.`hostname` AS `hostname`,`cci`.`Domain` AS `domain`,`cci`.`ipaddr` AS `ipaddr`,`mip`.`type` AS `type` from ((`mp_installed_patches` `mip` join `combined_patches_view` `cpfv` on((`mip`.`patch` = `cpfv`.`suname`))) join `mp_clients_view` `cci` on((`mip`.`cuuid` = `cci`.`cuuid`)));

-- ----------------------------
--  View structure for `mp_patchgroup_patches_view`
-- ----------------------------
DROP VIEW IF EXISTS `mp_patchgroup_patches_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `mp_patchgroup_patches_view` AS select `mp_patch_group`.`name` AS `patch_group`,`mp_patch_group`.`id` AS `id`,`mp_patch_group_patches`.`patch_id` AS `patch_id`,`combined_patches_view`.`name` AS `name`,`combined_patches_view`.`version` AS `version`,`combined_patches_view`.`suname` AS `suname`,`combined_patches_view`.`reboot` AS `reboot`,`combined_patches_view`.`type` AS `type`,`combined_patches_view`.`active` AS `active`,`combined_patches_view`.`severity` AS `severity`,`combined_patches_view`.`postdate` AS `postdate`,`combined_patches_view`.`title` AS `title`,`combined_patches_view`.`patch_state` AS `patch_state` from ((`mp_patch_group` join `mp_patch_group_patches` on((`mp_patch_group`.`id` = `mp_patch_group_patches`.`patch_group_id`))) join `combined_patches_view` on((`mp_patch_group_patches`.`patch_id` = `combined_patches_view`.`id`)));

-- ----------------------------
--  View structure for `new_patches_14day`
-- ----------------------------
DROP VIEW IF EXISTS `new_patches_14day`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `new_patches_14day` AS select `apple_patches`.`patchname` AS `patchname`,`apple_patches`.`title` AS `title`,`apple_patches`.`version` AS `version`,`apple_patches`.`postdate` AS `postdate`,`apple_patches`.`restartaction` AS `restartaction` from `apple_patches` where (`apple_patches`.`postdate` >= (now() - interval 14 day));

-- ----------------------------
--  View structure for `patchlist`
-- ----------------------------
-- DROP VIEW IF EXISTS `patchlist`;
-- CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `patchlist` AS select distinct `p`.`patch` AS `patch`,`p`.`description` AS `description`,substr(`p`.`osver`,1,4) AS `osver`,`p`.`reboot` AS `reboot`,`p`.`recommended` AS `recommended`,`ap`.`postdate` AS `postdate` from (`patches` `p` join `apple_patches` `ap` on((`p`.`patch` = `ap`.`supatchname`)));

-- ----------------------------
--  View structure for `savav_client_info`
-- ----------------------------
DROP VIEW IF EXISTS `savav_client_info`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `savav_client_info` AS select `si`.`cuuid` AS `cuuid`,`si`.`defsDate` AS `defsDate`,`si`.`savShortVersion` AS `savShortVersion`,`si`.`appPath` AS `appPath`,`si`.`savBundleVersion` AS `savBundleVersion`,`si`.`savAppName` AS `savAppName`,`si`.`mdate` AS `mdate`,`cci`.`hostname` AS `hostname`,`cci`.`ipaddr` AS `ipaddr`,`cci`.`osver` AS `osver`,`cci`.`ostype` AS `ostype` from (`savav_info` `si` join `mp_clients_view` `cci`) where (`si`.`cuuid` = `cci`.`cuuid`);

-- ----------------------------
--  View structure for `zclientpatchstatusprequery_view`
-- ----------------------------
DROP VIEW IF EXISTS `zclientpatchstatusprequery_view`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `zclientpatchstatusprequery_view` AS select `b1`.`cuuid` AS `cuuid`,`b1`.`date` AS `date`,`b1`.`patch` AS `patch`,`b1`.`description` AS `description`,`ap`.`akey` AS `pid` from (`mp_client_patches_apple` `b1` join `apple_patches` `ap` on((`b1`.`patch` = `ap`.`supatchname`))) union select `mp_client_patches_third`.`cuuid` AS `cuuid`,`mp_client_patches_third`.`date` AS `date`,`mp_client_patches_third`.`patch` AS `patch`,`mp_client_patches_third`.`description` AS `description`,`mp_client_patches_third`.`patch_id` AS `pid` from `mp_client_patches_third`;

SET FOREIGN_KEY_CHECKS = 1;