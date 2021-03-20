-- phpMyAdmin SQL Dump
-- version 4.9.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 20, 2021 at 05:17 PM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.2.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `node_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `jobdetail`
--

CREATE TABLE `jobdetail` (
  `jobID` varchar(20) NOT NULL,
  `macroOrder` int(5) NOT NULL,
  `macroType` varchar(20) NOT NULL,
  `searchEngine` varchar(20) NOT NULL,
  `searchTermName` varchar(20) NOT NULL,
  `linkOrTitle` varchar(255) NOT NULL,
  `pageVerifyText` varchar(255) NOT NULL,
  `minCharTime` int(5) NOT NULL,
  `maxCharTime` int(5) NOT NULL,
  `minClickTime` int(5) NOT NULL,
  `maxClickTime` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `jobdetail`
--

INSERT INTO `jobdetail` (`jobID`, `macroOrder`, `macroType`, `searchEngine`, `searchTermName`, `linkOrTitle`, `pageVerifyText`, `minCharTime`, `maxCharTime`, `minClickTime`, `maxClickTime`) VALUES
('ti-Sentry', 1, 'SearchEngine', 'Google', 'trucking insurance', 'Commercial Trucking Insurance and Owner Operator Truck ...', 'Flexible coverage options', 10, 50, 3000, 10000),
('ti-Sentry', 2, 'PageLink', 'Google', 'trucking insurance', 'More about commercial auto liability', 'Significant figures', 10, 50, 3000, 10000),
('ti-Sentry', 3, 'PageLink', 'Google', 'trucking insurance', 'Learn more about Sentry claims services', 'We communicate with you', 10, 50, 3000, 10000),
('ti-Sentry', 8, 'DirectPage', 'Google', 'trucking insurance', 'owneroperatordirect.com', 'THE BEST COMMERCIAL TRUCK INSURANCE PERIOD', 10, 50, 3000, 10000),
('ti-Progressive', 1, 'SearchEngine', 'Google', 'trucking insurance', 'Commercial Truck Insurance | Progressive Commercial', 'The #1 commercial truck insurer in America', 10, 50, 3000, 10000),
('ti-Sentry', 4, 'PageLink', 'Google', 'trucking insurance', 'claims online', 'Online tools and portals', 10, 50, 3000, 10000),
('ti-Sentry', 5, 'PageLink', 'Google', 'trucking insurance', 'Manufacturing and process industries', 'Manufacturing business insurance', 10, 50, 3000, 10000),
('ti-Sentry', 6, 'PageLink', 'Google', 'trucking insurance', 'More about electronic manufacturing', 'Electronic component manufacturing insurance', 10, 50, 3000, 10000),
('ti-Sentry', 7, 'PageLink', 'Google', 'trucking insurance', 'More about business auto insurance', 'Business auto insurance', 10, 50, 3000, 10000);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
