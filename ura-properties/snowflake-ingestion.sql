DROP 
  TABLE URA_PRIVATE;
  
CREATE TABLE URA_PRIVATE (
  MONTH date, STREET varchar, PROJECT varchar, 
  MARKET_SEGMENT varchar, LATITUDE float, 
  LONGITUDE float, AREA float, FLOOR_RANGE varchar, 
  NO_OF_UNITS int, TYPE_OF_SALE varchar, 
  PRICE float, PROPERTY_TYPE varchar, 
  DISTRICT varchar, TYPE_OF_AREA varchar, 
  TENURE varchar, NETT_PRICE float
) CLUSTER BY (MONTH);

TRUNCATE TABLE URA_PRIVATE;

COPY INTO URA_PRIVATE 
FROM 
  (
    SELECT 
      (
        regexp_extract_all(
          METADATA$FILENAME, '\\d{4}\\-\\d{2}-\\d{2}'
        ) [0]
      ):: DATE, 
      $1 : street :: VARCHAR, 
      $1 : project :: VARCHAR, 
      $1 : marketSegment :: VARCHAR, 
      $1 : latitude :: DOUBLE, 
      $1 : longitude :: DOUBLE, 
      $1 : area :: DOUBLE, 
      $1 : floorRange :: VARCHAR, 
      $1 : noOfUnits :: INTEGER, 
      $1 : typeOfSale :: VARCHAR, 
      $1 : price :: DOUBLE, 
      $1 : propertyType :: VARCHAR, 
      $1 : district :: VARCHAR, 
      $1 : typeOfArea :: VARCHAR, 
      $1 : tenure :: VARCHAR, 
      $1 : nettPrice :: DOUBLE 
    FROM 
      @URA_S3_STAGE
  ) file_format = (type = parquet);
  
select 
  * 
from 
  URA_PRIVATE 
limit 
  100;
