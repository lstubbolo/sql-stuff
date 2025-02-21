/*
	CHARINDEX(substring, string, (opt)_Start)
	SUBSTRING(string, _Start, length)
*/

--ID of current pdef
DECLARE @PdefID INT = 0

--	Indicates this is a sql part
DECLARE @SQLPart_StartStr NVARCHAR(64) = 'ETS.DataTables.TsDataTableCustomSql'

--	Content view str from current pdef
DECLARE @ContentView NVARCHAR(MAX) = ''



--	part start / end search strings
DECLARE @Part_StartStr NVARCHAR(64) = '<Part ID="'
DECLARE @Part_EndStr NVARCHAR(64) = '</Part>'

--	indexes/length of the entire part
DECLARE @Part_StartIndex INT = 0
DECLARE @Part_EndIndex INT = 0
DECLARE @Part_Len INT = 0



--	part ID start / end search strings
--DECLARE @PartID_StartStr NVARCHAR(64) = @Part_StartStr
DECLARE @PartID_EndStr NVARCHAR(64) = '" Key='

--	indexes / len of the partID
DECLARE @PartID_StartIndex INT = 0
DECLARE @PartID_EndIndex INT = 0
DECLARE @PartID_Len INT = 0


--	string that indicates the _End of the params portion of the part
DECLARE @_EndParamsStr NVARCHAR(64) = '"Sql":'

--	start / end / length of params portion of the part
DECLARE @Param_StartIndex INT = 0
DECLARE @Param_EndIndex INT = 0
DECLARE @Param_Len INT = 0



DECLARE @i INT = 0
--WHILE @i < 10
--BEGIN
	--SET @PdefID = 40 + @i
	SET @PdefID = 44

	--	pull out contentview so we don't have to keep querying
	SET @ContentView = (
		SELECT pd.ContentView FROM tPageDefinition pd WHERE pd.ID = @PdefID
	)

	/*	Part	*/

	--	rough _Start index of the part by searching for Sql Part Key
	DECLARE @TempPart_StartIndex INT = CHARINDEX(@SQLPart_StartStr, @ContentView) - 50
	
	--	Find indexes / length of whole part
	SET @Part_StartIndex =
		CHARINDEX(@Part_StartStr, @ContentView, @TempPart_StartIndex)
	
	SET @Part_EndIndex =
		CHARINDEX(@Part_EndStr, @ContentView, @Part_StartIndex) + + LEN(@Part_EndStr)

	SET @Part_Len = @Part_EndIndex - @Part_StartIndex

	--	String containing the entire part
	DECLARE @Part_Str NVARCHAR(MAX) = SUBSTRING(@ContentView, @Part_StartIndex, @Part_Len)

	--SELECT 
	--	@TempPart_StartIndex [@TempPart_StartIndex]
	--	, @Part_StartIndex [@Part_StartIndex]
	--	, @Part_EndIndex [@Part_EndIndex]
	--	, @@Part_Len [@PartLen]
	--	, @Part_Str [@PartStr]
	
	
	/*	PartID	*/
	
	SET @PartID_StartIndex = @Part_StartIndex + DATALENGTH(@Part_StartStr)
	SET @PartID_EndIndex = 
		CHARINDEX(@PartID_EndStr, @Part_Str, @PartID_StartIndex)
	SET @PartID_Len = @PartID_EndIndex - @PartID_StartIndex

	--	String containing the entire part
	DECLARE @PartID_Str NVARCHAR(64) = SUBSTRING(@ContentView, @Part_StartIndex, @Part_Len)

	SELECT 
		@Part_Str, @PartID_StartIndex, @PartID_EndIndex, @PartID_Str
	----	find _Start/_End index of SQL part Params
	--SET @Param_StartIndex = CHARINDEX(@SQLPart_StartStr, @ContentView) 
	--SET @Param_EndIndex = CHARINDEX(@_EndParamsStr, @ContentView, @Param_StartIndex)
	--SET @ParamLen = @Param_EndIndex - @Param_StartIndex
	
	--DECLARE @ParamStr NVARCHAR(MAX) = SUBSTRING(@ContentView, @Param_StartIndex, @ParamLen)
	

	--	Find _Start ID
	--SET @Part_ID = SUBSTRING(

	--)

	--SELECT  
	--	pd.ID
	--	, pd.Name
	--	, @Param_StartIndex [@Param_StartIndex]
	--	, @Param_EndIndex [@Param_EndIndex]
	--	, (@Param_EndIndex - @Param_StartIndex) [Len]
		
	--	, 
	--FROM tPageDefinition pd 
	--WHERE pd.ID = 40 + @i


	SET @i = @i+1


--_End