-- Player Health Data
CREATE TABLE IF NOT EXISTS `echo_health_data` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL UNIQUE,
    `blood_type` VARCHAR(5) DEFAULT 'O+',
    `organ_donor` TINYINT(1) DEFAULT 0,
    `mental_health` INT DEFAULT 100,
    `last_therapy` BIGINT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Organ Inventory
CREATE TABLE IF NOT EXISTS `echo_organs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `organ_type` VARCHAR(50) NOT NULL,
    `blood_type` VARCHAR(5) NOT NULL,
    `quality` INT DEFAULT 100,
    `donor_identifier` VARCHAR(50) DEFAULT NULL,
    `is_black_market` TINYINT(1) DEFAULT 0,
    `location` VARCHAR(50) DEFAULT 'hospital',
    `harvested_at` BIGINT NOT NULL,
    `expires_at` BIGINT NOT NULL,
    INDEX `idx_organ_type` (`organ_type`),
    INDEX `idx_blood_type` (`blood_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Organ Transactions
CREATE TABLE IF NOT EXISTS `echo_organ_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `organ_id` INT NOT NULL,
    `seller_identifier` VARCHAR(50),
    `buyer_identifier` VARCHAR(50) NOT NULL,
    `price` INT NOT NULL,
    `transaction_type` VARCHAR(20) NOT NULL,
    `timestamp` BIGINT NOT NULL,
    FOREIGN KEY (`organ_id`) REFERENCES `echo_organs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Mental Health Logs
CREATE TABLE IF NOT EXISTS `echo_mental_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `event_type` VARCHAR(50) NOT NULL,
    `impact` INT NOT NULL,
    `mental_before` INT NOT NULL,
    `mental_after` INT NOT NULL,
    `timestamp` BIGINT NOT NULL,
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Addiction Data
CREATE TABLE IF NOT EXISTS `echo_addictions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `substance` VARCHAR(50) NOT NULL,
    `addiction_level` DECIMAL(5,2) DEFAULT 0.00,
    `last_use` BIGINT DEFAULT 0,
    `clean_since` BIGINT DEFAULT NULL,
    `total_uses` INT DEFAULT 0,
    `relapses` INT DEFAULT 0,
    UNIQUE KEY `unique_addiction` (`identifier`, `substance`),
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Recovery Program
CREATE TABLE IF NOT EXISTS `echo_recovery` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(50) NOT NULL,
    `substance` VARCHAR(50) NOT NULL,
    `meetings_attended` INT DEFAULT 0,
    `sponsor_identifier` VARCHAR(50) DEFAULT NULL,
    `last_meeting` BIGINT DEFAULT 0,
    `program_started` BIGINT NOT NULL,
    `program_completed` TINYINT(1) DEFAULT 0,
    `completion_date` BIGINT DEFAULT NULL,
    UNIQUE KEY `unique_recovery` (`identifier`, `substance`),
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Therapy Sessions
CREATE TABLE IF NOT EXISTS `echo_therapy_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `patient_identifier` VARCHAR(50) NOT NULL,
    `therapist_identifier` VARCHAR(50) NOT NULL,
    `duration` INT NOT NULL,
    `mental_gain` INT NOT NULL,
    `payment` INT NOT NULL,
    `notes` TEXT,
    `session_date` BIGINT NOT NULL,
    INDEX `idx_patient` (`patient_identifier`),
    INDEX `idx_therapist` (`therapist_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;