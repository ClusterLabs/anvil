-- This is the database schema for the 'scan-cluster Scan Agent'.
-- 
-- NOTE: This agent is not host-bound. It's update by node 1 if it's in the cluster, else by node 2 if it's 
--       the only one online.
-- NOTE: Server data is not stored here. See scan-server for data on those resources.

CREATE TABLE scan_cluster (
    scan_cluster_uuid          uuid                        primary key,
    scan_cluster_anvil_uuid    uuid                        not null,       -- The Anvil! UUID this cluster is associated with.
    scan_cluster_name          text                        not null,       -- The name of the cluster
    scan_cluster_cib           text                        not null,       -- This is the CIB from disk, only updated when a node is a full member of the cluster. This is set to 'DELETED' if the node is gone.
    modified_date              timestamp with time zone    not null
);
ALTER TABLE scan_cluster OWNER TO admin;

CREATE TABLE history.scan_cluster (
    history_id                 bigserial,
    scan_cluster_uuid          uuid,
    scan_cluster_anvil_uuid    uuid,
    scan_cluster_name          text, 
    scan_cluster_cib      text, 
    modified_date              timestamp with time zone    not null
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
         scan_cluster_anvil_uuid, 
         scan_cluster_name, 
         scan_cluster_cib, 
         modified_date)
    VALUES
        (history_scan_cluster.scan_cluster_uuid, 
         history_scan_cluster.scan_cluster_anvil_uuid, 
         history_scan_cluster.scan_cluster_name, 
         history_scan_cluster.scan_cluster_cib, 
         history_scan_cluster.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster
    AFTER INSERT OR UPDATE ON scan_cluster
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster();

    
-- Node status information
CREATE TABLE scan_cluster_nodes (
    scan_cluster_node_uuid                 uuid                        primary key,
    scan_cluster_node_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
    scan_cluster_node_host_uuid            uuid                        not null,       -- This is the host UUID of the node.
    scan_cluster_node_name                 text                        not null,       -- This is the host name as reported by pacemaker. It _should_ match up to a host name in 'hosts'.
    scan_cluster_node_pacemaker_id         numeric                     not null,       -- This is the internal pacemaker ID number of this node.
    scan_cluster_node_in_ccm               boolean                     not null,       -- Indicates if the node is a corosync cluster member, first step in a node comint online.
    scan_cluster_node_crmd_member          boolean                     not null,       -- Indicates if the node is in the corosync process group. Value from the CIB is 'online' or 'offline'. Second step in a node coming online
    scan_cluster_node_cluster_member       boolean                     not null,       -- Indicates if the node has joined the controller and is a full member. Value from the CIB is 'member' or 'down'. Final step in the joining the cluster.
    scan_cluster_node_maintenance_mode     boolean                     not null,       -- Tracks when maintenance mode is enabled/disabled.
    modified_date                          timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_node_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid),
    FOREIGN KEY(scan_cluster_node_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster_nodes OWNER TO admin;

CREATE TABLE history.scan_cluster_nodes (
    history_id                             bigserial,
    scan_cluster_node_uuid                 uuid,
    scan_cluster_node_scan_cluster_uuid    uuid,
    scan_cluster_node_host_uuid            uuid,
    scan_cluster_node_name                 text,
    scan_cluster_node_pacemaker_id         numeric,
    scan_cluster_node_in_ccm               boolean, 
    scan_cluster_node_crmd_member          boolean, 
    scan_cluster_node_cluster_member       boolean, 
    scan_cluster_node_maintenance_mode     boolean, 
    modified_date                          timestamp with time zone    not null
);
ALTER TABLE history.scan_cluster_nodes OWNER TO admin;

CREATE FUNCTION history_scan_cluster_nodes() RETURNS trigger
AS $$
DECLARE
    history_scan_cluster_nodes RECORD;
BEGIN
    SELECT INTO history_scan_cluster_nodes * FROM scan_cluster_nodes WHERE scan_cluster_node_uuid=new.scan_cluster_node_uuid;
    INSERT INTO history.scan_cluster_nodes
        (scan_cluster_node_uuid, 
         scan_cluster_node_scan_cluster_uuid, 
         scan_cluster_node_host_uuid, 
         scan_cluster_node_name, 
         scan_cluster_node_pacemaker_id, 
         scan_cluster_node_in_ccm, 
         scan_cluster_node_crmd_member, 
         scan_cluster_node_cluster_member, 
         scan_cluster_node_maintenance_mode, 
         modified_date)
    VALUES
        (history_scan_cluster_nodes.scan_cluster_node_uuid, 
         history_scan_cluster_nodes.scan_cluster_node_scan_cluster_uuid, 
         history_scan_cluster_nodes.scan_cluster_node_host_uuid, 
         history_scan_cluster_nodes.scan_cluster_node_name, 
         history_scan_cluster_nodes.scan_cluster_node_pacemaker_id, 
         history_scan_cluster_nodes.scan_cluster_node_in_ccm, 
         history_scan_cluster_nodes.scan_cluster_node_crmd_member, 
         history_scan_cluster_nodes.scan_cluster_node_cluster_member, 
         history_scan_cluster_nodes.scan_cluster_node_maintenance_mode, 
         history_scan_cluster_nodes.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster_nodes() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster_nodes
    AFTER INSERT OR UPDATE ON scan_cluster_nodes
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_nodes();


-- TODO: We may want to track this data in the future. For now, we're not going to bother as we can always 
--       dig through the historical cib.xml.X files on the nodes. 
-- 
-- -- Constraints; Useful for tracking when servers are asked to migrate.
-- CREATE TABLE scan_cluster_constraints (
--     scan_cluster_constraint_uuid                 uuid                        primary key,
--     scan_cluster_constraint_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
--     scan_cluster_constraint_server_name          text                        not null,       -- This is the server name the constraint applies to.
--     scan_cluster_constraint_node1_name           text                        not null,       -- This is name of the first node
--     scan_cluster_constraint_node1_score          numeric                     not null,       -- This is the score assigned to the first node (larger number is higher priority)
--     scan_cluster_constraint_node2_name           text                        not null,       -- This is name of the second node
--     scan_cluster_constraint_node2_score          numeric                     not null,       -- This is the score assigned to the second node (larger number is higher priority)
--     modified_date                                timestamp with time zone    not null,
--     
--     FOREIGN KEY(scan_cluster_constraint_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid)
-- );
-- ALTER TABLE scan_cluster_constraints OWNER TO admin;
-- 
-- CREATE TABLE history.scan_cluster_constraints (
--     history_id                                   bigserial,
--     scan_cluster_constraint_uuid                 uuid,
--     scan_cluster_constraint_scan_cluster_uuid    uuid, 
--     scan_cluster_constraint_server_name          text, 
--     scan_cluster_constraint_node1_name           text, 
--     scan_cluster_constraint_node1_score          numeric, 
--     scan_cluster_constraint_node2_name           text, 
--     scan_cluster_constraint_node2_score          numeric, 
--     modified_date                                timestamp with time zone    not null
-- );
-- ALTER TABLE history.scan_cluster_constraints OWNER TO admin;
-- 
-- CREATE FUNCTION history_scan_cluster_constraints() RETURNS trigger
-- AS $$
-- DECLARE
--     history_scan_cluster_constraints RECORD;
-- BEGIN
--     SELECT INTO history_scan_cluster_constraints * FROM scan_cluster_constraints WHERE scan_cluster_constraint_uuid=new.scan_cluster_constraint_uuid;
--     INSERT INTO history.scan_cluster_constraints
--         (scan_cluster_constraint_uuid, 
--          scan_cluster_constraint_scan_cluster_uuid, 
--          scan_cluster_constraint_server_name, 
--          scan_cluster_constraint_node1_name, 
--          scan_cluster_constraint_node1_score, 
--          scan_cluster_constraint_node2_name, 
--          scan_cluster_constraint_node2_score, 
--          modified_date)
--     VALUES
--         (history_scan_cluster_constraints.scan_cluster_constraint_uuid, 
--          history_scan_cluster_constraints.scan_cluster_constraint_scan_cluster_uuid, 
--          history_scan_cluster_constraints.scan_cluster_constraint_server_name, 
--          history_scan_cluster_constraints.scan_cluster_constraint_node1_name, 
--          history_scan_cluster_constraints.scan_cluster_constraint_node1_score, 
--          history_scan_cluster_constraints.scan_cluster_constraint_node2_name, 
--          history_scan_cluster_constraints.scan_cluster_constraint_node2_score, 
--          history_scan_cluster_constraints.modified_date);
--     RETURN NULL;
-- END;
-- $$
-- LANGUAGE plpgsql;
-- ALTER FUNCTION history_scan_cluster_constraints() OWNER TO admin;
-- 
-- CREATE TRIGGER trigger_scan_cluster_constraints
--     AFTER INSERT OR UPDATE ON scan_cluster_constraints
--     FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_constraints();
-- 
-- 
-- -- This stores the fence (stonith) configuration data. We use 'fence' instead of 'stonith' because pacemaker 
-- -- uses both (see 'fence topology', for example), and 'fence' implies fabric and power fencing, where the 
-- -- name 'stonith' implies power fencing only.
-- CREATE TABLE scan_cluster_fences (
--     scan_cluster_fence_uuid                 uuid                        primary key,
--     scan_cluster_fence_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
--     scan_cluster_fence_target_node_name     text                        not null,       -- This is the node name that the fence will act on (kill)
--     scan_cluster_fence_name                 text                        not null,       -- This is the 'stonith id'
--     scan_cluster_fence_arguments            text                        not null,       -- This is the fence agent + collection of primitive variable=value pairs (the nvpairs)
--     scan_cluster_fence_operations           text                        not null,       -- This is the collection of operation variable=value pairs (the nvpairs)
--     modified_date                           timestamp with time zone    not null,
--     
--     FOREIGN KEY(scan_cluster_fence_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid)
-- );
-- ALTER TABLE scan_cluster_fences OWNER TO admin;
-- 
-- CREATE TABLE history.scan_cluster_fences (
--     history_id                              bigserial,
--     scan_cluster_fence_uuid                 uuid,
--     scan_cluster_fence_scan_cluster_uuid    uuid, 
--     scan_cluster_fence_target_node_name     text, 
--     scan_cluster_fence_name                 text, 
--     scan_cluster_fence_arguments            text, 
--     scan_cluster_fence_operations           text, 
--     modified_date                           timestamp with time zone    not null
-- );
-- ALTER TABLE history.scan_cluster_fences OWNER TO admin;
-- 
-- CREATE FUNCTION history_scan_cluster_fences() RETURNS trigger
-- AS $$
-- DECLARE
--     history_scan_cluster_fences RECORD;
-- BEGIN
--     SELECT INTO history_scan_cluster_fences * FROM scan_cluster_fences WHERE scan_cluster_fence_uuid=new.scan_cluster_fence_uuid;
--     INSERT INTO history.scan_cluster_fences
--         (scan_cluster_fence_uuid, 
--          scan_cluster_fence_scan_cluster_uuid, 
--          scan_cluster_fence_target_node_name, 
--          scan_cluster_fence_name, 
--          scan_cluster_fence_arguments, 
--          scan_cluster_fence_operations, 
--          modified_date)
--     VALUES
--         (history_scan_cluster_fences.scan_cluster_fence_uuid, 
--          history_scan_cluster_fences.scan_cluster_fence_scan_cluster_uuid, 
--          history_scan_cluster_fences.scan_cluster_fence_target_node_name, 
--          history_scan_cluster_fences.scan_cluster_fence_name, 
--          history_scan_cluster_fences.scan_cluster_fence_arguments, 
--          history_scan_cluster_fences.scan_cluster_fence_operations, 
--          history_scan_cluster_fences.modified_date);
--     RETURN NULL;
-- END;
-- $$
-- LANGUAGE plpgsql;
-- ALTER FUNCTION history_scan_cluster_fences() OWNER TO admin;
-- 
-- CREATE TRIGGER trigger_scan_cluster_fences
--     AFTER INSERT OR UPDATE ON scan_cluster_fences
--     FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_fences();
-- 
-- 
-- -- This stores data about the order of fencing actions
-- CREATE TABLE scan_cluster_fence_topologies (
--     scan_cluster_fence_topology_uuid                 uuid                        primary key,
--     scan_cluster_fence_topology_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
--     scan_cluster_fence_topology_target_node_name     text                        not null,       -- This is the node that the topology applies to.
--     scan_cluster_fence_topology_index                numeric                     not null,       -- This is numerical order that the associated devices will be tried in. Lower value == higher priority.
--     scan_cluster_fence_topology_device               text                        not null,       -- This is the (comma-separated) devices used in this index
--     modified_date                                    timestamp with time zone    not null,
--     
--     FOREIGN KEY(scan_cluster_fence_topology_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid)
-- );
-- ALTER TABLE scan_cluster_fence_topologies OWNER TO admin;
-- 
-- CREATE TABLE history.scan_cluster_fence_topologies (
--     history_id                                       bigserial,
--     scan_cluster_fence_topology_uuid                 uuid,
--     scan_cluster_fence_topology_scan_cluster_uuid    uuid, 
--     scan_cluster_fence_topology_target_node_name     text,
--     scan_cluster_fence_topology_index                numeric,
--     scan_cluster_fence_topology_device               text,
--     modified_date                                    timestamp with time zone    not null
-- );
-- ALTER TABLE history.scan_cluster_fence_topologies OWNER TO admin;
-- 
-- CREATE FUNCTION history_scan_cluster_fence_topologies() RETURNS trigger
-- AS $$
-- DECLARE
--     history_scan_cluster_fence_topologies RECORD;
-- BEGIN
--     SELECT INTO history_scan_cluster_fence_topologies * FROM scan_cluster_fence_topologies WHERE scan_cluster_fence_topology_uuid=new.scan_cluster_fence_topology_uuid;
--     INSERT INTO history.scan_cluster_fence_topologies
--         (scan_cluster_fence_topology_uuid, 
--          scan_cluster_fence_topology_scan_cluster_uuid, 
--          scan_cluster_fence_topology_target_node_name, 
--          scan_cluster_fence_topology_index, 
--          scan_cluster_fence_topology_device, 
--          modified_date)
--     VALUES
--         (history_scan_cluster_fence_topologies.scan_cluster_fence_topology_uuid, 
--          history_scan_cluster_fence_topologies.scan_cluster_fence_topology_scan_cluster_uuid, 
--          history_scan_cluster_fence_topologies.scan_cluster_fence_topology_target_node_name, 
--          history_scan_cluster_fence_topologies.scan_cluster_fence_topology_index, 
--          history_scan_cluster_fence_topologies.scan_cluster_fence_topology_device, 
--          history_scan_cluster_fence_topologies.modified_date);
--     RETURN NULL;
-- END;
-- $$
-- LANGUAGE plpgsql;
-- ALTER FUNCTION history_scan_cluster_fence_topologies() OWNER TO admin;
-- 
-- CREATE TRIGGER trigger_scan_cluster_fence_topologies
--     AFTER INSERT OR UPDATE ON scan_cluster_fence_topologies
--     FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_fence_topologies();
