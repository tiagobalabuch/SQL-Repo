SELECT
    DB_NAME( database_id )
  , non_transacted_access
  , non_transacted_access_desc
  , directory_name
FROM
    sys.database_filestream_options
WHERE
    directory_name IS NOT NULL;
GO

SELECT
    *
FROM
    sys.tables
WHERE
    is_filetable = 1;
SELECT
    *
FROM
    sys.filetables;


SELECT
    DB_NAME( database_id )
  , directory_name
FROM
    sys.database_filestream_options;
GO

SELECT
    OBJECT_NAME( parent_object_id ) AS 'FileTable'
  , OBJECT_NAME( object_id )        AS 'System-defined Object'
FROM
    sys.filetable_system_defined_objects
ORDER BY
    FileTable
  , 'System-defined Object';
GO

--View sorted list with friendly names  
SELECT
    OBJECT_NAME( parent_object_id ) AS 'FileTable'
  , OBJECT_NAME( object_id )        AS 'System-defined Object'
FROM
    sys.filetable_system_defined_objects
ORDER BY
    FileTable
  , 'System-defined Object';
GO

-- Directory and file structure
SELECT
    FT.name
  , IIF(FT.is_directory = 1, 'Directory', 'Files')                          [File Category]
  , FT.file_type                                                            [File Type]
  , (FT.cached_file_size) / 1024.0                                          [File Size (KB)]
  , FT.creation_time                                                        [Created Time]
  , FT.file_stream.GetFileNamespacePath( 1, 0 )                             [File Path]
  , ISNULL( PT.file_stream.GetFileNamespacePath( 1, 0 ), 'Root Directory' ) [Parent Path]
FROM
    your_file_table       FT WITH (READCOMMITTEDLOCK)
LEFT JOIN your_file_table PT WITH (READCOMMITTEDLOCK)
    ON FT.path_locator.GetAncestor( 1 ) = PT.path_locator;

-- File cache
SELECT
    [name]
  , [file_type]
  , CAST([file_stream] AS VARCHAR) FileContent
  , [cached_file_size]
  , [is_directory]
FROM
    [dbo].invoice_file_table WITH (READCOMMITTEDLOCK);
GO

--Script to retrieve windows process ID which blocks Filetable object
SELECT
    DB_NAME( database_id )                 [Databae Name]
  , OBJECT_NAME( object_id )               [FileTableName]
  , state_desc
  , item_name
  , opened_file_name
  , open_time
  , database_directory_name
  , login_name
  , CONVERT( INT, correlation_process_id ) [Windows Process ID]
FROM
    sys.dm_filestream_non_transacted_handles;

-- Close all open handles in the current database.
EXEC sp_kill_filestream_non_transacted_handles;

-- Close all open handles in myFileTable.
EXEC sp_kill_filestream_non_transacted_handles
    @table_name = 'YourFileTableName';

-- Close a specific handle in myFileTable.
EXEC sp_kill_filestream_non_transacted_handles
    @table_name = 'YourFileTableName'
  , @handle_id = 0x00000; -- get this value from sys.dm_filestream_non_transacted_handles dmv

-- How to: Identify the Locks Held by FileTables
SELECT
    opened_file_name
FROM
    sys.dm_filestream_non_transacted_handles
WHERE
    fcb_id IN ( SELECT request_owner_id FROM sys.dm_tran_locks );
GO


-- Managing file table

USE master;
GO
ALTER DATABASE data_staging
SET
    FILESTREAM (NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'Activation');
GO

USE master;
GO
ALTER DATABASE data_dev
SET
    FILESTREAM (NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'Activation');

USE [data_staging];
GO
ALTER TABLE [dbo].[customer_activation_file_table] SET (FILETABLE_DIRECTORY = N'activation_file_table');
GO
