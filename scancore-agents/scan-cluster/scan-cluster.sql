-- This is the database schema for the 'scan-cluster Scan Agent'.
-- 
-- NOTE: This agent is not host-bound. It's update by node 1 if it's in the cluster, else by node 2 if it's 
--       the only one online.

CREATE TABLE scan_cluster (
    scan_cluster_uuid                uuid                        primary key,
    scan_cluster_name                text                        not null,       -- The name of the cluster
    scan_cluster_stonith_enabled     boolean                     not null,       -- Tracks when stonith (fencing) was enabled/disabled
    scan_cluster_maintenance_mode    boolean                     not null,       -- Tracks when maintenance mode is enabled/disabled.
    modified_date                    timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster OWNER TO admin;

CREATE TABLE history.scan_cluster (
    history_id                       bigserial,
    scan_cluster_uuid                uuid,
    scan_cluster_name                text, 
    scan_cluster_stonith_enabled     boolean, 
    scan_cluster_maintenance_mode    boolean, 
    modified_date                    timestamp with time zone    not null
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
         scan_cluster_name, 
         scan_cluster_stonith_enabled, 
         scan_cluster_maintenance_mode, 
         modified_date)
    VALUES
        (history_scan_cluster.scan_cluster_uuid,
         history_scan_cluster.scan_cluster_host_uuid, 
         history_scan_cluster.scan_cluster_name, 
         history_scan_cluster.scan_cluster_stonith_enabled, 
         history_scan_cluster.scan_cluster_maintenance_mode, 
         history_scan_cluster.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster
    AFTER INSERT OR UPDATE ON scan_cluster
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster();


CREATE TABLE scan_cluster_nodes (
    scan_cluster_node_uuid                uuid                        primary key,
    scan_cluster_node_host_uuid           uuid                        not null,       -- This is the host UUID of the node.
    scan_cluster_node_name                text                        not null,       -- This is the host name as reported by pacemaker. It _should_ match up to a host name in 'hosts'.
    scan_cluster_node_pacemaker_id        numeric                     not null,       -- This is the internal pacemaker ID number of this node.
		my $node_id = $anvil->data->{cib}{parsed}{data}{node}{$node_name}{id};
		my $in_ccm  = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{in_ccm} eq "true"   ? 1 : 0; # 'true' or 'false'     - Corosync member
		my $crmd    = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{crmd}   eq "online" ? 1 : 0; # 'online' or 'offline' - In corosync process group
		my $join    = $anvil->data->{cib}{parsed}{cib}{node_state}{$node_id}{'join'} eq "member" ? 1 : 0; # 'member' or 'down'    - Completed controller join process
    
    modified_date                    timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster OWNER TO admin;

CREATE TABLE history.scan_cluster (
    history_id                       bigserial,
    scan_cluster_uuid                uuid,
    scan_cluster_host_uuid           uuid,
    scan_cluster_node_name                text, 
    scan_cluster_stonith_enabled     boolean, 
    scan_cluster_maintenance_mode    boolean, 
    modified_date                    timestamp with time zone    not null
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
         scan_cluster_name, 
         scan_cluster_stonith_enabled, 
         scan_cluster_maintenance_mode, 
         modified_date)
    VALUES
        (history_scan_cluster.scan_cluster_uuid,
         history_scan_cluster.scan_cluster_host_uuid, 
         history_scan_cluster.scan_cluster_name, 
         history_scan_cluster.scan_cluster_stonith_enabled, 
         history_scan_cluster.scan_cluster_maintenance_mode, 
         history_scan_cluster.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster
    AFTER INSERT OR UPDATE ON scan_cluster
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster();

