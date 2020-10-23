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

$anvil->data->{switches}{'shutdown'} = "";
$anvil->data->{switches}{boot}       = "";
$anvil->data->{switches}{server}     = "";
$anvil->Get->switches;

print "Connecting to the database(s);\n";
$anvil->Database->connect({debug => 3});
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});

my $cib = '<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="598" num_updates="3" admin_epoch="0" cib-last-written="Mon Oct 12 08:01:01 2020" update-origin="mk-a02n02" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="2">
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
        <nvpair id="cib-bootstrap-options-last-lrm-refresh" name="last-lrm-refresh" value="1602294579"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="mk-a02n01">
        <instance_attributes id="nodes-1">
          <nvpair id="nodes-1-maintenance" name="maintenance" value="on"/>
        </instance_attributes>
      </node>
      <node id="2" uname="mk-a02n02">
        <instance_attributes id="nodes-2">
          <nvpair id="nodes-2-maintenance" name="maintenance" value="on"/>
        </instance_attributes>
      </node>
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
          <op id="srv07-el6-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv07-el6-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv07-el6-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv07-el6-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
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
          <nvpair id="srv01-sql-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv01-sql-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv01-sql-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv01-sql-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv01-sql-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv01-sql-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv01-sql-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
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
          <op id="srv02-lab1-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv02-lab1-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv02-lab1-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv02-lab1-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
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
          <op id="srv08-m2-psql-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv08-m2-psql-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv08-m2-psql-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv08-m2-psql-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv03-lab2" provider="alteeve" type="server">
        <instance_attributes id="srv03-lab2-instance_attributes">
          <nvpair id="srv03-lab2-instance_attributes-name" name="name" value="srv03-lab2"/>
        </instance_attributes>
        <meta_attributes id="srv03-lab2-meta_attributes">
          <nvpair id="srv03-lab2-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv03-lab2-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv03-lab2-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv03-lab2-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv03-lab2-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv03-lab2-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv03-lab2-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv03-lab2-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv04-lab3" provider="alteeve" type="server">
        <instance_attributes id="srv04-lab3-instance_attributes">
          <nvpair id="srv04-lab3-instance_attributes-name" name="name" value="srv04-lab3"/>
        </instance_attributes>
        <meta_attributes id="srv04-lab3-meta_attributes">
          <nvpair id="srv04-lab3-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv04-lab3-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv04-lab3-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv04-lab3-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv04-lab3-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv04-lab3-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv04-lab3-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv04-lab3-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv05-lab4" provider="alteeve" type="server">
        <instance_attributes id="srv05-lab4-instance_attributes">
          <nvpair id="srv05-lab4-instance_attributes-name" name="name" value="srv05-lab4"/>
        </instance_attributes>
        <meta_attributes id="srv05-lab4-meta_attributes">
          <nvpair id="srv05-lab4-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv05-lab4-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv05-lab4-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv05-lab4-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv05-lab4-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv05-lab4-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv05-lab4-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv05-lab4-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="srv06-lab5" provider="alteeve" type="server">
        <instance_attributes id="srv06-lab5-instance_attributes">
          <nvpair id="srv06-lab5-instance_attributes-name" name="name" value="srv06-lab5"/>
        </instance_attributes>
        <meta_attributes id="srv06-lab5-meta_attributes">
          <nvpair id="srv06-lab5-meta_attributes-allow-migrate" name="allow-migrate" value="true"/>
          <nvpair id="srv06-lab5-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv06-lab5-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv06-lab5-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="INFINITY"/>
          <op id="srv06-lab5-monitor-interval-60" interval="60" name="monitor"/>
          <op id="srv06-lab5-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv06-lab5-start-interval-0s" interval="0s" name="start" on-fail="block" timeout="INFINITY"/>
          <op id="srv06-lab5-stop-interval-0s" interval="0s" name="stop" on-fail="block" timeout="INFINITY"/>
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
      <rsc_location id="location-srv03-lab2-mk-a02n01-200" node="mk-a02n01" rsc="srv03-lab2" score="200"/>
      <rsc_location id="location-srv03-lab2-mk-a02n02-100" node="mk-a02n02" rsc="srv03-lab2" score="100"/>
      <rsc_location id="location-srv04-lab3-mk-a02n01-200" node="mk-a02n01" rsc="srv04-lab3" score="200"/>
      <rsc_location id="location-srv04-lab3-mk-a02n02-100" node="mk-a02n02" rsc="srv04-lab3" score="100"/>
      <rsc_location id="location-srv05-lab4-mk-a02n01-200" node="mk-a02n01" rsc="srv05-lab4" score="200"/>
      <rsc_location id="location-srv05-lab4-mk-a02n02-100" node="mk-a02n02" rsc="srv05-lab4" score="100"/>
      <rsc_location id="location-srv06-lab5-mk-a02n01-200" node="mk-a02n01" rsc="srv06-lab5" score="200"/>
      <rsc_location id="location-srv06-lab5-mk-a02n02-100" node="mk-a02n02" rsc="srv06-lab5" score="100"/>
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
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="15:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;15:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1602502371" last-run="1602502371" exec-time="2" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="31:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:0;31:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="58" rc-code="0" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="648" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="17:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;17:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="13" rc-code="7" op-status="0" interval="0" last-rc-change="1602502372" last-run="1602502372" exec-time="0" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="35:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:0;35:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="59" rc-code="0" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="144" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="19:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;19:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="21" rc-code="7" op-status="0" interval="0" last-rc-change="1602502372" last-run="1602502372" exec-time="0" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="39:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:0;39:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="60" rc-code="0" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="620" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;21:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="29" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1448" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
          </lrm_resource>
          <lrm_resource id="srv01-sql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv01-sql_last_0" operation_key="srv01-sql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="22:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;22:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="33" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1444" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
          </lrm_resource>
          <lrm_resource id="srv02-lab1" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv02-lab1_last_0" operation_key="srv02-lab1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;23:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="37" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1448" queue-time="0" op-digest="c7a4471d0df53d7aab5392a1ba7d67e1"/>
          </lrm_resource>
          <lrm_resource id="srv08-m2-psql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv08-m2-psql_last_0" operation_key="srv08-m2-psql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="24:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;24:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="41" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1444" queue-time="0" op-digest="79b65e1a3736d1835da977ef2dee200d"/>
          </lrm_resource>
          <lrm_resource id="srv03-lab2" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv03-lab2_last_0" operation_key="srv03-lab2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="25:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;25:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="45" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1449" queue-time="0" op-digest="c193be9678d079bb7eb92e0bdefb2c9f"/>
          </lrm_resource>
          <lrm_resource id="srv04-lab3" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv04-lab3_last_0" operation_key="srv04-lab3_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="26:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;26:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="49" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1447" queue-time="0" op-digest="cb2426b2050bd79e2d7ca6ef986f4323"/>
          </lrm_resource>
          <lrm_resource id="srv05-lab4" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv05-lab4_last_0" operation_key="srv05-lab4_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="27:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;27:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="53" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1448" queue-time="0" op-digest="c738571d2348f506b23eda5a19a9b2ec"/>
          </lrm_resource>
          <lrm_resource id="srv06-lab5" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv06-lab5_last_0" operation_key="srv06-lab5_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="28:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;28:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n02" call-id="57" rc-code="7" op-status="0" interval="0" last-rc-change="1602502375" last-run="1602502375" exec-time="1480" queue-time="0" op-digest="750371be716fd8e695d423bf33be9d04"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="1" uname="mk-a02n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="29:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:0;29:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="58" rc-code="0" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="156" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;2:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="9" rc-code="7" op-status="0" interval="0" last-rc-change="1602502372" last-run="1602502372" exec-time="0" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="33:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:0;33:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="59" rc-code="0" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="622" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;4:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="17" rc-code="7" op-status="0" interval="0" last-rc-change="1602502372" last-run="1602502372" exec-time="0" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="37:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:0;37:0:0:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="60" rc-code="0" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="633" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;6:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="25" rc-code="7" op-status="0" interval="0" last-rc-change="1602502372" last-run="1602502372" exec-time="0" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;7:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="29" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1466" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
          </lrm_resource>
          <lrm_resource id="srv01-sql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv01-sql_last_0" operation_key="srv01-sql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="8:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;8:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="33" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1427" queue-time="0" op-digest="7acff34e45470837bd51c6d670b9878b"/>
          </lrm_resource>
          <lrm_resource id="srv02-lab1" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv02-lab1_last_0" operation_key="srv02-lab1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="9:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;9:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="37" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1398" queue-time="0" op-digest="c7a4471d0df53d7aab5392a1ba7d67e1"/>
          </lrm_resource>
          <lrm_resource id="srv08-m2-psql" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv08-m2-psql_last_0" operation_key="srv08-m2-psql_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="10:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;10:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="41" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1366" queue-time="0" op-digest="79b65e1a3736d1835da977ef2dee200d"/>
          </lrm_resource>
          <lrm_resource id="srv03-lab2" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv03-lab2_last_0" operation_key="srv03-lab2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="11:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;11:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="45" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1369" queue-time="0" op-digest="c193be9678d079bb7eb92e0bdefb2c9f"/>
          </lrm_resource>
          <lrm_resource id="srv04-lab3" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv04-lab3_last_0" operation_key="srv04-lab3_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="12:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;12:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="49" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1364" queue-time="0" op-digest="cb2426b2050bd79e2d7ca6ef986f4323"/>
          </lrm_resource>
          <lrm_resource id="srv05-lab4" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv05-lab4_last_0" operation_key="srv05-lab4_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="13:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;13:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="53" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1458" queue-time="0" op-digest="c738571d2348f506b23eda5a19a9b2ec"/>
          </lrm_resource>
          <lrm_resource id="srv06-lab5" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv06-lab5_last_0" operation_key="srv06-lab5_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="14:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" transition-magic="0:7;14:0:7:2b9d6b7e-5be6-467d-a3bd-f42e3b7718c7" exit-reason="" on_node="mk-a02n01" call-id="57" rc-code="7" op-status="0" interval="0" last-rc-change="1602502380" last-run="1602502380" exec-time="1415" queue-time="0" op-digest="750371be716fd8e695d423bf33be9d04"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>
';

$anvil->Cluster->parse_cib({debug => 2, cib => $cib});


