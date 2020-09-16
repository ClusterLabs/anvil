-- This is the database schema for the 'scan-cluster Scan Agent'.

CREATE TABLE scan_cluster (
    scan_cluster_uuid         uuid                        primary key,
    scan_cluster_host_uuid    uuid                        not null,
    modified_date             timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster OWNER TO admin;

CREATE TABLE history.scan_cluster (
    history_id                bigserial,
    scan_cluster_uuid         uuid,
    scan_cluster_host_uuid    uuid,
    modified_date             timestamp with time zone    not null
);
ALTER TABLE history.scan_cluster OWNER TO admin;

CREATE FUNCTION history_scan_cluster() RETURNS trigger
AS $$
DECLARE
    history_scan_cluster RECORD;
BEGIN
    SELECT INTO history_scan_cluster * FROM scan_cluster WHERE scan_cluster_uuid=new.scan_cluster_uuid;
    INSERT INTO history.scan_cluster
        (scan_cluster_uuid,
         scan_cluster_host_uuid, 
         modified_date)
    VALUES
        (history_scan_cluster.scan_cluster_uuid,
         history_scan_cluster.scan_cluster_host_uuid, 
         history_scan_cluster.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster
    AFTER INSERT OR UPDATE ON scan_cluster
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster();
