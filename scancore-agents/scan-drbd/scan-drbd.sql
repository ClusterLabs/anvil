-- This is the database schema for the 'scan-drbd' Scan Agent.

CREATE TABLE scan_drbd (
    scan_drbd_uuid                uuid                        not null    primary key,
    scan_drbd_host_uuid           uuid                        not null,
    scan_drbd_common_xml          text                        not null,                -- This is the raw <common> section of 'drbdadm dump-xml'.
    scan_drbd_flush_disk          boolean                     not null,                -- Set to true when disk flushes are enabled (only safe to be false when FBWC is used)
    scan_drbd_flush_md            boolean                     not null,                -- Set to true when meta-data flushes are enabled (only safe to be false when FBWC is used)
    scan_drbd_timeout             numeric                     not null,                -- This is how long we'll wait for a response from a peer (in seconds) before declaring it lost.
    scan_drbd_total_sync_speed    numeric                     not null,                -- This is the current total sync speed across all resync'ing volumes
    modified_date                 timestamp with time zone    not null,
    
    FOREIGN KEY(scan_drbd_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_drbd OWNER TO admin;

CREATE TABLE history.scan_drbd (
    history_id                    bigserial,
    scan_drbd_uuid                uuid,
    scan_drbd_host_uuid           uuid,
    scan_drbd_common_xml          text,
    scan_drbd_flush_disk          boolean,
    scan_drbd_flush_md            boolean,
    scan_drbd_timeout             numeric,
    scan_drbd_total_sync_speed    numeric, 
    modified_date                 timestamp with time zone    not null
);
ALTER TABLE history.scan_drbd OWNER TO admin;

CREATE FUNCTION history_scan_drbd() RETURNS trigger
AS $$
DECLARE
    history_scan_drbd RECORD;
BEGIN
    SELECT INTO history_scan_drbd * FROM scan_drbd WHERE scan_drbd_uuid=new.scan_drbd_uuid;
    INSERT INTO history.scan_drbd
        (scan_drbd_uuid, 
         scan_drbd_host_uuid, 
         scan_drbd_common_xml, 
         scan_drbd_flush_disk, 
         scan_drbd_flush_md, 
         scan_drbd_timeout, 
         scan_drbd_total_sync_speed, 
         modified_date)
    VALUES
        (history_scan_drbd.scan_drbd_uuid,
         history_scan_drbd.scan_drbd_host_uuid, 
         history_scan_drbd.scan_drbd_common_xml, 
         history_scan_drbd.scan_drbd_flush_disk, 
         history_scan_drbd.scan_drbd_flush_md, 
         history_scan_drbd.scan_drbd_timeout, 
         history_scan_drbd.scan_drbd_total_sync_speed, 
         history_scan_drbd.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_drbd() OWNER TO admin;

CREATE TRIGGER trigger_scan_drbd
    AFTER INSERT OR UPDATE ON scan_drbd
    FOR EACH ROW EXECUTE PROCEDURE history_scan_drbd();


-- This is mostly an anchor for the connections and volumes table
CREATE TABLE scan_drbd_resources (
    scan_drbd_resource_uuid         uuid                        not null    primary key,
    scan_drbd_resource_host_uuid    uuid                        not null,
    scan_drbd_resource_name         text                        not null,                -- The name of the resource.
    scan_drbd_resource_up           boolean                     not null,                -- This indicates if the resource is up on this host.
    scan_drbd_resource_xml          text                        not null,                -- This is the raw <common> section of 'drbd_resourceadm dump-xml'.
    modified_date                   timestamp with time zone    not null,
    
    FOREIGN KEY(scan_drbd_resource_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_drbd_resources OWNER TO admin;

CREATE TABLE history.scan_drbd_resources (
    history_id                      bigserial,
    scan_drbd_resource_uuid         uuid,
    scan_drbd_resource_host_uuid    uuid,
    scan_drbd_resource_name         text,
    scan_drbd_resource_up           boolean,
    scan_drbd_resource_xml          text,
    modified_date                   timestamp with time zone    not null
);
ALTER TABLE history.scan_drbd_resources OWNER TO admin;

CREATE FUNCTION history_scan_drbd_resources() RETURNS trigger
AS $$
DECLARE
    history_scan_drbd_resources RECORD;
BEGIN
    SELECT INTO history_scan_drbd_resources * FROM scan_drbd_resources WHERE scan_drbd_resource_uuid=new.scan_drbd_resource_uuid;
    INSERT INTO history.scan_drbd_resources
        (scan_drbd_resource_uuid, 
         scan_drbd_resource_host_uuid, 
         scan_drbd_resource_name, 
         scan_drbd_resource_up, 
         scan_drbd_resource_xml, 
	 modified_date)
    VALUES
        (history_scan_drbd_resources.scan_drbd_resource_uuid,
         history_scan_drbd_resources.scan_drbd_resource_host_uuid, 
         history_scan_drbd_resources.scan_drbd_resource_name, 
         history_scan_drbd_resources.scan_drbd_resource_up, 
         history_scan_drbd_resources.scan_drbd_resource_xml, 
         history_scan_drbd_resources.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_drbd_resources() OWNER TO admin;

CREATE TRIGGER trigger_scan_drbd_resources
    AFTER INSERT OR UPDATE ON scan_drbd_resources
    FOR EACH ROW EXECUTE PROCEDURE history_scan_drbd_resources();


-- Volumes under resources.
-- 
-- Disk States;
-- Diskless     - No local block device has been assigned to the DRBD driver. This may mean that the resource
--                has never attached to its backing device, that it has been manually detached using drbdadm 
--                detach, or that it automatically detached after a lower-level I/O error.
-- Inconsistent - The data is inconsistent. This status occurs immediately upon creation of a new resource, 
--                on both nodes (before the initial full sync). Also, this status is found in one node (the 
--                synchronization target) during synchronization.
-- Outdated     - Resource data is consistent, but outdated.
-- DUnknown     - This state is used for the peer disk if no network connection is available.
-- Consistent   - Consistent data of a node without connection. When the connection is established, it is 
--                decided whether the data is UpToDate or Outdated.
-- UpToDate     - Consistent, up-to-date state of the data. This is the normal state
-- 
-- NOTE: Transient states are not recorded, but are below for completeness sake
-- Attaching    - Transient state while reading meta data.
-- Detaching    - Transient state while detaching and waiting for ongoing IOs to complete.
-- Failed       - Transient state following an I/O failure report by the local block device. Next state: 
--                Diskless.
-- Negotiating  - Transient state when an Attach is carried out on an already-Connected DRBD device.
-- 
-- Resource Roles ;
-- Primary   - The resource is currently in the primary role, and may be read from and written to. This role 
--             only occurs on one of the two nodes, unless dual-primary mode is enabled.
-- Secondary - The resource is currently in the secondary role. It normally receives updates from its peer 
--             (unless running in disconnected mode), but may neither be read from nor written to. This role 
--             may occur on one or both nodes.
-- Unknown   - The resource’s role is currently unknown. The local resource role never has this status. It is
--             only displayed for the peer’s resource role, and only in disconnected mode.
--             
-- Replication states;
-- Off           - The volume is not replicated over this connection, since the connection is not Connected.
-- Established   - All writes to that volume are replicated online. This is the normal state.
-- StartingSyncS - Full synchronization, initiated by the administrator, is just starting. The next possible 
--                 states are: SyncSource or PausedSyncS.
-- StartingSyncT - Full synchronization, initiated by the administrator, is just starting. Next state: 
--                 WFSyncUUID.
-- WFBitMapS     - Partial synchronization is just starting. Next possible states: SyncSource or PausedSyncS.
-- WFBitMapT     - Partial synchronization is just starting. Next possible state: WFSyncUUID.
-- WFSyncUUID    - Synchronization is about to begin. Next possible states: SyncTarget or PausedSyncT.
-- SyncSource    - Synchronization is currently running, with the local node being the source of 
--                 synchronization.
-- SyncTarget    - Synchronization is currently running, with the local node being the target of 
--                 synchronization.
-- PausedSyncS   - The local node is the source of an ongoing synchronization, but synchronization is 
--                 currently paused. This may be due to a dependency on the completion of another 
--                 synchronization process, or due to synchronization having been manually interrupted by 
--                 drbdadm pause-sync.
-- PausedSyncT   - The local node is the target of an ongoing synchronization, but synchronization is 
--                 currently paused. This may be due to a dependency on the completion of another 
--                 synchronization process, or due to synchronization having been manually interrupted by 
--                 drbdadm pause-sync.
-- VerifyS       - On-line device verification is currently running, with the local node being the source of
--                 verification.
-- VerifyT       - On-line device verification is currently running, with the local node being the target of
--                 verification.
-- Ahead         - Data replication was suspended, since the link can not cope with the load. This state is
--                 enabled by the configuration on-congestion option (see Configuring congestion policies and
--                 suspended replication).
-- Behind        - Data replication was suspended by the peer, since the link can not cope with the load. 
--                 This state is enabled by the configuration on-congestion option on the peer node (see 
--                 Configuring congestion policies and suspended replication).
-- 
-- Connection States; 
-- 
-- StandAlone     - No network configuration available. The resource has not yet been connected, or has been administratively disconnected (using drbdadm disconnect), or has dropped its connection due to failed authentication or split brain.
-- Connecting     - This node is waiting until the peer node becomes visible on the network.
-- Connected      - A DRBD connection has been established, data mirroring is now active. This is the normal state.
-- 
-- NOTE: Temporary states are not recorded, but are below for completeness sake
-- Disconnecting  - Temporary state during disconnection. The next state is StandAlone.
-- Unconnected    - Temporary state, prior to a connection attempt. Possible next states: Connecting.
-- Timeout        - Temporary state following a timeout in the communication with the peer. Next state: 
--                  Unconnected.
-- BrokenPipe     - Temporary state after the connection to the peer was lost. Next state: Unconnected.
-- NetworkFailure - Temporary state after the connection to the partner was lost. Next state: Unconnected.
-- ProtocolError  - Temporary state after the connection to the partner was lost. Next state: Unconnected.
-- TearDown       - Temporary state. The peer is closing the connection. Next state: Unconnected.

-- NOTE: This table stores the information about this volume on the local host. 
CREATE TABLE scan_drbd_volumes (
    scan_drbd_volume_uuid                       uuid                        not null    primary key,
    scan_drbd_volume_host_uuid                  uuid                        not null, 
    scan_drbd_volume_scan_drbd_resource_uuid    uuid                        not null, 
    scan_drbd_volume_number                     numeric                     not null,                -- The name of the volume.
    scan_drbd_volume_device_path                text                        not null,                -- This is the device path to the DRBD resource
    scan_drbd_volume_device_minor               numeric                     not null,                -- This is the device minor number, which translates to '/dev/drbd<minor>' 
    scan_drbd_volume_size                       numeric                     not null,                -- This is size of the DRBD device (in bytes)
    modified_date                               timestamp with time zone    not null,
    
    FOREIGN KEY(scan_drbd_volume_scan_drbd_resource_uuid) REFERENCES scan_drbd_resources(scan_drbd_resource_uuid), 
    FOREIGN KEY(scan_drbd_volume_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_drbd_volumes OWNER TO admin;

CREATE TABLE history.scan_drbd_volumes (
    history_id                                  bigserial,
    scan_drbd_volume_uuid                       uuid,
    scan_drbd_volume_host_uuid                  uuid,
    scan_drbd_volume_scan_drbd_resource_uuid    uuid,
    scan_drbd_volume_number                     numeric,
    scan_drbd_volume_device_path                text,
    scan_drbd_volume_device_minor               numeric,
    scan_drbd_volume_size                       numeric,
    modified_date                               timestamp with time zone    not null
);
ALTER TABLE history.scan_drbd_volumes OWNER TO admin;

CREATE FUNCTION history_scan_drbd_volumes() RETURNS trigger
AS $$
DECLARE
    history_scan_drbd_volumes RECORD;
BEGIN
    SELECT INTO history_scan_drbd_volumes * FROM scan_drbd_volumes WHERE scan_drbd_volume_uuid=new.scan_drbd_volume_uuid;
    INSERT INTO history.scan_drbd_volumes
        (scan_drbd_volume_uuid, 
         scan_drbd_volume_host_uuid, 
         scan_drbd_volume_scan_drbd_resource_uuid, 
         scan_drbd_volume_number, 
         scan_drbd_volume_device_path, 
         scan_drbd_volume_device_minor, 
         scan_drbd_volume_size, 
	 modified_date)
    VALUES
        (history_scan_drbd_volumes.scan_drbd_volume_uuid,
         history_scan_drbd_volumes.scan_drbd_volume_host_uuid, 
         history_scan_drbd_volumes.scan_drbd_volume_scan_drbd_resource_uuid, 
         history_scan_drbd_volumes.scan_drbd_volume_number, 
         history_scan_drbd_volumes.scan_drbd_volume_device_path, 
         history_scan_drbd_volumes.scan_drbd_volume_device_minor, 
         history_scan_drbd_volumes.scan_drbd_volume_size, 
         history_scan_drbd_volumes.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_drbd_volumes() OWNER TO admin;

CREATE TRIGGER trigger_scan_drbd_volumes
    AFTER INSERT OR UPDATE ON scan_drbd_volumes
    FOR EACH ROW EXECUTE PROCEDURE history_scan_drbd_volumes();


-- This is the peer information for a given volume
CREATE TABLE scan_drbd_peers (
    scan_drbd_peer_uuid                      uuid                        not null    primary key,
    scan_drbd_peer_host_uuid                 uuid                        not null, 
    scan_drbd_peer_scan_drbd_volume_uuid     uuid                        not null, 
    scan_drbd_peer_host_name                 text                        not null,                -- The host name for this peer, as recorded in the config
    scan_drbd_peer_connection_state          text                        not null,                -- The connection state to the peer. See "Connection States" and "Replication States" above.
    scan_drbd_peer_local_disk_state          text                        not null,                -- The local disk state of the peer, see "Disk States" above.
    scan_drbd_peer_disk_state                text                        not null,                -- The local disk state of the peer, see "Disk States" above.
    scan_drbd_peer_local_role                text                        not null,                -- The current local role of the peer. 
    scan_drbd_peer_role                      text                        not null,                -- The current peer role of the peer. 
    scan_drbd_peer_out_of_sync_size          numeric                     not null,                -- This is the number of "out of sync" bytes. Set to '0' when both sides are UpToDate.
    scan_drbd_peer_replication_speed         numeric                     not null,                -- This is how many bytes per second are being copied. Set to '0' when not synchronizing.
    scan_drbd_peer_estimated_time_to_sync    numeric                     not null,                -- This is the number of second that is *estimated* remaining in the resync. Set to '0' when both sides are UpToDate.
    scan_drbd_peer_ip_address                text                        not null,                -- The (SN) IP address used for this peer.
    scan_drbd_peer_tcp_port                  numeric                     not null,                -- This is the port number used for this peer.
    scan_drbd_peer_protocol                  text                        not null,                -- This is 'A' for async peers (to DR, usually) or 'C' to sync peers (node peer and sometimes DR)
    scan_drbd_peer_fencing                   text                        not null,                -- Set to 'resource-and-stonith' for node peers and 'dont-care' for DR hosts.
    modified_date                            timestamp with time zone    not null,
    
    FOREIGN KEY(scan_drbd_peer_scan_drbd_volume_uuid) REFERENCES scan_drbd_resources(scan_drbd_resource_uuid), 
    FOREIGN KEY(scan_drbd_peer_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_drbd_peers OWNER TO admin;

CREATE TABLE history.scan_drbd_peers (
    history_id                               bigserial,
    scan_drbd_peer_uuid                      uuid,
    scan_drbd_peer_host_uuid                 uuid,
    scan_drbd_peer_scan_drbd_volume_uuid     uuid,
    scan_drbd_peer_host_name                 text, 
    scan_drbd_peer_connection_state          text, 
    scan_drbd_peer_local_disk_state          text, 
    scan_drbd_peer_disk_state                text, 
    scan_drbd_peer_local_role                text, 
    scan_drbd_peer_role                      text, 
    scan_drbd_peer_out_of_sync_size          numeric, 
    scan_drbd_peer_replication_speed         numeric, 
    scan_drbd_peer_estimated_time_to_sync    numeric, 
    scan_drbd_peer_ip_address                text, 
    scan_drbd_peer_tcp_port                  numeric, 
    scan_drbd_peer_protocol                  text, 
    scan_drbd_peer_fencing                   text, 
    modified_date                            timestamp with time zone    not null
);
ALTER TABLE history.scan_drbd_peers OWNER TO admin;

CREATE FUNCTION history_scan_drbd_peers() RETURNS trigger
AS $$
DECLARE
    history_scan_drbd_peers RECORD;
BEGIN
    SELECT INTO history_scan_drbd_peers * FROM scan_drbd_peers WHERE scan_drbd_peer_uuid=new.scan_drbd_peer_uuid;
    INSERT INTO history.scan_drbd_peers
        (scan_drbd_peer_uuid, 
         scan_drbd_peer_host_uuid, 
         scan_drbd_peer_scan_drbd_volume_uuid, 
         scan_drbd_peer_host_name, 
         scan_drbd_peer_connection_state, 
         scan_drbd_peer_local_disk_state, 
         scan_drbd_peer_disk_state, 
         scan_drbd_peer_local_role, 
         scan_drbd_peer_role, 
         scan_drbd_peer_out_of_sync_size, 
         scan_drbd_peer_replication_speed, 
         scan_drbd_peer_estimated_time_to_sync, 
         scan_drbd_peer_ip_address, 
         scan_drbd_peer_tcp_port, 
         scan_drbd_peer_protocol, 
         scan_drbd_peer_fencing, 
	 modified_date)
    VALUES
        (history_scan_drbd_peers.scan_drbd_peer_uuid,
         history_scan_drbd_peers.scan_drbd_peer_host_uuid, 
         history_scan_drbd_peers.scan_drbd_peer_scan_drbd_volume_uuid, 
         history_scan_drbd_peers.scan_drbd_peer_host_name, 
         history_scan_drbd_peers.scan_drbd_peer_connection_state, 
         history_scan_drbd_peers.scan_drbd_peer_local_disk_state, 
         history_scan_drbd_peers.scan_drbd_peer_disk_state, 
         history_scan_drbd_peers.scan_drbd_peer_local_role, 
         history_scan_drbd_peers.scan_drbd_peer_role, 
         history_scan_drbd_peers.scan_drbd_peer_out_of_sync_size, 
         history_scan_drbd_peers.scan_drbd_peer_replication_speed, 
         history_scan_drbd_peers.scan_drbd_peer_estimated_time_to_sync, 
         history_scan_drbd_peers.scan_drbd_peer_ip_address, 
         history_scan_drbd_peers.scan_drbd_peer_tcp_port, 
         history_scan_drbd_peers.scan_drbd_peer_protocol, 
         history_scan_drbd_peers.scan_drbd_peer_fencing, 
         history_scan_drbd_peers.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_drbd_peers() OWNER TO admin;

CREATE TRIGGER trigger_scan_drbd_peers
    AFTER INSERT OR UPDATE ON scan_drbd_peers
    FOR EACH ROW EXECUTE PROCEDURE history_scan_drbd_peers();
