-- This is the database schema for the 'scan-storage Scan Agent'.

CREATE TABLE scan_storage (
    scan_storage_uuid         uuid                        primary key,
    scan_storage_host_uuid    uuid                        not null,
    modified_date             timestamp with time zone    not null,
    
    FOREIGN KEY(scan_storage_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_storage OWNER TO admin;

CREATE TABLE history.scan_storage (
    history_id                    bigserial,
    scan_storage_uuid            uuid,
    scan_storage_host_uuid       uuid,
    modified_date                 timestamp with time zone    not null
);
ALTER TABLE history.scan_storage OWNER TO admin;

CREATE FUNCTION history_scan_storage() RETURNS trigger
AS $$
DECLARE
    history_scan_storage RECORD;
BEGIN
    SELECT INTO history_scan_storage * FROM scan_storage WHERE scan_storage_uuid=new.scan_storage_uuid;
    INSERT INTO history.scan_storage
        (scan_storage_uuid,
         scan_storage_host_uuid, 
         modified_date)
    VALUES
        (history_scan_storage.scan_storage_uuid,
         history_scan_storage.scan_storage_host_uuid, 
         history_scan_storage.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_storage() OWNER TO admin;

CREATE TRIGGER trigger_scan_storage
    AFTER INSERT OR UPDATE ON scan_storage
    FOR EACH ROW EXECUTE PROCEDURE history_scan_storage();
