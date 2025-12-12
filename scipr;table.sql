
CREATE DATABASE HoldingDB;
USE HoldingDB;

CREATE TABLE Region (
    RegionID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Code VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE EnterpriseType (
    TypeID INT AUTO_INCREMENT PRIMARY KEY,
    TypeName VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Enterprise (
    EnterpriseID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    RegionID INT NOT NULL,
    TypeID INT NOT NULL,
    FOREIGN KEY (RegionID) REFERENCES Region(RegionID),
    FOREIGN KEY (TypeID) REFERENCES EnterpriseType(TypeID),
    INDEX idx_region (RegionID),
    INDEX idx_type (TypeID)
);

CREATE TABLE IndicatorCategory (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Indicator (
    IndicatorID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    CategoryID INT NOT NULL,
    Unit VARCHAR(50),
    FOREIGN KEY (CategoryID) REFERENCES IndicatorCategory(CategoryID),
    INDEX idx_category (CategoryID)
);

CREATE TABLE ReportJournal (
    JournalID INT AUTO_INCREMENT PRIMARY KEY,
    EnterpriseID INT NOT NULL,
    Period DATE NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EnterpriseID) REFERENCES Enterprise(EnterpriseID),
    INDEX idx_period (Period)
);

CREATE TABLE ReportEntry (
    EntryID INT AUTO_INCREMENT PRIMARY KEY,
    JournalID INT NOT NULL,
    IndicatorID INT NOT NULL,
    Value DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (JournalID) REFERENCES ReportJournal(JournalID),
    FOREIGN KEY (IndicatorID) REFERENCES Indicator(IndicatorID),
    INDEX idx_journal_indicator (JournalID, IndicatorID)
);

CREATE TABLE Role (
    RoleID INT AUTO_INCREMENT PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE User (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    RoleID INT NOT NULL,
    FOREIGN KEY (RoleID) REFERENCES Role(RoleID),
    INDEX idx_username (Username)
);

CREATE TABLE AuditLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    Action VARCHAR(255) NOT NULL,
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    INDEX idx_timestamp (Timestamp)
);

