IF OBJECT_ID('dbo.RevokedSession','U') IS NULL
BEGIN
    CREATE TABLE dbo.RevokedSession (TokenHash varchar(64) NOT NULL PRIMARY KEY, ExpiresAt datetime2 NOT NULL);
    CREATE INDEX IX_RevokedSession_ExpiresAt ON dbo.RevokedSession(ExpiresAt);
END;
