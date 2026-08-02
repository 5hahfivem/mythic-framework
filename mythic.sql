-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               10.8.3-MariaDB - mariadb.org binary distribution
-- Server OS:                    Win64
-- HeidiSQL Version:             11.3.0.6295
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for mythicrp
CREATE DATABASE IF NOT EXISTS `mythicrp` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `mythicrp`;

-- Dumping structure for table mythicrp.bans
DROP TABLE IF EXISTS `bans`;
CREATE TABLE IF NOT EXISTS `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` int(11) DEFAULT NULL,
  `identifier` varchar(64) DEFAULT NULL,
  `tokens` longtext DEFAULT NULL,
  `reason` varchar(512) NOT NULL DEFAULT '',
  `issuer` varchar(64) NOT NULL DEFAULT '',
  `started` bigint(20) NOT NULL DEFAULT 0,
  `expires` bigint(20) NOT NULL DEFAULT -1,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `unbanned` longtext DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `account` (`account`) USING BTREE,
  KEY `identifier` (`identifier`) USING BTREE,
  KEY `active` (`active`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.bank_accounts
DROP TABLE IF EXISTS `bank_accounts`;
CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Account` int(11) NOT NULL,
  `Type` varchar(64) NOT NULL DEFAULT '',
  `Owner` varchar(64) DEFAULT NULL,
  `Name` varchar(128) NOT NULL DEFAULT '',
  `Balance` bigint(20) NOT NULL DEFAULT 0,
  `account` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `Account` (`Account`) USING BTREE,
  KEY `owner` (`Type`, `Owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.bank_accounts_transactions
DROP TABLE IF EXISTS `bank_accounts_transactions`;
CREATE TABLE IF NOT EXISTS `bank_accounts_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Account` int(11) NOT NULL,
  `Timestamp` bigint(20) NOT NULL DEFAULT 0,
  `transaction` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `Account` (`Account`) USING BTREE,
  KEY `Timestamp` (`Timestamp`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.billboards
DROP TABLE IF EXISTS `billboards`;
CREATE TABLE IF NOT EXISTS `billboards` (
  `billboardId` varchar(64) NOT NULL,
  `billboardUrl` varchar(512) NOT NULL,
  PRIMARY KEY (`billboardId`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.business_tvs
DROP TABLE IF EXISTS `business_tvs`;
CREATE TABLE IF NOT EXISTS `business_tvs` (
  `tv` varchar(64) NOT NULL,
  `link` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`tv`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.business_documents
DROP TABLE IF EXISTS `business_documents`;
CREATE TABLE IF NOT EXISTS `business_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(64) NOT NULL,
  `title` varchar(255) NOT NULL DEFAULT '',
  `authorName` varchar(128) DEFAULT NULL,
  `document` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `job` (`job`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.business_notices
DROP TABLE IF EXISTS `business_notices`;
CREATE TABLE IF NOT EXISTS `business_notices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(64) NOT NULL,
  `notice` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `job` (`job`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.business_receipts
DROP TABLE IF EXISTS `business_receipts`;
CREATE TABLE IF NOT EXISTS `business_receipts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(64) NOT NULL,
  `customerName` varchar(255) NOT NULL DEFAULT '',
  `authorName` varchar(128) DEFAULT NULL,
  `receipt` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `job` (`job`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.casino_bigwins
DROP TABLE IF EXISTS `casino_bigwins`;
CREATE TABLE IF NOT EXISTS `casino_bigwins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(64) NOT NULL,
  `Time` bigint(20) NOT NULL,
  `Winner` longtext NOT NULL,
  `Prize` varchar(255) NOT NULL,
  `MetaData` longtext DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.casino_config
DROP TABLE IF EXISTS `casino_config`;
CREATE TABLE IF NOT EXISTS `casino_config` (
  `key` varchar(64) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`key`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.casino_statistics
DROP TABLE IF EXISTS `casino_statistics`;
CREATE TABLE IF NOT EXISTS `casino_statistics` (
  `SID` int(11) NOT NULL,
  `stats` longtext NOT NULL,
  PRIMARY KEY (`SID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.character_convictions
DROP TABLE IF EXISTS `character_convictions`;
CREATE TABLE IF NOT EXISTS `character_convictions` (
  `SID` int(11) NOT NULL,
  `convictions` longtext NOT NULL,
  PRIMARY KEY (`SID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.character_convictions_expunged
DROP TABLE IF EXISTS `character_convictions_expunged`;
CREATE TABLE IF NOT EXISTS `character_convictions_expunged` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `SID` int(11) NOT NULL,
  `convictions` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `SID` (`SID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.character_documents
DROP TABLE IF EXISTS `character_documents`;
CREATE TABLE IF NOT EXISTS `character_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` int(11) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `document` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `owner` (`owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.character_emails
DROP TABLE IF EXISTS `character_emails`;
CREATE TABLE IF NOT EXISTS `character_emails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` int(11) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `unread` tinyint(1) NOT NULL DEFAULT 1,
  `expires` bigint(20) NOT NULL DEFAULT 0,
  `email` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `owner` (`owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.characters
DROP TABLE IF EXISTS `characters`;
CREATE TABLE IF NOT EXISTS `characters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `User` bigint(20) NOT NULL,
  `SID` int(11) NOT NULL,
  `First` varchar(64) NOT NULL DEFAULT '',
  `Last` varchar(64) NOT NULL DEFAULT '',
  `Phone` varchar(16) DEFAULT NULL,
  `Deleted` tinyint(1) NOT NULL DEFAULT 0,
  `LastPlayed` bigint(20) NOT NULL DEFAULT -1,
  `character` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `SID` (`SID`) USING BTREE,
  KEY `User` (`User`) USING BTREE,
  KEY `Phone` (`Phone`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.changelogs
DROP TABLE IF EXISTS `changelogs`;
CREATE TABLE IF NOT EXISTS `changelogs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` bigint(20) NOT NULL DEFAULT 0,
  `changelog` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `date` (`date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.crafting_cooldowns
DROP TABLE IF EXISTS `crafting_cooldowns`;
CREATE TABLE IF NOT EXISTS `crafting_cooldowns` (
  `bench` varchar(64) NOT NULL,
  `id` varchar(64) NOT NULL,
  `expires` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.dealer_data
DROP TABLE IF EXISTS `dealer_data`;
CREATE TABLE IF NOT EXISTS `dealer_data` (
  `dealership` varchar(64) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`dealership`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.dealer_records
DROP TABLE IF EXISTS `dealer_records`;
CREATE TABLE IF NOT EXISTS `dealer_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(64) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `category` varchar(64) DEFAULT NULL,
  `sellerName` varchar(128) DEFAULT NULL,
  `buyerName` varchar(128) DEFAULT NULL,
  `vehicleName` varchar(128) DEFAULT NULL,
  `record` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `dealership` (`dealership`) USING BTREE,
  KEY `time` (`time`) USING BTREE,
  KEY `category` (`category`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.dealer_records_buybacks
DROP TABLE IF EXISTS `dealer_records_buybacks`;
CREATE TABLE IF NOT EXISTS `dealer_records_buybacks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(64) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `record` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `dealership` (`dealership`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.dealer_showrooms
DROP TABLE IF EXISTS `dealer_showrooms`;
CREATE TABLE IF NOT EXISTS `dealer_showrooms` (
  `dealership` varchar(64) NOT NULL,
  `showroom` longtext NOT NULL,
  PRIMARY KEY (`dealership`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.dealer_stock
DROP TABLE IF EXISTS `dealer_stock`;
CREATE TABLE IF NOT EXISTS `dealer_stock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealership` varchar(64) NOT NULL,
  `vehicle` varchar(64) NOT NULL,
  `modelType` varchar(64) DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `lastStocked` bigint(20) NOT NULL DEFAULT 0,
  `lastPurchase` bigint(20) NOT NULL DEFAULT 0,
  `default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `dealership_vehicle` (`dealership`, `vehicle`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.defaults
DROP TABLE IF EXISTS `defaults`;
CREATE TABLE IF NOT EXISTS `defaults` (
  `collection` varchar(64) NOT NULL,
  `date` bigint(20) NOT NULL,
  PRIMARY KEY (`collection`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.entitytypes
DROP TABLE IF EXISTS `entitytypes`;
CREATE TABLE IF NOT EXISTS `entitytypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.firearms
DROP TABLE IF EXISTS `firearms`;
CREATE TABLE IF NOT EXISTS `firearms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Serial` varchar(64) NOT NULL,
  `Item` varchar(64) NOT NULL DEFAULT '',
  `Scratched` tinyint(1) NOT NULL DEFAULT 0,
  `FiledByPolice` tinyint(1) NOT NULL DEFAULT 0,
  `PoliceWeaponId` varchar(64) DEFAULT NULL,
  `ownerSID` int(11) DEFAULT NULL,
  `ownerName` varchar(128) DEFAULT NULL,
  `firearm` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `Serial` (`Serial`) USING BTREE,
  KEY `ownerSID` (`ownerSID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.firearms_projectiles
DROP TABLE IF EXISTS `firearms_projectiles`;
CREATE TABLE IF NOT EXISTS `firearms_projectiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Id` varchar(64) NOT NULL,
  `WeaponSerial` varchar(64) DEFAULT NULL,
  `projectile` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `EvidenceId` (`Id`) USING BTREE,
  KEY `WeaponSerial` (`WeaponSerial`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.inventory
DROP TABLE IF EXISTS `inventory`;
CREATE TABLE IF NOT EXISTS `inventory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb3 NOT NULL DEFAULT '0',
  `slot` int(11) DEFAULT NULL,
  `item_id` varchar(255) CHARACTER SET utf8mb3 DEFAULT NULL,
  `quality` int(11) DEFAULT NULL,
  `information` varchar(1024) CHARACTER SET utf8mb3 NOT NULL DEFAULT '0',
  `dropped` tinyint(4) NOT NULL DEFAULT 0,
  `creationDate` bigint(20) NOT NULL DEFAULT 0,
  `expiryDate` bigint(20) NOT NULL DEFAULT -1,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1164831 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.inventory_shop_logs
DROP TABLE IF EXISTS `inventory_shop_logs`;
CREATE TABLE IF NOT EXISTS `inventory_shop_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `inventory` varchar(255) NOT NULL DEFAULT '0',
  `item` varchar(255) NOT NULL DEFAULT '0',
  `count` int(11) NOT NULL DEFAULT 0,
  `itemId` bigint(20) DEFAULT NULL,
  `buyer` int(11) NOT NULL DEFAULT 0,
  `metadata` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.irc_channels
DROP TABLE IF EXISTS `irc_channels`;
CREATE TABLE IF NOT EXISTS `irc_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `character` int(11) NOT NULL,
  `slug` varchar(64) NOT NULL,
  `channel` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `character` (`character`) USING BTREE,
  KEY `slug` (`slug`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.irc_messages
DROP TABLE IF EXISTS `irc_messages`;
CREATE TABLE IF NOT EXISTS `irc_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel` varchar(64) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `message` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `channel` (`channel`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.jobs
DROP TABLE IF EXISTS `jobs`;
CREATE TABLE IF NOT EXISTS `jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Id` varchar(64) NOT NULL,
  `Type` varchar(32) NOT NULL DEFAULT '',
  `Name` varchar(128) NOT NULL DEFAULT '',
  `job` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `JobId` (`Id`) USING BTREE,
  KEY `Type` (`Type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.loans
DROP TABLE IF EXISTS `loans`;
CREATE TABLE IF NOT EXISTS `loans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Creation` bigint(20) NOT NULL DEFAULT 0,
  `SID` int(11) NOT NULL,
  `Type` varchar(32) NOT NULL DEFAULT '',
  `AssetIdentifier` varchar(64) NOT NULL DEFAULT '',
  `Defaulted` tinyint(1) NOT NULL DEFAULT 0,
  `InterestRate` double NOT NULL DEFAULT 0,
  `Total` bigint(20) NOT NULL DEFAULT 0,
  `Remaining` bigint(20) NOT NULL DEFAULT 0,
  `Paid` bigint(20) NOT NULL DEFAULT 0,
  `DownPayment` bigint(20) NOT NULL DEFAULT 0,
  `TotalPayments` int(11) NOT NULL DEFAULT 0,
  `PaidPayments` int(11) NOT NULL DEFAULT 0,
  `MissablePayments` int(11) NOT NULL DEFAULT 0,
  `MissedPayments` int(11) NOT NULL DEFAULT 0,
  `TotalMissedPayments` int(11) NOT NULL DEFAULT 0,
  `NextPayment` bigint(20) NOT NULL DEFAULT 0,
  `LastPayment` bigint(20) NOT NULL DEFAULT 0,
  `LastMissedPayment` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `SID` (`SID`) USING BTREE,
  KEY `AssetIdentifier` (`AssetIdentifier`) USING BTREE,
  KEY `NextPayment` (`NextPayment`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.loans_credit_scores
DROP TABLE IF EXISTS `loans_credit_scores`;
CREATE TABLE IF NOT EXISTS `loans_credit_scores` (
  `SID` int(11) NOT NULL,
  `Score` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`SID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.locations
DROP TABLE IF EXISTS `locations`;
CREATE TABLE IF NOT EXISTS `locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(64) NOT NULL,
  `Name` varchar(64) NOT NULL,
  `Coords` varchar(255) NOT NULL,
  `Heading` double NOT NULL DEFAULT 0,
  `default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `Type` (`Type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.logs
DROP TABLE IF EXISTS `logs`;
CREATE TABLE IF NOT EXISTS `logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` bigint(20) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  `component` varchar(64) NOT NULL DEFAULT '',
  `log` longtext NOT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `date` (`date`) USING BTREE,
  KEY `component` (`component`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.mdt_charges
DROP TABLE IF EXISTS `mdt_charges`;
CREATE TABLE IF NOT EXISTS `mdt_charges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charge` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.mdt_metrics
DROP TABLE IF EXISTS `mdt_metrics`;
CREATE TABLE IF NOT EXISTS `mdt_metrics` (
  `date` varchar(32) NOT NULL,
  `metrics` longtext NOT NULL,
  PRIMARY KEY (`date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.mdt_notices
DROP TABLE IF EXISTS `mdt_notices`;
CREATE TABLE IF NOT EXISTS `mdt_notices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notice` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.mdt_reports
DROP TABLE IF EXISTS `mdt_reports`;
CREATE TABLE IF NOT EXISTS `mdt_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ID` int(11) NOT NULL,
  `type` varchar(64) DEFAULT NULL,
  `title` varchar(255) NOT NULL DEFAULT '',
  `time` bigint(20) NOT NULL DEFAULT 0,
  `authorSID` int(11) DEFAULT NULL,
  `suspectNames` varchar(512) DEFAULT NULL,
  `report` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `ReportID` (`ID`) USING BTREE,
  KEY `time` (`time`) USING BTREE,
  KEY `authorSID` (`authorSID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.mdt_tags
DROP TABLE IF EXISTS `mdt_tags`;
CREATE TABLE IF NOT EXISTS `mdt_tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.mdt_warrants
DROP TABLE IF EXISTS `mdt_warrants`;
CREATE TABLE IF NOT EXISTS `mdt_warrants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `state` varchar(32) NOT NULL DEFAULT '',
  `warrant` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `state` (`state`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.meth_tables
DROP TABLE IF EXISTS `meth_tables`;
CREATE TABLE IF NOT EXISTS `meth_tables` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tier` int(11) NOT NULL DEFAULT 1,
  `created` bigint(20) NOT NULL,
  `cooldown` bigint(20) DEFAULT NULL,
  `recipe` varchar(512) NOT NULL,
  `active_cook` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.peds
DROP TABLE IF EXISTS `peds`;
CREATE TABLE IF NOT EXISTS `peds` (
  `Char` int(11) NOT NULL,
  `Ped` longtext NOT NULL,
  PRIMARY KEY (`Char`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.phone_calls
DROP TABLE IF EXISTS `phone_calls`;
CREATE TABLE IF NOT EXISTS `phone_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(16) NOT NULL,
  `number` varchar(16) DEFAULT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `unread` tinyint(1) NOT NULL DEFAULT 0,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `decryptable` tinyint(1) NOT NULL DEFAULT 0,
  `call` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `owner` (`owner`) USING BTREE,
  KEY `time` (`time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.phone_contacts
DROP TABLE IF EXISTS `phone_contacts`;
CREATE TABLE IF NOT EXISTS `phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `character` int(11) NOT NULL,
  `number` varchar(16) NOT NULL,
  `contact` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `character` (`character`) USING BTREE,
  KEY `number` (`number`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.phone_messages
DROP TABLE IF EXISTS `phone_messages`;
CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(16) NOT NULL,
  `number` varchar(16) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `unread` tinyint(1) NOT NULL DEFAULT 1,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `message` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `owner` (`owner`) USING BTREE,
  KEY `number` (`number`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.placed_meth_tables
DROP TABLE IF EXISTS `placed_meth_tables`;
CREATE TABLE IF NOT EXISTS `placed_meth_tables` (
  `table_id` int(11) NOT NULL,
  `owner` bigint(20) DEFAULT NULL,
  `placed` bigint(20) NOT NULL DEFAULT 0,
  `expires` bigint(20) NOT NULL DEFAULT 0,
  `coords` varchar(255) NOT NULL,
  `heading` double NOT NULL DEFAULT 0,
  PRIMARY KEY (`table_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.properties
DROP TABLE IF EXISTS `properties`;
CREATE TABLE IF NOT EXISTS `properties` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(64) DEFAULT NULL,
  `label` varchar(128) NOT NULL DEFAULT '',
  `price` bigint(20) NOT NULL DEFAULT 0,
  `interior` int(11) DEFAULT NULL,
  `sold` tinyint(1) NOT NULL DEFAULT 0,
  `soldAt` bigint(20) DEFAULT NULL,
  `foreclosed` tinyint(1) NOT NULL DEFAULT 0,
  `foreclosedTime` bigint(20) NOT NULL DEFAULT 0,
  `owner` longtext DEFAULT NULL,
  `location` longtext NOT NULL,
  `upgrades` longtext DEFAULT NULL,
  `keys` longtext DEFAULT NULL,
  `data` longtext DEFAULT NULL,
  `default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `label` (`label`) USING BTREE,
  KEY `sold` (`sold`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.properties_furniture
DROP TABLE IF EXISTS `properties_furniture`;
CREATE TABLE IF NOT EXISTS `properties_furniture` (
  `property` int(11) NOT NULL,
  `furniture` longtext NOT NULL,
  `updatedTime` bigint(20) NOT NULL DEFAULT 0,
  `updatedBy` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`property`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.roles
DROP TABLE IF EXISTS `roles`;
CREATE TABLE IF NOT EXISTS `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Abv` varchar(64) NOT NULL,
  `Name` varchar(64) NOT NULL,
  `Queue` longtext DEFAULT NULL,
  `Permission` longtext DEFAULT NULL,
  `default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `Abv` (`Abv`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.schematics
DROP TABLE IF EXISTS `schematics`;
CREATE TABLE IF NOT EXISTS `schematics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bench` varchar(64) NOT NULL,
  `item` varchar(64) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `bench` (`bench`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.scenes
DROP TABLE IF EXISTS `scenes`;
CREATE TABLE IF NOT EXISTS `scenes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `staff` tinyint(1) NOT NULL DEFAULT 0,
  `route` int(11) NOT NULL DEFAULT 0,
  `expires` bigint(20) NOT NULL DEFAULT 0,
  `scene` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `expires` (`expires`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.placed_props
DROP TABLE IF EXISTS `placed_props`;
CREATE TABLE IF NOT EXISTS `placed_props` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(255) NOT NULL DEFAULT '',
  `coords` varchar(255) NOT NULL,
  `heading` double NOT NULL DEFAULT 0,
  `created` datetime NOT NULL DEFAULT current_timestamp(),
  `creator` bigint(20) NOT NULL,
  `is_frozen` tinyint(1) NOT NULL DEFAULT 0,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `type` int(11) NOT NULL DEFAULT 0,
  `name_override` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.sequence
DROP TABLE IF EXISTS `sequence`;
CREATE TABLE IF NOT EXISTS `sequence` (
  `key` varchar(64) NOT NULL,
  `current` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`key`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.storage_units
DROP TABLE IF EXISTS `storage_units`;
CREATE TABLE IF NOT EXISTS `storage_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(128) NOT NULL DEFAULT '',
  `owner` int(11) NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 0,
  `location` longtext NOT NULL,
  `managedBy` varchar(64) DEFAULT NULL,
  `lastAccessed` bigint(20) NOT NULL DEFAULT 0,
  `soldBy` int(11) DEFAULT NULL,
  `soldAt` bigint(20) DEFAULT NULL,
  `passcode` varchar(16) NOT NULL DEFAULT '0000',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `owner` (`owner`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.store_bank_accounts
DROP TABLE IF EXISTS `store_bank_accounts`;
CREATE TABLE IF NOT EXISTS `store_bank_accounts` (
  `Shop` int(11) NOT NULL,
  `Account` int(11) NOT NULL,
  PRIMARY KEY (`Shop`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.tracks
DROP TABLE IF EXISTS `tracks`;
CREATE TABLE IF NOT EXISTS `tracks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `track` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.tracks_pd
DROP TABLE IF EXISTS `tracks_pd`;
CREATE TABLE IF NOT EXISTS `tracks_pd` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `track` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.users
DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` int(11) NOT NULL,
  `identifier` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL DEFAULT '',
  `forum` varchar(64) DEFAULT NULL,
  `avatar` varchar(512) DEFAULT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT 0,
  `joined` bigint(20) NOT NULL DEFAULT 0,
  `priority` int(11) NOT NULL DEFAULT 0,
  `groups` longtext NOT NULL,
  `tokens` longtext DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `identifier` (`identifier`) USING BTREE,
  KEY `account` (`account`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.vehicles
DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `VIN` varchar(64) NOT NULL,
  `Type` int(11) NOT NULL DEFAULT 0,
  `RegisteredPlate` varchar(16) NOT NULL DEFAULT '',
  `FakePlate` varchar(16) NOT NULL DEFAULT '',
  `Make` varchar(64) NOT NULL DEFAULT 'Unknown',
  `Model` varchar(64) NOT NULL DEFAULT 'Unknown',
  `ownerType` int(11) NOT NULL DEFAULT 0,
  `ownerId` varchar(64) NOT NULL DEFAULT '0',
  `ownerWorkplace` varchar(64) NOT NULL DEFAULT '',
  `ownerLevel` int(11) NOT NULL DEFAULT 0,
  `storageType` int(11) NOT NULL DEFAULT 0,
  `storageId` varchar(64) NOT NULL DEFAULT '0',
  `vehicle` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `VIN` (`VIN`) USING BTREE,
  KEY `RegisteredPlate` (`RegisteredPlate`) USING BTREE,
  KEY `FakePlate` (`FakePlate`) USING BTREE,
  KEY `owner` (`ownerType`, `ownerId`) USING BTREE,
  KEY `storage` (`storageType`, `storageId`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.

-- Dumping structure for table mythicrp.weed
DROP TABLE IF EXISTS `weed`;
CREATE TABLE IF NOT EXISTS `weed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `planted` bigint(20) NOT NULL,
  `plant` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
DROP TABLE IF EXISTS `outfit_codes`;
CREATE TABLE IF NOT EXISTS `outfit_codes` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`Code` VARCHAR(50) NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	`Label` VARCHAR(25) NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	`Data` LONGTEXT NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB
AUTO_INCREMENT=16
;


/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
