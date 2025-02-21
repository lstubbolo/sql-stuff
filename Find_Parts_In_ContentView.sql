--	
--	Search for string inside parts
--	--	Louis Stubbolo 
--	--	20 Feb 2025
--	
--	Iterates through page definitions records
--		with ContentView containing the search string
--	
--	the pdef records to be searched can be restricted to 
--		a single page by setting @PdefID field below
--	
--	Iterates through each part in ContentView string,
--		pulls out each part ID and Key
--	
--	Returns number of instances of search string in the part
--	
--	If search string is not set (value = '')
--		query will return every part in each pdef record
--	

--	The string we are searching for
DECLARE @Search_STR NVARCHAR(128) = ''

--	The pdef to be searched
--	Set to a specific pdef ID to search only one page
--	Set to 0 to return all pdef records
DECLARE @PdefID INT = 0


--	variables to help copy from pdef table to part table
DECLARE @PdefKey NVARCHAR(128) = ''
DECLARE @PdefName NVARCHAR(128) = ''

--	beginning / ending of content each part inside of ContentView string
DECLARE @PART_START_STR NVARCHAR(32) = '<Part ID='
DECLARE @PART_END_STR NVARCHAR(32) = '</Part>'

--	Table to hold all the pdefs that have parts containing @Search_STR
--	If @PdefID is set to non-zero value only that record will be returned
IF OBJECT_ID('tempdb..#Pdefs') IS NOT NULL DROP TABLE #Pdefs
SELECT 
	  pd.ID [pd_ID]
	, pd.[Key] [pd_key]
	, pd.Name [pd_name]
INTO #Pdefs
FROM tPageDefinition pd 
WHERE pd.ContentView LIKE '%' + @Search_STR + '%'
AND @PdefID IN(pd.ID, 0)
--SELECT * FROM #Pdefs


--	Table to hold each part pulled from 
--	delete temp table if it already exists
IF OBJECT_ID('tempdb..#Parts') IS NOT NULL DROP TABLE #Parts
CREATE TABLE #Parts (
	  Pdef_ID INT
	, Pdef_Key NVARCHAR(128)
	, Pdef_Name NVARCHAR(128)
	, Part_ID NVARCHAR(128)
	, Part_Key NVARCHAR(128)
	, Search_Str NVARCHAR(128)
	, Num_Instances_In_Part INT
	, Part_Str NVARCHAR(MAX)
)


