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

print "Connecting to the database(s);\n";
$anvil->Database->connect();
$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, 'print' => 1, level => 2, secure => 0, key => "log_0132"});
$anvil->Get->switches;

my $xml = '<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="322" num_updates="6" admin_epoch="0" cib-last-written="Sun Aug 16 18:24:22 2020" update-origin="mk-a02n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="2">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="mk-anvil-02"/>
        <nvpair id="cib-bootstrap-options-stonith-max-attempts" name="stonith-max-attempts" value="INFINITY"/>
        <nvpair id="cib-bootstrap-options-stonith-enabled" name="stonith-enabled" value="true"/>
        <nvpair id="cib-bootstrap-options-maintenance-mode" name="maintenance-mode" value="true"/>
        <nvpair id="cib-bootstrap-options-last-lrm-refresh" name="last-lrm-refresh" value="1597445952"/>
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
          <nvpair id="srv07-el6-meta_attributes-target-role" name="target-role" value="Stopped"/>
        </meta_attributes>
        <operations>
          <op id="srv07-el6-migrate_from-interval-0s" interval="0s" name="migrate_from" timeout="600"/>
          <op id="srv07-el6-migrate_to-interval-0s" interval="0s" name="migrate_to" timeout="600"/>
          <op id="srv07-el6-monitor-interval-60" interval="60" name="monitor" on-fail="block"/>
          <op id="srv07-el6-notify-interval-0s" interval="0s" name="notify" timeout="20"/>
          <op id="srv07-el6-start-interval-0s" interval="0s" name="start" timeout="30"/>
          <op id="srv07-el6-stop-interval-0s" interval="0s" name="stop" timeout="60"/>
        </operations>
      </primitive>
    </resources>
    <constraints>
      <rsc_location id="cli-prefer-srv07-el6" node="mk-a02n02" role="Started" rsc="srv07-el6" score="INFINITY"/>
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
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="8:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;8:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1597616557" last-run="1597616557" exec-time="2" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="17:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:0;17:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="30" rc-code="0" op-status="0" interval="0" last-rc-change="1597616558" last-run="1597616558" exec-time="598" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="10:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;10:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="13" rc-code="7" op-status="0" interval="0" last-rc-change="1597616557" last-run="1597616557" exec-time="0" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:0;21:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="31" rc-code="0" op-status="0" interval="0" last-rc-change="1597616558" last-run="1597616558" exec-time="98" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="12:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;12:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="21" rc-code="7" op-status="0" interval="0" last-rc-change="1597616557" last-run="1597616557" exec-time="0" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="25:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:0;25:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="32" rc-code="0" op-status="0" interval="0" last-rc-change="1597616558" last-run="1597616558" exec-time="591" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="14:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;14:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n02" call-id="29" rc-code="7" op-status="0" interval="0" last-rc-change="1597616558" last-run="1597616558" exec-time="536" queue-time="1" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="1" uname="mk-a02n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="15:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:0;15:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="30" rc-code="0" op-status="0" interval="0" last-rc-change="1597616559" last-run="1597616559" exec-time="113" queue-time="0" op-digest="230c3c46a7f39ff7a5ff7f1b8aa9f17d" op-secure-params=" password  passwd " op-secure-digest="a8bb97c4c1cae8f90e445a0ce85ecc19"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu01_last_0" operation_key="apc_snmp_node1_mk-pdu01_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;2:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="9" rc-code="7" op-status="0" interval="0" last-rc-change="1597616557" last-run="1597616557" exec-time="0" queue-time="0" op-digest="6b6191eeb61cd595ab0a26ec9762f8aa" op-secure-params=" password  passwd " op-secure-digest="1dc851b0efa605b4ec3f03e3a3ba62f7"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_mk-pdu02_last_0" operation_key="apc_snmp_node1_mk-pdu02_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="19:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:0;19:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="31" rc-code="0" op-status="0" interval="0" last-rc-change="1597616559" last-run="1597616559" exec-time="616" queue-time="0" op-digest="f4b11aca778aa58d81b7fa096bfe3fb4" op-secure-params=" password  passwd " op-secure-digest="78517effd4af72191ac2c0b9d8567fcd"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;4:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="17" rc-code="7" op-status="0" interval="0" last-rc-change="1597616557" last-run="1597616557" exec-time="0" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu01" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu01_last_0" operation_key="apc_snmp_node2_mk-pdu01_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:0;23:0:0:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="32" rc-code="0" op-status="0" interval="0" last-rc-change="1597616559" last-run="1597616559" exec-time="617" queue-time="0" op-digest="3d4af69481cb01c8c8f0f8af95940b99" op-secure-params=" password  passwd " op-secure-digest="fd2959d25b0a20f6d1bc630f7565fd78"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_mk-pdu02" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_mk-pdu02_last_0" operation_key="apc_snmp_node2_mk-pdu02_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;6:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="25" rc-code="7" op-status="0" interval="0" last-rc-change="1597616557" last-run="1597616557" exec-time="0" queue-time="0" op-digest="7787bf20740a07e14145707988b18000" op-secure-params=" password  passwd " op-secure-digest="11d1e757682ff46234d9816e06534953"/>
          </lrm_resource>
          <lrm_resource id="srv07-el6" type="server" class="ocf" provider="alteeve">
            <lrm_rsc_op id="srv07-el6_last_0" operation_key="srv07-el6_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" transition-magic="0:7;7:0:7:fd70072a-cb46-4085-89db-f7c0073f77ce" exit-reason="" on_node="mk-a02n01" call-id="29" rc-code="7" op-status="0" interval="0" last-rc-change="1597616559" last-run="1597616559" exec-time="541" queue-time="0" op-digest="41dcb3443c331f2fe7ae92962905159f"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>
';

$anvil->Cluster->parse_cib({
	debug => 2,
	#cib   => $xml,
});

print "Cluster is in maintenance mode? [".$anvil->data->{cib}{parsed}{data}{cluster}{'maintenance-mode'}."]\n";
