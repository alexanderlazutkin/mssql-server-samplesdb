CREATE SCHEMA IF NOT EXISTS dbo;

CREATE TABLE IF NOT EXISTS dbo."AdventureWorksDWBuildVersion" (
    "DBVersion" VARCHAR,
    "VersionDate" TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dbo."DatabaseLog" (
    "DatabaseLogID" INTEGER NOT NULL,
    "PostTime" TIMESTAMP NOT NULL,
    "DatabaseUser" VARCHAR NOT NULL,
    "Event" VARCHAR NOT NULL,
    "Schema" VARCHAR,
    "Object" VARCHAR,
    "TSQL" VARCHAR NOT NULL,
    "XmlEvent" VARCHAR NOT NULL,
    PRIMARY KEY ("DatabaseLogID")
);

CREATE TABLE IF NOT EXISTS dbo."DimAccount" (
    "AccountKey" INTEGER NOT NULL,
    "ParentAccountKey" INTEGER,
    "AccountCodeAlternateKey" INTEGER,
    "ParentAccountCodeAlternateKey" INTEGER,
    "AccountDescription" VARCHAR,
    "AccountType" VARCHAR,
    "Operator" VARCHAR,
    "CustomMembers" VARCHAR,
    "ValueType" VARCHAR,
    "CustomMemberOptions" VARCHAR,
    PRIMARY KEY ("AccountKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimCurrency" (
    "CurrencyKey" INTEGER NOT NULL,
    "CurrencyAlternateKey" VARCHAR NOT NULL,
    "CurrencyName" VARCHAR NOT NULL,
    PRIMARY KEY ("CurrencyKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimCustomer" (
    "CustomerKey" INTEGER NOT NULL,
    "GeographyKey" INTEGER,
    "CustomerAlternateKey" VARCHAR NOT NULL,
    "Title" VARCHAR,
    "FirstName" VARCHAR,
    "MiddleName" VARCHAR,
    "LastName" VARCHAR,
    "NameStyle" BOOLEAN,
    "BirthDate" DATE,
    "MaritalStatus" VARCHAR,
    "Suffix" VARCHAR,
    "Gender" VARCHAR,
    "EmailAddress" VARCHAR,
    "YearlyIncome" DECIMAL(19,4),
    "TotalChildren" INTEGER,
    "NumberChildrenAtHome" INTEGER,
    "EnglishEducation" VARCHAR,
    "SpanishEducation" VARCHAR,
    "FrenchEducation" VARCHAR,
    "EnglishOccupation" VARCHAR,
    "SpanishOccupation" VARCHAR,
    "FrenchOccupation" VARCHAR,
    "HouseOwnerFlag" VARCHAR,
    "NumberCarsOwned" INTEGER,
    "AddressLine1" VARCHAR,
    "AddressLine2" VARCHAR,
    "Phone" VARCHAR,
    "DateFirstPurchase" DATE,
    "CommuteDistance" VARCHAR,
    PRIMARY KEY ("CustomerKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimDate" (
    "DateKey" INTEGER NOT NULL,
    "FullDateAlternateKey" DATE NOT NULL,
    "DayNumberOfWeek" INTEGER NOT NULL,
    "EnglishDayNameOfWeek" VARCHAR NOT NULL,
    "SpanishDayNameOfWeek" VARCHAR NOT NULL,
    "FrenchDayNameOfWeek" VARCHAR NOT NULL,
    "DayNumberOfMonth" INTEGER NOT NULL,
    "DayNumberOfYear" INTEGER NOT NULL,
    "WeekNumberOfYear" INTEGER NOT NULL,
    "EnglishMonthName" VARCHAR NOT NULL,
    "SpanishMonthName" VARCHAR NOT NULL,
    "FrenchMonthName" VARCHAR NOT NULL,
    "MonthNumberOfYear" INTEGER NOT NULL,
    "CalendarQuarter" INTEGER NOT NULL,
    "CalendarYear" INTEGER NOT NULL,
    "CalendarSemester" INTEGER NOT NULL,
    "FiscalQuarter" INTEGER NOT NULL,
    "FiscalYear" INTEGER NOT NULL,
    "FiscalSemester" INTEGER NOT NULL,
    PRIMARY KEY ("DateKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimDepartmentGroup" (
    "DepartmentGroupKey" INTEGER NOT NULL,
    "ParentDepartmentGroupKey" INTEGER,
    "DepartmentGroupName" VARCHAR,
    PRIMARY KEY ("DepartmentGroupKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimEmployee" (
    "EmployeeKey" INTEGER NOT NULL,
    "ParentEmployeeKey" INTEGER,
    "EmployeeNationalIDAlternateKey" VARCHAR,
    "ParentEmployeeNationalIDAlternateKey" VARCHAR,
    "SalesTerritoryKey" INTEGER,
    "FirstName" VARCHAR NOT NULL,
    "LastName" VARCHAR NOT NULL,
    "MiddleName" VARCHAR,
    "NameStyle" BOOLEAN NOT NULL,
    "Title" VARCHAR,
    "HireDate" DATE,
    "BirthDate" DATE,
    "LoginID" VARCHAR,
    "EmailAddress" VARCHAR,
    "Phone" VARCHAR,
    "MaritalStatus" VARCHAR,
    "EmergencyContactName" VARCHAR,
    "EmergencyContactPhone" VARCHAR,
    "SalariedFlag" BOOLEAN,
    "Gender" VARCHAR,
    "PayFrequency" INTEGER,
    "BaseRate" DECIMAL(19,4),
    "VacationHours" INTEGER,
    "SickLeaveHours" INTEGER,
    "CurrentFlag" BOOLEAN NOT NULL,
    "SalesPersonFlag" BOOLEAN NOT NULL,
    "DepartmentName" VARCHAR,
    "StartDate" DATE,
    "EndDate" DATE,
    "Status" VARCHAR,
    "EmployeePhoto" VARCHAR,
    PRIMARY KEY ("EmployeeKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimGeography" (
    "GeographyKey" INTEGER NOT NULL,
    "City" VARCHAR,
    "StateProvinceCode" VARCHAR,
    "StateProvinceName" VARCHAR,
    "CountryRegionCode" VARCHAR,
    "EnglishCountryRegionName" VARCHAR,
    "SpanishCountryRegionName" VARCHAR,
    "FrenchCountryRegionName" VARCHAR,
    "PostalCode" VARCHAR,
    "SalesTerritoryKey" INTEGER,
    "IpAddressLocator" VARCHAR,
    PRIMARY KEY ("GeographyKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimOrganization" (
    "OrganizationKey" INTEGER NOT NULL,
    "ParentOrganizationKey" INTEGER,
    "PercentageOfOwnership" VARCHAR,
    "OrganizationName" VARCHAR,
    "CurrencyKey" INTEGER,
    PRIMARY KEY ("OrganizationKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimProduct" (
    "ProductKey" INTEGER NOT NULL,
    "ProductAlternateKey" VARCHAR,
    "ProductSubcategoryKey" INTEGER,
    "WeightUnitMeasureCode" VARCHAR,
    "SizeUnitMeasureCode" VARCHAR,
    "EnglishProductName" VARCHAR NOT NULL,
    "SpanishProductName" VARCHAR NOT NULL,
    "FrenchProductName" VARCHAR NOT NULL,
    "StandardCost" DECIMAL(19,4),
    "FinishedGoodsFlag" BOOLEAN NOT NULL,
    "Color" VARCHAR NOT NULL,
    "SafetyStockLevel" INTEGER,
    "ReorderPoint" INTEGER,
    "ListPrice" DECIMAL(19,4),
    "Size" VARCHAR,
    "SizeRange" VARCHAR,
    "Weight" DOUBLE,
    "DaysToManufacture" INTEGER,
    "ProductLine" VARCHAR,
    "DealerPrice" DECIMAL(19,4),
    "Class" VARCHAR,
    "Style" VARCHAR,
    "ModelName" VARCHAR,
    "LargePhoto" VARCHAR,
    "EnglishDescription" VARCHAR,
    "FrenchDescription" VARCHAR,
    "ChineseDescription" VARCHAR,
    "ArabicDescription" VARCHAR,
    "HebrewDescription" VARCHAR,
    "ThaiDescription" VARCHAR,
    "GermanDescription" VARCHAR,
    "JapaneseDescription" VARCHAR,
    "TurkishDescription" VARCHAR,
    "StartDate" TIMESTAMP,
    "EndDate" TIMESTAMP,
    "Status" VARCHAR,
    PRIMARY KEY ("ProductKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimProductCategory" (
    "ProductCategoryKey" INTEGER NOT NULL,
    "ProductCategoryAlternateKey" INTEGER,
    "EnglishProductCategoryName" VARCHAR NOT NULL,
    "SpanishProductCategoryName" VARCHAR NOT NULL,
    "FrenchProductCategoryName" VARCHAR NOT NULL,
    PRIMARY KEY ("ProductCategoryKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimProductSubcategory" (
    "ProductSubcategoryKey" INTEGER NOT NULL,
    "ProductSubcategoryAlternateKey" INTEGER,
    "EnglishProductSubcategoryName" VARCHAR NOT NULL,
    "SpanishProductSubcategoryName" VARCHAR NOT NULL,
    "FrenchProductSubcategoryName" VARCHAR NOT NULL,
    "ProductCategoryKey" INTEGER,
    PRIMARY KEY ("ProductSubcategoryKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimPromotion" (
    "PromotionKey" INTEGER NOT NULL,
    "PromotionAlternateKey" INTEGER,
    "EnglishPromotionName" VARCHAR,
    "SpanishPromotionName" VARCHAR,
    "FrenchPromotionName" VARCHAR,
    "DiscountPct" DOUBLE,
    "EnglishPromotionType" VARCHAR,
    "SpanishPromotionType" VARCHAR,
    "FrenchPromotionType" VARCHAR,
    "EnglishPromotionCategory" VARCHAR,
    "SpanishPromotionCategory" VARCHAR,
    "FrenchPromotionCategory" VARCHAR,
    "StartDate" TIMESTAMP NOT NULL,
    "EndDate" TIMESTAMP,
    "MinQty" INTEGER,
    "MaxQty" INTEGER,
    PRIMARY KEY ("PromotionKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimReseller" (
    "ResellerKey" INTEGER NOT NULL,
    "GeographyKey" INTEGER,
    "ResellerAlternateKey" VARCHAR,
    "Phone" VARCHAR,
    "BusinessType" VARCHAR NOT NULL,
    "ResellerName" VARCHAR NOT NULL,
    "NumberEmployees" INTEGER,
    "OrderFrequency" VARCHAR,
    "OrderMonth" INTEGER,
    "FirstOrderYear" INTEGER,
    "LastOrderYear" INTEGER,
    "ProductLine" VARCHAR,
    "AddressLine1" VARCHAR,
    "AddressLine2" VARCHAR,
    "AnnualSales" DECIMAL(19,4),
    "BankName" VARCHAR,
    "MinPaymentType" INTEGER,
    "MinPaymentAmount" DECIMAL(19,4),
    "AnnualRevenue" DECIMAL(19,4),
    "YearOpened" INTEGER,
    PRIMARY KEY ("ResellerKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimSalesReason" (
    "SalesReasonKey" INTEGER NOT NULL,
    "SalesReasonAlternateKey" INTEGER NOT NULL,
    "SalesReasonName" VARCHAR NOT NULL,
    "SalesReasonReasonType" VARCHAR NOT NULL,
    PRIMARY KEY ("SalesReasonKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimSalesTerritory" (
    "SalesTerritoryKey" INTEGER NOT NULL,
    "SalesTerritoryAlternateKey" INTEGER,
    "SalesTerritoryRegion" VARCHAR NOT NULL,
    "SalesTerritoryCountry" VARCHAR NOT NULL,
    "SalesTerritoryGroup" VARCHAR,
    "SalesTerritoryImage" VARCHAR,
    PRIMARY KEY ("SalesTerritoryKey")
);

CREATE TABLE IF NOT EXISTS dbo."DimScenario" (
    "ScenarioKey" INTEGER NOT NULL,
    "ScenarioName" VARCHAR,
    PRIMARY KEY ("ScenarioKey")
);

CREATE TABLE IF NOT EXISTS dbo."FactAdditionalInternationalProductDescription" (
    "ProductKey" INTEGER NOT NULL,
    "CultureName" VARCHAR NOT NULL,
    "ProductDescription" VARCHAR NOT NULL,
    PRIMARY KEY ("ProductKey", "CultureName")
);

CREATE TABLE IF NOT EXISTS dbo."FactCallCenter" (
    "FactCallCenterID" INTEGER NOT NULL,
    "DateKey" INTEGER NOT NULL,
    "WageType" VARCHAR NOT NULL,
    "Shift" VARCHAR NOT NULL,
    "LevelOneOperators" INTEGER NOT NULL,
    "LevelTwoOperators" INTEGER NOT NULL,
    "TotalOperators" INTEGER NOT NULL,
    "Calls" INTEGER NOT NULL,
    "AutomaticResponses" INTEGER NOT NULL,
    "Orders" INTEGER NOT NULL,
    "IssuesRaised" INTEGER NOT NULL,
    "AverageTimePerIssue" INTEGER NOT NULL,
    "ServiceGrade" DOUBLE NOT NULL,
    "Date" TIMESTAMP,
    PRIMARY KEY ("FactCallCenterID")
);

CREATE TABLE IF NOT EXISTS dbo."FactCurrencyRate" (
    "CurrencyKey" INTEGER NOT NULL,
    "DateKey" INTEGER NOT NULL,
    "AverageRate" DOUBLE NOT NULL,
    "EndOfDayRate" DOUBLE NOT NULL,
    "Date" TIMESTAMP,
    PRIMARY KEY ("CurrencyKey", "DateKey")
);

CREATE TABLE IF NOT EXISTS dbo."FactFinance" (
    "FinanceKey" INTEGER NOT NULL,
    "DateKey" INTEGER NOT NULL,
    "OrganizationKey" INTEGER NOT NULL,
    "DepartmentGroupKey" INTEGER NOT NULL,
    "ScenarioKey" INTEGER NOT NULL,
    "AccountKey" INTEGER NOT NULL,
    "Amount" DOUBLE NOT NULL,
    "Date" TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dbo."FactInternetSales" (
    "ProductKey" INTEGER NOT NULL,
    "OrderDateKey" INTEGER NOT NULL,
    "DueDateKey" INTEGER NOT NULL,
    "ShipDateKey" INTEGER NOT NULL,
    "CustomerKey" INTEGER NOT NULL,
    "PromotionKey" INTEGER NOT NULL,
    "CurrencyKey" INTEGER NOT NULL,
    "SalesTerritoryKey" INTEGER NOT NULL,
    "SalesOrderNumber" VARCHAR NOT NULL,
    "SalesOrderLineNumber" INTEGER NOT NULL,
    "RevisionNumber" INTEGER NOT NULL,
    "OrderQuantity" INTEGER NOT NULL,
    "UnitPrice" DECIMAL(19,4) NOT NULL,
    "ExtendedAmount" DECIMAL(19,4) NOT NULL,
    "UnitPriceDiscountPct" DOUBLE NOT NULL,
    "DiscountAmount" DOUBLE NOT NULL,
    "ProductStandardCost" DECIMAL(19,4) NOT NULL,
    "TotalProductCost" DECIMAL(19,4) NOT NULL,
    "SalesAmount" DECIMAL(19,4) NOT NULL,
    "TaxAmt" DECIMAL(19,4) NOT NULL,
    "Freight" DECIMAL(19,4) NOT NULL,
    "CarrierTrackingNumber" VARCHAR,
    "CustomerPONumber" VARCHAR,
    "OrderDate" TIMESTAMP,
    "DueDate" TIMESTAMP,
    "ShipDate" TIMESTAMP,
    PRIMARY KEY ("SalesOrderNumber", "SalesOrderLineNumber")
);

CREATE TABLE IF NOT EXISTS dbo."FactInternetSalesReason" (
    "SalesOrderNumber" VARCHAR NOT NULL,
    "SalesOrderLineNumber" INTEGER NOT NULL,
    "SalesReasonKey" INTEGER NOT NULL,
    PRIMARY KEY ("SalesOrderNumber", "SalesOrderLineNumber", "SalesReasonKey")
);

CREATE TABLE IF NOT EXISTS dbo."FactProductInventory" (
    "ProductKey" INTEGER NOT NULL,
    "DateKey" INTEGER NOT NULL,
    "MovementDate" DATE NOT NULL,
    "UnitCost" DECIMAL(19,4) NOT NULL,
    "UnitsIn" INTEGER NOT NULL,
    "UnitsOut" INTEGER NOT NULL,
    "UnitsBalance" INTEGER NOT NULL,
    PRIMARY KEY ("ProductKey", "DateKey")
);

CREATE TABLE IF NOT EXISTS dbo."FactResellerSales" (
    "ProductKey" INTEGER NOT NULL,
    "OrderDateKey" INTEGER NOT NULL,
    "DueDateKey" INTEGER NOT NULL,
    "ShipDateKey" INTEGER NOT NULL,
    "ResellerKey" INTEGER NOT NULL,
    "EmployeeKey" INTEGER NOT NULL,
    "PromotionKey" INTEGER NOT NULL,
    "CurrencyKey" INTEGER NOT NULL,
    "SalesTerritoryKey" INTEGER NOT NULL,
    "SalesOrderNumber" VARCHAR NOT NULL,
    "SalesOrderLineNumber" INTEGER NOT NULL,
    "RevisionNumber" INTEGER,
    "OrderQuantity" INTEGER,
    "UnitPrice" DECIMAL(19,4),
    "ExtendedAmount" DECIMAL(19,4),
    "UnitPriceDiscountPct" DOUBLE,
    "DiscountAmount" DOUBLE,
    "ProductStandardCost" DECIMAL(19,4),
    "TotalProductCost" DECIMAL(19,4),
    "SalesAmount" DECIMAL(19,4),
    "TaxAmt" DECIMAL(19,4),
    "Freight" DECIMAL(19,4),
    "CarrierTrackingNumber" VARCHAR,
    "CustomerPONumber" VARCHAR,
    "OrderDate" TIMESTAMP,
    "DueDate" TIMESTAMP,
    "ShipDate" TIMESTAMP,
    PRIMARY KEY ("SalesOrderNumber", "SalesOrderLineNumber")
);

CREATE TABLE IF NOT EXISTS dbo."FactSalesQuota" (
    "SalesQuotaKey" INTEGER NOT NULL,
    "EmployeeKey" INTEGER NOT NULL,
    "DateKey" INTEGER NOT NULL,
    "CalendarYear" INTEGER NOT NULL,
    "CalendarQuarter" INTEGER NOT NULL,
    "SalesAmountQuota" DECIMAL(19,4) NOT NULL,
    "Date" TIMESTAMP,
    PRIMARY KEY ("SalesQuotaKey")
);

CREATE TABLE IF NOT EXISTS dbo."FactSurveyResponse" (
    "SurveyResponseKey" INTEGER NOT NULL,
    "DateKey" INTEGER NOT NULL,
    "CustomerKey" INTEGER NOT NULL,
    "ProductCategoryKey" INTEGER NOT NULL,
    "EnglishProductCategoryName" VARCHAR NOT NULL,
    "ProductSubcategoryKey" INTEGER NOT NULL,
    "EnglishProductSubcategoryName" VARCHAR NOT NULL,
    "Date" TIMESTAMP,
    PRIMARY KEY ("SurveyResponseKey")
);

CREATE TABLE IF NOT EXISTS dbo."NewFactCurrencyRate" (
    "AverageRate" FLOAT,
    "CurrencyID" VARCHAR,
    "CurrencyDate" DATE,
    "EndOfDayRate" FLOAT,
    "CurrencyKey" INTEGER,
    "DateKey" INTEGER
);

CREATE TABLE IF NOT EXISTS dbo."ProspectiveBuyer" (
    "ProspectiveBuyerKey" INTEGER NOT NULL,
    "ProspectAlternateKey" VARCHAR,
    "FirstName" VARCHAR,
    "MiddleName" VARCHAR,
    "LastName" VARCHAR,
    "BirthDate" TIMESTAMP,
    "MaritalStatus" VARCHAR,
    "Gender" VARCHAR,
    "EmailAddress" VARCHAR,
    "YearlyIncome" DECIMAL(19,4),
    "TotalChildren" INTEGER,
    "NumberChildrenAtHome" INTEGER,
    "Education" VARCHAR,
    "Occupation" VARCHAR,
    "HouseOwnerFlag" VARCHAR,
    "NumberCarsOwned" INTEGER,
    "AddressLine1" VARCHAR,
    "AddressLine2" VARCHAR,
    "City" VARCHAR,
    "StateProvinceCode" VARCHAR,
    "PostalCode" VARCHAR,
    "Phone" VARCHAR,
    "Salutation" VARCHAR,
    "Unknown" INTEGER,
    PRIMARY KEY ("ProspectiveBuyerKey")
);
