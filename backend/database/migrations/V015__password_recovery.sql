IF OBJECT_ID('dbo.PasswordRecovery','U') IS NULL
BEGIN
    CREATE TABLE dbo.PasswordRecovery(
        EmailKey char(64) NOT NULL PRIMARY KEY,
        AccountId int NULL REFERENCES dbo.TaiKhoan(MaTaiKhoan),
        CredentialKey char(64) NULL, CodeHash char(64) NULL, TicketHash char(64) NULL,
        ExpiresAt bigint NOT NULL, WindowStart bigint NOT NULL, LastRequest bigint NOT NULL,
        Sends int NOT NULL, Attempts int NOT NULL
    );
    CREATE INDEX IX_PasswordRecovery_Window ON dbo.PasswordRecovery(WindowStart);
END;
