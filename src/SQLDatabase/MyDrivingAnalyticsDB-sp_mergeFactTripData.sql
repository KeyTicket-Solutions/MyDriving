/****** Object:  StoredProcedure [dbo].[sp_mergeFactTripData]    Script Date: 3/21/2016 8:40:50 PM ******/
CREATE PROCEDURE [dbo].[sp_mergeFactTripData] 
AS
BEGIN
	SET NOCOUNT ON;
DECLARE @userCount int;
DECLARE @userTable table(
 userId nvarchar(100) NOT NULL,
 vin nvarchar(20)
);
DECLARE @vinTable table(
  vin nvarchar(20)
);

INSERT INTO @vinTable
 SELECT distinct x.vin 
		FROM dbo.factTripDataTemp x 
		WHERE x.vin IS NOT NULL
		AND x.vin != ''
		AND vin != '-255'
		AND x.vin NOT IN (SELECT 
			                 distinct vinNum 
							 FROM dbo.dimVinLookup);

	DECLARE @vinCount int;
	SELECT @vinCount = COUNT(*) FROM @vinTable;

IF (@vinCount > 0)
 BEGIN
   INSERT INTO dbo.dimVinLookup 
   SELECT distinct vin, 'Unknown','Unknown',1995,'Unknown' 
   from dbo.factTripDataTemp
   WHERE vin IS NOT NULL 
		AND vin != ''
		AND vin != '-255'
		AND vin not in (SELECT distinct vinNum from dbo.dimVinLookup);
 END

INSERT INTO @userTable
SELECT distinct userId, vin from dbo.factTripDataTemp x 
WHERE userId IS NOT NULL
AND userId != ''
AND userID != '-255'
AND vin IS NOT NULL
AND vin != ''
AND vin != '-255'
AND CONCAT(x.userId,'_',x.vin) not in (SELECT distinct CONCAT(userId,'_',vin) FROM dbo.dimUser);

SELECT @userCount = count(*)
FROM @userTable;

IF (@userCount > 0)
 BEGIN
   INSERT INTO dbo.dimUser (userId, vin)
   SELECT *
   FROM @userTable;
 END

INSERT INTO dbo.factTripData
SELECT distinct
	a.tripId,
	a.userId,
	a.vin,
	a.tripStartTime,
	b.driverType,
	a.AverageSpeed,
	a.Hard_Accel,
	a.Hard_Brakes,
	a.DroveWithMILOn,
	a.LengthOfTrip,
	a.cLat,
	a.cLon 
FROM dbo.factTripDataTemp a JOIN dbo.factMLOutputData b
ON a.tripId = b.tripId AND a.userId = b.userId
WHERE a.tripId is not null
AND a.userId is not null
AND a.userId != ''
AND a.userID != '-255'
AND a.vin IS NOT NULL
AND a.vin != ''
AND a.vin != '-255'
AND CONCAT(a.userId,'_',a.vin) IN (SELECT distinct CONCAT(userId,'_',vin) FROM dbo.dimUser)
AND a.vin IN (SELECT distinct vinNum from dbo.dimVinLookup)
AND b.driverType is not NULL
AND a.tripId not in (SELECT distinct tripId from dbo.factTripData);

END
