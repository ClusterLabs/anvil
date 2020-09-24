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
    scan_cluster_node_uuid                 uuid                        primary key,
    scan_cluster_node_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
    scan_cluster_node_host_uuid            uuid                        not null,       -- This is the host UUID of the node.
    scan_cluster_node_name                 text                        not null,       -- This is the host name as reported by pacemaker. It _should_ match up to a host name in 'hosts'.
    scan_cluster_node_pacemaker_id         numeric                     not null,       -- This is the internal pacemaker ID number of this node.
    modified_date                          timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_node_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid),
    FOREIGN KEY(scan_cluster_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster_nodes OWNER TO admin;

CREATE TABLE history.scan_cluster_nodes (
    history_id                             bigserial,
    scan_cluster_node_uuid                 uuid,
    scan_cluster_node_scan_cluster_uuid    uuid,
    scan_cluster_node_host_uuid            uuid,
    scan_cluster_node_name                 text,
    scan_cluster_node_pacemaker_id         numeric,
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
         modified_date)
    VALUES
        (history_scan_cluster_nodes.scan_cluster_node_uuid, 
         history_scan_cluster_nodes.scan_cluster_node_scan_cluster_uuid, 
         history_scan_cluster_nodes.scan_cluster_node_host_uuid, 
         history_scan_cluster_nodes.scan_cluster_node_name, 
         history_scan_cluster_nodes.scan_cluster_node_pacemaker_id, 
         history_scan_cluster_nodes.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster_nodes() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster_nodes
    AFTER INSERT OR UPDATE ON scan_cluster_nodes
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_nodes();


CREATE TABLE scan_cluster_stoniths (
    scan_cluster_stonith_uuid                 uuid                        primary key,
    scan_cluster_stonith_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
    scan_cluster_stonith_host_uuid            uuid                        not null,       -- This is the host UUID of the node.
    scan_cluster_stonith_name                 text                        not null,       -- This is the 'stonith id'
    scan_cluster_stonith_arguments            text                        not null,       -- This is the fence agent + collection of primitive variable=value pairs (the nvpairs)
    scan_cluster_stonith_operations           text                        not null,       -- This is the collection of operation variable=value pairs (the nvpairs)
    modified_date                             timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_stonith_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid),
    FOREIGN KEY(scan_cluster_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster_stoniths OWNER TO admin;

CREATE TABLE history.scan_cluster_stoniths (
    history_id                                bigserial,
    scan_cluster_stonith_uuid                 uuid,
    scan_cluster_stonith_scan_cluster_uuid    uuid, 
    scan_cluster_stonith_host_uuid            uuid, 
    scan_cluster_stonith_name                 text, 
    scan_cluster_stonith_arguments            text, 
    scan_cluster_stonith_operations           text, 
    modified_date                             timestamp with time zone    not null
);
ALTER TABLE history.scan_cluster_stoniths OWNER TO admin;

CREATE FUNCTION history_scan_cluster_stoniths() RETURNS trigger
AS $$
DECLARE
    history_scan_cluster_stoniths RECORD;
BEGIN
    SELECT INTO history_scan_cluster_stoniths * FROM scan_cluster_stoniths WHERE scan_cluster_stonith_uuid=new.scan_cluster_stonith_uuid;
    INSERT INTO history.scan_cluster_stoniths
        (scan_cluster_stonith_uuid, 
         scan_cluster_stonith_scan_cluster_uuid, 
         scan_cluster_stonith_host_uuid, 
         scan_cluster_stonith_name, 
         scan_cluster_stonith_arguments, 
         scan_cluster_stonith_operations, 
         modified_date)
    VALUES
        (history_scan_cluster_stoniths.scan_cluster_stonith_uuid, 
         history_scan_cluster_stoniths.scan_cluster_stonith_scan_cluster_uuid, 
         history_scan_cluster_stoniths.scan_cluster_stonith_host_uuid, 
         history_scan_cluster_stoniths.scan_cluster_stonith_name, 
         history_scan_cluster_stoniths.scan_cluster_stonith_arguments, 
         history_scan_cluster_stoniths.scan_cluster_stonith_operations, 
         history_scan_cluster_stoniths.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster_stoniths() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster_stoniths
    AFTER INSERT OR UPDATE ON scan_cluster_stoniths
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_stoniths();


CREATE TABLE scan_cluster_servers (
    scan_cluster_server_uuid                 uuid                        primary key,
    scan_cluster_server_scan_cluster_uuid    uuid                        not null,       -- The parent scan_cluster_uuid.
    scan_cluster_server_name                 text                        not null,       -- This is the name of the server (ocf primitive id)
    scan_cluster_server_state                text                        not null,       -- This is the 'running' or why it's off (off by user, etc)
    scan_cluster_server_host_name            uuid                        not null,       -- This is the (cluster) name of the node hosting the server. Blank if the server is off.
    scan_cluster_server_arguments            text                        not null,       -- This is the collection of primitive variable=value pairs (the nvpairs)
    scan_cluster_server_operations           text                        not null,       -- This is the collection of operation variable=value pairs (the nvpairs)
    scan_cluster_server_meta                 text                        not null,       -- This is the collection of meta attribute variable=value pairs (the nvpairs)
    modified_date                            timestamp with time zone    not null,
    
    FOREIGN KEY(scan_cluster_server_scan_cluster_uuid) REFERENCES scan_cluster(scan_cluster_uuid),
    FOREIGN KEY(scan_cluster_host_uuid) REFERENCES hosts(host_uuid)
);
ALTER TABLE scan_cluster_servers OWNER TO admin;

CREATE TABLE history.scan_cluster_servers (
    history_id                               bigserial,
    scan_cluster_server_uuid                 uuid,
    scan_cluster_server_scan_cluster_uuid    uuid, 
    scan_cluster_server_name                 text, 
    scan_cluster_server_arguments            text, 
    scan_cluster_server_operations           text, 
    scan_cluster_server_meta                 text, 
    modified_date                            timestamp with time zone    not null
);
ALTER TABLE history.scan_cluster_servers OWNER TO admin;

CREATE FUNCTION history_scan_cluster_servers() RETURNS trigger
AS $$
DECLARE
    history_scan_cluster_servers RECORD;
BEGIN
    SELECT INTO history_scan_cluster_servers * FROM scan_cluster_servers WHERE scan_cluster_server_uuid=new.scan_cluster_server_uuid;
    INSERT INTO history.scan_cluster_servers
        (scan_cluster_server_uuid, 
         scan_cluster_server_scan_cluster_uuid, 
         scan_cluster_server_name, 
         scan_cluster_server_arguments, 
         scan_cluster_server_operations, 
         scan_cluster_server_meta, 
         modified_date)
    VALUES
        (history_scan_cluster_servers.scan_cluster_server_uuid, 
         history_scan_cluster_servers.scan_cluster_server_scan_cluster_uuid, 
         history_scan_cluster_servers.scan_cluster_server_host_uuid, 
         history_scan_cluster_servers.scan_cluster_server_name, 
         history_scan_cluster_servers.scan_cluster_server_arguments, 
         history_scan_cluster_servers.scan_cluster_server_operations, 
         history_scan_cluster_servers.modified_date);
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
ALTER FUNCTION history_scan_cluster_servers() OWNER TO admin;

CREATE TRIGGER trigger_scan_cluster_servers
    AFTER INSERT OR UPDATE ON scan_cluster_servers
    FOR EACH ROW EXECUTE PROCEDURE history_scan_cluster_servers();


-- Example CIB
# pcs resource
  * srv07-el6	(ocf::alteeve:server):	Stopped (disabled)
  * srv01-sql	(ocf::alteeve:server):	Started mk-a02n01
  * srv02-lab1	(ocf::alteeve:server):	Started mk-a02n01
  * srv08-m2-psql	(ocf::alteeve:server):	Stopped (disabled)
  
<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="418" num_updates="4" admin_epoch="0" cib-last-written="Mon Sep 21 13:30:38 2020" update-origin="mk-a02n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="2">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="mk-anvil-02"/>
        <nvpair id="cib-bootstrap-options-stonith-max-attempts" name="stonith-max-attempts" value="INFINITY"/>
        <nvpair id="cib-bootstrap-options-stonith-enabled" name="stonith-enabled" value="true"/>
        <nvpair id="cib-bootstrap-options-maintenance-mode" name="maintenance-mode" value="false"/>
        <nvpair id="cib-bootstrap-options-last-lrm-refresh" name="last-lrm-refresh" value="1597956504"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="mk-a02n01"/>
      <node id="2" uname="mk-a02n02"/>
    </nodes>
    <resources>
      <primitive class="stonith" id="ipmilan_node1" type="fence_ipmilan">
        <instance_attributes id="ipmilan_node1-instance_attributes">
          <nvpair id="ipmilan_node1-instance_attributes-ipaddr" name="ipaddr" value="10.201.13.1"/>
          <nvpair id="ipmilan_node1-instance_attributes-password" name="password" value="another secret p"/>
          <nvpair id="ipmilan_node1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="ipmilan_node1-instance_attributes-username" name="username" value="admin"/>
        </instance_attributes>
        <operations>
          <op id="ipmilan_node1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node1_mk-pdu01-instance_attributes">
          <nvpair id="apc_snmp_node1_mk-pdu01-instance_attributes-ip" name="ip" value="10.201.2.3"/>
          <nvpair id="apc_snmp_node1_mk-pdu01-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="apc_snmp_node1_mk-pdu01-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node1_mk-pdu01-instance_attributes-port" name="port" value="3"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node1_mk-pdu01-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node1_mk-pdu02-instance_attributes">
          <nvpair id="apc_snmp_node1_mk-pdu02-instance_attributes-ip" name="ip" value="10.201.2.4"/>
          <nvpair id="apc_snmp_node1_mk-pdu02-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="apc_snmp_node1_mk-pdu02-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node1_mk-pdu02-instance_attributes-port" name="port" value="3"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node1_mk-pdu02-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="ipmilan_node2" type="fence_ipmilan">
        <instance_attributes id="ipmilan_node2-instance_attributes">
          <nvpair id="ipmilan_node2-instance_attributes-ipaddr" name="ipaddr" value="10.201.13.2"/>
          <nvpair id="ipmilan_node2-instance_attributes-password" name="password" value="another secret p"/>
          <nvpair id="ipmilan_node2-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n02"/>
          <nvpair id="ipmilan_node2-instance_attributes-username" name="username" value="admin"/>
        </instance_attributes>
        <operations>
          <op id="ipmilan_node2-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node2_mk-pdu01-instance_attributes">
          <nvpair id="apc_snmp_node2_mk-pdu01-instance_attributes-ip" name="ip" value="10.201.2.3"/>
          <nvpair id="apc_snmp_node2_mk-pdu01-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n02"/>
          <nvpair id="apc_snmp_node2_mk-pdu01-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node2_mk-pdu01-instance_attributes-port" name="port" value="4"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node2_mk-pdu01-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node2_mk-pdu02-instance_attributes">
          <nvpair id="apc_snmp_node2_mk-pdu02-instance_attributes-ip" name="ip" value="10.201.2.4"/>
          <nvpair id="apc_snmp_node2_mk-pdu02-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n02"/>
          <nvpair id="apc_snmp_node2_mk-pdu02-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node2_mk-pdu02-instance_attributes-port" name="port" value="4"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node2_mk-pdu02-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv07-el6" provider="alteeve" type="server">
        <instance_attributes id="srv07-el6-instance_attributes">
          <nvpair id="srv07-el6-instance_attributes-name" name="name" value="srv07-el6"/>
        </instance_attributes>
        <meta_attributes id="srv07-el6-meta_attributes">
          <nvpair id="srv07-el6-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv07-el6-meta_attributes-migrate_to" name="migrate_to" value="INFINITY"/>
          <nvpair id="srv07-el6-meta_attributes-stop" name="stop" value="INFINITY"/>
          <nvpair id="srv07-el6-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv07-el6-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv07-el6-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv07-el6-monitor-interval-60" interval="60" name="monitor" on-fail="block"/>
          <op id="srv07-el6-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv07-el6-start-interval-0s" interval="0s" name="start" timeout="30"/>
          <op id="srv07-el6-stop-interval-0s" interval="0s" name="stop" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv01-sql" provider="alteeve" type="server">
        <instance_attributes id="srv01-sql-instance_attributes">
          <nvpair id="srv01-sql-instance_attributes-name" name="name" value="srv01-sql"/>
        </instance_attributes>
        <meta_attributes id="srv01-sql-meta_attributes">
          <nvpair id="srv01-sql-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv01-sql-meta_attributes-migrate_to" name="migrate_to" value="INFINITY"/>
          <nvpair id="srv01-sql-meta_attributes-stop" name="stop" value="INFINITY"/>
        </meta_attributes>
        <operations>
          <op id="srv01-sql-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv01-sql-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv01-sql-monitor-interval-60" interval="60" name="monitor" on-fail="block"/>
          <op id="srv01-sql-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv01-sql-start-interval-0s" interval="0s" name="start" timeout="30"/>
          <op id="srv01-sql-stop-interval-0s" interval="0s" name="stop" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv02-lab1" provider="alteeve" type="server">
        <instance_attributes id="srv02-lab1-instance_attributes">
          <nvpair id="srv02-lab1-instance_attributes-name" name="name" value="srv02-lab1"/>
        </instance_attributes>
        <meta_attributes id="srv02-lab1-meta_attributes">
          <nvpair id="srv02-lab1-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv02-lab1-meta_attributes-migrate_to" name="migrate_to" value="INFINITY"/>
          <nvpair id="srv02-lab1-meta_attributes-stop" name="stop" value="INFINITY"/>
        </meta_attributes>
        <operations>
          <op id="srv02-lab1-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv02-lab1-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv02-lab1-monitor-interval-60" interval="60" name="monitor" on-fail="block"/>
          <op id="srv02-lab1-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv02-lab1-start-interval-0s" interval="0s" name="start" timeout="30"/>
          <op id="srv02-lab1-stop-interval-0s" interval="0s" name="stop" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv08-m2-psql" provider="alteeve" type="server">
        <instance_attributes id="srv08-m2-psql-instance_attributes">
          <nvpair id="srv08-m2-psql-instance_attributes-name" name="name" value="srv08-m2-psql"/>
        </instance_attributes>
        <meta_attributes id="srv08-m2-psql-meta_attributes">
          <nvpair id="srv08-m2-psql-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv08-m2-psql-meta_attributes-migrate_to" name="migrate_to" value="INFINITY"/>
          <nvpair id="srv08-m2-psql-meta_attributes-stop" name="stop" value="INFINITY"/>
          <nvpair id="srv08-m2-psql-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv08-m2-psql-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv08-m2-psql-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv08-m2-psql-monitor-interval-60" interval="60" name="monitor" on-fail="block"/>
          <op id="srv08-m2-psql-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv08-m2-psql-start-interval-0s" interval="0s" name="start" timeout="30"/>
          <op id="srv08-m2-psql-stop-interval-0s" interval="0s" name="stop" timeout="INFINITY"/>
        </operations>
      </primitive>
    </resources>
    <constraints>
      <rsc_location id="location-srv07-el6-mk-a02n01-200" node="mk-a02n01" rsc="srv07-el6" score="200"/>
      <rsc_location id="location-srv07-el6-mk-a02n02-100" node="mk-a02n02" rsc="srv07-el6" score="100"/>
      <rsc_location id="location-srv01-sql-mk-a02n01-200" node="mk-a02n01" rsc="srv01-sql" score="200"/>
      <rsc_location id="location-srv01-sql-mk-a02n02-100" node="mk-a02n02" rsc="srv01-sql" score="100"/>
      <rsc_location id="location-srv02-lab1-mk-a02n01-200" node="mk-a02n01" rsc="srv02-lab1" score="200"/>
      <rsc_location id="location-srv02-lab1-mk-a02n02-100" node="mk-a02n02" rsc="srv02-lab1" score="100"/>
      <rsc_location id="location-srv08-m2-psql-mk-a02n01-200" node="mk-a02n01" rsc="srv08-m2-psql" score="200"/>
      <rsc_location id="location-srv08-m2-psql-mk-a02n02-100" node="mk-a02n02" rsc="srv08-m2-psql" score="100"/>
    </constraints>
    <fencing-topology>
      <fencing-level devices="ipmilan_node1" id="fl-mk-a02n01-1" index="1" target="mk-a02n01"/>
      <fencing-level devices="apc_snmp_node1_mk-pdu01,apc_snmp_node1_mk-pdu02" id="fl-mk-a02n01-2" index="2" target="mk-a02n01"/>
      <fencing-level devices="ipmilan_node2" id="fl-mk-a02n02-1" index="1" target="mk-a02n02"/>
      <fencing-level devices="apc_snmp_node2_mk-pdu01,apc_snmp_node2_mk-pdu02" id="fl-mk-a02n02-2" index="2" target="mk-a02n02"/>
    </fencing-topology>
  </configuration>
  <status>
    <node_state id="2" uname="mk-a02n02" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="2">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="11:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;11:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1600708714" last-run="1600708714" exec-time="1" queue-time="1" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;23:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="42" rc-code="0" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="623" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_monitor_60000" operation_key="apc_snmp_node1_mk-pdu01_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="24:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;24:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="47" rc-code="0" op-status="0" interval="60000" last-rc-change="1600708715" exec-time="556" queue-time="0" op-digest="9dd197b1c8871a78c74a32b26949998d" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="13:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;13:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="13" rc-code="7" op-status="0" interval="0" last-rc-change="1600708714" last-run="1600708714" exec-time="0" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="27:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;27:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="43" rc-code="0" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="100" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
            <lrm_rsc_op id="ipmilan_node2_monitor_60000" operation_key="ipmilan_node2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="28:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;28:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="45" rc-code="0" op-status="0" interval="60000" last-rc-change="1600708715" exec-time="86" queue-time="0" op-digest="467ef5117cbb737e5c6fc23b58809791" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="15:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;15:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="21" rc-code="7" op-status="0" interval="0" last-rc-change="1600708714" last-run="1600708714" exec-time="0" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="31:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;31:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="44" rc-code="0" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="603" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_monitor_60000" operation_key="apc_snmp_node2_mk-pdu02_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="32:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;32:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="46" rc-code="0" op-status="0" interval="60000" last-rc-change="1600708715" exec-time="555" queue-time="0" op-digest="910a16919098d7bca091e972cf8844f5" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="17:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;17:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="29" rc-code="7" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="605" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
          </lrm_resource>
          <lrm_resource id="srv01-sql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv01-sql_last_0" operation_key="srv01-sql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="18:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;18:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="33" rc-code="7" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="604" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
          </lrm_resource>
          <lrm_resource id="srv02-lab1" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv02-lab1_last_0" operation_key="srv02-lab1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="19:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;19:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="37" rc-code="7" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="603" queue-time="0" op-digest="c7a4471d0df53d7aab5392a1ba7d67e1"/>
          </lrm_resource>
          <lrm_resource id="srv08-m2-psql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv08-m2-psql_last_0" operation_key="srv08-m2-psql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="20:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;20:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n02" call-id="41" rc-code="7" op-status="0" interval="0" last-rc-change="1600708715" last-run="1600708715" exec-time="602" queue-time="0" op-digest="79b65e1a3736d1835da977ef2dee200d"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="1" uname="mk-a02n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;21:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="42" rc-code="0" op-status="0" interval="0" last-rc-change="1600708716" last-run="1600708716" exec-time="172" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
            <lrm_rsc_op id="ipmilan_node1_monitor_60000" operation_key="ipmilan_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="22:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;22:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="45" rc-code="0" op-status="0" interval="60000" last-rc-change="1600708716" exec-time="90" queue-time="0" op-digest="7064441a5f8ccc94d13cc9a1433de0a5" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;2:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="9" rc-code="7" op-status="0" interval="0" last-rc-change="1600708714" last-run="1600708714" exec-time="0" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="25:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;25:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="43" rc-code="0" op-status="0" interval="0" last-rc-change="1600708716" last-run="1600708716" exec-time="666" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_monitor_60000" operation_key="apc_snmp_node1_mk-pdu02_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="26:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;26:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="46" rc-code="0" op-status="0" interval="60000" last-rc-change="1600708717" exec-time="574" queue-time="1" op-digest="da20bfed231d75a3b22f97eb06bb445f" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;4:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="17" rc-code="7" op-status="0" interval="0" last-rc-change="1600708714" last-run="1600708714" exec-time="0" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="29:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;29:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="44" rc-code="0" op-status="0" interval="0" last-rc-change="1600708716" last-run="1600708716" exec-time="675" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_monitor_60000" operation_key="apc_snmp_node2_mk-pdu01_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="30:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;30:0:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="47" rc-code="0" op-status="0" interval="60000" last-rc-change="1600708717" exec-time="565" queue-time="0" op-digest="5b8d168b9627dad87e1ba2edace17f1e" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;6:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="25" rc-code="7" op-status="0" interval="0" last-rc-change="1600708714" last-run="1600708714" exec-time="0" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;7:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="29" rc-code="7" op-status="0" interval="0" last-rc-change="1600708716" last-run="1600708716" exec-time="598" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
          </lrm_resource>
          
          <lrm_resource id="srv01-sql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv01-sql_last_0" operation_key="srv01-sql_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="19:1:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;19:1:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="48" rc-code="0" op-status="0" interval="0" last-rc-change="1600709387" last-run="1600709387" exec-time="13119" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
            <lrm_rsc_op id="srv01-sql_monitor_60000" operation_key="srv01-sql_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="20:1:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;20:1:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="49" rc-code="0" op-status="0" interval="60000" last-rc-change="1600709400" exec-time="546" queue-time="0" op-digest="0434e67501e3e7af47a547723c35b411"/>
          </lrm_resource>
          
          <lrm_resource id="srv02-lab1" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv02-lab1_last_0" operation_key="srv02-lab1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="22:2:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;22:2:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="50" rc-code="0" op-status="0" interval="0" last-rc-change="1600709438" last-run="1600709438" exec-time="12668" queue-time="0" op-digest="c7a4471d0df53d7aab5392a1ba7d67e1"/>
            <lrm_rsc_op id="srv02-lab1_monitor_60000" operation_key="srv02-lab1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:2:0:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:0;23:2:0:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="51" rc-code="0" op-status="0" interval="60000" last-rc-change="1600709451" exec-time="549" queue-time="0" op-digest="435d654a0384ef5a77a7517d682950ce"/>
          </lrm_resource>
          
          <lrm_resource id="srv08-m2-psql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv08-m2-psql_last_0" operation_key="srv08-m2-psql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="10:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" transition-magic="0:7;10:0:7:2c429916-850e-4468-abb7-8f95e44fdf8e" exit-reason="" on_node="mk-a02n01" call-id="41" rc-code="7" op-status="0" interval="0" last-rc-change="1600708716" last-run="1600708716" exec-time="596" queue-time="0" op-digest="79b65e1a3736d1835da977ef2dee200d"/>
          </lrm_resource>
          
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>
--