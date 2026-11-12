-- Archway Performance Datamart | T01-T53 | Azure Databricks / Unity Catalog
-- Column contract M53_20261006_01. Design package prepared 2026-11-12.
-- ER/Studio SQL file import. The model schema gold stands for one customer Gold schema.
-- Archived column observation 2026-10-18; archived key observation 2026-10-31.
-- Table structures and named informational PKs only; storage properties are outside this model.
-- ERD edition. Nine proposed FK lines visualize explicit version references in control.dm_join.
-- The catalog snapshot recorded zero FKs. The optional lines are for modeling only.
-- All 211 logical joins are described in Gold53_Relationships.csv and the logical XMI.
-- The Archway_Gold53_Physical.sql edition reproduces only the observed keys.

-- T01 / G01 / Core v5
-- Calendar, fiscal dates, breakpoint and reporting-window flags.
-- Proposed business / merge key: SourceEnvironmentCode, DateKey
CREATE TABLE `gold`.`dim_date` (
    `DateKey` DATE NOT NULL COMMENT 'Calendar date — primary join key for all facts',
    `CalendarYear` INT NOT NULL COMMENT '4-digit year',
    `CalendarQuarter` SMALLINT NOT NULL COMMENT '1-4',
    `CalendarMonth` SMALLINT NOT NULL COMMENT '1-12',
    `MonthName` STRING NOT NULL COMMENT 'January…December',
    `FiscalYear` INT NOT NULL COMMENT 'Fiscal year (may differ from calendar)',
    `FiscalQuarter` SMALLINT NOT NULL COMMENT 'Fiscal quarter 1-4',
    `FiscalMonth` SMALLINT NOT NULL COMMENT 'Fiscal month 1-12',
    `IsBusinessDay` BOOLEAN NOT NULL COMMENT '1 if trading/business day',
    `IsMonthEnd` BOOLEAN NOT NULL COMMENT '1 if last business day of month',
    `IsQuarterEnd` BOOLEAN NOT NULL COMMENT '1 if last business day of quarter',
    `IsYearEnd` BOOLEAN NOT NULL COMMENT '1 if last business day of year',
    `IsBreakpointDate` BOOLEAN NOT NULL COMMENT '1 if this date is a performance period breakpoint for any fund',
    `IsBalanceForward` BOOLEAN NOT NULL COMMENT '1 if this date is a balance-forward (DHU) breakpoint',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_date_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T02 / G03 / Core v5
-- Tenant identity, partition and feature switches.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID
CREATE TABLE `gold`.`dim_customer` (
    `CustomerID` INT NOT NULL COMMENT 'Tenant identifier',
    `CustomerName` STRING NOT NULL COMMENT 'Customer display name',
    `CustomerStatus` STRING NOT NULL COMMENT 'Active / Inactive',
    `PartitionNumberF3` SMALLINT NOT NULL COMMENT 'Pre-resolved fn_GetFACT3PartitionNumber result — avoid function call per query',
    `PartitionNumberF2` SMALLINT NOT NULL COMMENT 'Pre-resolved fn_GetFACT2PartitionNumber result',
    `LongShortNettingEnabled` BOOLEAN NOT NULL COMMENT 'fn_AllowDWCustomerAccess(\'WHLongShortNetting\') result — cached',
    `WHConvertedToV2` BOOLEAN NOT NULL COMMENT 'fn_AllowDWCustomerAccess(\'WHConverted\') — uses V2 warehouse tables vs legacy',
    `AllowDailySecPerf` BOOLEAN NOT NULL COMMENT 'fn_AllowDWCustomerAccess(\'factDailySecurityPerformance\') — main load gate',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_customer_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T03 / G02 / Core v5
-- Effective-dated fund and reporting-currency master.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, ValidFrom
CREATE TABLE `gold`.`dim_fund` (
    `FundID` INT NOT NULL COMMENT 'Source Fund.FundID',
    `FundName` STRING NOT NULL COMMENT 'Fund display name',
    `FundCurrency` STRING NOT NULL COMMENT 'Base/reporting currency. SCD2 because historical calcs use currency in effect at the time',
    `FundType` STRING COMMENT 'LP / Corporation / Trust / SMA / Other',
    `InceptionDate` DATE COMMENT 'Fund inception date — drives ITD calculation',
    `ManagerName` STRING COMMENT 'Investment manager name',
    `CustomerID` INT NOT NULL COMMENT 'Tenant identifier',
    `IsActive` BOOLEAN NOT NULL COMMENT '0 = inactive / archived fund',
    `WHLockedDate` DATE COMMENT 'Warehouse-locked date. Standard loader will not overwrite data on or before this date',
    `ValidFrom` DATE NOT NULL COMMENT 'Effective start date of this SCD2 record',
    `ValidTo` DATE COMMENT 'Effective end date; NULL = current record',
    `IsCurrent` BOOLEAN NOT NULL COMMENT '1 = current active record',
    `SourceAuditDate` TIMESTAMP_NTZ COMMENT 'Source-system audit timestamp used for change detection and lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ObservedAtUtc` TIMESTAMP NOT NULL COMMENT 'When the warehouse observed this version/correction, separate from business validity.',
    CONSTRAINT `dim_fund_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T04 / G03 / Core v5
-- Effective-dated security master and financial attributes.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SecurityID, ValidFrom
CREATE TABLE `gold`.`dim_security` (
    `SecurityID` INT NOT NULL COMMENT 'Source Security.SecurityID',
    `SecurityName` STRING NOT NULL COMMENT 'Display name',
    `Ticker` STRING COMMENT 'Exchange ticker symbol',
    `ISIN` STRING COMMENT 'ISIN identifier',
    `CUSIP` STRING COMMENT 'CUSIP identifier',
    `AssetClass` STRING COMMENT 'Asset class (Equity, Fixed Income, etc.)',
    `SecurityTypeID` INT COMMENT 'Security type foreign key. SCD2 tracked.',
    `SecurityMultiplier` DECIMAL(18,6) NOT NULL COMMENT 'Price multiplier (e.g. bond face value factor). Critical for all price × quantity calculations.',
    `NotionalValue` BOOLEAN NOT NULL COMMENT '1 if this is a notional (synthetic) security for FK_NotionalPerfSecurityID linkage',
    `IsPrivateEquity` BOOLEAN NOT NULL COMMENT '1 if PE security (SecurityClass.FK_GroupID=800297). Drives DHU/PE pipeline separation.',
    `CashOrCashEquivalent` BOOLEAN NOT NULL COMMENT '1 if this security should be suppressed under @SuppressCashEquivalent flag in reporting',
    `CustomerID` INT NOT NULL COMMENT 'Tenant identifier',
    `ValidFrom` DATE NOT NULL COMMENT 'SCD2 effective start',
    `ValidTo` DATE COMMENT 'SCD2 effective end; NULL=current',
    `IsCurrent` BOOLEAN NOT NULL COMMENT '1=current record',
    `SourceAuditDate` TIMESTAMP_NTZ COMMENT 'Source-system audit timestamp used for change detection and lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ObservedAtUtc` TIMESTAMP NOT NULL COMMENT 'When the warehouse observed this version/correction, separate from business validity.',
    CONSTRAINT `dim_security_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T05 / G02 / Core v5
-- Fund performance breakpoint and prior breakpoint dates.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, BreakpointID
CREATE TABLE `gold`.`dim_breakpoint` (
    `BreakpointID` INT NOT NULL COMMENT 'Surrogate key',
    `FundID` INT NOT NULL COMMENT 'Fund this breakpoint belongs to',
    `BreakpointDate` DATE NOT NULL COMMENT 'Period end date / boundary date',
    `PriorBreakpointDate` DATE COMMENT 'The preceding breakpoint date (NULL for first breakpoint)',
    `BreakpointStartDate` DATE COMMENT 'Day after PriorBreakpointDate = start of this period',
    `IsRevertible` BOOLEAN NOT NULL COMMENT '1 if this is a Go-Forward period breakpoint',
    `IsBalanceForward` BOOLEAN NOT NULL COMMENT '1 if this is a DHU (balance-forward) breakpoint',
    `IsInception` BOOLEAN NOT NULL COMMENT '1 if this is the very first breakpoint (inception)',
    `RowNumAsc` INT NOT NULL COMMENT 'Row number oldest-to-newest within fund',
    `RowNumDesc` INT NOT NULL COMMENT 'Row number newest-to-oldest. RowNumDesc=1 = most recent (used in DHU purge).',
    `CustomerID` INT COMMENT 'Archway customer/tenant identifier.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_breakpoint_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T06 / G01 / Core v5
-- Conformed currency reference.
-- Proposed business / merge key: SourceEnvironmentCode, CurrencyCode
CREATE TABLE `gold`.`dim_currency` (
    `CurrencyCode` STRING NOT NULL COMMENT 'ISO currency code (USD, EUR, GBP, etc.)',
    `CurrencyName` STRING COMMENT 'Full currency name',
    `Region` STRING COMMENT 'Geographic region',
    `IsBaseCurrency` BOOLEAN NOT NULL COMMENT '1 if this is the system base/reporting currency',
    `DecimalPlaces` SMALLINT NOT NULL COMMENT 'Standard decimal places for formatting',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_currency_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T07 / G02 / Core v5
-- Fund chart of accounts for ownership and activity classification.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, COAID, ValidFrom
CREATE TABLE `gold`.`dim_chart_of_accounts` (
    `COAID` INT NOT NULL COMMENT 'Source ChartOfAccounts.COAID. -1 = no COA sentinel',
    `COAAccountCode` STRING NOT NULL COMMENT 'Account code string',
    `AccountType` SMALLINT NOT NULL COMMENT '1=Asset, 2=Liability, 3=Equity, 4=Income, 5=Expense. The most important attribute — drives ALL GL classification logic',
    `AccountName` STRING COMMENT 'Account display name',
    `FundID` INT NOT NULL COMMENT 'Account belongs to this fund',
    `NetOfFeesReporting` BOOLEAN NOT NULL COMMENT '1 = this account participates in net-of-fees performance (uproc_...NetOfFees)',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `IsActive` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether active applies.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ValidFrom` TIMESTAMP_NTZ NOT NULL COMMENT 'Business-effective start; do not replace with load time.',
    `ValidTo` TIMESTAMP_NTZ COMMENT 'Exclusive end of this effective version; NULL means open-ended only when policy allows.',
    `IsCurrent` BOOLEAN NOT NULL COMMENT 'Current effective version marker; historical joins still use observation-time intervals.',
    `ObservedAtUtc` TIMESTAMP NOT NULL COMMENT 'When the warehouse observed this version/correction, separate from business validity.',
    CONSTRAINT `dim_chart_of_accounts_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T08 / G01 / Core v5
-- Ledger function-code normalization and flags.
-- Proposed business / merge key: SourceEnvironmentCode, FunctionCodeID
CREATE TABLE `gold`.`dim_glfunction_code` (
    `FunctionCodeID` INT NOT NULL COMMENT 'Source FK_FunctionCodeID value',
    `FunctionCodeName` STRING NOT NULL COMMENT 'Descriptive name',
    `Category` STRING NOT NULL COMMENT 'Income / Accrual / Payment / Basis / AP / Transfer / Settlement',
    `DebitCreditDirection` STRING NOT NULL COMMENT '\'Credit-Debit\' (income positive) or \'Debit-Credit\' (payment positive)',
    `IsIncomeCode` BOOLEAN NOT NULL COMMENT '1 for codes 1004/1005/1006/1014/1015/1016',
    `IsAPCode` BOOLEAN NOT NULL COMMENT '1 for codes 5001/5002/5004/5005',
    `IsSettlement` BOOLEAN NOT NULL COMMENT '1 if this code represents cash settlement (excluded from accrual calcs)',
    `IsExcludedFromPendingCash` BOOLEAN NOT NULL COMMENT '1 for code 6002 — excluded from PendingCash and IRRCashFlow',
    `AccountTypeFilter` STRING COMMENT '\'4or5\' / \'1or2\' / \'Any\' / \'BasisAdjustment\' — account type required for this function code',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_glfunction_code_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T09 / G01 / Core v5
-- Security and portfolio corporate-action reference.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ActionID
CREATE TABLE `gold`.`dim_corporate_action` (
    `ActionID` INT NOT NULL COMMENT 'Source CorporateActions.ActionID',
    `ActionType` STRING NOT NULL COMMENT '\'Spin Off\' / \'Merger\' / \'Stock Split\'',
    `SecurityID` INT NOT NULL COMMENT 'Security the action applies to',
    `ActionDate` DATE NOT NULL COMMENT 'Date of the corporate action',
    `SpinOffPercentage` DECIMAL(18,6) COMMENT 'Percentage of market value spun off (from CorporateActions.Data2)',
    `IssuePrice` DECIMAL(18,6) COMMENT 'Spinoff issue price (from Data5) — takes precedence over computed market value',
    `IsPortfolioSpecific` BOOLEAN NOT NULL COMMENT '1 if this action is linked to a specific portfolio via CorporateActionPortfolio',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_corporate_action_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T10 / G01 / Core v5
-- Normalized transaction direction and special behaviors.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, TransactionTypeName, BuySell, SourceFunctionCode
CREATE TABLE `gold`.`dim_transaction_type` (
    `TransactionTypeKey` INT NOT NULL COMMENT 'Surrogate or durable key for transaction type.',
    `TransactionTypeName` STRING NOT NULL COMMENT 'Transaction Type Name value populated by etl.usp_Load_10_Dim_TransactionType.',
    `BuySell` STRING COMMENT 'Buy Sell value populated by etl.usp_Load_10_Dim_TransactionType.',
    `IsTransfer` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether transfer applies.',
    `IsSpinOff` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether spin off applies.',
    `IsMerger` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether merger applies.',
    `IsInKind` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether in kind applies.',
    `IsGift` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether gift applies.',
    `SourceFunctionCode` STRING COMMENT 'Source Function Code value populated by etl.usp_Load_10_Dim_TransactionType.',
    `CustomerID` INT COMMENT 'Archway customer/tenant identifier.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_transaction_type_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T11 / G01 / Core v5
-- Versioned security price by portfolio and price date.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SecurityID, FK_PortfolioID, PriceDate, ValidFrom
CREATE TABLE `gold`.`dim_security_price` (
    `SecurityPriceKey` BIGINT NOT NULL COMMENT 'Identity surrogate',
    `SecurityID` INT NOT NULL COMMENT 'Source SecurityValue.SecurityID',
    `FK_PortfolioID` INT COMMENT 'NULL=generic price; non-NULL=portfolio-specific override. fn_GetMax_SecurityValue_WithPortfolioSpecific prioritises non-NULL.',
    `PriceDate` DATE NOT NULL COMMENT 'Date of the price observation',
    `SecurityValue` DECIMAL(28,12) COMMENT 'Primary price value',
    `SecurityValue2` DECIMAL(28,12) COMMENT 'Alternate price (e.g. bid/ask)',
    `SecurityValue3` DECIMAL(28,12) COMMENT 'Third price variant',
    `AnnualizedPayment` DECIMAL(28,12) COMMENT 'For fixed income: annualised coupon/payment',
    `ValidFrom` DATE NOT NULL COMMENT 'SCD2 effective start',
    `ValidTo` DATE COMMENT 'SCD2 effective end; NULL=current',
    `IsCurrent` BOOLEAN NOT NULL COMMENT '1=current record',
    `CustomerID` INT COMMENT 'Archway customer/tenant identifier.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_security_price_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T12 / G01 / Core v5
-- Security class master.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SourceOwnerCustomerID, SecurityClassID
CREATE TABLE `gold`.`dim_security_class` (
    `SecurityClassID` INT NOT NULL COMMENT 'Source SecurityClass.SecurityClassID',
    `SecurityClassName` STRING NOT NULL COMMENT 'Class name (e.g. \'Public Equity\', \'Private Equity\')',
    `MajorOrMinor` STRING NOT NULL COMMENT '\'Major\' or \'Minor\' — the two hierarchy levels',
    `SortOrder` INT NOT NULL COMMENT 'Display sort order',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceCustomerID` INT NOT NULL COMMENT 'Identifier of the originating source row for Customer lineage.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_security_class_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T13 / G01 / Core v5
-- Security class options and parent class association.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SourceOwnerCustomerID, SecurityClassOptionID
CREATE TABLE `gold`.`dim_security_class_option` (
    `SecurityClassOptionID` INT NOT NULL COMMENT 'Source SecurityClassOption.SecurityClassOptionID',
    `SecurityClassOptionName` STRING NOT NULL COMMENT 'Option display name (e.g. \'Domestic Equity\', \'Global PE\')',
    `SecurityClassID` INT NOT NULL COMMENT 'Parent class',
    `SortOrder` INT NOT NULL COMMENT 'Display sort order — used in report ordering',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceCustomerID` INT NOT NULL COMMENT 'Identifier of the originating source row for Customer lineage.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_security_class_option_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T14 / G01 / Core v5
-- Benchmark definitions and synthetic metadata.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SourceOwnerCustomerID, BenchmarkRateID
CREATE TABLE `gold`.`dim_benchmark` (
    `BenchmarkRateID` INT NOT NULL COMMENT 'Source SecurityBenchmarkRate.BenchmarkRateID',
    `BenchmarkName` STRING NOT NULL COMMENT 'Benchmark display name (e.g. \'S&P 500\', \'MSCI World\')',
    `BenchmarkType` STRING COMMENT 'Index / Custom / Blended',
    `IsSynthetic` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether synthetic applies.',
    `SecurityClassID` INT COMMENT 'Identifier for security class at this table grain.',
    `SortOrder` INT NOT NULL COMMENT 'Sort Order value populated by etl.usp_Load_14_Dim_Benchmark.',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `IsActive` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether active applies.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `dim_benchmark_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T15 / G01 / Core v5
-- Valid long-short and position-direction flag combinations.
-- Proposed business / merge key: SourceEnvironmentCode, LongShortMultiplier, PriorLongShortMultiplier, DHU, LongShortNettingEnabled, IsBalanceForward
CREATE TABLE `gold`.`junk_long_short_flags` (
    `FlagKey` INT NOT NULL COMMENT 'Surrogate key 1-32',
    `LongShortMultiplier` SMALLINT NOT NULL COMMENT '+1 = long position; -1 = short position',
    `PriorLongShortMultiplier` SMALLINT NOT NULL COMMENT '±1 prior period direction',
    `DHU` BOOLEAN NOT NULL COMMENT '0=live data; 1=balance-forward/DHU data',
    `LongShortNettingEnabled` BOOLEAN NOT NULL COMMENT 'Customer-level LongShortNetting feature flag',
    `IsBalanceForward` BOOLEAN NOT NULL COMMENT '1 if associated with a balance-forward period',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `junk_long_short_flags_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T16 / G06 / Core v5
-- Breakpoint ownership and PAO fan-out from master to feeder profiles.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, MasterFundID, MasterPortfolioID, ProfileID, FeederFundID, FeederPortfolioID, COAID, BreakPointDate
CREATE TABLE `gold`.`bridge_nested_profile` (
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `MasterFundID` INT NOT NULL COMMENT 'Master/fund-level fund',
    `MasterPortfolioID` INT NOT NULL COMMENT 'Master portfolio',
    `ProfileID` INT NOT NULL COMMENT 'Investor profile',
    `BreakPointStart` DATE NOT NULL COMMENT 'First day of this breakpoint period',
    `BreakPointDate` DATE NOT NULL COMMENT 'Last day of this breakpoint period (from Breakpoints table)',
    `Ownership` DECIMAL(28,12) NOT NULL COMMENT 'Investor total economic interest % (informational — not used for metric scaling)',
    `Allocation` DECIMAL(28,12) NOT NULL COMMENT '% of P&L/numerator/income flows allocated to this investor. Used for: ReportingNumerator, non-NoUG components of PriorBasis/BasisChange/CashFlow/IRREndingBasis.',
    `PreAllocationOwnership` DECIMAL(28,12) NOT NULL COMMENT '% of capital stock (EndingBasis, MarketValue, FXGainLoss, NoUG components). Reflects actual capital deployed.',
    `PriorPreAllocationOwnership` DECIMAL(28,12) NOT NULL COMMENT 'Prior period\'s PreAllocationOwnership. Used on FIRST DAY of new period (LongShortNetting=1) to prevent discontinuous basis jumps at renegotiation.',
    `FeederFundID` INT NOT NULL COMMENT 'Investor feeder fund. Source: WarehouseNestedProfile.FundID_Origin',
    `FeederPortfolioID` INT NOT NULL COMMENT 'Investor feeder portfolio. Source: WarehouseNestedProfile.PortfolioID_Origin',
    `COAID` INT NOT NULL COMMENT 'COA linking feeder→master. Allows multiple investors via different COA codes.',
    `IsZeroAllocationPlaceholder` BOOLEAN NOT NULL COMMENT '1 if this is a synthetic zero-allocation row (investor lost complete allocation) — triggers quasi-CF computation in Fact-2 ETL',
    `SourceWarehouseNestedProfileID` BIGINT COMMENT 'Identifier of the originating source row for Warehouse Nested Profile lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `OwnershipPathSetID` STRING NOT NULL COMMENT 'Auditable full path membership including origins/COA/breakpoints; not a single inferred percentage.',
    CONSTRAINT `bridge_nested_profile_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T17 / G05 / Core v5
-- Fund/security daily financial kernel results (Fact-3).
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, PortfolioID, SecurityID, Date, LocalCurrency, DHU
CREATE TABLE `gold`.`fact_daily_security_performance` (
    `SecurityPerformanceID` BIGINT NOT NULL COMMENT 'Identity key. Never exposed to reports.',
    `PartitionNumber` SMALLINT NOT NULL COMMENT 'Multi-tenancy shard. Every query must filter on this.',
    `DHU` BOOLEAN NOT NULL COMMENT '0=live, 1=balance-forward. Standard loader RAISERRORs on DHU=1 in date range.',
    `Date` DATE NOT NULL COMMENT 'Observation date. Part of natural key. Never updated post-insert.',
    `CustomerID` INT NOT NULL COMMENT 'Tenant ID. Never updated post-insert.',
    `FundID` INT NOT NULL COMMENT 'One of few updatable non-key columns (fund remapping).',
    `PortfolioID` INT NOT NULL COMMENT 'Fund portfolio. Never updated post-insert.',
    `SecurityID` INT NOT NULL COMMENT '-1 sentinel for net-of-fees fund-level rows (SecurityID=-1 from uproc_...NetOfFees).',
    `BreakpointDate` TIMESTAMP_NTZ COMMENT 'Period boundary from fn_Get_BreakpointDateSkippingInception. Updated when breakpoint changes.',
    `LocalCurrency` STRING NOT NULL COMMENT 'Transaction currency. Never updated post-insert.',
    `LongShortMultiplier` SMALLINT NOT NULL COMMENT '±1. Updatable. Flips sign on short positions.',
    `PriorLongShortMultiplier` SMALLINT NOT NULL COMMENT '±1. Prior period direction. Only populated when @ReturnPriorLongShortMultiplier=1.',
    `FlagKey` INT COMMENT 'Surrogate key for the combined long/short, DHU, netting, and balance-forward flag set.',
    `ReportingNumerator` DECIMAL(28,12) NOT NULL COMMENT 'P&L gain: Income−Amm+BuyProfit+SellProfit+PositionProfit−BasisIn+BasisOut−InKind. Numerator of TWR.',
    `ReportingPriorBasis` DECIMAL(28,12) NOT NULL COMMENT 'Beginning-of-period invested capital. TWR denominator start. = prior-day market value.',
    `ReportingPriorBasisNoUG` DECIMAL(28,12) NOT NULL COMMENT 'Prior basis ex-unrealized gains. Used for UG/NoUG split in Fact-2 investor scaling. 0 for DHU rows.',
    `ReportingBasisChange` DECIMAL(28,12) NOT NULL COMMENT 'Net capital flows: calls+subscriptions+distributions+transfers±manual. Denominator adjustment.',
    `ReportingEndingBasis` DECIMAL(28,12) NOT NULL COMMENT 'End-of-period cost basis. Used as next period\'s ReportingPriorBasis.',
    `ReportingMarketValue` DECIMAL(28,12) NOT NULL COMMENT 'End-of-period market value = SecurityPrice × Qty × SecurityMultiplier × ExRate.',
    `ReportingCashFlow` DECIMAL(28,12) NOT NULL COMMENT 'Total IRR cash flow: capital calls/subscriptions + income distributions.',
    `ReportingCashFlowAdjustment` DECIMAL(28,12) NOT NULL COMMENT 'Quasi-CF: implicit flow when ownership % changes at breakpoint. 0 for DHU rows.',
    `ReportingIRRCashFlowBasisNoUG` DECIMAL(28,12) NOT NULL COMMENT 'NoUG portion of CashFlow (capital calls only). Investor scaling split. 0 for DHU rows.',
    `ReportingIRREndingBasis` DECIMAL(28,12) NOT NULL COMMENT 'IRR ending basis incl. EndingBasisAdjustment (manual GL adjustments via SUM OVER UniqueIdentifyingID).',
    `ReportingIRREndingBasisNoUG` DECIMAL(28,12) NOT NULL COMMENT 'IRR ending basis ex-UG. Used in Fact-2 UG/NoUG investor scaling. 0 for DHU rows.',
    `ReportingIRREndingShortAdj` DECIMAL(28,12) NOT NULL COMMENT 'Short position IRR adj = 2×(|BasisCF|−|CF|). Only for short positions under LongShortNetting. 0 DHU.',
    `ReportingFXGainLoss` DECIMAL(28,12) NOT NULL COMMENT 'FX gain/loss = (currentExRate−priorExRate) × LocalMarketValue. 0 for DHU rows.',
    `SourceSecurityPerformanceID` BIGINT COMMENT 'Identifier of the originating source row for Security Performance lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `IsOpeningSeed` BOOLEAN NOT NULL COMMENT '1 when the row represents a seeded opening state rather than a normally calculated daily row.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Reporting monetary basis used by kernel; do not infer all reporting amounts are USD.',
    `InputPolicyID` STRING NOT NULL COMMENT 'Recognition, netting, valuation and other kernel-input policy identity.',
    `ComponentRole` STRING NOT NULL COMMENT 'Native performance component/perspective role; prevents summing overlapping representations.',
    CONSTRAINT `fact_daily_security_performance_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T18 / G06 / Core v5
-- Prior-day position and investor opening seed for bounded history.
-- Proposed business / merge key: SourceEnvironmentCode, SeedDate, CustomerID, FundID, PortfolioID, SecurityID, ProfileID, FeederFundID, FeederPortfolioID, COAID, ReportingCurrency, SeedLevel, LongShortMultiplier
CREATE TABLE `gold`.`fact_performance_opening_seed` (
    `OpeningSeedKey` BIGINT NOT NULL COMMENT 'Surrogate or durable key for opening seed.',
    `SeedDate` DATE NOT NULL COMMENT 'Date associated with seed.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `PortfolioID` INT NOT NULL COMMENT 'Portfolio identifier.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `ProfileID` INT COMMENT 'Investor profile identifier.',
    `FeederFundID` INT COMMENT 'Identifier for feeder fund at this table grain.',
    `FeederPortfolioID` INT COMMENT 'Identifier for feeder portfolio at this table grain.',
    `COAID` INT COMMENT 'Chart-of-accounts identifier.',
    `ReportingCurrency` STRING NOT NULL COMMENT 'Currency in which the report measure is expressed.',
    `LongShortMultiplier` SMALLINT NOT NULL COMMENT 'Direction multiplier, normally +1 for long and -1 for short.',
    `ReportingEndingBasis` DECIMAL(28,12) NOT NULL COMMENT 'End-of-period reporting-currency basis.',
    `ReportingMarketValue` DECIMAL(28,12) NOT NULL COMMENT 'End-of-period reporting-currency market value.',
    `ReportingIRREndingBasis` DECIMAL(28,12) NOT NULL COMMENT 'Ending basis used as the XIRR closing leg.',
    `ReportingIRREndingShortAdj` DECIMAL(28,12) NOT NULL COMMENT 'Adjustment required to reconcile XIRR for short positions.',
    `HistoricalInceptionDate` DATE COMMENT 'Date associated with historical inception.',
    `SeedLevel` STRING NOT NULL COMMENT 'Seed Level value populated by etl.usp_Load_18_Fact_PerformanceOpeningSeed.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Reporting monetary basis used by kernel; do not infer all reporting amounts are USD.',
    `InputPolicyID` STRING NOT NULL COMMENT 'Recognition, netting, valuation and other kernel-input policy identity.',
    `ComponentRole` STRING NOT NULL COMMENT 'Native performance component/perspective role; prevents summing overlapping representations.',
    CONSTRAINT `fact_performance_opening_seed_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T19 / G06 / Core v5
-- Investor-level daily Fact-2 using allocation and PAO scaling.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SecurityID, MasterFundID, MasterPortfolioID, FeederFundID, FeederPortfolioID, COAID, ProfileID, Date, LocalCurrency, FeederRow, DHU
CREATE TABLE `gold`.`fact_investor_performance_profile` (
    `DailySecurityPerformanceID` BIGINT NOT NULL COMMENT 'Identity surrogate key.',
    `PartitionNumber` SMALLINT NOT NULL COMMENT 'Different partition fn from Fact-3. fn_GetFACT2PartitionNumber.',
    `DHU` BOOLEAN NOT NULL COMMENT '0=live; propagated from Fact-3 on INSERT.',
    `Date` DATE NOT NULL COMMENT 'Observation date. Part of composite natural key. Immutable.',
    `CustomerID` INT NOT NULL COMMENT 'Tenant ID. Immutable.',
    `SecurityID` INT NOT NULL COMMENT 'Security. -1 for net-of-fees rows. Immutable.',
    `MasterPortfolioID` INT NOT NULL COMMENT 'Fund-level portfolio. Immutable.',
    `MasterFundID` INT NOT NULL COMMENT 'Master fund. Updated on fund remapping.',
    `FeederPortfolioID` INT NOT NULL COMMENT 'Investor portfolio. -1 if no feeder. Immutable.',
    `FeederFundID` INT NOT NULL COMMENT 'Investor fund. -1 if no feeder. Updated on fund remapping.',
    `COAID` INT NOT NULL COMMENT 'COA linking feeder→master. -1 if no COA linkage. Immutable.',
    `ProfileID` INT NOT NULL COMMENT 'Investor profile. -1 if no profile. Updated on profile remapping.',
    `LocalCurrency` STRING NOT NULL COMMENT 'Inherited from Fact-3. Immutable.',
    `FeederRow` SMALLINT NOT NULL COMMENT 'ROW_NUMBER() within (SecurityID, MasterPortfolioID, Date, COAID, FeederPortfolioID, LocalCurrency) — handles multiple NestedProfile entries for same combo.',
    `LongShortMultiplier` SMALLINT NOT NULL COMMENT 'Pass-through from Fact-3. Updatable.',
    `PriorLongShortMultiplier` SMALLINT NOT NULL COMMENT 'Pass-through from Fact-3. Updatable.',
    `FlagKey` INT COMMENT 'Surrogate key for the combined long/short, DHU, netting, and balance-forward flag set.',
    `ReportingNumerator` DECIMAL(28,12) NOT NULL COMMENT 'Fact3.ReportingNumerator × Allocation.',
    `ReportingPriorBasis` DECIMAL(28,12) NOT NULL COMMENT '(Allocation × (PriorBasis−PriorBasisNoUG)) + (PriorBasisNoUG × PreAllocationOwnership). Split because UG portion uses Allocation; cost basis uses PreAllocationOwnership.',
    `ReportingBasisChange` DECIMAL(28,12) NOT NULL COMMENT '(IRRCashFlowBasisNoUG × PreAllocationOwnership) + ((CashFlow−IRRCashFlowBasisNoUG) × Allocation). Capital calls scale by PreAllocationOwnership; income by Allocation.',
    `ReportingEndingBasis` DECIMAL(28,12) NOT NULL COMMENT 'Fact3.ReportingEndingBasis × PreAllocationOwnership. Capital stock measure — always PreAllocationOwnership.',
    `ReportingMarketValue` DECIMAL(28,12) NOT NULL COMMENT 'Fact3.ReportingMarketValue × PreAllocationOwnership.',
    `ReportingCashFlow` DECIMAL(28,12) NOT NULL COMMENT 'Same split as BasisChange; then adjusted by quasi-CF: -= PriorFact3EndingBasis × (CurrentPAO − PriorPAO).',
    `ReportingCashFlowAdjustment` DECIMAL(28,12) NOT NULL COMMENT 'When LongShortNetting=1: = PriorFact3EndingBasis × (CurrentPAO−PriorPAO). When=0: Fact3.CashFlowAdj × Allocation.',
    `ReportingIRREndingBasis` DECIMAL(28,12) NOT NULL COMMENT '(IRREndingBasisNoUG × PreAllocationOwnership) + ((IRREndingBasis−IRREndingBasisNoUG) × Allocation). Same UG/NoUG split as PriorBasis.',
    `ReportingIRREndingShortAdj` DECIMAL(28,12) NOT NULL COMMENT 'Fact3.ReportingIRREndingShortAdj × Allocation. P&L measure — Allocation scaling.',
    `ReportingFXGainLoss` DECIMAL(28,12) NOT NULL COMMENT 'Fact3.ReportingFXGainLoss × PreAllocationOwnership. Capital stock measure.',
    `SourceDailySecurityPerformanceID` BIGINT COMMENT 'Identifier of the originating source row for Daily Security Performance lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `IsOpeningSeed` BOOLEAN NOT NULL COMMENT '1 when the row represents a seeded opening state rather than a normally calculated daily row.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Reporting monetary basis used by kernel; do not infer all reporting amounts are USD.',
    `InputPolicyID` STRING NOT NULL COMMENT 'Recognition, netting, valuation and other kernel-input policy identity.',
    `ComponentRole` STRING NOT NULL COMMENT 'Native performance component/perspective role; prevents summing overlapping representations.',
    `OwnershipRecordVersionID` STRING NOT NULL COMMENT 'Exact effective allocation/PAO/ownership slice used for this investor result.',
    `SourceFact3RecordVersionID` STRING NOT NULL COMMENT 'Exact version of the unallocated daily performance row used.',
    CONSTRAINT `fact_investor_performance_profile_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T20 / G05 / Core v5
-- Effective-dated portfolio and performance attributes.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, PortfolioID, ValidFrom
CREATE TABLE `gold`.`dim_portfolio` (
    `PortfolioID` INT NOT NULL COMMENT 'Source Portfolios.PortfolioID',
    `PortfolioName` STRING NOT NULL COMMENT 'Display name',
    `StrategyType` STRING COMMENT 'Investment strategy — tracked across changes',
    `FundID` INT NOT NULL COMMENT 'Fund this portfolio belongs to',
    `PortfolioCash` STRING COMMENT 'COA code for the portfolio\'s cash account',
    `PortfolioDueToDueFrom` STRING COMMENT 'COA code for due-to/due-from account — drives PendingCash performance',
    `FK_PendingCashPerfSecurityID` INT COMMENT 'SecurityID representing pending cash performance',
    `FK_NotionalPerfSecurityID` INT COMMENT 'SecurityID representing notional (unfunded) performance',
    `IsLongShort` BOOLEAN NOT NULL COMMENT '1 if this portfolio participates in long/short netting',
    `PortfolioCurrency` STRING COMMENT 'Portfolio base currency if different from fund',
    `CustomerID` INT NOT NULL COMMENT 'Tenant identifier',
    `IsCollapsed` BOOLEAN NOT NULL COMMENT '1 if this portfolio should be collapsed to class level in reporting',
    `PerformanceStartDate` DATE COMMENT 'Effective start date for performance calculations',
    `ValidFrom` DATE NOT NULL COMMENT 'SCD2 effective start',
    `ValidTo` DATE COMMENT 'SCD2 effective end; NULL=current',
    `IsCurrent` BOOLEAN NOT NULL COMMENT '1=current record',
    `SourceAuditDate` TIMESTAMP_NTZ COMMENT 'Source-system audit timestamp used for change detection and lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ObservedAtUtc` TIMESTAMP NOT NULL COMMENT 'When the warehouse observed this version/correction, separate from business validity.',
    CONSTRAINT `dim_portfolio_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T21 / G03 / Core v5
-- Profile/investor master for reporting and ownership.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ProfileID, ValidFrom
CREATE TABLE `gold`.`dim_investor_profile` (
    `ProfileID` INT NOT NULL COMMENT 'Source Profile.ProfileID. -1 = no profile sentinel',
    `ProfileName` STRING NOT NULL COMMENT 'Investor/profile display name',
    `InvestorType` STRING COMMENT 'LP / GP / Co-Invest / SMA / Fund of Funds',
    `FeederFundID` INT COMMENT 'Feeder fund if this profile invests via a feeder structure',
    `FeederPortfolioID` INT COMMENT 'Feeder portfolio',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `IsActive` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether active applies.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ValidFrom` TIMESTAMP_NTZ NOT NULL COMMENT 'Business-effective start; do not replace with load time.',
    `ValidTo` TIMESTAMP_NTZ COMMENT 'Exclusive end of this effective version; NULL means open-ended only when policy allows.',
    `IsCurrent` BOOLEAN NOT NULL COMMENT 'Current effective version marker; historical joins still use observation-time intervals.',
    `ObservedAtUtc` TIMESTAMP NOT NULL COMMENT 'When the warehouse observed this version/correction, separate from business validity.',
    CONSTRAINT `dim_investor_profile_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T22 / G06 / Core v5
-- Six grouping contexts and class-option reporting metadata.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, GroupingType, SourceObjectID, ClassID, ClassOptionID, MasterFeederFlag, LookThroughFlag, CollapseFlag, NodeType, MembershipSetID
CREATE TABLE `gold`.`dim_page_grouping` (
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Synthetic key. Unique across all grouping types.',
    `PageGroupingName` STRING NOT NULL COMMENT 'Display name of the group (profile name, fund name, portfolio name, or class option name)',
    `GroupingType` STRING NOT NULL COMMENT '\'Profile\' / \'Entity\' / \'Portfolio\' / \'ProfileClass\' / \'EntityClass\' / \'PortfolioClass\'',
    `SourceObjectID` INT NOT NULL COMMENT 'Identifier of the original source object normalized into the report grouping.',
    `FeederFundID` INT COMMENT 'For Profile/Entity groupings: the investor\'s fund',
    `FeederPortfolioID` INT COMMENT 'For Portfolio groupings: the investor\'s portfolio',
    `GlobalClassOptionID` INT COMMENT 'For EntityClass groupings: GlobalClassOption',
    `ProfileClassOptionID` INT COMMENT 'For ProfileClass groupings: ProfileClassOption',
    `ClassID` INT COMMENT 'Identifier for class at this table grain.',
    `ClassOptionID` INT COMMENT 'Identifier for class option at this table grain.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `InceptionDate` DATE COMMENT 'Date associated with inception.',
    `CollapseFlag` BOOLEAN NOT NULL COMMENT 'Collapse Flag value populated by etl.usp_Load_22_Dim_PageGrouping.',
    `SuppressNonTotalPerformance` BOOLEAN NOT NULL COMMENT 'Suppress Non Total Performance value populated by etl.usp_Load_22_Dim_PageGrouping.',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `IsActive` BOOLEAN NOT NULL COMMENT '0 = inactive grouping',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `NodeType` STRING NOT NULL COMMENT 'Typed report node: fund, portfolio, profile, class, security, cash, other asset or total.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Stable context-compatible report-node identity, not an ambiguous integer from different source tables.',
    `MembershipSetID` STRING NOT NULL COMMENT 'Retained typed member/version set resolving this grouping under approved effective-date policy.',
    CONSTRAINT `dim_page_grouping_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T23 / G01 / Core v5
-- Valid customer major/minor class combinations.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, MajorSecurityClassID, MinorSecurityClassID
CREATE TABLE `gold`.`bridge_report_security_class_pair` (
    `ReportSecurityClassPairKey` BIGINT NOT NULL COMMENT 'Surrogate or durable key for report security class pair.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `MajorSecurityClassID` INT NOT NULL COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT NOT NULL COMMENT 'Identifier of the minor security-class definition.',
    `PairName` STRING COMMENT 'Pair Name value populated by etl.usp_Load_23_Bridge_ReportSecurityClassPair.',
    `IsDefault` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether default applies.',
    `IsActive` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether active applies.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `bridge_report_security_class_pair_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T24 / G07 / Core v5
-- Materialized report parameter context.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ActiveFundID, GroupingType, PageGroupingID, SourceObjectID, MasterFeederFlag, LookThroughFlag, ReportStartDate, ReportEndDate, IsRolling, IsCalendarYear, CalcMethod, AnnualizeFlag, DeAnnualizeFlag, FeeType, CurrencyCode, MajorSecurityClassID, MinorSecurityClassID, BeginningEndingBasis, ContinuousBasis, ModelVersion, SelectionSetID, GroupingDefinitionID, PolicySetID, ResolvedFeatureSetID
CREATE TABLE `gold`.`dim_report_context` (
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Surrogate or durable key for report context.',
    `ContextCode` STRING NOT NULL COMMENT 'Context Code value populated by etl.usp_Load_24_Dim_ReportContext.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `ActiveFundID` INT NOT NULL COMMENT 'Identifier for active fund at this table grain.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `SourceObjectID` INT NOT NULL COMMENT 'Identifier of the original source object normalized into the report grouping.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `ReportStartDate` DATE NOT NULL COMMENT 'Date associated with report start.',
    `ReportEndDate` DATE NOT NULL COMMENT 'Date associated with report end.',
    `IsRolling` BOOLEAN NOT NULL COMMENT '1 for rolling windows and 0 for calendar-based windows where applicable.',
    `IsCalendarYear` BOOLEAN NOT NULL COMMENT '1 when the period is anchored to a calendar-year boundary.',
    `CalcMethod` STRING NOT NULL COMMENT 'Selected return method, normally TW/TWR or XIRR.',
    `AnnualizeFlag` BOOLEAN NOT NULL COMMENT 'Annualize Flag value populated by etl.usp_Load_24_Dim_ReportContext.',
    `DeAnnualizeFlag` BOOLEAN NOT NULL COMMENT 'De Annualize Flag value populated by etl.usp_Load_24_Dim_ReportContext.',
    `FeeType` STRING NOT NULL COMMENT 'Fee treatment for the row, such as gross or net of fees.',
    `CurrencyCode` STRING NOT NULL COMMENT 'ISO-style currency code used by the model.',
    `MajorSecurityClassID` INT NOT NULL COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT NOT NULL COMMENT 'Identifier of the minor security-class definition.',
    `IsActive` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether active applies.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `BeginningEndingBasis` BOOLEAN COMMENT 'Beginning/ending basis policy selection carried by this context/result; do not conflate with continuous-basis selection.',
    `ContinuousBasis` BOOLEAN COMMENT 'Continuous basis policy selection carried by this context/result; key and publish independently from other approved policies.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CalculationContextID` STRING NOT NULL COMMENT 'Canonical reusable calculation context, independent of job run.',
    `SelectionSetID` STRING NOT NULL COMMENT 'Immutable positive-selection membership; do not equate ActiveFundID with all selected economic funds.',
    `GroupingDefinitionID` STRING NOT NULL COMMENT 'Ordered grouping-axis definition; supports MPLP\'s third axis without truncation.',
    `PolicySetID` STRING NOT NULL COMMENT 'Normalized collection of approved fee/basis/ownership/collapse/annualization/recognition policies.',
    `CanonicalContextJSON` STRING NOT NULL COMMENT 'Deterministic normalized economic request with exact effective parameters; preserve order only when meaningful.',
    `ContextFingerprint` STRING NOT NULL COMMENT 'Hash of canonical context; canonical payload retained to diagnose collisions or normalization errors.',
    `ResolvedFeatureSetID` STRING NOT NULL COMMENT 'Effective WHConverted and other source branch flags used for the approved baseline and engine path.',
    CONSTRAINT `dim_report_context_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T25 / G07 / Core v5
-- Selected and standard period window definitions and coverage.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, ReportContextKey, PeriodKey, ReportStartDate, ReportEndDate, PeriodStartDate, PeriodEndDate, IsRolling, IsCalendarYear, ModelVersion
CREATE TABLE `gold`.`dim_report_time_period` (
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Identifier for report time period at this table grain.',
    `PeriodKey` STRING NOT NULL COMMENT '\'Period\' / \'QTD\' / \'YTD\' / \'1Year\' / \'3Year\' / \'5Year\' / \'10Year\' / \'ITD\' / \'Year1Prior\' etc.',
    `PeriodOrdinal` SMALLINT NOT NULL COMMENT 'Period Ordinal value populated by etl.usp_Load_25_Dim_ReportTimePeriod.',
    `FundID` INT NOT NULL COMMENT 'Fund for which this period is resolved',
    `ReportStartDate` DATE NOT NULL COMMENT 'Date associated with report start.',
    `ReportEndDate` DATE NOT NULL COMMENT 'The as-of report date',
    `PeriodStartDate` DATE NOT NULL COMMENT 'Resolved start date of this period (from fn_Report_ReturnPeriodDates)',
    `PeriodEndDate` DATE NOT NULL COMMENT 'Resolved end date (= ReportEndDate for most periods)',
    `PeriodDays` INT NOT NULL COMMENT 'DATEDIFF(d, PeriodStartDate-1, PeriodEndDate)',
    `IsRolling` BOOLEAN NOT NULL COMMENT '1 for rolling periods (1Year, 3Year, etc.); 0 for cumulative (YTD, QTD)',
    `IsCalendarYear` BOOLEAN NOT NULL COMMENT '1 when the period is anchored to a calendar-year boundary.',
    `IsInceptionPeriod` BOOLEAN NOT NULL COMMENT '1 for ITD period',
    `InceptionDate` DATE COMMENT 'Effective inception date for ITD window',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `DataCoverageStartDate` DATE COMMENT 'Earliest date of available source history considered for completeness.',
    `IsCompleteWindow` BOOLEAN NOT NULL COMMENT '1 when the complete required history/window is available and the return may be published; otherwise 0.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `CoverageStatus` STRING COMMENT 'Named data-coverage assessment for the requested window, such as Complete or an identified prerequisite gap.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ResolvedWindowID` STRING NOT NULL COMMENT 'Immutable resolved financial window including custom start/end, fiscal/inception and endpoint policy.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Report context whose actual date policy produced this row.',
    `OpeningValueDate` DATE COMMENT 'Logical opening valuation date per legacy contract; source price observation may precede it.',
    `HistoryEndExclusive` DATE NOT NULL COMMENT 'Exclusive end of required input history, distinct from inclusive report end.',
    CONSTRAINT `dim_report_time_period_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T26 / G03 / Core v5
-- Effective-dated major/minor security classifications.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, ValidFrom
CREATE TABLE `gold`.`bridge_security_classification` (
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `SecurityID` INT NOT NULL COMMENT 'Security',
    `MajorSecurityClassID` INT NOT NULL COMMENT 'Major class',
    `MajorSecurityClassOptionID` INT NOT NULL COMMENT 'Major class option assignment',
    `MinorSecurityClassID` INT NOT NULL COMMENT 'Minor class',
    `MinorSecurityClassOptionID` INT NOT NULL COMMENT 'Minor class option assignment',
    `ValidFrom` DATE NOT NULL COMMENT 'Start date of this classification assignment',
    `ValidTo` DATE COMMENT 'End date; NULL=current',
    `IsCurrent` BOOLEAN NOT NULL COMMENT '1=active classification',
    `SourceMajorClassificationID` BIGINT COMMENT 'Identifier of the originating source row for Major Classification lineage.',
    `SourceMinorClassificationID` BIGINT COMMENT 'Identifier of the originating source row for Minor Classification lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `bridge_security_classification_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T27 / G07 / Core v5
-- Effective-dated hierarchy of benchmark assignments.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SourceTable, SourceAssignmentID, PageGroupingID, BenchmarkLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, BenchmarkRateID, EffectiveDate
CREATE TABLE `gold`.`bridge_benchmark_assignment` (
    `BenchmarkAssignmentID` BIGINT NOT NULL COMMENT 'Identifier for benchmark assignment at this table grain.',
    `CustomerID` INT NOT NULL COMMENT 'Tenant',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Group receiving this benchmark',
    `BenchmarkRateID` INT NOT NULL COMMENT 'The benchmark assigned',
    `BenchmarkLevel` STRING NOT NULL COMMENT '\'Total\' / \'MajorClass\' / \'MinorClass\' / \'Security\' — which level this benchmark applies at',
    `SecurityClassOptionMajorID` INT COMMENT 'Populated for MajorClass level benchmarks',
    `SecurityClassOptionMinorID` INT COMMENT 'Populated for MinorClass level benchmarks',
    `SecurityID` INT COMMENT 'Populated for Security level benchmarks',
    `EffectiveDate` DATE NOT NULL COMMENT 'Start of benchmark assignment',
    `ExpiryDate` DATE COMMENT 'End of assignment; NULL=current',
    `IsCurrent` BOOLEAN NOT NULL COMMENT '1=current assignment',
    `SourceTable` STRING COMMENT 'Origin: Profile_BenchmarkRate / Fund_BenchmarkRate / Portfolio_BenchmarkRate / GlobalClassOption_BenchmarkRate / SecurityClassOption_BenchmarkRate',
    `SourceAssignmentID` BIGINT COMMENT 'Identifier of the originating source row for Assignment lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `bridge_benchmark_assignment_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T28 / G04 / Core v5
-- Daily directional FX rates.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, RateDate, FromCurrency, ToCurrency
CREATE TABLE `gold`.`fact_exchange_rate_daily` (
    `ExchangeRateDailyKey` BIGINT NOT NULL COMMENT 'Surrogate or durable key for exchange rate daily.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `RateDate` DATE NOT NULL COMMENT 'Date for which the exchange rate applies.',
    `FromCurrency` STRING NOT NULL COMMENT 'Source currency of the directional exchange rate.',
    `ToCurrency` STRING NOT NULL COMMENT 'Target currency of the directional exchange rate.',
    `ExchangeRate` DECIMAL(28,12) NOT NULL COMMENT 'Multiplier converting an amount from FromCurrency to ToCurrency for RateDate.',
    `IsEstimated` BOOLEAN NOT NULL COMMENT '1 when the rate/value is estimated rather than final.',
    `SourceExchangeRateID` BIGINT COMMENT 'Identifier of the originating source row for Exchange Rate lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `fact_exchange_rate_daily_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T29 / G05 / Core v5
-- Atomic position, cash-flow, income and basis calculation inputs.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, PortfolioID, SecurityID, Date
CREATE TABLE `gold`.`fact_daily_returns_base` (
    `DailyReturnsBaseID` BIGINT NOT NULL COMMENT 'Identifier for daily returns base at this table grain.',
    `AuditUser` STRING COMMENT '@AuditUser parameter. Typically \'Mantis7314Fix\' for batch runs.',
    `AuditDate` TIMESTAMP_NTZ COMMENT 'GETDATE() at INSERT time.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` BIGINT NOT NULL COMMENT 'Fund/entity identifier.',
    `PortfolioID` BIGINT NOT NULL COMMENT 'Portfolio identifier.',
    `SecurityID` BIGINT NOT NULL COMMENT 'Security/instrument identifier.',
    `Date` TIMESTAMP_NTZ NOT NULL COMMENT 'Observation date.',
    `Numerator` DECIMAL(30,14) COMMENT 'Income−Amm+DayPurchaseIncome+DaySaleIncome+DayPositionIncome−ManualBasisIn−CallBasis+CallIncome+TransferBasisOut+ManualBasisOut+ManualBasisIncome+DistBasis+DistIncome−InKindUG+InKindUGOut.',
    `Denominator` DECIMAL(30,14) COMMENT 'ABS(PriorMV) + capital deployment. Direction-aware based on PriorQuantity sign.',
    `whIncome` DECIMAL(30,14) COMMENT 'Income from FunctionCodes 1004/1005/1014/1015/1016, AccountType 4 or 5.',
    `Amm` DECIMAL(30,14) COMMENT 'Amortization from FunctionCode 1006. Subtracted from income in Numerator.',
    `Book` DECIMAL(30,14) COMMENT 'Current security price × ExRate (fn_GetMax_SecurityValue fallback to BookValue then TaxBasis).',
    `Quantity` DECIMAL(30,14) COMMENT 'Current period-end quantity from OpenPosition.',
    `BuyCost` DECIMAL(30,14) COMMENT 'Weighted avg cost per unit for buy transactions: SUM(TotalCost×ExRate)/SUM(BuyQty).',
    `BuyQuantity` DECIMAL(30,14) COMMENT 'Total units purchased this date.',
    `PriorBook` DECIMAL(30,14) COMMENT 'Prior-day security price × ExRate.',
    `PriorQuantity` DECIMAL(30,14) COMMENT 'Prior period-end quantity. PriorQty=0 means new position.',
    `SellCost` DECIMAL(30,14) COMMENT 'Weighted avg cost per unit for sell transactions.',
    `SellQuantity` DECIMAL(30,14) COMMENT 'Total units sold this date.',
    `TransferQuantity` DECIMAL(30,14) COMMENT 'Transfer Quantity value populated by etl.usp_Load_29_Fact_DailyReturnsBase.',
    `InKindUG` DECIMAL(30,14) COMMENT 'Total in-kind transfer unrealized gain. Subtracted from Numerator.',
    `TransferValue` DECIMAL(30,14) COMMENT 'Transfer Value value populated by etl.usp_Load_29_Fact_DailyReturnsBase.',
    `CallBasis` DECIMAL(30,14) COMMENT 'Capital calls: SecurityCall.Amount × ExRate. Added to Denominator.',
    `CallIncome` DECIMAL(30,14) COMMENT 'Call fee income: SecurityCall.AmountFees × −1 × ExRate. Added to Numerator.',
    `DistributionBasis` DECIMAL(30,14) COMMENT 'Return of capital distributions. Added to Numerator.',
    `DistributionIncome` DECIMAL(30,14) COMMENT 'Income distributions. Added to Numerator.',
    `TransferBasisOut` DECIMAL(30,14) COMMENT 'Basis transferred out: PortfolioTransactionTransfer → BasisAdjustment (FK_GLID_From).',
    `TransferBasisIn` DECIMAL(30,14) COMMENT 'Basis transferred in: PortfolioTransactionTransfer → BasisAdjustment (FK_GLID_To).',
    `ManualBasisIn` DECIMAL(30,14) COMMENT 'Manual GL basis additions from BasisAdjustment, FunctionCodes 1018/1012. Subtracted from Numerator.',
    `ManualBasisOut` DECIMAL(30,14) COMMENT 'Manual GL basis reductions. Added to Numerator.',
    `ManualBasisIncome` DECIMAL(30,14) COMMENT 'FunctionCode 1018 income component. Added to Numerator.',
    `DayPurchaseIncome` DECIMAL(30,14) COMMENT '(CurrentPrice−BuyCost/Mult)×BuyQty×Mult. P&L on purchases this day.',
    `DaySaleIncome` DECIMAL(30,14) COMMENT '(SellCost/Mult−CurrentPrice)×SellQty×Mult. P&L on sales this day.',
    `DayPositionIncome` DECIMAL(30,14) COMMENT '(CurrentPrice×HoldQty×Mult×ExRate)−(PriorPrice×PriorQty×Mult×PriorExRate). MTM P&L.',
    `InKindUGIn` DECIMAL(30,14) COMMENT 'In-kind UG on transfers IN (Buy-side + gift-in). Added to Denominator.',
    `InKindUGOut` DECIMAL(30,14) COMMENT 'In-kind UG on transfers OUT (Sell-side + gift-out). Added to Numerator.',
    `SourceBaseID` BIGINT COMMENT 'Identifier of the originating source row for Base lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Reporting monetary basis used by kernel; do not infer all reporting amounts are USD.',
    `InputPolicyID` STRING NOT NULL COMMENT 'Recognition, netting, valuation and other kernel-input policy identity.',
    `ComponentRole` STRING NOT NULL COMMENT 'Native performance component/perspective role; prevents summing overlapping representations.',
    CONSTRAINT `fact_daily_returns_base_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T30 / G05 / Core v5
-- Realized gains, manual basis permutations and tax lots.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, FundID, PortfolioID, SecurityID, Date, UniqueIdentifyingID, LotSuffix, OpenGLID, CloseGLID, LocalCurrency, ReportingCurrency
CREATE TABLE `gold`.`fact_realized_gains_tax_lot` (
    `RealizedGainsTaxLotID` BIGINT NOT NULL COMMENT 'Identifier for realized gains tax lot at this table grain.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `PortfolioID` INT NOT NULL COMMENT 'Portfolio identifier.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `Date` DATE NOT NULL COMMENT 'Observation/performance date.',
    `UniqueIdentifyingID` STRING NOT NULL COMMENT 'Identifier for unique identifying at this table grain.',
    `LotSuffix` STRING NOT NULL COMMENT 'Lot Suffix value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `OpenGLID` BIGINT COMMENT 'Identifier for open gl at this table grain.',
    `CloseGLID` BIGINT COMMENT 'Identifier for close gl at this table grain.',
    `OpenDate` DATE COMMENT 'Date associated with open.',
    `CloseDate` DATE COMMENT 'Date associated with close.',
    `PurchasePrice` DECIMAL(30,14) COMMENT 'Purchase Price value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `SalePrice` DECIMAL(30,14) COMMENT 'Sale Price value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `Quantity` DECIMAL(30,14) COMMENT 'Quantity value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingOpeningCost` DECIMAL(30,14) COMMENT 'Reporting Opening Cost value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingClosingCost` DECIMAL(30,14) COMMENT 'Reporting Closing Cost value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingPriorOpenMarketValue` DECIMAL(30,14) COMMENT 'Reporting Prior Open Market Value value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingCurrentOpenMarketValue` DECIMAL(30,14) COMMENT 'Reporting Current Open Market Value value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisIn_TranOpen_GLClose` DECIMAL(30,14) COMMENT 'Local Manual Basis In Tran Open GLClose value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisOut_TranOpen_GLClose` DECIMAL(30,14) COMMENT 'Local Manual Basis Out Tran Open GLClose value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisIn_TranClose_GLOpen` DECIMAL(30,14) COMMENT 'Local Manual Basis In Tran Close GLOpen value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisOut_TranClose_GLOpen` DECIMAL(30,14) COMMENT 'Local Manual Basis Out Tran Close GLOpen value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisIn_GLClose_TranOpen` DECIMAL(30,14) COMMENT 'Local Manual Basis In GLClose Tran Open value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisOut_GLClose_TranOpen` DECIMAL(30,14) COMMENT 'Local Manual Basis Out GLClose Tran Open value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisIn_GLOpen_TranClose` DECIMAL(30,14) COMMENT 'Local Manual Basis In GLOpen Tran Close value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LocalManualBasisOut_GLOpen_TranClose` DECIMAL(30,14) COMMENT 'Local Manual Basis Out GLOpen Tran Close value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisIn_TranOpen_GLClose` DECIMAL(30,14) COMMENT 'Reporting Manual Basis In Tran Open GLClose value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisOut_TranOpen_GLClose` DECIMAL(30,14) COMMENT 'Reporting Manual Basis Out Tran Open GLClose value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisIn_TranClose_GLOpen` DECIMAL(30,14) COMMENT 'Reporting Manual Basis In Tran Close GLOpen value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisOut_TranClose_GLOpen` DECIMAL(30,14) COMMENT 'Reporting Manual Basis Out Tran Close GLOpen value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisIn_GLClose_TranOpen` DECIMAL(30,14) COMMENT 'Reporting Manual Basis In GLClose Tran Open value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisOut_GLClose_TranOpen` DECIMAL(30,14) COMMENT 'Reporting Manual Basis Out GLClose Tran Open value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisIn_GLOpen_TranClose` DECIMAL(30,14) COMMENT 'Reporting Manual Basis In GLOpen Tran Close value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingManualBasisOut_GLOpen_TranClose` DECIMAL(30,14) COMMENT 'Reporting Manual Basis Out GLOpen Tran Close value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingSpinoff` DECIMAL(30,14) COMMENT 'Reporting Spinoff value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingMerger` DECIMAL(30,14) COMMENT 'Reporting Merger value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingIRRBasisCashFlow` DECIMAL(30,14) COMMENT 'Reporting IRRBasis Cash Flow value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `ReportingIRREndingBasis` DECIMAL(30,14) COMMENT 'Ending basis used as the XIRR closing leg.',
    `ReportingIRREndingShortAdj` DECIMAL(30,14) COMMENT 'Adjustment required to reconcile XIRR for short positions.',
    `LongShortMultiplier` SMALLINT NOT NULL COMMENT 'Direction multiplier, normally +1 for long and -1 for short.',
    `LocalCurrency` STRING COMMENT 'Currency in which the source position or transaction is denominated.',
    `ReportingCurrency` STRING COMMENT 'Currency in which the report measure is expressed.',
    `SourceCategory` STRING COMMENT 'Source Category value populated by etl.usp_Load_30_Fact_RealizedGainsTaxLot.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceCompletenessCode` STRING NOT NULL COMMENT 'Code describing which source components were available for the tax-lot calculation.',
    `IsComplete` BOOLEAN NOT NULL COMMENT '1 when required source components for the row were complete.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `fact_realized_gains_tax_lot_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T31 / G04 / Core v5
-- Normalized GL postings, converted amounts and flags.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, GLID, GLRowID
CREATE TABLE `gold`.`fact_general_ledger_activity` (
    `GeneralLedgerActivityID` BIGINT NOT NULL COMMENT 'Identifier for general ledger activity at this table grain.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `PortfolioID` INT COMMENT 'Portfolio identifier.',
    `SecurityID` INT COMMENT 'Security/instrument identifier.',
    `COAID` INT COMMENT 'Chart-of-accounts identifier.',
    `FunctionCodeID` INT COMMENT 'Identifier for function code at this table grain.',
    `GLID` BIGINT NOT NULL COMMENT 'Identifier for gl at this table grain.',
    `GLRowID` BIGINT NOT NULL COMMENT 'Identifier for glrow at this table grain.',
    `GLDate` DATE NOT NULL COMMENT 'Date associated with gl.',
    `GLAccountCode` STRING COMMENT 'GLAccount Code value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `Debit` DECIMAL(30,14) NOT NULL COMMENT 'Debit value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `Credit` DECIMAL(30,14) NOT NULL COMMENT 'Credit value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `LocalAmount` DECIMAL(30,14) COMMENT 'Local Amount value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `GLCurrency` STRING COMMENT 'GLCurrency value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `GLBaseCurrency` STRING COMMENT 'GLBase Currency value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `GLExchangeRate` DECIMAL(30,14) COMMENT 'GLExchange Rate value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `MultiCurrencyMultiplier` DECIMAL(30,14) COMMENT 'Multi Currency Multiplier value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `ReportingAmount` DECIMAL(30,14) COMMENT 'Reporting Amount value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `IsIncome` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether income applies.',
    `IsAccrual` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether accrual applies.',
    `IsAP` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether ap applies.',
    `IsBasisAdjustment` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether basis adjustment applies.',
    `IsSettlement` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether settlement applies.',
    `AuditUser` STRING COMMENT 'Audit User value populated by etl.usp_Load_31_Fact_GeneralLedgerActivity.',
    `AuditDate` TIMESTAMP_NTZ COMMENT 'Date associated with audit.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `fact_general_ledger_activity_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T32 / G06 / Core v5
-- Allocated investor cash flow and GL/transaction activity.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SourceTransactionID, SourceGLID, ActivityDate, FundID, PortfolioID, ProfileID, SecurityID, COAID, ActivityType, LocalCurrency, ReportingCurrency
CREATE TABLE `gold`.`fact_investor_activity` (
    `InvestorActivityKey` BIGINT NOT NULL COMMENT 'Surrogate or durable key for investor activity.',
    `ActivityDate` DATE NOT NULL COMMENT 'Date associated with activity.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `PortfolioID` INT COMMENT 'Portfolio identifier.',
    `ProfileID` INT COMMENT 'Investor profile identifier.',
    `SecurityID` INT COMMENT 'Security/instrument identifier.',
    `COAID` INT COMMENT 'Chart-of-accounts identifier.',
    `ActivityType` STRING NOT NULL COMMENT 'Activity Type value populated by etl.usp_Load_32_Fact_InvestorActivity.',
    `LocalCurrency` STRING COMMENT 'Currency in which the source position or transaction is denominated.',
    `ReportingCurrency` STRING NOT NULL COMMENT 'Currency in which the report measure is expressed.',
    `LocalAmount` DECIMAL(28,12) NOT NULL COMMENT 'Local Amount value populated by etl.usp_Load_32_Fact_InvestorActivity.',
    `ReportingAmount` DECIMAL(28,12) NOT NULL COMMENT 'Reporting Amount value populated by etl.usp_Load_32_Fact_InvestorActivity.',
    `Quantity` DECIMAL(28,12) COMMENT 'Quantity value populated by etl.usp_Load_32_Fact_InvestorActivity.',
    `SourceTransactionID` BIGINT COMMENT 'Identifier of the originating source row for Transaction lineage.',
    `SourceGLID` BIGINT COMMENT 'Identifier of the originating source row for GL lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `fact_investor_activity_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T33 / G07 / Core v5
-- As-of security classification and display details.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, CustomerID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, ModelVersion
CREATE TABLE `gold`.`snap_security_classification` (
    `SecurityClassificationSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for security classification snapshot at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `MajorSecurityClassID` INT NOT NULL COMMENT 'Identifier of the major security-class definition.',
    `MajorSecurityClassOptionID` INT NOT NULL COMMENT 'Identifier of the major security-class option assigned to the security/report slice.',
    `MajorSecurityClassOptionName` STRING NOT NULL COMMENT 'Major Security Class Option Name value populated by etl.usp_Load_33_Snap_SecurityClassification.',
    `MajorSortOrder` INT NOT NULL COMMENT 'Major Sort Order value populated by etl.usp_Load_33_Snap_SecurityClassification.',
    `MinorSecurityClassID` INT NOT NULL COMMENT 'Identifier of the minor security-class definition.',
    `MinorSecurityClassOptionID` INT NOT NULL COMMENT 'Identifier of the minor security-class option assigned to the security/report slice.',
    `MinorSecurityClassOptionName` STRING NOT NULL COMMENT 'Minor Security Class Option Name value populated by etl.usp_Load_33_Snap_SecurityClassification.',
    `MinorSortOrder` INT NOT NULL COMMENT 'Minor Sort Order value populated by etl.usp_Load_33_Snap_SecurityClassification.',
    `CashOrCashEquivalent` BOOLEAN NOT NULL COMMENT 'Cash Or Cash Equivalent value populated by etl.usp_Load_33_Snap_SecurityClassification.',
    `IsOtherAsset` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether other asset applies.',
    `SourceMajorEffectiveDate` DATE COMMENT 'Date associated with source major effective.',
    `SourceMinorEffectiveDate` DATE COMMENT 'Date associated with source minor effective.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    CONSTRAINT `snap_security_classification_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T34 / G08 / Core v5
-- As-of calculation and report display inception dates.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, CustomerID, FundID, GroupingType, PageGroupingID, MasterFeederFlag, LookThroughFlag, RollupLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, ContinuousBasisFlag, ModelVersion, ReportContextKey, ReportTimePeriodID, ReportNodeID, ReportingCurrencyCode
CREATE TABLE `gold`.`snap_inception_dates` (
    `InceptionDateSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for inception date snapshot at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `RollupLevel` STRING NOT NULL COMMENT 'Report aggregation level represented by the row.',
    `SecurityClassOptionMajorID` INT NOT NULL COMMENT 'Major security-class option at the report/snapshot grain.',
    `SecurityClassOptionMinorID` INT NOT NULL COMMENT 'Minor security-class option at the report/snapshot grain.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `InceptionDate` DATE NOT NULL COMMENT 'Date associated with inception.',
    `InceptionDateDisplay` DATE NOT NULL COMMENT 'Inception Date Display value populated by etl.usp_Load_34_Snap_InceptionDates.',
    `ContinuousBasisFlag` BOOLEAN NOT NULL COMMENT 'Basis-eligibility mode requiring continuous basis where configured.',
    `SourceRowCount` BIGINT NOT NULL COMMENT 'Source Row Count value populated by etl.usp_Load_34_Snap_InceptionDates.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `MajorSecurityClassID` INT COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT COMMENT 'Identifier of the minor security-class definition.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `PublicationRunID` STRING COMMENT 'Execution/publication identifier that groups rows written by one snapshot publication run.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact economic report context; included in semantic uniqueness and publication scope.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Resolved period/window identity. Valuation endpoint records use their linked report window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Exact typed node whose value/presence is published.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable generation shared by all report result components; readers pin once per report.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Exact computation against frozen inputs/rules, distinct from job run.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Explicit reporting basis in result uniqueness; no cross-currency overwrite.',
    CONSTRAINT `snap_inception_dates_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T35 / G08 / Core v5
-- Pre-aggregated TW/XIRR inputs, eligibility and period coverage.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, CustomerID, FundID, GroupingType, PageGroupingID, MasterFeederFlag, LookThroughFlag, RollupLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, PeriodKey, PeriodStartDate, PeriodEndDate, FeeType, DetailType, IsRolling, BeginningEndingBasis, ContinuousBasis, ModelVersion, ReportContextKey, ReportTimePeriodID, ReportNodeID, ReportingCurrencyCode
CREATE TABLE `gold`.`snap_period_performance` (
    `PeriodPerformanceSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for period performance snapshot at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `RollupLevel` STRING NOT NULL COMMENT 'Report aggregation level represented by the row.',
    `SecurityClassOptionMajorID` INT NOT NULL COMMENT 'Major security-class option at the report/snapshot grain.',
    `SecurityClassOptionMinorID` INT NOT NULL COMMENT 'Minor security-class option at the report/snapshot grain.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `PeriodKey` STRING NOT NULL COMMENT 'Canonical period label such as Period, MTD, QTD, YTD, ITD, or a rolling/calendar multi-year horizon.',
    `PeriodStartDate` DATE NOT NULL COMMENT 'Inclusive first date of the resolved period window.',
    `PeriodEndDate` DATE NOT NULL COMMENT 'Inclusive final date of the resolved period window.',
    `PeriodDays` INT NOT NULL COMMENT 'Number of calendar days in the resolved period window.',
    `FeeType` STRING NOT NULL COMMENT 'Fee treatment for the row, such as gross or net of fees.',
    `DetailType` STRING NOT NULL COMMENT 'Report detail/total classification used to distinguish security, grouping, benchmark, or total rows.',
    `SumReportingNumerator` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Numerator value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingPriorBasis` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Prior Basis value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingBasisChange` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Basis Change value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingCashFlowAdj` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Cash Flow Adj value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingEndingBasis` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Ending Basis value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingMarketValue` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Market Value value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingCashFlow` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting Cash Flow value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingIRREndingBasis` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting IRREnding Basis value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumReportingIRREndingShortAdj` DECIMAL(38,12) NOT NULL COMMENT 'Sum Reporting IRREnding Short Adj value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumPriorBasisXLSM` DECIMAL(38,12) NOT NULL COMMENT 'Sum Prior Basis XLSM value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `SumBasisChangeXNeg` DECIMAL(38,12) NOT NULL COMMENT 'Sum Basis Change XNeg value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `OpeningIRRMarketValue` DECIMAL(38,12) NOT NULL COMMENT 'Opening IRRMarket Value value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `ClosingIRRMarketValue` DECIMAL(38,12) NOT NULL COMMENT 'Closing IRRMarket Value value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `TWRReturnRaw` DOUBLE COMMENT 'Raw time-weighted return produced from period components before final display/annualization treatment.',
    `XIRRReturnRaw` DOUBLE COMMENT 'Raw money-weighted XIRR return produced from dated cash flows and opening/closing legs.',
    `XIRRShortReturnMultiplier` SMALLINT NOT NULL COMMENT 'XIRRShort Return Multiplier value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `InPositionFlag` BOOLEAN NOT NULL COMMENT 'In Position Flag value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `InPositionEnd` BOOLEAN NOT NULL COMMENT 'In Position End value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `DirectionChanged` BOOLEAN NOT NULL COMMENT '1 when the position changed between net long and net short within the evaluated window.',
    `LongShortNettingEnabled` BOOLEAN NOT NULL COMMENT 'Customer setting indicating whether long and short positions are netted in performance logic.',
    `IsBalanceForward` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether balance forward applies.',
    `DailyRowCount` INT NOT NULL COMMENT 'Daily Row Count value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `CashFlowEventCount` INT NOT NULL COMMENT 'Cash Flow Event Count value populated by etl.usp_Load_35_Snap_PeriodPerformance.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `MajorSecurityClassID` INT COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT COMMENT 'Identifier of the minor security-class definition.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `IsRolling` BOOLEAN COMMENT '1 for rolling windows and 0 for calendar-based windows where applicable.',
    `CoverageStatus` STRING COMMENT 'Named data-coverage assessment for the requested window, such as Complete or an identified prerequisite gap.',
    `InceptionDateUsed` DATE COMMENT 'Inception date actually used to resolve the ITD or eligibility window for this row.',
    `IsCompleteWindow` BOOLEAN NOT NULL COMMENT '1 when the complete required history/window is available and the return may be published; otherwise 0.',
    `PublicationRunID` STRING COMMENT 'Execution/publication identifier that groups rows written by one snapshot publication run.',
    `BeginningEndingBasis` BOOLEAN COMMENT 'Beginning/ending basis policy selection carried by this context/result; do not conflate with continuous-basis selection.',
    `ContinuousBasis` BOOLEAN COMMENT 'Continuous basis policy selection carried by this context/result; key and publish independently from other approved policies.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact economic report context; included in semantic uniqueness and publication scope.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Resolved period/window identity. Valuation endpoint records use their linked report window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Exact typed node whose value/presence is published.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable generation shared by all report result components; readers pin once per report.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Exact computation against frozen inputs/rules, distinct from job run.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Explicit reporting basis in result uniqueness; no cross-currency overwrite.',
    CONSTRAINT `snap_period_performance_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T36 / G08 / Core v5
-- Period-aligned benchmark return calculations.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, CustomerID, FundID, GroupingType, PageGroupingID, MasterFeederFlag, LookThroughFlag, RollupLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, PeriodKey, PeriodStartDate, PeriodEndDate, BenchmarkRateID, IsRolling, ModelVersion, ReportContextKey, ReportTimePeriodID, ReportNodeID, ReportingCurrencyCode
CREATE TABLE `gold`.`snap_benchmark_returns_by_period` (
    `BenchmarkReturnSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for benchmark return snapshot at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `RollupLevel` STRING NOT NULL COMMENT 'Report aggregation level represented by the row.',
    `SecurityClassOptionMajorID` INT NOT NULL COMMENT 'Major security-class option at the report/snapshot grain.',
    `SecurityClassOptionMinorID` INT NOT NULL COMMENT 'Minor security-class option at the report/snapshot grain.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `PeriodKey` STRING NOT NULL COMMENT 'Canonical period label such as Period, MTD, QTD, YTD, ITD, or a rolling/calendar multi-year horizon.',
    `PeriodStartDate` DATE NOT NULL COMMENT 'Inclusive first date of the resolved period window.',
    `PeriodEndDate` DATE NOT NULL COMMENT 'Inclusive final date of the resolved period window.',
    `PeriodDays` INT NOT NULL COMMENT 'Number of calendar days in the resolved period window.',
    `BenchmarkRateID` INT NOT NULL COMMENT 'Identifier for benchmark rate at this table grain.',
    `BenchmarkReturnRaw` DECIMAL(28,12) COMMENT 'Benchmark Return Raw value populated by etl.usp_Load_36_Snap_BenchmarkReturnsByPeriod.',
    `BenchmarkReturnValue` DECIMAL(28,12) COMMENT 'Benchmark return aligned to the report period and assignment.',
    `BenchmarkReturnAnnualised` DECIMAL(28,12) COMMENT 'Benchmark Return Annualised value populated by etl.usp_Load_36_Snap_BenchmarkReturnsByPeriod.',
    `IsCompleteWindow` BOOLEAN NOT NULL COMMENT '1 when the complete required history/window is available and the return may be published; otherwise 0.',
    `MajorSecurityClassID` INT COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT COMMENT 'Identifier of the minor security-class definition.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `IsRolling` BOOLEAN COMMENT '1 for rolling windows and 0 for calendar-based windows where applicable.',
    `PublicationRunID` STRING COMMENT 'Execution/publication identifier that groups rows written by one snapshot publication run.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact economic report context; included in semantic uniqueness and publication scope.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Resolved period/window identity. Valuation endpoint records use their linked report window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Exact typed node whose value/presence is published.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable generation shared by all report result components; readers pin once per report.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Exact computation against frozen inputs/rules, distinct from job run.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Explicit reporting basis in result uniqueness; no cross-currency overwrite.',
    CONSTRAINT `snap_benchmark_returns_by_period_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T37 / G08 / Core v5
-- Period-aware financial return and benchmark snapshot.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, CustomerID, FundID, GroupingType, PageGroupingID, MasterFeederFlag, LookThroughFlag, RollupLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, PeriodKey, PeriodStartDate, PeriodEndDate, CalcMethod, FeeType, DetailType, IsRolling, BeginningEndingBasis, ContinuousBasis, ModelVersion, ReportContextKey, ReportTimePeriodID, ReportNodeID, ReportingCurrencyCode
CREATE TABLE `gold`.`snap_returns_by_period` (
    `ReturnSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for return snapshot at this table grain.',
    `PeriodPerformanceSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for period performance snapshot at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `RollupLevel` STRING NOT NULL COMMENT 'Report aggregation level represented by the row.',
    `SecurityClassOptionMajorID` INT NOT NULL COMMENT 'Major security-class option at the report/snapshot grain.',
    `SecurityClassOptionMinorID` INT NOT NULL COMMENT 'Minor security-class option at the report/snapshot grain.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `PeriodKey` STRING NOT NULL COMMENT 'Canonical period label such as Period, MTD, QTD, YTD, ITD, or a rolling/calendar multi-year horizon.',
    `PeriodStartDate` DATE NOT NULL COMMENT 'Inclusive first date of the resolved period window.',
    `PeriodEndDate` DATE NOT NULL COMMENT 'Inclusive final date of the resolved period window.',
    `PeriodDays` INT NOT NULL COMMENT 'Number of calendar days in the resolved period window.',
    `CalcMethod` STRING NOT NULL COMMENT 'Selected return method, normally TW/TWR or XIRR.',
    `FeeType` STRING NOT NULL COMMENT 'Fee treatment for the row, such as gross or net of fees.',
    `DetailType` STRING NOT NULL COMMENT 'Report detail/total classification used to distinguish security, grouping, benchmark, or total rows.',
    `ReturnValue` DOUBLE COMMENT 'Selected display return for the configured calculation method and period.',
    `ReturnValueAnnualised` DOUBLE COMMENT 'Return annualized according to period length, eligibility, and annualize/de-annualize rules.',
    `ReturnValueCumulative` DOUBLE COMMENT 'Non-annualized cumulative return for the complete period.',
    `IsInvalid` BOOLEAN NOT NULL COMMENT '1 when the return is mathematically invalid or suppressed, including direction-change conditions.',
    `IsInPosition` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether in position applies.',
    `InPositionEnd` BOOLEAN NOT NULL COMMENT 'In Position End value populated by etl.usp_Load_37_Snap_ReturnsByPeriod.',
    `DirectionChanged` BOOLEAN NOT NULL COMMENT '1 when the position changed between net long and net short within the evaluated window.',
    `LongShortNettingEnabled` BOOLEAN NOT NULL COMMENT 'Customer setting indicating whether long and short positions are netted in performance logic.',
    `IsBalanceForward` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether balance forward applies.',
    `BenchmarkRateID` INT COMMENT 'Identifier for benchmark rate at this table grain.',
    `BenchmarkReturnValue` DOUBLE COMMENT 'Benchmark return aligned to the report period and assignment.',
    `BenchmarkReturnValueAnnualised` DOUBLE COMMENT 'Annualized benchmark return aligned to the same eligibility rules as the report return.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `IsCompleteWindow` BOOLEAN NOT NULL COMMENT '1 when the complete required history/window is available and the return may be published; otherwise 0.',
    `MajorSecurityClassID` INT COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT COMMENT 'Identifier of the minor security-class definition.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `IsRolling` BOOLEAN COMMENT '1 for rolling windows and 0 for calendar-based windows where applicable.',
    `CoverageStatus` STRING COMMENT 'Named data-coverage assessment for the requested window, such as Complete or an identified prerequisite gap.',
    `InceptionDateUsed` DATE COMMENT 'Inception date actually used to resolve the ITD or eligibility window for this row.',
    `PublicationRunID` STRING COMMENT 'Execution/publication identifier that groups rows written by one snapshot publication run.',
    `BeginningEndingBasis` BOOLEAN COMMENT 'Beginning/ending basis policy selection carried by this context/result; do not conflate with continuous-basis selection.',
    `ContinuousBasis` BOOLEAN COMMENT 'Continuous basis policy selection carried by this context/result; key and publish independently from other approved policies.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact economic report context; included in semantic uniqueness and publication scope.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Resolved period/window identity. Valuation endpoint records use their linked report window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Exact typed node whose value/presence is published.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable generation shared by all report result components; readers pin once per report.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Exact computation against frozen inputs/rules, distinct from job run.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Explicit reporting basis in result uniqueness; no cross-currency overwrite.',
    CONSTRAINT `snap_returns_by_period_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T38 / G08 / Core v5
-- Beginning/ending MV and basis snapshot.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, BeginDate, CustomerID, FundID, GroupingType, PageGroupingID, MasterFeederFlag, LookThroughFlag, RollupLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, FeeType, DetailType, ModelVersion, ReportContextKey, ReportTimePeriodID, ReportNodeID, ReportingCurrencyCode, ValuationPolicyID
CREATE TABLE `gold`.`snap_market_value_latest` (
    `MarketValueSnapshotID` BIGINT NOT NULL COMMENT 'Identifier for market value snapshot at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `BeginDate` DATE NOT NULL COMMENT 'Date associated with begin.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `RollupLevel` STRING NOT NULL COMMENT 'Report aggregation level represented by the row.',
    `SecurityClassOptionMajorID` INT NOT NULL COMMENT 'Major security-class option at the report/snapshot grain.',
    `SecurityClassOptionMinorID` INT NOT NULL COMMENT 'Minor security-class option at the report/snapshot grain.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `FeeType` STRING NOT NULL COMMENT 'Fee treatment for the row, such as gross or net of fees.',
    `DetailType` STRING NOT NULL COMMENT 'Report detail/total classification used to distinguish security, grouping, benchmark, or total rows.',
    `BeginningMarketValue` DECIMAL(38,12) COMMENT 'Market value at the opening comparison date, normally the calendar day before the report start.',
    `EndingMarketValue` DECIMAL(38,12) COMMENT 'Market value at the report/snapshot end date.',
    `BeginningBasis` DECIMAL(38,12) COMMENT 'Basis at the opening comparison date.',
    `EndingBasis` DECIMAL(38,12) COMMENT 'Basis at the report/snapshot end date.',
    `InPositionBeginning` BOOLEAN NOT NULL COMMENT 'In Position Beginning value populated by etl.usp_Load_38_Snap_MarketValueLatest.',
    `InPositionEnd` BOOLEAN NOT NULL COMMENT 'In Position End value populated by etl.usp_Load_38_Snap_MarketValueLatest.',
    `UsedEstimatedPrice` BOOLEAN NOT NULL COMMENT 'Used Estimated Price value populated by etl.usp_Load_38_Snap_MarketValueLatest.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `MajorSecurityClassID` INT COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT COMMENT 'Identifier of the minor security-class definition.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `BeginningValueStatus` STRING COMMENT 'Beginning Value Status value populated by etl.usp_Load_38_Snap_MarketValueLatest.',
    `PublicationRunID` STRING COMMENT 'Execution/publication identifier that groups rows written by one snapshot publication run.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact economic report context; included in semantic uniqueness and publication scope.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Resolved period/window identity. Valuation endpoint records use their linked report window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Exact typed node whose value/presence is published.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable generation shared by all report result components; readers pin once per report.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Exact computation against frozen inputs/rules, distinct from job run.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Explicit reporting basis in result uniqueness; no cross-currency overwrite.',
    `HasValuation` BOOLEAN NOT NULL COMMENT 'Explicit valuation-row presence, even when performance is absent.',
    `HasActivity` BOOLEAN NOT NULL COMMENT 'Selected monetary object has activity in the reporting window.',
    `HasReturnObservation` BOOLEAN NOT NULL COMMENT 'A matching return observation exists; false does not mean zero return.',
    `ReturnEligibilityStatus` STRING NOT NULL COMMENT 'VALID / NOT_APPLICABLE / INSUFFICIENT_HISTORY / UNKNOWN_INCEPTION / INVALID as approved.',
    `PresenceReason` STRING NOT NULL COMMENT 'Reason the node is present: valuation/activity/return/required hierarchy.',
    `ValuationPolicyID` STRING NOT NULL COMMENT 'Accrual/price/monetary-view policy identity used for these values.',
    CONSTRAINT `snap_market_value_latest_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T39 / G08 / Core v5
-- Published BI period returns, copied from accepted snapshot.
-- Proposed business / merge key: SourceEnvironmentCode, SnapshotDate, CustomerID, FundID, GroupingType, PageGroupingID, MasterFeederFlag, LookThroughFlag, RollupLevel, SecurityClassOptionMajorID, SecurityClassOptionMinorID, SecurityID, MajorSecurityClassID, MinorSecurityClassID, PeriodKey, PeriodStartDate, PeriodEndDate, CalcMethod, FeeType, DetailType, IsRolling, BeginningEndingBasis, ContinuousBasis, ModelVersion, ReportContextKey, ReportTimePeriodID, ReportNodeID, ReportingCurrencyCode
CREATE TABLE `gold`.`fact_returns_by_period` (
    `ReturnsByPeriodID` BIGINT NOT NULL COMMENT 'Identifier for returns by period at this table grain.',
    `SnapshotDate` DATE NOT NULL COMMENT 'As-of date represented by the snapshot row.',
    `CustomerID` INT NOT NULL COMMENT 'Archway customer/tenant identifier.',
    `FundID` INT NOT NULL COMMENT 'Fund/entity identifier.',
    `GroupingType` STRING NOT NULL COMMENT 'Type of report page/grouping object, for example Profile, Entity, Portfolio, or class option.',
    `PageGroupingID` BIGINT NOT NULL COMMENT 'Surrogate identifier of the normalized report page/grouping object.',
    `MasterFeederFlag` STRING NOT NULL COMMENT 'Indicates the master/feeder reporting mode represented by the row.',
    `LookThroughFlag` BOOLEAN NOT NULL COMMENT '1 when nested holdings are reported through to underlying positions.',
    `RollupLevel` STRING NOT NULL COMMENT 'Report aggregation level represented by the row.',
    `SecurityClassOptionMajorID` INT NOT NULL COMMENT 'Major security-class option at the report/snapshot grain.',
    `SecurityClassOptionMinorID` INT NOT NULL COMMENT 'Minor security-class option at the report/snapshot grain.',
    `SecurityID` INT NOT NULL COMMENT 'Security/instrument identifier.',
    `PeriodKey` STRING NOT NULL COMMENT 'Canonical period label such as Period, MTD, QTD, YTD, ITD, or a rolling/calendar multi-year horizon.',
    `PeriodStartDate` DATE NOT NULL COMMENT 'Inclusive first date of the resolved period window.',
    `PeriodEndDate` DATE NOT NULL COMMENT 'Inclusive final date of the resolved period window.',
    `PeriodDays` INT NOT NULL COMMENT 'Number of calendar days in the resolved period window.',
    `CalcMethod` STRING NOT NULL COMMENT 'Selected return method, normally TW/TWR or XIRR.',
    `FeeType` STRING NOT NULL COMMENT 'Fee treatment for the row, such as gross or net of fees.',
    `DetailType` STRING NOT NULL COMMENT 'Report detail/total classification used to distinguish security, grouping, benchmark, or total rows.',
    `ReturnValue` DOUBLE COMMENT 'Selected display return for the configured calculation method and period.',
    `ReturnValueAnnualised` DOUBLE COMMENT 'Return annualized according to period length, eligibility, and annualize/de-annualize rules.',
    `ReturnValueCumulative` DOUBLE COMMENT 'Non-annualized cumulative return for the complete period.',
    `IsInvalid` BOOLEAN NOT NULL COMMENT '1 when the return is mathematically invalid or suppressed, including direction-change conditions.',
    `IsInPosition` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether in position applies.',
    `DirectionChanged` BOOLEAN NOT NULL COMMENT '1 when the position changed between net long and net short within the evaluated window.',
    `LongShortNettingEnabled` BOOLEAN NOT NULL COMMENT 'Customer setting indicating whether long and short positions are netted in performance logic.',
    `IsBalanceForward` BOOLEAN NOT NULL COMMENT 'Boolean indicator for whether balance forward applies.',
    `BenchmarkRateID` INT COMMENT 'Identifier for benchmark rate at this table grain.',
    `BenchmarkReturnValue` DOUBLE COMMENT 'Benchmark return aligned to the report period and assignment.',
    `BenchmarkReturnValueAnnualised` DOUBLE COMMENT 'Annualized benchmark return aligned to the same eligibility rules as the report return.',
    `SourceSnapReturnID` BIGINT COMMENT 'Identifier of the originating source row for Snap Return lineage.',
    `LoadDts` TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when the row was loaded or last published by the datamart process.',
    `IsCompleteWindow` BOOLEAN NOT NULL COMMENT '1 when the complete required history/window is available and the return may be published; otherwise 0.',
    `MajorSecurityClassID` INT COMMENT 'Identifier of the major security-class definition.',
    `MinorSecurityClassID` INT COMMENT 'Identifier of the minor security-class definition.',
    `ModelVersion` SMALLINT NOT NULL COMMENT 'Version of the performance model that produced the row; current v5 publication rows use version 5.',
    `IsRolling` BOOLEAN COMMENT '1 for rolling windows and 0 for calendar-based windows where applicable.',
    `CoverageStatus` STRING COMMENT 'Named data-coverage assessment for the requested window, such as Complete or an identified prerequisite gap.',
    `InceptionDateUsed` DATE COMMENT 'Inception date actually used to resolve the ITD or eligibility window for this row.',
    `PublicationRunID` STRING COMMENT 'Execution/publication identifier that groups rows written by one snapshot publication run.',
    `BeginningEndingBasis` BOOLEAN COMMENT 'Beginning/ending basis policy selection carried by this context/result; do not conflate with continuous-basis selection.',
    `ContinuousBasis` BOOLEAN COMMENT 'Continuous basis policy selection carried by this context/result; key and publish independently from other approved policies.',
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact economic report context; included in semantic uniqueness and publication scope.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Resolved period/window identity. Valuation endpoint records use their linked report window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Exact typed node whose value/presence is published.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable generation shared by all report result components; readers pin once per report.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Exact computation against frozen inputs/rules, distinct from job run.',
    `ReportingCurrencyCode` STRING NOT NULL COMMENT 'Explicit reporting basis in result uniqueness; no cross-currency overwrite.',
    CONSTRAINT `fact_returns_by_period_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T40 / G05 / Extension*
-- Position valuation independent of return eligibility.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, MonetaryObjectID, ObjectType, FundID, PortfolioID, SecurityID, COAID, ValuationDate, LocalCurrencyCode, ReportingCurrencyCode, ValuationPolicyID
CREATE TABLE `gold`.`fact_position_valuation_daily` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `MonetaryObjectID` STRING NOT NULL COMMENT 'Source-qualified stable identity of position, account, cash or other monetary object.',
    `ObjectType` STRING NOT NULL COMMENT 'POSITION / COA / CASH / OTHER_ASSET; distinguishes monetary objects from security-only rows.',
    `FundID` BIGINT COMMENT 'Fund of the valued object.',
    `PortfolioID` BIGINT COMMENT 'Portfolio when applicable; null for fund/account-level valuation.',
    `SecurityID` BIGINT COMMENT 'Security when applicable; never fabricated for non-security assets.',
    `COAID` BIGINT COMMENT 'Ledger account for account/other-asset valuation.',
    `ValuationDate` DATE NOT NULL COMMENT 'Logical as-of valuation date, not necessarily latest price observation date.',
    `LocalCurrencyCode` STRING COMMENT 'Native monetary currency of the position.',
    `ReportingCurrencyCode` STRING COMMENT 'Output currency selected by the context.',
    `Quantity` DECIMAL(38,13) COMMENT 'Source quantity; instrument-specific valuation formula uses multiplier and chosen price.',
    `UnitPrice` DOUBLE COMMENT 'Selected value observation before instrument-specific adjustments.',
    `SecurityMultiplier` DOUBLE COMMENT 'Source instrument multiplier; precision/type verified in mapping.',
    `SourcePriceID` BIGINT COMMENT 'Selected original price observation key.',
    `SecurityPriceVersionID` STRING COMMENT 'Exact conformed price-record version used.',
    `PriceObservationDate` DATE COMMENT 'Date of the selected source price observation, separately retained from valuation date.',
    `FXRateRecordVersionID` STRING COMMENT 'Dated FX conversion observation or approved triangulation input-set reference.',
    `LocalMarketValue` DECIMAL(38,14) COMMENT 'Native value from approved instrument/valuation rules; not assumed recoverable from returns.',
    `ReportingMarketValue` DECIMAL(38,14) COMMENT 'Converted value with exact FX lineage and rounding policy.',
    `OpenAccruedAmount` DECIMAL(38,14) COMMENT 'Separately retained open accrued component; do not implicitly add to every view.',
    `ClosedAccruedAmount` DECIMAL(38,14) COMMENT 'Separately retained closed-position accrued component.',
    `ReportingBasis` DECIMAL(38,14) COMMENT 'Reporting basis under explicit basis policy, not necessarily market value.',
    `ValuationPolicyID` STRING COMMENT 'Pricing/accrual/basis view rules used for this observation.',
    `PresenceStatus` STRING COMMENT 'Position/account valuation is present, missing input or not applicable; distinguish absence from zero.',
    `PriceStatus` STRING COMMENT 'Final/estimated/stale/missing selection status; retained alongside source flags.',
    `ReturnEligibilityStatus` STRING COMMENT 'Independent eligibility of performance for this node; never filters away a valid valuation.',
    `OwnershipInputSetID` STRING COMMENT 'Exact dated ownership inputs for owner-scaled valuation, where applicable.',
    CONSTRAINT `fact_position_valuation_daily_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T41 / G01 / Extension*
-- Atomic signed transaction economic event fact.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, TransactionID
CREATE TABLE `gold`.`fact_transaction` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `TransactionID` BIGINT NOT NULL COMMENT 'Native transaction identity; use source environment/owner namespace.',
    `GLID` BIGINT COMMENT 'Linked ledger transaction identifier; not a replacement for TransactionID.',
    `CashGLID` BIGINT COMMENT 'Linked cash ledger event.',
    `FundID` BIGINT COMMENT 'Fund resolved through the portfolio at the approved effective date.',
    `PortfolioID` BIGINT COMMENT 'Trade portfolio.',
    `SecurityID` BIGINT COMMENT 'Traded security.',
    `TradeDate` DATE COMMENT 'Business trade date.',
    `SettlementDate` DATE COMMENT 'Settlement date, including trades crossing a report boundary.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Native transaction currency.',
    `TransactionTypeKey` BIGINT COMMENT 'Conformed transaction-type lookup; retain original type as source attribute.',
    `SourceTransactionType` STRING COMMENT 'Original transaction-type label retained unchanged.',
    `BuySell` STRING COMMENT 'Original trade side, used by approved sign conventions.',
    `Quantity` DECIMAL(38,13) COMMENT 'Source signed/unsigned quantity as provided; side is separate.',
    `UnitPrice` DECIMAL(38,13) COMMENT 'Source unit trade price; preserve source precision.',
    `TotalCost` DECIMAL(38,13) COMMENT 'Source total cost before report-specific economic sign interpretation.',
    `AccruedInterest` DECIMAL(38,13) COMMENT 'Source accrued interest component.',
    `CommissionComponents` ARRAY<STRUCT<ComponentCode:STRING,Amount:DECIMAL(38,13)>> COMMENT 'Retain Commission and Commission2..5 separately by component code; do not collapse fee taxonomy.',
    `TaxBasis` DECIMAL(38,13) COMMENT 'Source tax-basis attribute, not a replacement for approved realized-gain logic.',
    `EconomicEventKey` STRING NOT NULL COMMENT 'Cross-reference linking this record to GL/cash/PE representations of the same economic event.',
    `PerformanceRecognitionRole` STRING COMMENT 'Trade, settlement, cash or other role selected by an approved performance rule.',
    `SourceAuditDate` TIMESTAMP_NTZ COMMENT 'Source audit timestamp retained separately from TradeDate.',
    CONSTRAINT `fact_transaction_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T42 / G07 / Extension*
-- Reusable raw benchmark observations.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, SourceOwnerCustomerID, BenchmarkRateID, SourceObservationID, ObservationKind, SeriesVersion
CREATE TABLE `gold`.`fact_benchmark_observation` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `BenchmarkRateID` BIGINT COMMENT 'Benchmark definition identity qualified by source owner.',
    `SourceObservationID` BIGINT COMMENT 'Original benchmark observation key.',
    `ObservationDate` DATE COMMENT 'Date of the underlying level/return observation.',
    `ObservationKind` STRING NOT NULL COMMENT 'LEVEL / PERIOD_RETURN / SYNTHETIC_RETURN; source semantics must be verified.',
    `ObservedValue` DOUBLE COMMENT 'Original source double-precision observation value; do not assume this is a percentage return.',
    `ObservationStartDate` DATE COMMENT 'Start of observation interval when the value is a return.',
    `ObservationEndDate` DATE COMMENT 'End of observation interval when the value is a return.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Applicable series currency; null only when genuinely not meaningful.',
    `ReturnBasis` STRING COMMENT 'Price/total-return and gross/net basis of the benchmark series.',
    `SeriesVersion` STRING NOT NULL COMMENT 'Source publication/revision or synthetic-series definition version.',
    `SyntheticInputSetID` STRING COMMENT 'Constituents, weights, dates and observations for a synthetic benchmark, retained in audit.',
    `QualityStatus` STRING COMMENT 'Valid/missing/discontinued/duplicate/unresolved observation status.',
    CONSTRAINT `fact_benchmark_observation_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T43 / G01 / Extension*
-- Versioned allocation model and target classification.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, AllocationModelID, ValidFrom
CREATE TABLE `gold`.`dim_allocation_model` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `AllocationModelID` BIGINT COMMENT 'Native model identity qualified by source customer/environment.',
    `ModelName` STRING COMMENT 'Source allocation model name.',
    `ModelCode` STRING COMMENT 'Source model code.',
    `SecurityTypeModel` BOOLEAN COMMENT 'Source flag selecting security-type model behavior.',
    `SecurityClassModel` BOOLEAN COMMENT 'Source flag selecting security-class model behavior.',
    `SecurityClassID` BIGINT COMMENT 'Source classification definition used by the model, when applicable.',
    `ValidFrom` TIMESTAMP_NTZ COMMENT 'Approved effective start; otherwise explicitly observation-versioned, not fabricated history.',
    `ValidTo` TIMESTAMP_NTZ COMMENT 'Exclusive end of effective/observed version.',
    `ObservedAtUtc` TIMESTAMP COMMENT 'Time the model definition was observed in a source capture.',
    `HistoryStatus` STRING COMMENT 'BUSINESS_EFFECTIVE or OBSERVED_ONLY; missing historical semantics remain explicit.',
    CONSTRAINT `dim_allocation_model_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T44 / G07 / Extension*
-- Effective allocation weights and tolerances.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, AllocationModelVersionID, BindingSourceTable, BindingSourceID, SubjectType, FundID, PortfolioID, BucketType, BucketNativeID, EffectiveFrom
CREATE TABLE `gold`.`fact_allocation_target` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `AllocationModelID` BIGINT COMMENT 'Stable model identity.',
    `AllocationModelVersionID` STRING NOT NULL COMMENT 'Exact model definition version.',
    `BindingSourceTable` STRING NOT NULL COMMENT 'AllocationModel_Fund or AllocationModel_Portfolio; do not collapse native IDs.',
    `BindingSourceID` BIGINT NOT NULL COMMENT 'Original effective assignment row ID.',
    `SubjectType` STRING NOT NULL COMMENT 'FUND or PORTFOLIO assignment type.',
    `FundID` BIGINT COMMENT 'Bound fund for fund-level assignment.',
    `PortfolioID` BIGINT COMMENT 'Bound portfolio for portfolio-level assignment.',
    `BucketType` STRING NOT NULL COMMENT 'SECURITY_CLASS_OPTION or SECURITY_TYPE; type namespace is part of identity.',
    `BucketNativeID` BIGINT COMMENT 'Source class-option/type identifier; meaning qualified by BucketType.',
    `SecurityClassOptionID` BIGINT COMMENT 'Class-option FK populated only for matching bucket type.',
    `TargetWeightRaw` DECIMAL(38,14) COMMENT 'Source allocation value before approved percent/fraction normalization.',
    `TargetWeight` DECIMAL(38,14) COMMENT 'Normalized fractional weight, only after source unit is verified.',
    `TolerancePlus` DECIMAL(38,14) COMMENT 'Source upper tolerance; unit controlled by source flag.',
    `ToleranceMinus` DECIMAL(38,14) COMMENT 'Source lower tolerance; unit controlled by source flag.',
    `TolerancePercentage` BOOLEAN COMMENT 'Source indication of percentage-based tolerance.',
    `EffectiveFrom` DATE NOT NULL COMMENT 'Intersection start of assignment, target weight and model validity.',
    `EffectiveToExclusive` DATE COMMENT 'Intersection end of independently versioned assignment and target intervals.',
    CONSTRAINT `fact_allocation_target_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T45 / G04 / Extension*
-- Commitment and subscription contract identities.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ContractType, SourceContractID, ValidFrom
CREATE TABLE `gold`.`dim_investment_contract` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `InvestmentContractID` STRING NOT NULL COMMENT 'Stable identity from source namespace + contract type + native contract ID, not position key.',
    `ContractType` STRING NOT NULL COMMENT 'COMMITMENT or SUBSCRIPTION; additional types require approved contracts.',
    `SourceContractID` BIGINT NOT NULL COMMENT 'Original commitment/subscription identifier.',
    `PositionBusinessKey` STRING NOT NULL COMMENT 'Parent aggregate fund/portfolio/security/currency position; may have many contracts.',
    `FundID` BIGINT COMMENT 'Receiving fund/investing-book position fund per original record role.',
    `PortfolioID` BIGINT COMMENT 'Portfolio holding the commitment/subscription.',
    `SecurityID` BIGINT COMMENT 'Investment security associated with contract.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Contract denomination.',
    `ContractDate` DATE COMMENT 'Commitment/subscription contractual business date.',
    `FundingDate` DATE COMMENT 'Subscription funding date, distinct from contractual date.',
    `ExpirationDate` DATE COMMENT 'Commitment expiration date; preserve NULL policy.',
    `OriginalAmount` DECIMAL(38,14) COMMENT 'Amount on this distinct source contract; never sum multiple revisions.',
    `GLID` BIGINT COMMENT 'Linked source GL identity, where available.',
    `SourcePolicyComponents` ARRAY<STRUCT<ComponentCode:STRING,UpdatesMV:BOOLEAN,UpdatesCommitment:BOOLEAN,RecallablePercent:DECIMAL(38,14)>> COMMENT 'Contract default flags retained independently for call/fee/ROC/income components; event-level overrides remain separate.',
    `ValidFrom` TIMESTAMP_NTZ COMMENT 'Source-supported effective or observed start of this contract version.',
    `ValidTo` TIMESTAMP_NTZ COMMENT 'Exclusive end of contract version validity.',
    `HistoryStatus` STRING COMMENT 'Business-effective/observed-only history provenance.',
    CONSTRAINT `dim_investment_contract_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T46 / G05 / Extension*
-- Capital call/distribution component events and recognition policy.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, InvestmentContractID, SourceEventTable, SourceEventID, ComponentCode, RecognitionPolicyID
CREATE TABLE `gold`.`fact_private_capital_event_component` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `InvestmentContractID` STRING NOT NULL COMMENT 'Stable linked commitment identity; key includes tenant/environment.',
    `InvestmentContractVersionID` STRING NOT NULL COMMENT 'Exact contract version applied to this event.',
    `SourceEventTable` STRING NOT NULL COMMENT 'SecurityCall or SecurityDistribution; part of source identity.',
    `SourceEventID` BIGINT NOT NULL COMMENT 'Original event identity qualified by SourceEventTable.',
    `ComponentCode` STRING NOT NULL COMMENT 'CALL_PRINCIPAL, FEE1/2/3, ROC, INCOME1/2/3/4, etc.; no destructive aggregation.',
    `EventDate` DATE COMMENT 'Original event business date.',
    `FundingDate` DATE COMMENT 'Actual funding date where available; distribution does not inherit a guessed call funding date.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Denomination from approved event/contract currency precedence.',
    `ComponentAmount` DECIMAL(38,14) COMMENT 'Original amount for this individual component, not net cash flow.',
    `EconomicCashFlowSign` SMALLINT COMMENT 'Signed role under approved performance cash-flow policy; not inferred from amount alone.',
    `UpdatesMarketValue` BOOLEAN COMMENT 'Event\'s component-specific source flag; NULL stays unresolved.',
    `UpdatesRemainingCommitment` BOOLEAN COMMENT 'Component-specific commitment-update flag where defined; do not derive from fee-only status.',
    `RecallablePercentRaw` DECIMAL(38,14) COMMENT 'Component-specific original recallability percentage/value.',
    `SourceCOAID` BIGINT COMMENT 'Component expense/income account identifier when supplied.',
    `GLID` BIGINT COMMENT 'Linked GL event for cross-representation deduplication.',
    `EconomicEventKey` STRING NOT NULL COMMENT 'Stable event cross-reference shared with ledger/cash representations; selects authoritative flow representation.',
    `RecognitionPolicyID` STRING COMMENT 'Date/sign/fee/recallability rules used to interpret this component.',
    CONSTRAINT `fact_private_capital_event_component_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T47 / G09 / Extension*
-- As-of private capital position/multiple components.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, InvestmentContractID, AsOfDate, ReportingCurrencyCode, CapitalPolicyID
CREATE TABLE `gold`.`snap_private_capital_position` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `InvestmentContractID` STRING NOT NULL COMMENT 'Commitment identity whose state is measured.',
    `InvestmentContractVersionID` STRING NOT NULL COMMENT 'Exact contract version included.',
    `AsOfDate` DATE NOT NULL COMMENT 'State observation/report date.',
    `ReportingCurrencyCode` STRING COMMENT 'Currency in which commitment/cash/NAV components are comparable.',
    `CapitalPolicyID` STRING NOT NULL COMMENT 'Rules for commitment adjustments, fees, recallable amounts and NAV allocation.',
    `CommitmentAmount` DECIMAL(38,14) COMMENT 'Approved effective commitment amount for this contract as of date.',
    `CalledAmount` DECIMAL(38,14) COMMENT 'Recognized call components per policy; funding and business-date distinction retained.',
    `FeesAmount` DECIMAL(38,14) COMMENT 'Recognized fee components per policy, without assuming every fee reduces commitment.',
    `DistributedCapital` DECIMAL(38,14) COMMENT 'Recognized return-of-capital components.',
    `DistributedIncome` DECIMAL(38,14) COMMENT 'Recognized income components, with independent source flag treatment.',
    `RecallableAmount` DECIMAL(38,14) COMMENT 'Active recallable capital/income amount under source time and percent rules.',
    `RemainingCommitment` DECIMAL(38,14) COMMENT 'State recomputed from approved commitment-affecting components, not a universal commitment-minus-all-calls formula.',
    `AllocatedNAV` DECIMAL(38,14) COMMENT 'NAV attributable to this contract only when source allocation is proven; otherwise NULL with status.',
    `PaidInDenominator` DECIMAL(38,14) COMMENT 'Retained denominator used by approved multiples; source fee/funding policy governs.',
    `DPI` DOUBLE COMMENT 'Distribution-to-paid-in ratio under a separately approved report metric definition.',
    `RVPI` DOUBLE COMMENT 'Residual-value-to-paid-in ratio under approved metric definition.',
    `TVPI` DOUBLE COMMENT 'Total-value-to-paid-in ratio under approved metric definition.',
    `NAVAllocationStatus` STRING COMMENT 'PROVEN / POSITION_ONLY / UNRESOLVED; prevents repeating position NAV across commitments.',
    `CoverageStatus` STRING COMMENT 'Completeness of relevant contract/event/valuation history.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable result generation.',
    CONSTRAINT `snap_private_capital_position_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T48 / G09 / Extension*
-- Effective restrictions, lockups, notice and gates.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, InvestmentContractVersionID, SourceRestrictionID, SourceSubscriptionID, EffectiveFrom, TermsPolicyID
CREATE TABLE `gold`.`dim_liquidity_terms` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `InvestmentContractVersionID` STRING NOT NULL COMMENT 'Exact subscription contract version owning restriction.',
    `SourceRestrictionID` BIGINT NOT NULL COMMENT 'Original restriction record identity.',
    `SourceSubscriptionID` BIGINT COMMENT 'Subscription used to resolve source tenant and investment identity.',
    `EffectiveFrom` DATE NOT NULL COMMENT 'Source restriction effective date.',
    `EffectiveToExclusive` DATE COMMENT 'Next applicable restriction version boundary under source rules.',
    `LockupExpiration` DATE COMMENT 'Original lockup expiry date.',
    `HardLockup` BOOLEAN COMMENT 'Source hard-lockup flag.',
    `LockupPenalty` DECIMAL(38,14) COMMENT 'Source penalty amount/rate; unit must be resolved, not guessed.',
    `LiquidityFrequency` STRING COMMENT 'Original availability frequency.',
    `FrequencyDate` DATE COMMENT 'Source anchor for the frequency schedule.',
    `NoticeDays` INT COMMENT 'Source liquidity notice length; day/calendar business basis requires policy.',
    `GateProvision` DECIMAL(38,14) COMMENT 'Original gate value; percentage/basis rules remain explicit.',
    `TermsPolicyID` STRING NOT NULL COMMENT 'Approved interpretation of frequency/notice/gate/penalty terms.',
    CONSTRAINT `dim_liquidity_terms_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T49 / G09 / Extension*
-- As-of per-contract future liquidity buckets.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, InvestmentContractVersionID, LiquidityTermsVersionID, AsOfDate, BucketStartDate, BucketEndExclusive, ScenarioID, CurrencyCode, ReportContextKey
CREATE TABLE `gold`.`fact_liquidity_projection` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `InvestmentContractVersionID` STRING NOT NULL COMMENT 'Subscription/contract version being projected.',
    `LiquidityTermsVersionID` STRING NOT NULL COMMENT 'Exact effective terms applied to projection.',
    `AsOfDate` DATE NOT NULL COMMENT 'Projection observation date.',
    `BucketStartDate` DATE NOT NULL COMMENT 'Inclusive projected liquidity interval start.',
    `BucketEndExclusive` DATE NOT NULL COMMENT 'Exclusive projected liquidity interval end.',
    `ScenarioID` STRING NOT NULL COMMENT 'Projection assumptions, not a hidden default.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Currency of all projection amounts.',
    `OpeningAvailableNAV` DECIMAL(38,14) COMMENT 'Approved contract-level NAV before bucket restrictions; do not duplicate position NAV.',
    `EligibleAmount` DECIMAL(38,14) COMMENT 'Eligible amount in this bucket under approved terms and event state.',
    `GatedAmount` DECIMAL(38,14) COMMENT 'Amount constrained by source gate interpretation.',
    `HoldbackAmount` DECIMAL(38,14) COMMENT 'Outstanding source redemption holdback allocated to this state.',
    `ReserveAmount` DECIMAL(38,14) COMMENT 'Outstanding source reserve retained independently from holdback.',
    `PenaltyAmount` DECIMAL(38,14) COMMENT 'Penalty amount calculated under approved rules.',
    `AvailabilityStatus` STRING COMMENT 'AVAILABLE / LOCKED / GATED / UNKNOWN / NOT_APPLICABLE as approved.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Exact projection context.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable result generation.',
    CONSTRAINT `fact_liquidity_projection_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T50 / G10 / Extension*
-- Versioned risk results, observations and benchmark policy.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ReportContextKey, ReportTimePeriodID, ReportNodeID, MetricDefinitionID, BenchmarkRateID, ObservationFrequency, StatisticalConvention, CurrencyCode
CREATE TABLE `gold`.`fact_risk_metric` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Context defining selected economic population, method, fee, currency and policies.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Actual resolved calculation window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Typed node whose result is calculated.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Reproducible computation identifier.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable approved generation of result components.',
    `MetricDefinitionID` STRING NOT NULL COMMENT 'Exact metric formula/version/units; similar names do not imply equal formulas.',
    `MetricStatus` STRING NOT NULL COMMENT 'VALID / INSUFFICIENT_HISTORY / INVALID / NOT_APPLICABLE / UNRESOLVED_RULE.',
    `MetricValue` DOUBLE COMMENT 'Risk statistic output; formula chosen by approved definition, not fixed by table name.',
    `BenchmarkRateID` BIGINT COMMENT 'Optional reference series used in statistic.',
    `ObservationFrequency` STRING COMMENT 'Daily/monthly or other approved observation cadence.',
    `ObservationCount` BIGINT COMMENT 'Number of eligible observations actually used.',
    `RequiredObservationCount` BIGINT COMMENT 'Minimum sample length imposed by the metric definition.',
    `StatisticalConvention` STRING COMMENT 'Sample vs population denominator and missing-value rules.',
    `AnnualizationFactor` DOUBLE COMMENT 'Factor applied by source-approved statistical convention.',
    `ReferenceInputSetID` STRING COMMENT 'Exact benchmark/risk-free/reference observations used alongside investment returns.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Required comparable series currency where meaningful.',
    CONSTRAINT `fact_risk_metric_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T51 / G10 / Extension*
-- Cross-sectional return dispersion and weighting.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ReportContextKey, ReportTimePeriodID, ReportNodeID, MetricDefinitionID, PopulationSetID, WeightingMethod
CREATE TABLE `gold`.`fact_dispersion` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Context defining selected economic population, method, fee, currency and policies.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Actual resolved calculation window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Typed node whose result is calculated.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Reproducible computation identifier.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable approved generation of result components.',
    `MetricDefinitionID` STRING NOT NULL COMMENT 'Exact metric formula/version/units; similar names do not imply equal formulas.',
    `MetricStatus` STRING NOT NULL COMMENT 'VALID / INSUFFICIENT_HISTORY / INVALID / NOT_APPLICABLE / UNRESOLVED_RULE.',
    `PopulationSetID` STRING COMMENT 'Immutable cross-sectional member population with eligibility/version evidence.',
    `WeightingMethod` STRING COMMENT 'Equal-weight, asset-weight or other source-approved scheme.',
    `EligibleMemberCount` BIGINT COMMENT 'Number of included members, not all source entities.',
    `ExcludedForInvalidityCount` BIGINT COMMENT 'Ineligible members counted separately; not use of deferred report-exclusion features.',
    `WeightSum` DECIMAL(38,14) COMMENT 'Retained sum of eligible weights under approved normalization.',
    `WeightedReturnSum` DOUBLE COMMENT 'Intermediate statistical sum for reproducibility.',
    `WeightedSquaredDeviationSum` DOUBLE COMMENT 'Retained intermediate variance component.',
    `DispersionValue` DOUBLE COMMENT 'Final cross-sectional statistic under approved convention.',
    CONSTRAINT `fact_dispersion_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T52 / G10 / Extension*
-- Monetary and percentage return contribution.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ReportContextKey, ReportTimePeriodID, ReportNodeID, ParentNodeID, ChildNodeID, MetricDefinitionID, SecurityID, CurrencyCode, ContributionUnit, LinkingMethodID
CREATE TABLE `gold`.`fact_performance_contribution` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Context defining selected economic population, method, fee, currency and policies.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Actual resolved calculation window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Typed node whose result is calculated.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Reproducible computation identifier.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable approved generation of result components.',
    `MetricDefinitionID` STRING NOT NULL COMMENT 'Exact metric formula/version/units; similar names do not imply equal formulas.',
    `MetricStatus` STRING NOT NULL COMMENT 'VALID / INSUFFICIENT_HISTORY / INVALID / NOT_APPLICABLE / UNRESOLVED_RULE.',
    `ParentNodeID` STRING COMMENT 'Parent total/group against which this child\'s contribution is interpreted.',
    `ChildNodeID` STRING COMMENT 'Contributing disjoint member node; not arbitrary cross-joined fact row.',
    `SecurityID` BIGINT COMMENT 'Contributing security where node is security-level.',
    `CurrencyCode` STRING NOT NULL COMMENT 'Monetary contribution currency.',
    `MonetaryNumerator` DECIMAL(38,14) COMMENT 'Retained gain/income or other approved monetary contribution numerator.',
    `ReturnDenominator` DECIMAL(38,14) COMMENT 'Retained denominator at parent population grain.',
    `ContributionValue` DOUBLE COMMENT 'Contribution under the metric-specific linking convention.',
    `ContributionUnit` STRING COMMENT 'CURRENCY / DECIMAL_RETURN / PERCENTAGE_POINTS as explicitly defined.',
    `LinkingMethodID` STRING COMMENT 'Approved multi-period linking convention; do not sum daily percentages.',
    CONSTRAINT `fact_performance_contribution_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- T53 / G10 / Extension*
-- Allocation/selection/interaction effects with residual policy.
-- Proposed business / merge key: SourceEnvironmentCode, CustomerID, ReportContextKey, ReportTimePeriodID, ReportNodeID, MetricDefinitionID, AttributionBucketID, EffectCode, BenchmarkRateID, EffectUnit, LinkingMethodID
CREATE TABLE `gold`.`fact_performance_attribution` (
    `SourceEnvironmentCode` STRING NOT NULL COMMENT 'Authorized source namespace such as MT. Native IDs never cross this namespace without mapping.',
    `SourceOwnerCustomerID` BIGINT COMMENT 'Native owner of source records; may differ from consuming CustomerID for shared reference observations.',
    `RecordVersionID` STRING NOT NULL COMMENT 'Immutable identifier for this precise row and input/rule version; derived from canonical identity and version, not arbitrary row order.',
    `SourceCaptureSetID` STRING NOT NULL COMMENT 'Frozen multi-database capture-set identifier; a label alone is not snapshot isolation.',
    `InputSetID` STRING NOT NULL COMMENT 'Retained exact calculation/derivation input membership and source record versions; reusable audit evidence.',
    `PipelineRunID` STRING NOT NULL COMMENT 'Customer execution ledger reference, separate from publication generation and calculation identity.',
    `RuleVersion` STRING NOT NULL COMMENT 'Approved financial/mapping rule version plus code reference used to construct this row.',
    `CustomerID` BIGINT NOT NULL COMMENT 'Consuming enterprise/tenant; used with source namespace and customer access controls.',
    `LoadDts` TIMESTAMP NOT NULL COMMENT 'UTC ingestion/publication timestamp, not financial effective date.',
    `ReportContextKey` BIGINT NOT NULL COMMENT 'Context defining selected economic population, method, fee, currency and policies.',
    `ReportTimePeriodID` BIGINT NOT NULL COMMENT 'Actual resolved calculation window.',
    `ReportNodeID` STRING NOT NULL COMMENT 'Typed node whose result is calculated.',
    `CalculationExecutionID` STRING NOT NULL COMMENT 'Reproducible computation identifier.',
    `PublicationSetID` STRING NOT NULL COMMENT 'Immutable approved generation of result components.',
    `MetricDefinitionID` STRING NOT NULL COMMENT 'Exact metric formula/version/units; similar names do not imply equal formulas.',
    `MetricStatus` STRING NOT NULL COMMENT 'VALID / INSUFFICIENT_HISTORY / INVALID / NOT_APPLICABLE / UNRESOLVED_RULE.',
    `AttributionBucketID` STRING COMMENT 'Class/sector/security/other typed attribution bucket.',
    `EffectCode` STRING COMMENT 'Source-defined allocation/selection/interaction/residual effect, without assuming methodology.',
    `BenchmarkRateID` BIGINT COMMENT 'Selected comparator.',
    `PortfolioWeight` DOUBLE COMMENT 'Weight used by approved effect formula and period convention.',
    `BenchmarkWeight` DOUBLE COMMENT 'Comparator weight at compatible grain.',
    `PortfolioReturn` DOUBLE COMMENT 'Comparable investment bucket return input.',
    `BenchmarkReturn` DOUBLE COMMENT 'Comparable benchmark bucket return input.',
    `EffectValue` DOUBLE COMMENT 'Output effect under exact formula, units and linking policy.',
    `EffectUnit` STRING COMMENT 'Decimal return/percentage points/currency; never ambiguous.',
    `LinkingMethodID` STRING COMMENT 'Exact multi-period linking or decomposition method.',
    `ResidualValue` DOUBLE COMMENT 'Explicit residual when required; must reconcile at the parent total.',
    `ContributionInputSetID` STRING COMMENT 'Exact linked contribution components.',
    CONSTRAINT `fact_performance_attribution_pk` PRIMARY KEY (`RecordVersionID`)
) USING DELTA;

-- Optional diagram constraints. Each references a declared parent row-version key.

-- J110 | T19 -> T16 | Trace the applied allocation/PAO slice to the corresponding ownership bridge version. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_investor_performance_profile`
    ADD CONSTRAINT `fk_model_j110_t19_t16` FOREIGN KEY (`OwnershipRecordVersionID`)
    REFERENCES `gold`.`bridge_nested_profile` (`RecordVersionID`);

-- J111 | T19 -> T17 | Trace an investor allocation (Fact 2) to the exact unallocated daily performance row (Fact 3). Multiple allocations can share a parent amount. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_investor_performance_profile`
    ADD CONSTRAINT `fk_model_j111_t19_t17` FOREIGN KEY (`SourceFact3RecordVersionID`)
    REFERENCES `gold`.`fact_daily_security_performance` (`RecordVersionID`);

-- J144 | T40 -> T11 | Trace the valuation to its conformed price-record version; a missing price reference has no match. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_position_valuation_daily`
    ADD CONSTRAINT `fk_model_j144_t40_t11` FOREIGN KEY (`SecurityPriceVersionID`)
    REFERENCES `gold`.`dim_security_price` (`RecordVersionID`);

-- J161 | T44 -> T43 | Trace the target weight to the exact allocation-model definition version. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_allocation_target`
    ADD CONSTRAINT `fk_model_j161_t44_t43` FOREIGN KEY (`AllocationModelVersionID`)
    REFERENCES `gold`.`dim_allocation_model` (`RecordVersionID`);

-- J173 | T46 -> T45 | Trace the event component to the applied investment contract version. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_private_capital_event_component`
    ADD CONSTRAINT `fk_model_j173_t46_t45` FOREIGN KEY (`InvestmentContractVersionID`)
    REFERENCES `gold`.`dim_investment_contract` (`RecordVersionID`);

-- J179 | T47 -> T45 | Trace the as-of position to its included investment contract version. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`snap_private_capital_position`
    ADD CONSTRAINT `fk_model_j179_t47_t45` FOREIGN KEY (`InvestmentContractVersionID`)
    REFERENCES `gold`.`dim_investment_contract` (`RecordVersionID`);

-- J182 | T48 -> T45 | Trace the liquidity restriction to its owning investment contract version. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`dim_liquidity_terms`
    ADD CONSTRAINT `fk_model_j182_t48_t45` FOREIGN KEY (`InvestmentContractVersionID`)
    REFERENCES `gold`.`dim_investment_contract` (`RecordVersionID`);

-- J186 | T49 -> T45 | Trace the projection to its specified subscription or investment contract version. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_liquidity_projection`
    ADD CONSTRAINT `fk_model_j186_t49_t45` FOREIGN KEY (`InvestmentContractVersionID`)
    REFERENCES `gold`.`dim_investment_contract` (`RecordVersionID`);

-- J187 | T49 -> T48 | Trace the projection to the exact liquidity terms applied. The optional diagram connector uses the recorded parent row-version key. Verify source/tenant membership when resolving the reference.
ALTER TABLE `gold`.`fact_liquidity_projection`
    ADD CONSTRAINT `fk_model_j187_t49_t48` FOREIGN KEY (`LiquidityTermsVersionID`)
    REFERENCES `gold`.`dim_liquidity_terms` (`RecordVersionID`);

