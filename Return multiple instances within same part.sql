--	TODO: Return multiple instances within same part

--	string we are searching for
--DECLARE @Search_STR NVARCHAR(128) = 'blagh'
DECLARE @Search_STR NVARCHAR(128) = 'Usuário'

--	Attempt to match search string to resx
DECLARE @Translation_STR NVARCHAR(128) = (
	ISNULL(
		(	SELECT TOP 1 ri.[Key] FROM tResourceTranslation rt
			LEFT JOIN tResourceItem ri ON ri.ID = rt.ResourceItemID
			WHERE 
				@Search_STR = ri.[Key]
				OR @Search_STR = ri.DefaultValue
				OR @Search_STR = rt.Value 
		), '')
)
-- SELECT @Translation_STR [@Translation_STR]

--	Display message if search string was a resx key, value, or default value
IF (@Translation_STR <> '') 
	BEGIN
		SELECT 
			 '--->' [Search String Matches Translation]
			, @Search_STR [@SearchString]
			, ri.[Key] [ResourceItemKey]
			, ri.DefaultValue [ResourceItemDefaultValue]
			, rt.Value [ResourceTranslationValue]
			, 'resx:' + rg.[Key] + '.' + ri.[Key] + ', db' [full resx]
		FROM tResourceTranslation rt
		LEFT JOIN tResourceItem ri ON ri.ID = rt.ResourceItemID
		LEFT JOIN tResourceGroup rg ON rg.ID = ri.ResourceGroupID
		WHERE 
			@Search_STR = ri.[Key]
			OR @Search_STR = ri.DefaultValue
			OR @Search_STR = rt.Value 
	END
ELSE
	BEGIN SELECT 'Nah' END

--	beginning / end of content part string
DECLARE @PART_START_STR NVARCHAR(32) = '<Part ID='
DECLARE @PART_END_STR NVARCHAR(32) = '}]]></Parameters></Part>'

--	TODO: Find way to pull out the exact param
--	beginning / end of params portion of part
--DECLARE @PARAMS_StartSTR NVARCHAR(32) = '<Parameters><![CDATA[{'
--DECLARE @PARAMS_END_STR NVARCHAR(32) = '}]]></Parameters>'


--	Table to hold all the pdefs that have parts w/ @Search_STR
IF OBJECT_ID('tempdb..#Pdefs') IS NOT NULL DROP TABLE #Pdefs
SELECT 
	  pd.ID [pd_ID]
	, pd.[Key] [pd_key]
	, pd.Name [pd_name]
INTO #Pdefs
FROM tPageDefinition pd WHERE pd.ContentView LIKE '%' + @Search_STR + '%'
--SELECT * FROM #Pdefs

--	Holds pdef ID from table
DECLARE @PdefID INT = 0

--	Table to hold all of the parts
--	delete temp table if it already exists
IF OBJECT_ID('tempdb..#Parts') IS NOT NULL DROP TABLE #Parts
CREATE TABLE #Parts (
	PDEF_ID INT
	, PDEF_Key NVARCHAR(128)
	, PDEF_Name NVARCHAR(128)
	, PART_ID NVARCHAR(128)
	, PART_Key NVARCHAR(128)
	, NUM_Instances INT
	, PART_STR NVARCHAR(MAX)
)

--SELECT TOP 1 pd_ID FROM #Pdefs
--WHERE pd_ID > @PdefID
--ORDER BY pd_ID ASC


