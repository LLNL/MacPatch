/*
  MacPatch Database Schema
	All Tables
	Version 2.2.0
	Rev 4
*/

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `acl_computer_group_members`
-- ----------------------------
DROP TABLE IF EXISTS `acl_computer_group_members`;
CREATE TABLE `acl_computer_group_members` (
  `ClientID` varchar(50) NOT NULL,
  `GroupID` varchar(50) DEFAULT 'Default',
  PRIMARY KEY (`ClientID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `acl_computer_groups`
-- ----------------------------
DROP TABLE IF EXISTS `acl_computer_groups`;
CREATE TABLE `acl_computer_groups` (
  `GroupID` varchar(50) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `UserOwner` varchar(255) NOT NULL,
  `GroupOwner` varchar(50) DEFAULT NULL,
  `Profile` varchar(50) DEFAULT 'Default',
  PRIMARY KEY (`GroupID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `acl_group_members`
-- ----------------------------
DROP TABLE IF EXISTS `acl_group_members`;
CREATE TABLE `acl_group_members` (
  `GroupID` varchar(50) NOT NULL,
  `UserID` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `acl_groups`
-- ----------------------------
DROP TABLE IF EXISTS `acl_groups`;
CREATE TABLE `acl_groups` (
  `GroupID` varchar(50) NOT NULL,
  `Name` varchar(255) NOT NULL,
  PRIMARY KEY (`GroupID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `acl_users`
-- ----------------------------
DROP TABLE IF EXISTS `acl_users`;
CREATE TABLE `acl_users` (
  `UserID` varchar(255) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `UserKey` varchar(50) DEFAULT '0',
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `apple_patches`
-- ----------------------------
DROP TABLE IF EXISTS `apple_patches`;
CREATE TABLE `apple_patches` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `akey` varchar(50) NOT NULL,
  `postdate` datetime NOT NULL,
  `version` varchar(20) NOT NULL,
  `restartaction` varchar(20) NOT NULL,
  `patchname` varchar(100) NOT NULL,
  `supatchname` varchar(100) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text CHARACTER SET utf8,
  `description64` longtext,
  `severity` varchar(20) DEFAULT 'High',
  `severity_int` int(2) DEFAULT '3',
  `patch_state` varchar(10) DEFAULT 'Create',
  `osver_support` varchar(10) DEFAULT 'NA',
  PRIMARY KEY (`rid`),
  KEY `idx_apple_patches` (`supatchname`,`patchname`,`restartaction`),
  KEY `idx_akey` (`akey`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `apple_patches_mp_additions`
-- ----------------------------
DROP TABLE IF EXISTS `apple_patches_mp_additions`;
CREATE TABLE `apple_patches_mp_additions` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `version` varchar(20) NOT NULL,
  `supatchname` varchar(100) NOT NULL,
  `severity` varchar(20) DEFAULT 'High',
  `severity_int` int(2) DEFAULT '3',
  `patch_state` varchar(10) DEFAULT 'Create',
  `patch_install_weight` int(2) unsigned DEFAULT '60',
  `patch_reboot` int(1) unsigned DEFAULT '0',
  `osver_support` varchar(10) DEFAULT 'NA',
  PRIMARY KEY (`rid`),
  KEY `idx_apple_patches` (`supatchname`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `dataMgrlogs`
-- ----------------------------
DROP TABLE IF EXISTS `dataMgrlogs`;
CREATE TABLE `dataMgrlogs` (
  `LogID` int(11) NOT NULL AUTO_INCREMENT,
  `tablename` varchar(180) DEFAULT NULL,
  `pkval` varchar(250) DEFAULT NULL,
  `action` varchar(60) DEFAULT NULL,
  `DatePerformed` datetime DEFAULT NULL,
  `data` text,
  `sql` text,
  PRIMARY KEY (`LogID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `mp_adm_group_users`
-- ----------------------------
DROP TABLE IF EXISTS `mp_adm_group_users`;
CREATE TABLE `mp_adm_group_users` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `group_id` varchar(50) NOT NULL DEFAULT '1',
  `user_id` varchar(100) NOT NULL,
  `user_type` int(1) DEFAULT NULL,
  `last_login` datetime NOT NULL DEFAULT '2000-01-01 12:00:00',
  `number_of_logins` int(11) NOT NULL,
  `enabled` int(1) unsigned DEFAULT '1',
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_adm_groups`
-- ----------------------------
DROP TABLE IF EXISTS `mp_adm_groups`;
CREATE TABLE `mp_adm_groups` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `group_id` varchar(50) NOT NULL,
  `group_name` varchar(255) NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_adm_users`
-- ----------------------------
DROP TABLE IF EXISTS `mp_adm_users`;
CREATE TABLE `mp_adm_users` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(255) NOT NULL,
  `user_pass` varchar(255) NOT NULL,
  `user_RealName` varchar(255) DEFAULT 'NA',
  `enabled` int(1) unsigned DEFAULT '1',
  PRIMARY KEY (`rid`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_agent_config`
-- ----------------------------
DROP TABLE IF EXISTS `mp_agent_config`;
CREATE TABLE `mp_agent_config` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `aid` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `isDefault` int(1) unsigned DEFAULT '0',
  `revision` varchar(50) DEFAULT '0',
  PRIMARY KEY (`rid`,`aid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_agent_config_data`
-- ----------------------------
DROP TABLE IF EXISTS `mp_agent_config_data`;
CREATE TABLE `mp_agent_config_data` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `aid` varchar(50) NOT NULL,
  `aKey` varchar(255) NOT NULL,
  `aKeyValue` varchar(255) NOT NULL,
  `enforced` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_apple_patch_criteria`
-- ----------------------------
DROP TABLE IF EXISTS `mp_apple_patch_criteria`;
CREATE TABLE `mp_apple_patch_criteria` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `puuid` varchar(50) DEFAULT NULL,
  `supatchname` varchar(255) DEFAULT NULL,
  `type` varchar(25) DEFAULT NULL,
  `type_data` mediumtext,
  `type_action` int(1) unsigned DEFAULT '0',
  `type_order` int(2) DEFAULT NULL,
  `cdate` datetime DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `idx_puuid` (`puuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `cDateTime_Trig` BEFORE INSERT ON `mp_apple_patch_criteria` FOR EACH ROW SET new.cdate = now(), new.mdate = now();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mDateTime_Trig` BEFORE UPDATE ON `mp_apple_patch_criteria` FOR EACH ROW SET new.mdate = now();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_asus_catalogs`
-- ----------------------------
DROP TABLE IF EXISTS `mp_asus_catalogs`;
CREATE TABLE `mp_asus_catalogs` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `catalog_url` varchar(255) NOT NULL,
  `os_minor` int(2) NOT NULL,
  `os_major` int(2) NOT NULL,
  `c_order` int(2) DEFAULT NULL,
  `proxy` int(1) NOT NULL DEFAULT '0',
  `catalog_group_name` varchar(255) NOT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_rid` (`rid`),
  KEY `idx_minor_os` (`os_minor`,`c_order`,`proxy`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_baseline`
-- ----------------------------
DROP TABLE IF EXISTS `mp_baseline`;
CREATE TABLE `mp_baseline` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `baseline_id` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `cdate` datetime NOT NULL,
  `mdate` datetime NOT NULL,
  `state` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`,`baseline_id`),
  KEY `b_idx` (`baseline_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_baseline_dev`
-- ----------------------------
DROP TABLE IF EXISTS `mp_baseline_dev`;
CREATE TABLE `mp_baseline_dev` (
  `rid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `baseline_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `type` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`,`baseline_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_baseline_patches`
-- ----------------------------
DROP TABLE IF EXISTS `mp_baseline_patches`;
CREATE TABLE `mp_baseline_patches` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `baseline_id` bigint(20) NOT NULL,
  `p_id` varchar(50) NOT NULL,
  `p_name` varchar(255) DEFAULT NULL,
  `p_version` varchar(255) DEFAULT NULL,
  `p_postdate` datetime DEFAULT NULL,
  `p_title` varchar(255) DEFAULT NULL,
  `p_reboot` varchar(255) DEFAULT NULL,
  `p_type` varchar(255) DEFAULT NULL,
  `p_suname` varchar(255) DEFAULT NULL,
  `p_active` varchar(255) DEFAULT NULL,
  `p_severity` varchar(255) DEFAULT NULL,
  `p_patch_state` varchar(255) DEFAULT NULL,
  `baseline_enabled` int(1) DEFAULT '0',
  PRIMARY KEY (`rid`,`baseline_id`),
  KEY `b_idx` (`baseline_id`),
  KEY `pid_idx` (`p_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_baseline_patches_dev`
-- ----------------------------
DROP TABLE IF EXISTS `mp_baseline_patches_dev`;
CREATE TABLE `mp_baseline_patches_dev` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `baseline_id` bigint(20) DEFAULT NULL,
  `patch_id` varchar(100) NOT NULL,
  `patch_name` varchar(255) DEFAULT NULL,
  `patch_version` varchar(100) DEFAULT NULL,
  `patch_postdate` datetime DEFAULT NULL,
  `state` int(1) unsigned DEFAULT '0',
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_baseline_patches_history_dev`
-- ----------------------------
DROP TABLE IF EXISTS `mp_baseline_patches_history_dev`;
CREATE TABLE `mp_baseline_patches_history_dev` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `baseline_id` bigint(20) NOT NULL,
  `patch_id` varchar(100) DEFAULT NULL,
  `patch_name` varchar(255) DEFAULT NULL,
  `patch_version` varchar(100) DEFAULT NULL,
  `patch_postdate` datetime DEFAULT NULL,
  `state_from` int(11) DEFAULT '0',
  `state_to` int(11) NOT NULL DEFAULT '0',
  `mdate` datetime NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_client_agents`
-- ----------------------------
DROP TABLE IF EXISTS `mp_client_agents`;
CREATE TABLE `mp_client_agents` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `puuid` varchar(50) NOT NULL,
  `type` varchar(10) NOT NULL,
  `osver` varchar(255) NOT NULL DEFAULT '*',
  `agent_ver` varchar(10) NOT NULL,
  `version` varchar(10) DEFAULT NULL,
  `build` varchar(10) DEFAULT NULL,
  `framework` varchar(10) DEFAULT NULL,
  `pkg_name` varchar(100) NOT NULL,
  `pkg_url` varchar(255) DEFAULT NULL,
  `pkg_hash` varchar(50) DEFAULT NULL,
  `active` int(1) unsigned NOT NULL DEFAULT '0',
  `state` int(1) unsigned NOT NULL DEFAULT '0',
  `cdate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `main_idx` (`puuid`,`type`,`agent_ver`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mdate_agnt_in` BEFORE INSERT ON `mp_client_agents` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mdate_agnt_up` BEFORE UPDATE ON `mp_client_agents` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_client_agents_filters`
-- ----------------------------
DROP TABLE IF EXISTS `mp_client_agents_filters`;
CREATE TABLE `mp_client_agents_filters` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `attribute` varchar(255) NOT NULL,
  `attribute_oper` varchar(10) NOT NULL,
  `attribute_filter` varchar(255) NOT NULL,
  `attribute_condition` varchar(10) NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_client_errors`
-- ----------------------------
DROP TABLE IF EXISTS `mp_client_errors`;
CREATE TABLE `mp_client_errors` (
  `rid` bigint(20) unsigned NOT NULL,
  `cuuid` varchar(50) NOT NULL,
  `cdate` datetime DEFAULT NULL,
  `error` text NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `add_cdate` BEFORE INSERT ON `mp_client_errors` FOR EACH ROW SET new.cdate = now();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_client_patches_apple`
-- ----------------------------
DROP TABLE IF EXISTS `mp_client_patches_apple`;
CREATE TABLE `mp_client_patches_apple` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime DEFAULT '0000-00-00 00:00:00',
  `patch` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `size` varchar(255) NOT NULL,
  `recommended` varchar(255) NOT NULL,
  `restart` varchar(255) NOT NULL,
  `version` varchar(255) DEFAULT NULL,
  `mdate` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_no_dups` (`cuuid`,`patch`,`type`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_client_patches_third`
-- ----------------------------
DROP TABLE IF EXISTS `mp_client_patches_third`;
CREATE TABLE `mp_client_patches_third` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime DEFAULT '0000-00-00 00:00:00',
  `patch` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `size` varchar(255) NOT NULL,
  `recommended` varchar(255) NOT NULL,
  `restart` varchar(255) NOT NULL,
  `patch_id` varchar(255) NOT NULL,
  `version` varchar(255) DEFAULT NULL,
  `mdate` timestamp NULL DEFAULT NULL,
  `bundleID` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_no_dups` (`cuuid`,`type`,`patch_id`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_client_patches_third_copy`
-- ----------------------------
DROP TABLE IF EXISTS `mp_client_patches_third_copy`;
CREATE TABLE `mp_client_patches_third_copy` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime DEFAULT '0000-00-00 00:00:00',
  `patch` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `size` varchar(255) NOT NULL,
  `recommended` varchar(255) NOT NULL,
  `restart` varchar(255) NOT NULL,
  `patch_id` varchar(255) NOT NULL,
  `version` varchar(255) DEFAULT NULL,
  `mdate` timestamp NULL DEFAULT NULL,
  `bundleID` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_no_dups` (`cuuid`,`type`,`patch_id`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_clients`
-- ----------------------------
DROP TABLE IF EXISTS `mp_clients`;
CREATE TABLE `mp_clients` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `serialNo` varchar(100) DEFAULT 'NA',
  `hostname` varchar(255) DEFAULT 'NA',
  `computername` varchar(255) DEFAULT 'NA',
  `ipaddr` varchar(64) DEFAULT 'NA',
  `macaddr` varchar(64) DEFAULT 'NA',
  `osver` varchar(255) DEFAULT 'NA',
  `ostype` varchar(255) DEFAULT 'NA',
  `consoleUser` varchar(255) DEFAULT 'NA',
  `needsreboot` varchar(255) DEFAULT 'NA',
  `agent_version` varchar(20) DEFAULT 'NA',
  `agent_build` varchar(10) DEFAULT '0',
  `client_version` varchar(20) DEFAULT 'NA',
  `rhash` varchar(50) DEFAULT 'NA',
  `mdate` datetime DEFAULT NULL,
  `cdate` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_cuuid` (`cuuid`),
  KEY `idx_clientinfo` (`hostname`,`ipaddr`,`cuuid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mdate_insrt01` BEFORE INSERT ON `mp_clients` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mdate_updt01` BEFORE UPDATE ON `mp_clients` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_clients_key`
-- ----------------------------
DROP TABLE IF EXISTS `mp_clients_key`;
CREATE TABLE `mp_clients_key` (
  `rid` bigint(20) NOT NULL,
  `cuuid` varchar(50) NOT NULL,
  `ckey` varchar(255) NOT NULL,
  `cdate` datetime NOT NULL,
  `mdate` datetime NOT NULL,
  PRIMARY KEY (`rid`,`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `insrt_key01` BEFORE INSERT ON `mp_clients_key` FOR EACH ROW SET NEW.mdate = NOW(), New.cdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `updt_key01` BEFORE UPDATE ON `mp_clients_key` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_clients_plist`
-- ----------------------------
DROP TABLE IF EXISTS `mp_clients_plist`;
CREATE TABLE `mp_clients_plist` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL DEFAULT '',
  `rhash` varchar(50) DEFAULT 'NA',
  `mdate` datetime DEFAULT NULL,
  `EnableASUS` varchar(255) DEFAULT 'NA',
  `MPDLTimeout` varchar(255) DEFAULT 'NA',
  `AllowClient` varchar(255) DEFAULT 'NA',
  `MPServerSSL` varchar(255) DEFAULT 'NA',
  `Domain` varchar(255) DEFAULT 'NA',
  `Name` varchar(255) DEFAULT 'NA',
  `MPInstallTimeout` varchar(255) DEFAULT 'NA',
  `MPServerDLLimit` varchar(255) DEFAULT 'NA',
  `PatchGroup` varchar(255) DEFAULT 'NA',
  `MPProxyEnabled` varchar(255) DEFAULT 'NA',
  `CatalogURL1` varchar(255) DEFAULT 'NA',
  `CatalogURL2` varchar(255) DEFAULT 'NA',
  `SAVDefScanRandomize` varchar(255) DEFAULT 'NA',
  `Description` varchar(255) DEFAULT 'NA',
  `MPDLConTimeout` varchar(255) DEFAULT 'NA',
  `MPProxyServerPort` varchar(255) DEFAULT 'NA',
  `MPProxyServerAddress` varchar(255) DEFAULT 'NA',
  `AllowServer` varchar(255) DEFAULT 'NA',
  `MPServerAddress` varchar(255) DEFAULT 'NA',
  `MPServerPort` varchar(255) DEFAULT 'NA',
  `MPServerTimeout` varchar(255) DEFAULT 'NA',
  `Reboot` varchar(255) DEFAULT 'NA',
  `DialogText` varchar(255) DEFAULT 'NA',
  `cdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PatchState` varchar(255) DEFAULT 'NA',
  `ClientScanInterval` varchar(255) DEFAULT 'NA',
  `MPAgentExecDebug` varchar(255) DEFAULT 'NA',
  `PatchGrouop` varchar(255) DEFAULT 'NA',
  `MPAgentDebug` varchar(255) DEFAULT 'NA',
  `PachGroup` varchar(255) DEFAULT 'NA',
  `SWDistGroup` varchar(255) DEFAULT 'NA',
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_cuuid` (`cuuid`),
  KEY `idx_clientinfo` (`cuuid`,`Domain`,`PatchGroup`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_clients_tasks`
-- ----------------------------
DROP TABLE IF EXISTS `mp_clients_tasks`;
CREATE TABLE `mp_clients_tasks` (
  `rid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `cuuid` varchar(50) DEFAULT NULL,
  `id` varchar(255) DEFAULT NULL,
  `idrev` varchar(255) DEFAULT NULL,
  `idsig` varchar(255) DEFAULT NULL,
  `cmd` varchar(255) DEFAULT NULL,
  `cmdalt` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `mode` varchar(255) DEFAULT NULL,
  `startdate` varchar(255) DEFAULT NULL,
  `enddate` varchar(255) DEFAULT NULL,
  `interval` varchar(255) DEFAULT NULL,
  `active` varchar(255) DEFAULT NULL,
  `scope` varchar(255) DEFAULT NULL,
  `parent` varchar(255) DEFAULT NULL,
  `task_type` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_installed_patches`
-- ----------------------------
DROP TABLE IF EXISTS `mp_installed_patches`;
CREATE TABLE `mp_installed_patches` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `patch` varchar(255) NOT NULL,
  `patch_name` varchar(255) DEFAULT 'NA',
  `type` varchar(255) NOT NULL,
  `server_name` varchar(255) DEFAULT 'NA',
  `date` timestamp NULL DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `idx_cuuid` (`cuuid`),
  KEY `idx_patch` (`patch`),
  KEY `idx_type` (`type`),
  KEY `idx_date` (`date`),
  KEY `idx_all` (`cuuid`,`date`,`patch`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_installed_patches_errors`
-- ----------------------------
DROP TABLE IF EXISTS `mp_installed_patches_errors`;
CREATE TABLE `mp_installed_patches_errors` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL DEFAULT '',
  `patch` varchar(50) DEFAULT NULL,
  `result` int(10) DEFAULT NULL,
  `resultString` text,
  `cdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`,`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mpipe_cdate` BEFORE INSERT ON `mp_installed_patches_errors` FOR EACH ROW SET NEW.cdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_installed_patches_new`
-- ----------------------------
DROP TABLE IF EXISTS `mp_installed_patches_new`;
CREATE TABLE `mp_installed_patches_new` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `patch` varchar(255) NOT NULL,
  `patch_name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `server_name` varchar(255) DEFAULT NULL,
  `date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `idx_cuuid` (`cuuid`),
  KEY `idx_patch` (`patch`),
  KEY `idx_type` (`type`),
  KEY `idx_date` (`date`),
  KEY `idx_all` (`cuuid`,`date`,`patch`,`type`,`patch_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_patch_group`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patch_group`;
CREATE TABLE `mp_patch_group` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `id` varchar(50) NOT NULL,
  `type` int(1) NOT NULL DEFAULT '0',
  `hash` varchar(50) DEFAULT '0',
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `id_idx` (`id`),
  KEY `rid_idx` (`rid`),
  KEY `name_idx` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mdate_isrt_grp01` BEFORE INSERT ON `mp_patch_group` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mdate_updt_grp01` BEFORE UPDATE ON `mp_patch_group` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_patch_group_data`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patch_group_data`;
CREATE TABLE `mp_patch_group_data` (
  `pid` varchar(50) NOT NULL,
  `hash` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  `data_type` varchar(4) DEFAULT 'SOAP',
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`pid`),
  UNIQUE KEY `pid_idx` (`pid`),
  KEY `hash_idx` (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `trg_insrt_mdate_data1` BEFORE INSERT ON `mp_patch_group_data` FOR EACH ROW Set NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `trg_update_mdate_data1` BEFORE UPDATE ON `mp_patch_group_data` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_patch_group_members`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patch_group_members`;
CREATE TABLE `mp_patch_group_members` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(255) NOT NULL,
  `patch_group_id` varchar(50) NOT NULL,
  `is_owner` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`),
  KEY `rid_idx` (`rid`),
  KEY `pgid_idx` (`patch_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_patch_group_patches`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patch_group_patches`;
CREATE TABLE `mp_patch_group_patches` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `patch_id` varchar(50) NOT NULL,
  `patch_group_id` varchar(50) NOT NULL,
  PRIMARY KEY (`rid`),
  KEY `rid_idx` (`rid`),
  KEY `pgid_idx` (`patch_group_id`),
  KEY `pid_idx` (`patch_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_patches`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patches`;
CREATE TABLE `mp_patches` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `puuid` varchar(50) NOT NULL,
  `bundle_id` varchar(50) NOT NULL DEFAULT 'gov.llnl.Default',
  `patch_name` varchar(100) NOT NULL,
  `patch_ver` varchar(20) NOT NULL,
  `patch_vendor` varchar(255) DEFAULT 'NA',
  `patch_install_weight` int(2) unsigned DEFAULT '30',
  `description` varchar(255) DEFAULT NULL,
  `description_url` varchar(255) DEFAULT NULL,
  `patch_severity` varchar(10) NOT NULL,
  `patch_state` varchar(10) NOT NULL,
  `patch_reboot` varchar(3) NOT NULL,
  `cve_id` varchar(255) DEFAULT NULL,
  `active` int(1) NOT NULL,
  `pkg_preinstall` text,
  `pkg_postinstall` text,
  `pkg_name` varchar(100) DEFAULT NULL,
  `pkg_size` varchar(100) DEFAULT '0',
  `pkg_hash` varchar(100) DEFAULT NULL,
  `pkg_path` varchar(255) DEFAULT NULL,
  `pkg_url` varchar(255) DEFAULT NULL,
  `pkg_env_var` varchar(255) DEFAULT NULL,
  `cdate` datetime DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`,`puuid`),
  UNIQUE KEY `puuid_idx` (`puuid`),
  KEY `bundle_idx` (`bundle_id`),
  KEY `patch_idx` (`patch_name`,`patch_ver`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_patches_criteria`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patches_criteria`;
CREATE TABLE `mp_patches_criteria` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `puuid` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `type_data` text NOT NULL,
  `type_order` int(2) NOT NULL,
  `type_required_order` int(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`,`puuid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `puuid_idx` (`puuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_patches_requisits`
-- ----------------------------
DROP TABLE IF EXISTS `mp_patches_requisits`;
CREATE TABLE `mp_patches_requisits` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `puuid` varchar(50) NOT NULL,
  `type` int(1) NOT NULL,
  `type_txt` varchar(25) NOT NULL,
  `type_order` int(2) NOT NULL,
  `puuid_ref` varchar(50) NOT NULL,
  PRIMARY KEY (`rid`,`puuid`),
  UNIQUE KEY `rid_idx` (`rid`),
  UNIQUE KEY `insert_idx` (`puuid`,`type`,`type_order`,`puuid_ref`),
  KEY `puuid` (`puuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_proxy_conf`
-- ----------------------------
DROP TABLE IF EXISTS `mp_proxy_conf`;
CREATE TABLE `mp_proxy_conf` (
  `rid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `address` varchar(255) NOT NULL,
  `port` int(10) DEFAULT '2600',
  `description` text,
  `active` int(1) DEFAULT '1',
  `cdate` datetime DEFAULT NULL,
  `mdate` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_proxy_key`
-- ----------------------------
DROP TABLE IF EXISTS `mp_proxy_key`;
CREATE TABLE `mp_proxy_key` (
  `rid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `proxy_key` varchar(100) NOT NULL,
  `mdate` datetime DEFAULT NULL,
  `type` int(1) NOT NULL,
  PRIMARY KEY (`rid`,`proxy_key`),
  UNIQUE KEY `type_idx` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_proxy_logs`
-- ----------------------------
DROP TABLE IF EXISTS `mp_proxy_logs`;
CREATE TABLE `mp_proxy_logs` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `log_type` int(11) NOT NULL DEFAULT '0',
  `log_data` longtext,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `log_type_idx` (`log_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `proxy_log_date` BEFORE INSERT ON `mp_proxy_logs` FOR EACH ROW Set new.mdate = now();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_selfupdate_filters`
-- ----------------------------
DROP TABLE IF EXISTS `mp_selfupdate_filters`;
CREATE TABLE `mp_selfupdate_filters` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `attribute` varchar(255) NOT NULL,
  `attribute_oper` varchar(10) NOT NULL,
  `attribute_filter` varchar(255) NOT NULL,
  `attribute_condition` varchar(10) NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_server_list`
-- ----------------------------
DROP TABLE IF EXISTS `mp_server_list`;
CREATE TABLE `mp_server_list` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `listid` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `version` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`,`listid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_servers`
-- ----------------------------
DROP TABLE IF EXISTS `mp_servers`;
CREATE TABLE `mp_servers` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `listid` varchar(50) NOT NULL,
  `server` varchar(255) NOT NULL,
  `port` int(10) NOT NULL DEFAULT '2600',
  `useSSL` int(1) NOT NULL DEFAULT '1',
  `useSSLAuth` int(1) NOT NULL DEFAULT '0',
  `isMaster` int(1) NOT NULL DEFAULT '0',
  `isProxy` int(1) NOT NULL DEFAULT '0',
  `active` int(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_servers_old`
-- ----------------------------
DROP TABLE IF EXISTS `mp_servers_old`;
CREATE TABLE `mp_servers_old` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `server` varchar(255) NOT NULL,
  `server_port` int(6) unsigned NOT NULL DEFAULT '2601',
  `type` int(1) NOT NULL DEFAULT '1',
  `type_order` int(2) NOT NULL DEFAULT '0',
  `active` int(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_software`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software`;
CREATE TABLE `mp_software` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `suuid` varchar(50) NOT NULL,
  `patch_bundle_id` varchar(100) DEFAULT NULL,
  `auto_patch` int(1) NOT NULL DEFAULT '0',
  `sState` int(1) DEFAULT '0',
  `sName` varchar(255) NOT NULL,
  `sVendor` varchar(255) DEFAULT NULL,
  `sVersion` varchar(40) NOT NULL,
  `sDescription` varchar(255) DEFAULT NULL,
  `sVendorURL` varchar(255) DEFAULT NULL,
  `sReboot` int(11) DEFAULT '0',
  `sw_type` varchar(10) DEFAULT NULL,
  `sw_path` varchar(255) DEFAULT NULL,
  `sw_url` varchar(255) DEFAULT NULL,
  `sw_size` int(11) unsigned DEFAULT '0',
  `sw_hash` varchar(50) DEFAULT NULL,
  `sw_pre_install_script` longtext,
  `sw_post_install_script` longtext,
  `sw_uninstall_script` longtext,
  `sw_env_var` varchar(255) DEFAULT NULL,
  `cdate` datetime DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`,`suuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mps_trg_insrt1` BEFORE INSERT ON `mp_software` FOR EACH ROW SET NEW.cdate = NOW(), NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mps_trg_updt1` BEFORE UPDATE ON `mp_software` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_software_criteria`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_criteria`;
CREATE TABLE `mp_software_criteria` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `suuid` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `type_data` text NOT NULL,
  `type_order` int(2) NOT NULL,
  `type_required_order` int(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`rid`,`suuid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `puuid_idx` (`suuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_software_group_tasks`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_group_tasks`;
CREATE TABLE `mp_software_group_tasks` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `sw_group_id` varchar(50) NOT NULL,
  `sw_task_id` varchar(50) NOT NULL,
  `selected` int(11) DEFAULT '0',
  PRIMARY KEY (`rid`),
  KEY `sw_task_idx` (`sw_task_id`),
  KEY `sw_grp_idx` (`sw_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_software_groups`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_groups`;
CREATE TABLE `mp_software_groups` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `gid` varchar(50) NOT NULL,
  `gName` varchar(255) NOT NULL,
  `gDescription` varchar(255) DEFAULT NULL,
  `gType` int(1) NOT NULL DEFAULT '0',
  `gHash` varchar(50) DEFAULT '0',
  `state` int(1) unsigned DEFAULT '1',
  `cdate` datetime DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`,`gid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `msg_insrt_trg1` BEFORE INSERT ON `mp_software_groups` FOR EACH ROW SET NEW.cdate = NOW(), NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `msg_updt_trg1` BEFORE UPDATE ON `mp_software_groups` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_software_groups_privs`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_groups_privs`;
CREATE TABLE `mp_software_groups_privs` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `gid` varchar(50) NOT NULL,
  `uid` varchar(255) NOT NULL,
  `isOwner` int(1) DEFAULT '0',
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_software_installs`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_installs`;
CREATE TABLE `mp_software_installs` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL DEFAULT '',
  `tuuid` varchar(50) DEFAULT NULL,
  `suuid` varchar(50) DEFAULT NULL,
  `action` varchar(1) DEFAULT 'i',
  `result` int(10) DEFAULT NULL,
  `resultString` text,
  `cdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`,`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `swdist_install_cdate` BEFORE INSERT ON `mp_software_installs` FOR EACH ROW SET NEW.cdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_software_requisits`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_requisits`;
CREATE TABLE `mp_software_requisits` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `suuid` varchar(50) DEFAULT NULL,
  `type` int(1) DEFAULT '0',
  `type_txt` varchar(255) DEFAULT NULL,
  `type_order` int(2) DEFAULT '0',
  `suuid_ref` varchar(50) NOT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mp_software_task`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_task`;
CREATE TABLE `mp_software_task` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tuuid` varchar(50) NOT NULL,
  `name` varchar(255) NOT NULL,
  `primary_suuid` varchar(50) DEFAULT NULL,
  `active` int(1) DEFAULT '0',
  `sw_task_type` varchar(2) DEFAULT 'o' COMMENT 'Task Type -  \nOptional = o, \nOptional - Mandatory = om\nMandatory = m',
  `sw_task_privs` varchar(255) DEFAULT 'Global' COMMENT 'Global, Group = Name',
  `sw_start_datetime` datetime DEFAULT NULL,
  `sw_end_datetime` datetime DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  `cdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mpst_trg_insrt1` BEFORE INSERT ON `mp_software_task` FOR EACH ROW SET NEW.cdate = NOW(), NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mpst_trg_updt1` BEFORE UPDATE ON `mp_software_task` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mp_software_tasks_data`
-- ----------------------------
DROP TABLE IF EXISTS `mp_software_tasks_data`;
CREATE TABLE `mp_software_tasks_data` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `gid` varchar(50) NOT NULL,
  `gDataHash` varchar(50) NOT NULL,
  `gData` longtext NOT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `idx_task_data` (`gid`,`gDataHash`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `mdate_insrt_trg` BEFORE INSERT ON `mp_software_tasks_data` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;
delimiter ;;
CREATE TRIGGER `mdate_updt_trg` BEFORE UPDATE ON `mp_software_tasks_data` FOR EACH ROW SET NEW.mdate = NOW();
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mpi_AppUsage`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_AppUsage`;
CREATE TABLE `mpi_AppUsage` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_app_version` varchar(255) NULL,
  `mpa_app_name` varchar(255) NULL,
  `mpa_last_launched` varchar(255) NULL,
  `mpa_times_launched` varchar(255) NULL,
  `mpa_app_path` varchar(255) NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_ClientTasks`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_ClientTasks`;
CREATE TABLE `mpi_ClientTasks` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_id` varchar(255) NULL,
  `mpa_description` varchar(255) NULL,
  `mpa_startdate` varchar(255) NULL,
  `mpa_enddate` varchar(255) NULL,
  `mpa_active` varchar(255) NULL,
  `mpa_interval` varchar(255) NULL,
  `mpa_idrev` varchar(255) NULL,
  `mpa_parent` varchar(255) NULL,
  `mpa_scope` varchar(255) NULL,
  `mpa_cmdalt` varchar(255) NULL,
  `mpa_mode` varchar(255) NULL,
  `mpa_idsig` varchar(255) NULL,
  `mpa_cmd` varchar(255) NULL,
  `mpa_name` varchar(255) NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_DirectoryServices`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_DirectoryServices`;
CREATE TABLE `mpi_DirectoryServices` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_cn` varchar(255) NULL,
  `mpa_AD_Kerberos_ID` varchar(255) NULL,
  `mpa_HasSLAM` varchar(255) NULL,
  `mpa_distinguishedName` varchar(255) NULL,
  `mpa_AD_Computer_ID` varchar(255) NULL,
  `mpa_DNSName` varchar(255) NULL,
  `mpa_Bound_To_Domain` varchar(255) NULL,
  `mpa_ADDomain` varchar(255) NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_DiskInfo`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_DiskInfo`;
CREATE TABLE `mpi_DiskInfo` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_MediaName` varchar(255) NULL,
  `mpa_MediaUUID` varchar(255) NULL,
  `mpa_VolumePath` varchar(255) NULL,
  `mpa_MediaSize` varchar(255) NULL,
  `mpa_MediaWritable` varchar(255) NULL,
  `mpa_DeviceModel` varchar(255) NULL,
  `mpa_MediaRemovable` varchar(255) NULL,
  `mpa_DeviceRevision` varchar(255) NULL,
  `mpa_VolumeMountable` varchar(255) NULL,
  `mpa_MediaEjectable` varchar(255) NULL,
  `mpa_MediaPath` varchar(255) NULL,
  `mpa_MediaBSDName` varchar(255) NULL,
  `mpa_DeviceInternal` varchar(255) NULL,
  `mpa_MediaFreeSpace` varchar(255) NULL,
  `mpa_DeviceProtocol` varchar(255) NULL,
  `mpa_MediaBlockSize` varchar(255) NULL,
  `mpa_VolumeKind` varchar(255) NULL,
  `mpa_UNIXPath` varchar(255) NULL,
  `mpa_VolumeUUID` varchar(255) NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_Groups`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_Groups`;
CREATE TABLE `mpi_Groups` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_FullName` varchar(255) NULL,
  `mpa_GroupMembership` varchar(255) NULL,
  `mpa_GroupName` varchar(255) NULL,
  `mpa_GroupID` varchar(255) NULL,
  `mpa_RecordType` varchar(255) NULL,
  `mpa_GroupMembers` varchar(255) NULL,
  `mpa_MetaNodeLocation` varchar(255) NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_InternetPlugins`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_InternetPlugins`;
CREATE TABLE `mpi_InternetPlugins` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_BundleIdentifier` varchar(255) NULL,
  `mpa_path_real` varchar(255) NULL,
  `mpa_WebPluginName` varchar(255) NULL,
  `mpa_path` varchar(255) NULL,
  `mpa_version` varchar(255) NULL,
  `mpa_name` varchar(255) NULL,
  `mpa_lastModified` varchar(255) NULL,
  PRIMARY KEY (`rid`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_SPApplications`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_SPApplications`;
CREATE TABLE `mpi_SPApplications` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_Name` varchar(255) NULL,
  `mpa_Version` varchar(255) NULL,
  `mpa_Last_Modified` varchar(255) NULL,
  `mpa_Kind` varchar(255) NULL,
  `mpa_Get_Info_String` varchar(255) NULL,
  `mpa_Location` varchar(255) NULL,
  `cdateInt` bigint(20) unsigned DEFAULT '0',
  `dateInt` int(11) DEFAULT '0',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_rid` (`rid`),
  KEY `idx_cuuid` (`cuuid`),
  KEY `idx_date` (`date`),
  KEY `idx_cdateInt` (`cdateInt`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
delimiter ;;
CREATE TRIGGER `dateInt_trig` BEFORE INSERT ON `mpi_SPApplications` FOR EACH ROW BEGIN
IF NEW.date = NEW.date THEN
SET NEW.cdateInt = DATE_FORMAT(NEW.date,'%Y%m%d%H%i%s');
END IF;
END;
 ;;
delimiter ;

-- ----------------------------
--  Table structure for `mpi_SPFrameworks`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_SPFrameworks`;
CREATE TABLE `mpi_SPFrameworks` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_has64BitIntelCode` varchar(255) NULL,
  `mpa_Version` varchar(255) NULL,
  `mpa_Kind` varchar(255) NULL,
  `mpa_Location` varchar(255) NULL,
  `mpa_Name` varchar(255) NULL,
  `mpa_Private_Framework` varchar(255) NULL,
  `mpa_lastModified` varchar(255) NULL,
  PRIMARY KEY (`rid`),
  KEY `cuuid_idx` (`cuuid`),
  KEY `idx_all` (`cuuid`,`mpa_Name`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_SPHardwareOverview`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_SPHardwareOverview`;
CREATE TABLE `mpi_SPHardwareOverview` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime DEFAULT '0000-00-00 00:00:00',
  `mpa_Model_Name` varchar(255) DEFAULT NULL,
  `mpa_Model_Identifier` varchar(255) DEFAULT NULL,
  `mpa_Processor_Name` varchar(255) DEFAULT NULL,
  `mpa_Processor_Speed` varchar(255) DEFAULT NULL,
  `mpa_Number_of_Processors` varchar(255) DEFAULT NULL,
  `mpa_Total_Number_of_Cores` varchar(255) DEFAULT NULL,
  `mpa_L2_Cache` varchar(255) DEFAULT NULL,
  `mpa_Memory` varchar(255) DEFAULT NULL,
  `mpa_Bus_Speed` varchar(255) NULL,
  `mpa_Boot_ROM_Version` varchar(255) NULL,
  `mpa_SMC_Version` varchar(255) NULL,
  `mpa_Serial_Number` varchar(255) NULL,
  `mpa_Hardware_UUID` varchar(255) NULL,
  `mpa_Sudden_Motion_Sensor` varchar(255) NULL,
  `mpa_State` varchar(255) NULL,
  `mpa_L3_Cache` varchar(255) NULL,
  `mpa_Processor_Interconnect_Speed` varchar(255) NULL,
  `mpa_SMC_Version_(processor_tray)` varchar(255) NULL,
  `mpa_Serial_Number_(processor_tray)` varchar(255) NULL,
  `mpa_Sales_Order_Number` varchar(255) DEFAULT NULL,
  `mpa_Version` varchar(255) DEFAULT NULL,
  `mpa_L3_Cache_(per_Processor)` varchar(255) NULL,
  `mpa_LOM_Revision` varchar(255) DEFAULT NULL,
  `mpa_Machine_Name` varchar(255) DEFAULT NULL,
  `mpa_Machine_Model` varchar(255) DEFAULT NULL,
  `mpa_CPU_Type` varchar(255) DEFAULT NULL,
  `mpa_CPU_Speed` varchar(255) DEFAULT NULL,
  `mpa_L3_Cache_(per_CPU)` varchar(255) DEFAULT NULL,
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_L3_Cache_per_Processor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_cuuid` (`cuuid`),
  KEY `idx_find` (`rid`,`cuuid`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_SPNetwork`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_SPNetwork`;
CREATE TABLE `mpi_SPNetwork` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_Name` varchar(255) NULL,
  `mpa_Type` varchar(255) NULL,
  `mpa_Hardware` varchar(255) NULL,
  `mpa_BSD_Device_Name` varchar(255) NULL,
  `mpa_Has_IP_Assigned` varchar(255) NULL,
  `mpa_IPv4_Addresses` varchar(255) NULL,
  `mpa_IPv4_Configuration_Method` varchar(255) NULL,
  `mpa_IPv4_Interface_Name` varchar(255) NULL,
  `mpa_IPv4_NetworkSignature` varchar(255) NULL,
  `mpa_IPv4_Router` varchar(255) NULL,
  `mpa_IPv4_Subnet_Masks` varchar(255) NULL,
  `mpa_AppleTalk_Configuration_Method` varchar(255) NULL,
  `mpa_AppleTalk_Default_Zone` varchar(255) NULL,
  `mpa_AppleTalk_Interface_Name` varchar(255) NULL,
  `mpa_AppleTalk_Network_ID` varchar(255) NULL,
  `mpa_AppleTalk_Node_ID` varchar(255) NULL,
  `mpa_DNS_Search_Domains` varchar(255) NULL,
  `mpa_DNS_Server_Addresses` varchar(255) NULL,
  `mpa_Proxies_Exceptions_List` varchar(255) NULL,
  `mpa_Proxies_FTP_Passive_Mode` varchar(255) NULL,
  `mpa_Proxies_HTTP_Proxy_Enabled` varchar(255) NULL,
  `mpa_Proxies_HTTP_Proxy_Port` varchar(255) NULL,
  `mpa_Proxies_HTTP_Proxy_Server` varchar(255) NULL,
  `mpa_Ethernet_MAC_Address` varchar(255) NULL,
  `mpa_Ethernet_Media_Options` varchar(255) NULL,
  `mpa_Ethernet_Media_Subtype` varchar(255) NULL,
  `mpa_IPv4_Network_Signature` varchar(255) NULL,
  `mpa_Configuration_Method` varchar(255) NULL,
  `mpa_Proxies_Service_Order` varchar(255) NULL,
  `mpa_Proxies_FTP_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Gopher_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Proxies_HTTPS_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Proxies_RTSP_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Proxies_SOCKS_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Ethernet_Hardware_Type` varchar(255) DEFAULT NULL,
  `mpa_DNS_Domain_Name` varchar(255) NULL,
  `mpa_Domain_Name` varchar(255) DEFAULT NULL,
  `mpa_Domain_Name_Servers` varchar(255) DEFAULT NULL,
  `mpa_Lease_Duration_(seconds)` varchar(255) DEFAULT NULL,
  `mpa_DHCP_Message_Type` varchar(255) DEFAULT NULL,
  `mpa_Routers` varchar(255) DEFAULT NULL,
  `mpa_Server_Identifier` varchar(255) DEFAULT NULL,
  `mpa_Subnet_Mask` varchar(255) DEFAULT NULL,
  `mpa_Media_Subtype` varchar(255) NULL,
  `mpa_AppleTalk_Network_Range` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Proxy_Configuration_Method` varchar(255) DEFAULT NULL,
  `mpa_Proxies_ExcludeSimpleHostnames` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Auto_Discovery_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Exclude_Simple_Hostnames` varchar(255) DEFAULT NULL,
  `mpa_AppleTalk_Node` varchar(255) DEFAULT NULL,
  `mpa_Proxies_FTP_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_Proxies_FTP_Proxy_Server` varchar(255) DEFAULT NULL,
  `mpa_IPv4_DHCP_Client_ID` varchar(255) DEFAULT NULL,
  `mpa_IPv4_Hostname` varchar(255) DEFAULT NULL,
  `mpa_Addresses` varchar(255) DEFAULT NULL,
  `mpa_Prefix_Length` varchar(255) DEFAULT NULL,
  `mpa_Proxies_HTTPS_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_Proxies_HTTPS_Proxy_Server` varchar(255) DEFAULT NULL,
  `mpa_Proxies_SOCKS_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_Proxies_SOCKS_Proxy_Server` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Auto_Configure_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Auto_Configure_URL` varchar(255) DEFAULT NULL,
  `mpa_IPv4_Destination_Addresses` varchar(255) DEFAULT NULL,
  `mpa_Supplemental_Match_Orders` varchar(255) DEFAULT NULL,
  `mpa_FTP_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_FTP_Passive_Mode` varchar(255) DEFAULT NULL,
  `mpa_FTP_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_Gopher_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_Gopher_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_HTTP_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_HTTP_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_HTTPS_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_HTTPS_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_RTSP_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_RTSP_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_SOCKS_Proxy_Enabled` varchar(255) DEFAULT NULL,
  `mpa_SOCKS_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_Option_Overload` varchar(255) DEFAULT NULL,
  `mpa_Marginal_Power` varchar(255) DEFAULT NULL,
  `mpa_Metric` varchar(255) DEFAULT NULL,
  `mpa_Portability` varchar(255) DEFAULT NULL,
  `mpa_Total_Power` varchar(255) DEFAULT NULL,
  `mpa_Service_Order` varchar(255) DEFAULT NULL,
  `mpa_Server_Addresses` varchar(255) DEFAULT NULL,
  `mpa_Ethernet_Service_Order` varchar(255) DEFAULT NULL,
  `mpa_Hardware_Type` varchar(255) DEFAULT NULL,
  `mpa_Flags` varchar(255) DEFAULT NULL,
  `mpa_Interface_Name` varchar(255) DEFAULT NULL,
  `mpa_Router` varchar(255) DEFAULT NULL,
  `mpa_ipv6_address` varchar(255) DEFAULT NULL,
  `mpa_DNS_Supplemental_Match_Domains` varchar(255) DEFAULT NULL,
  `mpa_DNS_SupplementalMatchOrder` varchar(255) DEFAULT NULL,
  `mpa_Proxies_IPv6_Address` varchar(255) DEFAULT NULL,
  `mpa_Ethernet_ipv6_address` varchar(255) DEFAULT NULL,
  `dateInt` int(11) DEFAULT '0',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_DHCP_Routers` varchar(255) NULL,
  `mpa_DHCP_Domain_Name_Servers` varchar(255) NULL,
  `mpa_DHCP_Lease_Duration_seconds` varchar(255) NULL,
  `mpa_DHCP_Domain_Name` varchar(255) NULL,
  `mpa_DHCP_Server_Identifier` varchar(255) NULL,
  `mpa_DHCP_DHCP_Message_Type` varchar(255) NULL,
  `mpa_DHCP_Subnet_Mask` varchar(255) NULL,
  `mpa_Subnet_Masks` varchar(255) DEFAULT NULL,
  `mpa_IPv4_ServerAddress` varchar(255) DEFAULT NULL,
  `mpa_IPv4_OverridePrimary` varchar(255) DEFAULT NULL,
  `mpa_Proxies_ExceptionList` varchar(255) DEFAULT NULL,
  `mpa_Network_Signature` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Gopher_Proxy_Port` varchar(255) DEFAULT NULL,
  `mpa_Proxies_Gopher_Proxy_Server` varchar(255) DEFAULT NULL,
  `mpa_IPv4_ARPResolvedIPAddress` varchar(255) NULL,
  `mpa_IPv4_ARPResolvedHardwareAddress` varchar(255) NULL,
  `mpa_DHCP_Service_Order` varchar(255) DEFAULT NULL,
  `mpa_Proxies_BSD_Device_Name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_SPSystemOverview`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_SPSystemOverview`;
CREATE TABLE `mpi_SPSystemOverview` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_Name` varchar(255) NULL,
  `mpa_System_Version` varchar(255) NULL,
  `mpa_Kernel_Version` varchar(255) NULL,
  `mpa_Boot_Volume` varchar(255) NULL,
  `mpa_Boot_Mode` varchar(255) NULL,
  `mpa_Computer_Name` varchar(255) NULL,
  `mpa_User_Name` varchar(255) NULL,
  `mpa_Time_since_boot` varchar(255) NULL,
  `mpa_Secure_Virtual_Memory` varchar(255) NULL,
  `mpa_64-bit_Kernel_and_Extensions` varchar(255) NULL,
  `mpa_Server_Configuration` varchar(255) DEFAULT NULL,
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `mpi_Users`
-- ----------------------------
DROP TABLE IF EXISTS `mpi_Users`;
CREATE TABLE `mpi_Users` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL,
  `date` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mdate` datetime NULL DEFAULT '0000-00-00 00:00:00',
  `mpa_FullName` varchar(255) NULL,
  `mpa_OriginalNodeName` varchar(255) NULL,
  `mpa_UserID` varchar(255) NULL,
  `mpa_AuthenticationAuthority` varchar(255) NULL,
  `mpa_HomeDir` varchar(255) NULL,
  `mpa_UserShell` varchar(255) NULL,
  `mpa_UserName` varchar(255) NULL,
  `mpa_RecordType` varchar(255) NULL,
  `mpa_GroupID` varchar(255) NULL,
  `mpa_MetaNodeLocation` varchar(255) NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `profiles`
-- ----------------------------
DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
  `rid` int(10) NOT NULL AUTO_INCREMENT,
  `oid` varchar(50) DEFAULT NULL,
  `clientgroups` varchar(1000) DEFAULT NULL,
  `recordcount` int(10) DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `savav_defs`
-- ----------------------------
DROP TABLE IF EXISTS `savav_defs`;
CREATE TABLE `savav_defs` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `arch` varchar(3) NOT NULL,
  `current` varchar(3) NOT NULL,
  `defdate` varchar(8) NOT NULL,
  `file` varchar(255) NOT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `savav_info`
-- ----------------------------
DROP TABLE IF EXISTS `savav_info`;
CREATE TABLE `savav_info` (
  `rid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cuuid` varchar(50) NOT NULL DEFAULT '',
  `defsDate` varchar(25) DEFAULT NULL,
  `savShortVersion` varchar(25) DEFAULT NULL,
  `appPath` varchar(255) DEFAULT NULL,
  `lastFullScan` varchar(25) DEFAULT NULL,
  `savBundleVersion` varchar(25) DEFAULT NULL,
  `savAppName` varchar(50) DEFAULT NULL,
  `mdate` datetime DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `idx_rid` (`rid`),
  KEY `idx_cuuid` (`cuuid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `ws_log`
--  Depricated in 2.2.x
-- ----------------------------
DROP TABLE IF EXISTS `ws_log`;
CREATE TABLE `ws_log` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdate` datetime DEFAULT NULL,
  `event_type` varchar(25) NOT NULL,
  `event` mediumtext NOT NULL,
  `host` varchar(255) NOT NULL,
  `scriptName` varchar(100) DEFAULT NULL,
  `pathInfo` varchar(255) DEFAULT NULL,
  `serverName` varchar(100) DEFAULT NULL,
  `serverType` varchar(100) DEFAULT NULL,
  `serverHost` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `ws_idx` (`event_type`,`cdate`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `ws_adm_logs`
-- ----------------------------
DROP TABLE IF EXISTS `ws_adm_logs`;
CREATE TABLE `ws_adm_logs` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdate` datetime DEFAULT NULL,
  `event_type` varchar(25) NOT NULL,
  `event` mediumtext NOT NULL,
  `host` varchar(255) NOT NULL,
  `scriptName` varchar(100) DEFAULT NULL,
  `pathInfo` varchar(255) DEFAULT NULL,
  `serverName` varchar(100) DEFAULT NULL,
  `serverType` varchar(100) DEFAULT NULL,
  `serverHost` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `ws_idx` (`event_type`,`cdate`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `ws_clt_logs`
-- ----------------------------
DROP TABLE IF EXISTS `ws_clt_logs`;
CREATE TABLE `ws_clt_logs` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdate` datetime DEFAULT NULL,
  `event_type` varchar(25) NOT NULL,
  `event` mediumtext NOT NULL,
  `host` varchar(255) NOT NULL,
  `scriptName` varchar(100) DEFAULT NULL,
  `pathInfo` varchar(255) DEFAULT NULL,
  `serverName` varchar(100) DEFAULT NULL,
  `serverType` varchar(100) DEFAULT NULL,
  `serverHost` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `ws_idx` (`event_type`,`cdate`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `ws_srv_logs`
-- ----------------------------
DROP TABLE IF EXISTS `ws_log`;
CREATE TABLE `ws_srv_logs` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdate` datetime DEFAULT NULL,
  `event_type` varchar(25) NOT NULL,
  `event` mediumtext NOT NULL,
  `host` varchar(255) NOT NULL,
  `scriptName` varchar(100) DEFAULT NULL,
  `pathInfo` varchar(255) DEFAULT NULL,
  `serverName` varchar(100) DEFAULT NULL,
  `serverType` varchar(100) DEFAULT NULL,
  `serverHost` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `ws_idx` (`event_type`,`cdate`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `ws_log_jobs`
-- ----------------------------
DROP TABLE IF EXISTS `ws_log_jobs`;
CREATE TABLE `ws_log_jobs` (
  `rid` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdate` datetime DEFAULT NULL,
  `event_type` varchar(25) NOT NULL,
  `event` mediumtext NOT NULL,
  `host` varchar(255) NOT NULL,
  `scriptName` varchar(100) DEFAULT NULL,
  `pathInfo` varchar(255) DEFAULT NULL,
  `serverName` varchar(100) DEFAULT NULL,
  `serverType` varchar(100) DEFAULT NULL,
  `serverHost` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`rid`),
  UNIQUE KEY `rid_idx` (`rid`),
  KEY `ws_idx` (`event_type`,`cdate`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;

SET FOREIGN_KEY_CHECKS = 1;
