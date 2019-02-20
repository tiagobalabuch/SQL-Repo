-- https://sqland.wordpress.com/2016/10/17/query-store-new-in-sql-server-2016-part-vi/
-- Etienne Lopes


DROP FUNCTION IF EXISTS fn_DisplaySetOptions;
GO
CREATE FUNCTION fn_DisplaySetOptions
(
  @Set_Options AS INT
)
RETURNS VARCHAR(8000)
AS
BEGIN
  --Variables:
  DECLARE
    @Result     VARCHAR(8000) = '',
    @FoundValue INT;
  DECLARE @SetOptionsList TABLE
  (
    [Value] INT,
    [Option] VARCHAR(60)
  );

  --Create the SetOptions List having its values collected from: https://msdn.microsoft.com/en-us/library/ms189472.aspx:
  INSERT INTO @SetOptionsList
  VALUES
  ( 1,      'ANSI_PADDING' ),
  ( 2,      'Parallel Plan' ),
  ( 4,      'FORCEPLAN' ),
  ( 8,      'CONCAT_NULL_YIELDS_NULL' ),
  ( 16,     'ANSI_WARNINGS' ),
  ( 32,     'ANSI_NULLS' ),
  ( 64,     'QUOTED_IDENTIFIER' ),
  ( 128,    'ANSI_NULL_DFLT_ON' ),
  ( 256,    'ANSI_NULL_DFLT_OFF' ),
  ( 512,    'NoBrowseTable' ),
  ( 1024,   'TriggerOneRow' ),
  ( 2048,   'ResyncQuery' ),
  ( 4096,   'ARITH_ABORT' ),
  ( 8192,   'NUMERIC_ROUNDABORT' ),
  ( 16384,  'DATEFIRST' ),
  ( 32768,  'DATEFORMAT' ),
  ( 65536,  'LanguageID' ),
  ( 131072, 'UPON' ),
  ( 262144, 'ROWCOUNT' );

  --Recursive part:
  SELECT TOP 1
    @FoundValue = ISNULL ([Value], -1),
    @Result     = ISNULL ([Option], '') + ' (' + CAST(@FoundValue AS VARCHAR) + ')' + '; '
  FROM @SetOptionsList
  WHERE [Value] <= @Set_Options
  ORDER BY [Value] DESC;

  --Result composition:
  RETURN @Result + CASE
                     WHEN @FoundValue > -1 THEN dbo.fn_DisplaySetOptions (@Set_Options - @FoundValue)
                     ELSE ''
                   END;

END;
GO