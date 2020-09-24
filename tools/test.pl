#!/usr/bin/perl
# 

use strict;
use warnings;
use Anvil::Tools;
use Data::Dumper;
use String::ShellQuote;
use utf8;
binmode(STDERR, ':encoding(utf-8)');
binmode(STDOUT, ':encoding(utf-8)');
 
my $THIS_FILE           =  ($0 =~ /^.*\/(.*)$/)[0];
my $running_directory   =  ($0 =~ /^(.*?)\/$THIS_FILE$/)[0];
if (($running_directory =~ /^\./) && ($ENV{PWD}))
{
	$running_directory =~ s/^\./$ENV{PWD}/;
}

# Turn off buffering so that the pinwheel will display while waiting for the SSH call(s) to complete.
$| = 1;

my $anvil = Anvil::Tools->new();
$anvil->Log->level({set => 2});
$anvil->Log->secure({set => 1});
$anvil->Get->switches;

print "Connecting to the database(s);\n";
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});

$anvil->Cluster->shutdown_server({
	debug  => 2,
	server => "srv07-el6",
});
$anvil->Cluster->shutdown_server({
	debug  => 2,
	server => "srv01-sql",
});
exit;

my $cib = '<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="453" num_updates="8" admin_epoch="0" cib-last-written="Thu Sep 24 01:26:31 2020" update-origin="mk-a02n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="1">
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
        <nvpair id="cib-bootstrap-options-last-lrm-refresh" name="last-lrm-refresh" value="1600924958"/>
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
          <nvpair id="srv02-lab1-meta_attributes-target-role" name="target-role" value="Stopped"/>
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
      <rsc_location id="location-srv08-m2-psql-mk-a02n01-200" node="mk-a02n01" rsc="srv08-m2-psql" score="200"/>
      <rsc_location id="location-srv08-m2-psql-mk-a02n02-100" node="mk-a02n02" rsc="srv08-m2-psql" score="100"/>
      <rsc_location id="location-srv01-sql-mk-a02n02-100" node="mk-a02n02" rsc="srv01-sql" score="100"/>
      <rsc_location id="location-srv01-sql-mk-a02n01-200" node="mk-a02n01" rsc="srv01-sql" score="200"/>
      <rsc_location id="location-srv02-lab1-mk-a02n02-100" node="mk-a02n02" rsc="srv02-lab1" score="100"/>
      <rsc_location id="location-srv02-lab1-mk-a02n01-200" node="mk-a02n01" rsc="srv02-lab1" score="200"/>
      <rsc_location id="location-srv07-el6-mk-a02n01-200" node="mk-a02n01" rsc="srv07-el6" score="200"/>
      <rsc_location id="location-srv07-el6-mk-a02n02-100" node="mk-a02n02" rsc="srv07-el6" score="100"/>
    </constraints>
    <fencing-topology>
      <fencing-level devices="ipmilan_node1" id="fl-mk-a02n01-1" index="1" target="mk-a02n01"/>
      <fencing-level devices="apc_snmp_node1_mk-pdu01,apc_snmp_node1_mk-pdu02" id="fl-mk-a02n01-2" index="2" target="mk-a02n01"/>
      <fencing-level devices="ipmilan_node2" id="fl-mk-a02n02-1" index="1" target="mk-a02n02"/>
      <fencing-level devices="apc_snmp_node2_mk-pdu01,apc_snmp_node2_mk-pdu02" id="fl-mk-a02n02-2" index="2" target="mk-a02n02"/>
    </fencing-topology>
  </configuration>
  <status>
    <node_state id="1" uname="mk-a02n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;21:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="42" rc-code="0" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="115" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
            <lrm_rsc_op id="ipmilan_node1_monitor_60000" operation_key="ipmilan_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="22:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;22:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="45" rc-code="0" op-status="0" interval="60000" last-rc-change="1600870208" exec-time="90" queue-time="0" op-digest="7064441a5f8ccc94d13cc9a1433de0a5" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;2:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="9" rc-code="7" op-status="0" interval="0" last-rc-change="1600870207" last-run="1600870207" exec-time="0" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="25:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;25:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="43" rc-code="0" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="907" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_monitor_60000" operation_key="apc_snmp_node1_mk-pdu02_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="26:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;26:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="47" rc-code="0" op-status="0" interval="60000" last-rc-change="1600870209" exec-time="1175" queue-time="0" op-digest="da20bfed231d75a3b22f97eb06bb445f" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;4:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="17" rc-code="7" op-status="0" interval="0" last-rc-change="1600870207" last-run="1600870207" exec-time="0" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="29:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;29:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="44" rc-code="0" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="874" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_monitor_60000" operation_key="apc_snmp_node2_mk-pdu01_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="30:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;30:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="46" rc-code="0" op-status="0" interval="60000" last-rc-change="1600870209" exec-time="789" queue-time="0" op-digest="5b8d168b9627dad87e1ba2edace17f1e" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;6:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="25" rc-code="7" op-status="0" interval="0" last-rc-change="1600870207" last-run="1600870207" exec-time="0" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_migrate_from_0" operation="migrate_from" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="25:85:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;25:85:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="75" rc-code="0" op-status="0" interval="0" last-rc-change="1600925198" last-run="1600925198" exec-time="551" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f" migrate_source="mk-a02n02" migrate_target="mk-a02n01"/>
            <lrm_rsc_op id="srv07-el6_monitor_60000" operation_key="srv07-el6_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:85:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;23:85:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="76" rc-code="0" op-status="0" interval="60000" last-rc-change="1600925201" exec-time="541" queue-time="0" op-digest="65d0f0c9227f2593835f5de6c9cb9d0e"/>
          </lrm_resource>
          <lrm_resource id="srv08-m2-psql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv08-m2-psql_last_0" operation_key="srv08-m2-psql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="10:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;10:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="41" rc-code="7" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="593" queue-time="0" op-digest="79b65e1a3736d1835da977ef2dee200d"/>
          </lrm_resource>
          <lrm_resource id="srv01-sql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv01-sql_last_0" operation_key="srv01-sql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;7:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="64" rc-code="0" op-status="0" interval="0" last-rc-change="1600924959" last-run="1600924959" exec-time="547" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
            <lrm_rsc_op id="srv01-sql_last_failure_0" operation_key="srv01-sql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;7:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="64" rc-code="0" op-status="0" interval="0" last-rc-change="1600924959" last-run="1600924959" exec-time="547" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
            <lrm_rsc_op id="srv01-sql_monitor_60000" operation_key="srv01-sql_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="24:79:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;24:79:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="69" rc-code="0" op-status="0" interval="60000" last-rc-change="1600924960" exec-time="564" queue-time="0" op-digest="0434e67501e3e7af47a547723c35b411"/>
          </lrm_resource>
          <lrm_resource id="srv02-lab1" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv02-lab1_last_0" operation_key="srv02-lab1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="8:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;8:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n01" call-id="68" rc-code="7" op-status="0" interval="0" last-rc-change="1600924959" last-run="1600924959" exec-time="546" queue-time="0" op-digest="c7a4471d0df53d7aab5392a1ba7d67e1"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
      <transient_attributes id="1">
        <instance_attributes id="status-1"/>
      </transient_attributes>
    </node_state>
    <node_state id="2" uname="mk-a02n02" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="2">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="11:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;11:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1600870206" last-run="1600870206" exec-time="2" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;23:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="42" rc-code="0" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="849" queue-time="1" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_monitor_60000" operation_key="apc_snmp_node1_mk-pdu01_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="24:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;24:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="46" rc-code="0" op-status="0" interval="60000" last-rc-change="1600870209" exec-time="755" queue-time="0" op-digest="9dd197b1c8871a78c74a32b26949998d" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="13:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;13:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="13" rc-code="7" op-status="0" interval="0" last-rc-change="1600870207" last-run="1600870207" exec-time="0" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="27:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;27:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="43" rc-code="0" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="106" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
            <lrm_rsc_op id="ipmilan_node2_monitor_60000" operation_key="ipmilan_node2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="28:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;28:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="45" rc-code="0" op-status="0" interval="60000" last-rc-change="1600870208" exec-time="87" queue-time="0" op-digest="467ef5117cbb737e5c6fc23b58809791" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="15:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;15:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="21" rc-code="7" op-status="0" interval="0" last-rc-change="1600870207" last-run="1600870207" exec-time="0" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="31:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;31:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="44" rc-code="0" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="872" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_monitor_60000" operation_key="apc_snmp_node2_mk-pdu02_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="32:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;32:0:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="47" rc-code="0" op-status="0" interval="60000" last-rc-change="1600870209" exec-time="759" queue-time="0" op-digest="910a16919098d7bca091e972cf8844f5" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv01-sql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv01-sql_last_0" operation_key="srv01-sql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="18:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;18:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="33" rc-code="7" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="564" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
          </lrm_resource>
          <lrm_resource id="srv02-lab1" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv02-lab1_last_0" operation_key="srv02-lab1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="19:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;19:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="37" rc-code="7" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="558" queue-time="0" op-digest="c7a4471d0df53d7aab5392a1ba7d67e1"/>
          </lrm_resource>
          <lrm_resource id="srv08-m2-psql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv08-m2-psql_last_0" operation_key="srv08-m2-psql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="20:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:7;20:0:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="41" rc-code="7" op-status="0" interval="0" last-rc-change="1600870208" last-run="1600870208" exec-time="562" queue-time="0" op-digest="79b65e1a3736d1835da977ef2dee200d"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_stop_0" operation="stop" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:85:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;21:85:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="64" rc-code="0" op-status="0" interval="0" last-rc-change="1600925199" last-run="1600925199" exec-time="1881" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f" migrate_source="mk-a02n02" migrate_target="mk-a02n01"/>
            <lrm_rsc_op id="srv07-el6_last_failure_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="9:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;9:78:7:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="55" rc-code="0" op-status="0" interval="0" last-rc-change="1600924959" last-run="1600924959" exec-time="552" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
            <lrm_rsc_op id="srv07-el6_monitor_60000" operation_key="srv07-el6_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:83:0:829209fd-35f2-4626-a9cd-f8a50a62871e" transition-magic="0:0;23:83:0:829209fd-35f2-4626-a9cd-f8a50a62871e" exit-reason="" on_node="mk-a02n02" call-id="61" rc-code="0" op-status="0" interval="60000" last-rc-change="1600925173" exec-time="539" queue-time="0" op-digest="65d0f0c9227f2593835f5de6c9cb9d0e"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
      <transient_attributes id="2">
        <instance_attributes id="status-2"/>
      </transient_attributes>
    </node_state>
  </status>
</cib>
';
my $not_in_cluster = $anvil->Cluster->parse_cib({debug => 2, cib => $cib});
if ($not_in_cluster)
{
	print "This node isn't in the cluster.\n";
}
else
{
	print "CIB parsed.\n";
}