--	loop through pdefs in table
WHILE (SELECT COUNT(*) FROM #Pdefs) > 0

BEGIN

	--	get the top pagedefinition id from table, then delete that row
	SET @PdefID = (SELECT TOP 1 [pd_ID] FROM #Pdefs)
	DELETE FROM #Pdefs WHERE [pd_ID] = @PdefID

	--	page name / key
	DECLARE @PdefName NVARCHAR(128) = (SELECT TOP 1 Name FROM tPageDefinition WHERE ID = @PdefID )
	DECLARE @PdefKey NVARCHAR(128) = (SELECT TOP 1 [Key] FROM tPageDefinition WHERE ID = @PdefID )

	--	Pull ContentView only once per loop
	DECLARE @ContentView NVARCHAR(MAX) = (
		SELECT pd.ContentView FROM tPageDefinition pd
		WHERE pd.ID = @PdefID
	)
	
	--	Add one to offset 1-index
	DECLARE @View_Len INT = LEN(@ContentView) +1
	--SELECT @View_Len [@View_Len]

	DECLARE @TotalParts INT = (
		SELECT (
			(@View_Len - LEN(REPLACE(@ContentView, @PART_START_STR, '')))
				/ LEN(@PART_START_STR))
		)
	--SELECT @TotalParts [TotalParts]


	--	Loop Stuff

	--	counts the number of loops
	DECLARE @Part_Loop_INDEX INT = @TotalParts

	--	holds the current index
	DECLARE @View_STR_INDEX INT = 1

	--	Loop within the content view
	WHILE @Part_Loop_INDEX > 0
	
	BEGIN

		SET @Part_Loop_INDEX = @Part_Loop_INDEX -1

		--	Start looking for the next part where the previous one left off
		--	get whole part
		DECLARE @Part_StartIndex INT = CHARINDEX(@PART_START_STR, @ContentView, @View_STR_INDEX)
		DECLARE @Part_EndIndex INT = 
			CHARINDEX(@PART_END_STR, @ContentView, @Part_StartIndex) + LEN(@PART_END_STR)
		DECLARE @Part_STR NVARCHAR(MAX) = 
			SUBSTRING(@ContentView, @Part_StartIndex, @Part_EndIndex - @Part_StartIndex)

		--	get number of instances of string within each part
		DECLARE @Instances INT = 
			(SELECT LEN(@Part_STR)-LEN(REPLACE(@Part_STR, @Search_STR,'')))/LEN(@Search_STR)

		--	Set search index for next loop
		SET @View_STR_INDEX = @Part_EndIndex

		--	move to next part it doesn't have the search string
		IF (CHARINDEX(@Search_STR, @Part_STR, 1) = 0 ) 
			CONTINUE

		--	part has the search string at least once
		ELSE 
		BEGIN
			--	get Part ID, Key
			--Starting chars of part are always '<PartID="'
			DECLARE @PartID_StartIndex INT = 11
	
			--Find index of next '"'
			DECLARE @PartID_EndIndex INT = CHARINDEX('"', @Part_STR, @PartID_StartIndex)
	
			DECLARE @PartID_STR NVARCHAR(128) = 
				SUBSTRING(@Part_STR, @PartID_StartIndex, @PartID_EndIndex - @PartID_StartIndex)

			--	Key always follows PartID with '" Key="'
			DECLARE @PartKey_StartIndex INT = @PartID_EndIndex + 7
	
			--Find index of next '"'
			DECLARE @PartKey_EndIndex INT = CHARINDEX('"', @Part_STR, @PartKey_StartIndex)
	
			--	get the key
			DECLARE @PartKey_STR NVARCHAR(128) = 
				SUBSTRING(@Part_STR, @PartKey_StartIndex, @PartKey_EndIndex - @PartKey_StartIndex)

			--	Add record to table
			INSERT INTO #Parts
			SELECT
				@PdefID
				, @PdefKey
				, @PdefName
				, @PartID_STR [@PartID_STR ]
				, @PartKey_STR [@PartKey_STR]
				, @Instances
				, @Part_STR


		END -- End part search
	
	END	--	End part loop

END --	end pdef loop


IF (SELECT COUNT(*) FROM #Parts) > 0
	BEGIN
		SELECT * FROM #Parts
	END

ELSE 
	BEGIN
		SELECT 'No Instances Found' [404]
	END

DROP TABLE #Parts
DROP TABLE #Pdefs