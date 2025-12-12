CREATE DATABASE HoldingDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE HoldingDB;
CREATE TABLE Region (
    RegionID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Code VARCHAR(20) UNIQUE NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL
);

CREATE TABLE EnterpriseType (
    TypeID INT AUTO_INCREMENT PRIMARY KEY,
    TypeName VARCHAR(100) NOT NULL UNIQUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL
);

CREATE TABLE Enterprise (
    EnterpriseID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    RegionID INT NOT NULL,
    TypeID INT NOT NULL,
    INN VARCHAR(20),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (RegionID) REFERENCES Region(RegionID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (TypeID) REFERENCES EnterpriseType(TypeID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_region (RegionID),
    INDEX idx_type (TypeID)
);

CREATE TABLE IndicatorCategory (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL
);

CREATE TABLE UnitDictionary (
    UnitCode VARCHAR(20) PRIMARY KEY,
    UnitName VARCHAR(100) NOT NULL UNIQUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Indicator (
    IndicatorID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    CategoryID INT NOT NULL,
    Unit VARCHAR(50) NOT NULL,
    IsActive TINYINT(1) DEFAULT 1,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (CategoryID) REFERENCES IndicatorCategory(CategoryID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (Unit) REFERENCES UnitDictionary(UnitCode)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_category (CategoryID)
);

CREATE TABLE ReportJournal (
    JournalID INT AUTO_INCREMENT PRIMARY KEY,
    EnterpriseID INT NOT NULL,
    Period DATE NOT NULL,
    Status ENUM('DRAFT','SUBMITTED','APPROVED','CANCELED') DEFAULT 'DRAFT',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (EnterpriseID) REFERENCES Enterprise(EnterpriseID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_period (Period)
);

CREATE TABLE ReportEntry (
    EntryID INT AUTO_INCREMENT PRIMARY KEY,
    JournalID INT NOT NULL,
    IndicatorID INT NOT NULL,
    Value DECIMAL(15,2) NOT NULL,
    Comment VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (JournalID) REFERENCES ReportJournal(JournalID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (IndicatorID) REFERENCES Indicator(IndicatorID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_journal_indicator (JournalID, IndicatorID)
);

CREATE TABLE Role (
    RoleID INT AUTO_INCREMENT PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE User (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    RoleID INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (RoleID) REFERENCES Role(RoleID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_username (Username)
);

CREATE TABLE AuditLog (
    LogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    Action VARCHAR(255) NOT NULL,
    Details JSON,
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES User(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_timestamp (Timestamp)
);

INSERT INTO Region (Name, Code) VALUES
('Dolnośląskie','DS'),('Mazowieckie','MZ'),('Małopolskie','MP');

INSERT INTO EnterpriseType (TypeName) VALUES
('CENTRALA'),('ZAKŁAD PRODUKCYJNY'),('MAGAZYN');

INSERT INTO Enterprise (Name, RegionID, TypeID, INN) VALUES
('Centrala Holding S.A.',1,1,'PL1000000001'),
('Zakład Wrocław',1,2,'PL2000000002');

INSERT INTO IndicatorCategory (CategoryName) VALUES
('Finansowe'),('Produkcyjne');

INSERT INTO UnitDictionary (UnitCode, UnitName) VALUES
('PLN','Polski Złoty'),('pcs','Sztuki');

INSERT INTO Indicator (Name, CategoryID, Unit) VALUES
('Przychód',1,'PLN'),('Koszt',1,'PLN'),('Wolumen produkcji',2,'pcs');

INSERT INTO Role (RoleName) VALUES ('admin'),('auditor'),('analyst');

INSERT INTO User (Username,PasswordHash,RoleID) VALUES
('admin','hash1',1),('auditor1','hash2',2);

INSERT INTO ReportJournal (EnterpriseID,Period,Status) VALUES
(1,'2025-10-01','SUBMITTED'),(2,'2025-10-01','APPROVED');

INSERT INTO ReportEntry (JournalID,IndicatorID,Value,Comment) VALUES
(1,1,1250000,'Konsolidacja'),(1,2,950000,'OPEX'),(2,3,25000,'Sery A');

DELIMITER $$
CREATE TRIGGER trg_update_timestamp BEFORE UPDATE ON Enterprise
FOR EACH ROW SET NEW.UpdatedAt = CURRENT_TIMESTAMP;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_journal_cancel AFTER UPDATE ON ReportJournal
FOR EACH ROW
BEGIN
    IF NEW.Status='CANCELED' AND OLD.Status<>'CANCELED' THEN
        UPDATE ReportEntry SET Value=0, Comment=CONCAT(IFNULL(Comment,''),' [cancelled]')
        WHERE JournalID=NEW.JournalID;
        INSERT INTO AuditLog(UserID,Action,Details)
        VALUES(1,'JOURNAL_CANCELED',JSON_OBJECT('JournalID',NEW.JournalID,'Period',NEW.Period));
    END IF;
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE sp_region_create(IN pName VARCHAR(100),IN pCode VARCHAR(20))
BEGIN
    INSERT INTO Region(Name,Code) VALUES(pName,pCode);
END$$
DELIMITER ;

SELECT e.Name,j.Period,
SUM(CASE WHEN i.Name='Przychód' THEN re.Value ELSE 0 END) AS Revenue,
SUM(CASE WHEN i.Name='Koszt' THEN re.Value ELSE 0 END) AS Cost
FROM ReportJournal j
JOIN Enterprise e ON e.EnterpriseID=j.EnterpriseID
JOIN ReportEntry re ON re.JournalID=j.JournalID
JOIN Indicator i ON i.IndicatorID=re.IndicatorID
GROUP BY e.Name,j.Period;