--	loop through pdef records in table - delete each one as we go
WHILE (SELECT COUNT(*) FROM #Pdefs) > 0
BEGIN

	--	get the top pdef record from #Pdefs temp table, 
	--	pull out id, name, and key, then delete that row
	SET @PdefID = (SELECT TOP 1 [pd_ID] FROM #Pdefs)
	SET @PdefName = (SELECT TOP 1 [pd_key] FROM #Pdefs)
	SET @PdefKey = (SELECT TOP 1 [pd_name] FROM #Pdefs)
	
	DELETE FROM #Pdefs WHERE [pd_ID] = @PdefID

	--	Pull ContentView only once per loop
	DECLARE @ContentView NVARCHAR(MAX) = (
		SELECT pd.ContentView FROM tPageDefinition pd
		WHERE pd.ID = @PdefID
	)

	--	If search string isn't blank, check content view for search string 
	--	and bail out if it doesn't 
	IF (@Search_STR <> '' AND
		CHARINDEX(@Search_STR, @ContentView, 1) = 0)
	CONTINUE


	--	Get length of ContentView (and add one to offset 1-index issues)
	DECLARE @View_Len INT = LEN(@ContentView) + 1

	--	Get count of parts inside of the contentview
	--		replace part prefix with a blank string, 
	--		get the differernce in lengths
	--		divide the difference in lengths by length of prefix
	DECLARE @TotalParts INT = (
		SELECT (
			(@View_Len - LEN(REPLACE(@ContentView, @PART_START_STR, ''))) / LEN(@PART_START_STR))
		)
	
	--	Loop Stuff

	--	counts the number of loops
	--	Sets to number of parts found, and decrements with each iteration
	DECLARE @Part_Loop_INDEX INT = @TotalParts
	
	--	holds the current character index within the contentview
	DECLARE @View_STR_INDEX INT = 1
	
	--	START THE LOOP
	WHILE @Part_Loop_INDEX > 0
	BEGIN
	 
		--	Decrement loop counter
		SET @Part_Loop_INDEX = @Part_Loop_INDEX - 1

		--	Start looking for the next part at character index @View_STR_INDEX in the ContentView
		--	Will either be the end ending character index of the previous part (or 1)
		DECLARE @Part_StartIndex INT = CHARINDEX(@PART_START_STR, @ContentView, @View_STR_INDEX)
		DECLARE @Part_EndIndex INT = 
			CHARINDEX(@PART_END_STR, @ContentView, @Part_StartIndex) + LEN(@PART_END_STR)
		
		--	get string containing the whole part
		DECLARE @Part_STR NVARCHAR(MAX) = 
			SUBSTRING(@ContentView, @Part_StartIndex, @Part_EndIndex - @Part_StartIndex)

		--	Set string index to the end of the current part 
		--	Next loop will start looking for the next part at this index
		SET @View_STR_INDEX = @Part_EndIndex

		--	if search string is set, move to next part if current one doesn't have the search string
		IF ( (@Search_STR <> '') AND
			CHARINDEX(@Search_STR, @Part_STR, 1) = 0 )
			CONTINUE

		--	Set to -1 if returning all parts
		--	otherwise get number of instances of search string within each part
		DECLARE @Instances INT = 
			CASE WHEN @Search_STR = '' THEN -1
			ELSE (SELECT LEN(@Part_STR)-LEN(REPLACE(@Part_STR, @Search_STR,'')))/LEN(@Search_STR)
		END

		--	Find Part ID and Key inside Part String
		--	Starting chars of part are always '[2_Whitespace_Chars]<PartID="'
		DECLARE @PartID_StartIndex INT = 11
		
		--	Find index of next '"' 
		DECLARE @PartID_EndIndex INT = CHARINDEX('"', @Part_STR, @PartID_StartIndex)
		
		--	get the ID
		DECLARE @PartID_STR NVARCHAR(128) = 
			SUBSTRING(@Part_STR, @PartID_StartIndex, @PartID_EndIndex - @PartID_StartIndex)

		--	Key always follows PartID with '" Key="'
		DECLARE @PartKey_StartIndex INT = @PartID_EndIndex + LEN('" Key="')
		
		--Find index of next '"'
		DECLARE @PartKey_EndIndex INT = CHARINDEX('"', @Part_STR, @PartKey_StartIndex)
		
		--	get the key
		DECLARE @PartKey_STR NVARCHAR(128) = 
			SUBSTRING(@Part_STR, @PartKey_StartIndex, @PartKey_EndIndex - @PartKey_StartIndex)
			
		--	Add record to parts table
		INSERT INTO #Parts
		SELECT
			  @PdefID
			, @PdefKey
			, @PdefName
			, @PartID_STR [@PartID_STR ]
			, @PartKey_STR [@PartKey_STR]
			, @Search_STR
			, @Instances
			, @Part_STR

	END	--	End part loop

END --	end pdef loop

--	Display all parts found, or an error message if none found
IF (SELECT COUNT(*) FROM #Parts) > 0
BEGIN
	SELECT * FROM #Parts
	ORDER BY PDEF_ID, PART_ID
END

ELSE 
BEGIN
	SELECT 'No Instances Found' [404]
END

DROP TABLE #Parts
DROP TABLE #Pdefs

--	This is a WIP - not fully tested
--	The idea is that if a string from a screenshot is translated,
--		this query would pick that up and return the corresponding
--		translation resource to help with searching for it

--	Attempt to match search string to translation resource
--	Will print out a message if match is found
DECLARE @Translation_STR NVARCHAR(128) = (
	ISNULL(
		(	SELECT TOP 1 ri.[Key] FROM tResourceTranslation rt
			LEFT JOIN tResourceItem ri ON ri.ID = rt.ResourceItemID
			WHERE 
				ri.[Key] LIKE '%' + @Search_STR + '%'
				OR ri.DefaultValue LIKE '%' + @Search_STR + '%'
				OR rt.Value LIKE '%' + @Search_STR + '%'
		), '')
)
-- SELECT @Translation_STR [@Translation_STR]

--	Display message if search string was a resx key, value, or default value
IF (@Translation_STR <> '' AND @Search_STR <> '') 
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