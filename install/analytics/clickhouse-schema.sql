-- ClickHouse analytics schema for kgateway Portal API access logging.
--
-- Variant A confirmed by smoke test (2026-05-19): %DYNAMIC_METADATA(io.solo.gloo.portal:...)%
-- expands inside openTelemetry.attributes and fields land in LogAttributes (not ResourceAttributes).
--
-- Note on WHERE filter: when a DYNAMIC_METADATA key is absent (non-portal traffic),
-- the OTel access log formatter expands the placeholder to '-' (a literal dash), not ''.
-- The materialized view therefore filters with != '-' to exclude non-portal traffic.

-- api_logs: OTel landing table — schema matches what the ClickHouse exporter creates via create_schema: true.
-- Pre-creating it here so the materialized view below can reference it.
-- The exporter (create_schema: true) uses CREATE TABLE IF NOT EXISTS, so it will skip this on first connect.
CREATE TABLE IF NOT EXISTS default.api_logs (
    Timestamp           DateTime64(9)                            CODEC(Delta(8), ZSTD(1)),
    TraceId             String                                   CODEC(ZSTD(1)),
    SpanId              String                                   CODEC(ZSTD(1)),
    TraceFlags          UInt32                                   CODEC(ZSTD(1)),
    SeverityText        LowCardinality(String)                   CODEC(ZSTD(1)),
    SeverityNumber      Int32                                    CODEC(ZSTD(1)),
    ServiceName         LowCardinality(String)                   CODEC(ZSTD(1)),
    Body                String                                   CODEC(ZSTD(1)),
    ResourceSchemaUrl   String                                   CODEC(ZSTD(1)),
    ResourceAttributes  Map(LowCardinality(String), String)      CODEC(ZSTD(1)),
    ScopeSchemaUrl      String                                   CODEC(ZSTD(1)),
    ScopeName           String                                   CODEC(ZSTD(1)),
    ScopeVersion        String                                   CODEC(ZSTD(1)),
    ScopeAttributes     Map(LowCardinality(String), String)      CODEC(ZSTD(1)),
    LogAttributes       Map(LowCardinality(String), String)      CODEC(ZSTD(1))
) ENGINE = MergeTree()
PARTITION BY toDate(Timestamp)
ORDER BY (ServiceName, Timestamp)
TTL toDateTime(Timestamp) + toIntervalSecond(604800)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1;

-- api_access_logs: typed analytics table, queried by Grafana
CREATE TABLE IF NOT EXISTS default.api_access_logs (
    Timestamp      DateTime64(9) CODEC(Delta(8), ZSTD(1)),
    ApiProductId   LowCardinality(String) CODEC(ZSTD(1)),
    ApiProductName LowCardinality(String) CODEC(ZSTD(1)),
    ApiVersion     LowCardinality(String) CODEC(ZSTD(1)),
    Method         LowCardinality(String) CODEC(ZSTD(1)),
    Path           String CODEC(ZSTD(1)),
    ResponseCode   UInt16 CODEC(ZSTD(1)),
    DurationMs     UInt32 CODEC(ZSTD(1)),
    BytesSent      UInt64 CODEC(ZSTD(1)),
    BytesReceived  UInt64 CODEC(ZSTD(1)),
    UserAgent      String CODEC(ZSTD(1)),
    RequestId      String CODEC(ZSTD(1)),
    ApplicationId  LowCardinality(String) CODEC(ZSTD(1))
) ENGINE = MergeTree()
PARTITION BY toDate(Timestamp)
ORDER BY (Timestamp, ApiProductId)
TTL toDateTime(Timestamp) + toIntervalSecond(604800)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1;

-- Variant A materialized view: reads from LogAttributes (confirmed by smoke test 2026-05-19).
-- Filters on ApiProductId != '-' because absent DYNAMIC_METADATA keys expand to '-', not ''.
-- This excludes non-portal traffic that was not processed by the Portal ext-auth plugin.
CREATE MATERIALIZED VIEW IF NOT EXISTS default.api_access_logs_mv
TO default.api_access_logs AS
SELECT
    Timestamp,
    LogAttributes['api_product_id']                   AS ApiProductId,
    LogAttributes['api_product_name']                 AS ApiProductName,
    LogAttributes['api_version']                      AS ApiVersion,
    LogAttributes['method']                           AS Method,
    LogAttributes['path']                             AS Path,
    toUInt16OrZero(LogAttributes['response_code'])    AS ResponseCode,
    toUInt32OrZero(LogAttributes['duration_ms'])      AS DurationMs,
    toUInt64OrZero(LogAttributes['bytes_sent'])       AS BytesSent,
    toUInt64OrZero(LogAttributes['bytes_received'])   AS BytesReceived,
    LogAttributes['user_agent']                       AS UserAgent,
    LogAttributes['request_id']                       AS RequestId,
    LogAttributes['application_id']                   AS ApplicationId
FROM default.api_logs
WHERE LogAttributes['api_product_id'] != '-';
