/* DESTRUCTIVE LAB ONLY. Reserved database name; refuses to overwrite existing databases. */
SET NOCOUNT ON;
IF DB_ID(N'ToolkitBenchmark') IS NOT NULL
    THROW 51000, 'ToolkitBenchmark already exists; inspect and remove it manually before running.', 1;
CREATE DATABASE ToolkitBenchmark;
GO
USE ToolkitBenchmark;
CREATE TABLE dbo.Workload (
    id int NOT NULL CONSTRAINT PK_Workload PRIMARY KEY,
    bucket int NOT NULL,
    payload char(200) NOT NULL
);
WITH digits AS (
    SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS v(n)
)
INSERT dbo.Workload(id, bucket, payload)
SELECT 1 + a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n,
       (a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n) % 1000,
       REPLICATE('x', 200)
FROM digits AS a CROSS JOIN digits AS b CROSS JOIN digits AS c
CROSS JOIN digits AS d CROSS JOIN digits AS e;
UPDATE STATISTICS dbo.Workload WITH FULLSCAN;
