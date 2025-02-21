/*
	CHARINDEX(substring, string, (opt)start)
	SUBSTRING(string, start, length)
*/

--ID of current pdef
DECLARE @PdefID INT = 44

--	Indicates this is a sql part
DECLARE @SQLPartStartStr NVARCHAR(64) = 'ETS.DataTables.TsDataTableCustomSql'

--	Content view str from current pdef
DECLARE @ContentView NVARCHAR(MAX) = (
	SELECT pd.ContentView FROM tPageDefinition pd WHERE pd.ID = @PdefID
)


--	The string where we are searching for the substring
DECLARE @SearchStr NVARCHAR(MAX) = @ContentView
DECLARE @SearchStrLength INT = DATALENGTH(@ContentView)

--	The string we are searching for
DECLARE @SubStr NVARCHAR(64) = @SQLPartStartStr
DECLARE @SubStrLen INT = DATALENGTH(@SubStr)

--	String we are searching inside with all occurrences removed
DECLARE @SearchStrMod NVARCHAR(MAX) = REPLACE(@SearchStr, @SubStr, '')
DECLARE @SearchStrModLength INT = DATALENGTH(@SearchStrMod)

--	if all occurrences are deleted from source string, 
--	the number of occurrences can be determined by finding 
--	difference in length and dividing by length of search string
DECLARE @Occurrences INT = (@SearchStrLength - @SearchStrModLength) / @SubStrLen
	

SELECT  
	pd.ID [PageDefID]
	, pd.Name
	, @SubStr [SubString]
	, @Occurrences [Occurrences]

FROM tPageDefinition pd WHERE pd.ID = @PdefID