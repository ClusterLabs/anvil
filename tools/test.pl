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

my $xml = '<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="28" num_updates="0" admin_epoch="0" cib-last-written="Wed Jul 29 23:45:47 2020" update-origin="mk-a02n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="2">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="mk-anvil-02"/>
        <nvpair id="cib-bootstrap-options-stonith-max-attempts" name="stonith-max-attempts" value="INFINITY"/>
        <nvpair id="cib-bootstrap-options-stonith-enabled" name="stonith-enabled" value="true"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="mk-a02n01"/>
      <node id="2" uname="mk-a02n02"/>
    </nodes>
    <resources>
      <primitive class="stonith" id="ipmilan_node1" type="fence_ipmilan">
        <instance_attributes id="ipmilan_node1-instance_attributes">
          <nvpair id="ipmilan_node1-instance_attributes-delay" name="delay" value="15"/>
          <nvpair id="ipmilan_node1-instance_attributes-ipaddr" name="ipaddr" value="10.201.13.1"/>
          <nvpair id="ipmilan_node1-instance_attributes-password" name="password" value="another secret p"/>
          <nvpair id="ipmilan_node1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="ipmilan_node1-instance_attributes-username" name="username" value="admin"/>
        </instance_attributes>
        <operations>
          <op id="ipmilan_node1-monitor-interval-60" interval="60" name="monitor"/>
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
      <primitive class="stonith" id="apc_snmp_node1_psu1" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node1_psu1-instance_attributes">
          <nvpair id="apc_snmp_node1_psu1-instance_attributes-ip" name="ip" value="10.201.2.3"/>
          <nvpair id="apc_snmp_node1_psu1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="apc_snmp_node1_psu1-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node1_psu1-instance_attributes-port" name="port" value="3"/>
          <nvpair id="apc_snmp_node1_psu1-instance_attributes-power_wait" name="power_wait" value="5"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node1_psu1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node1_psu2" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node1_psu2-instance_attributes">
          <nvpair id="apc_snmp_node1_psu2-instance_attributes-ip" name="ip" value="10.201.2.4"/>
          <nvpair id="apc_snmp_node1_psu2-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="apc_snmp_node1_psu2-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node1_psu2-instance_attributes-port" name="port" value="3"/>
          <nvpair id="apc_snmp_node1_psu2-instance_attributes-power_wait" name="power_wait" value="5"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node1_psu2-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node2_psu1" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node2_psu1-instance_attributes">
          <nvpair id="apc_snmp_node2_psu1-instance_attributes-ip" name="ip" value="10.201.2.3"/>
          <nvpair id="apc_snmp_node2_psu1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n02"/>
          <nvpair id="apc_snmp_node2_psu1-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node2_psu1-instance_attributes-port" name="port" value="4"/>
          <nvpair id="apc_snmp_node2_psu1-instance_attributes-power_wait" name="power_wait" value="5"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node2_psu1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="apc_snmp_node2_psu2" type="fence_apc_snmp">
        <instance_attributes id="apc_snmp_node2_psu2-instance_attributes">
          <nvpair id="apc_snmp_node2_psu2-instance_attributes-ip" name="ip" value="10.201.2.4"/>
          <nvpair id="apc_snmp_node2_psu2-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n02"/>
          <nvpair id="apc_snmp_node2_psu2-instance_attributes-pcmk_off_action" name="pcmk_off_action" value="reboot"/>
          <nvpair id="apc_snmp_node2_psu2-instance_attributes-port" name="port" value="4"/>
          <nvpair id="apc_snmp_node2_psu2-instance_attributes-power_wait" name="power_wait" value="5"/>
        </instance_attributes>
        <operations>
          <op id="apc_snmp_node2_psu2-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="delay_node1" type="fence_delay">
        <instance_attributes id="delay_node1-instance_attributes">
          <nvpair id="delay_node1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n01"/>
          <nvpair id="delay_node1-instance_attributes-wait" name="wait" value="60"/>
        </instance_attributes>
        <operations>
          <op id="delay_node1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="delay_node2" type="fence_delay">
        <instance_attributes id="delay_node2-instance_attributes">
          <nvpair id="delay_node2-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="mk-a02n02"/>
          <nvpair id="delay_node2-instance_attributes-wait" name="wait" value="60"/>
        </instance_attributes>
        <operations>
          <op id="delay_node2-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
    </resources>
    <constraints/>
    <fencing-topology>
      <fencing-level devices="ipmilan_node1" id="fl-mk-a02n01-1" index="1" target="mk-a02n01"/>
      <fencing-level devices="ipmilan_node2" id="fl-mk-a02n02-1" index="1" target="mk-a02n02"/>
      <fencing-level devices="apc_snmp_node1_psu1,apc_snmp_node1_psu2" id="fl-mk-a02n01-2" index="2" target="mk-a02n01"/>
      <fencing-level devices="apc_snmp_node2_psu1,apc_snmp_node2_psu2" id="fl-mk-a02n02-2" index="2" target="mk-a02n02"/>
      <fencing-level devices="delay_node1" id="fl-mk-a02n01-3" index="3" target="mk-a02n01"/>
      <fencing-level devices="delay_node2" id="fl-mk-a02n02-3" index="3" target="mk-a02n02"/>
    </fencing-topology>
  </configuration>
  <status>
    <node_state id="2" uname="mk-a02n02" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="2">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;7:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1596077508" last-run="1596077508" exec-time="2" queue-time="0" op-digest="94ccc3ba507c38b16a5ab5adad892afe" op-secure-params=" password  passwd " op-secure-digest="30aa995f9bd3385e535d0a45b5b673c7"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="15:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;15:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="26" rc-code="0" op-status="0" interval="0" last-rc-change="1596077508" last-run="1596077508" exec-time="87" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
            <lrm_rsc_op id="ipmilan_node2_monitor_60000" operation_key="ipmilan_node2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="16:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;16:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="29" rc-code="0" op-status="0" interval="60000" last-rc-change="1596077509" exec-time="87" queue-time="0" op-digest="467ef5117cbb737e5c6fc23b58809791" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_psu1" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_psu1_last_0" operation_key="apc_snmp_node1_psu1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="9:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;9:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="13" rc-code="7" op-status="0" interval="0" last-rc-change="1596077508" last-run="1596077508" exec-time="0" queue-time="0" op-digest="bf350e059a2283cb416a705205fcef98" op-secure-params=" password  passwd " op-secure-digest="91abc2f7f37dfdd5f531054a74a66ced"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_psu2" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_psu2_last_0" operation_key="apc_snmp_node1_psu2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="19:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;19:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="27" rc-code="0" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="809" queue-time="0" op-digest="7ff7ebe3c6b94ef30b8074ffb385cacb" op-secure-params=" password  passwd " op-secure-digest="a3c98981d6a0382ece4146587d008b5c"/>
            <lrm_rsc_op id="apc_snmp_node1_psu2_monitor_60000" operation_key="apc_snmp_node1_psu2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="20:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;20:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="31" rc-code="0" op-status="0" interval="60000" last-rc-change="1596077509" exec-time="775" queue-time="0" op-digest="534f24f08deb08c3f65872f2139ebf6b" op-secure-params=" password  passwd " op-secure-digest="a3c98981d6a0382ece4146587d008b5c"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_psu1" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_psu1_last_0" operation_key="apc_snmp_node2_psu1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="11:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;11:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="21" rc-code="7" op-status="0" interval="0" last-rc-change="1596077508" last-run="1596077508" exec-time="0" queue-time="0" op-digest="e4739b474ee5043eaf7233ee12ee51d3" op-secure-params=" password  passwd " op-secure-digest="3f31fc0be92206a110435411ffb3caf8"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_psu2" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_psu2_last_0" operation_key="apc_snmp_node2_psu2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="23:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;23:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="28" rc-code="0" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="782" queue-time="0" op-digest="f3b985aa75b8f5fa0df015dc0b03b1f1" op-secure-params=" password  passwd " op-secure-digest="26e92809fff4cf6b4cd47ff641d8276a"/>
            <lrm_rsc_op id="apc_snmp_node2_psu2_monitor_60000" operation_key="apc_snmp_node2_psu2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="24:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;24:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="30" rc-code="0" op-status="0" interval="60000" last-rc-change="1596077509" exec-time="745" queue-time="0" op-digest="0e4b4767fac04c243d40c582eb192994" op-secure-params=" password  passwd " op-secure-digest="26e92809fff4cf6b4cd47ff641d8276a"/>
          </lrm_resource>
          <lrm_resource id="delay_node1" type="fence_delay" class="stonith">
            <lrm_rsc_op id="delay_node1_last_0" operation_key="delay_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="8:13:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;8:13:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="45" rc-code="7" op-status="0" interval="0" last-rc-change="1596080690" last-run="1596080690" exec-time="0" queue-time="0" op-digest="cc9e9045724a0f58a4c1e20e87fc27e0"/>
          </lrm_resource>
          <lrm_resource id="delay_node2" type="fence_delay" class="stonith">
            <lrm_rsc_op id="delay_node2_last_0" operation_key="delay_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="24:14:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;24:14:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="50" rc-code="0" op-status="0" interval="0" last-rc-change="1596080694" last-run="1596080694" exec-time="16" queue-time="0" op-digest="3c18f0bcefeff3c4b79dda97eed85b65"/>
            <lrm_rsc_op id="delay_node2_monitor_60000" operation_key="delay_node2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="25:14:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;25:14:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n02" call-id="51" rc-code="0" op-status="0" interval="60000" last-rc-change="1596080694" exec-time="16" queue-time="0" op-digest="28ef7d9656d3e7ad95f689543241ecf8"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="1" uname="mk-a02n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="ipmilan_node1" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node1_last_0" operation_key="ipmilan_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="13:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;13:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="26" rc-code="0" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="93" queue-time="0" op-digest="94ccc3ba507c38b16a5ab5adad892afe" op-secure-params=" password  passwd " op-secure-digest="30aa995f9bd3385e535d0a45b5b673c7"/>
            <lrm_rsc_op id="ipmilan_node1_monitor_60000" operation_key="ipmilan_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="14:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;14:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="29" rc-code="0" op-status="0" interval="60000" last-rc-change="1596077509" exec-time="84" queue-time="0" op-digest="8010b53c30280214d0b61d74406e67ec" op-secure-params=" password  passwd " op-secure-digest="30aa995f9bd3385e535d0a45b5b673c7"/>
          </lrm_resource>
          <lrm_resource id="ipmilan_node2" type="fence_ipmilan" class="stonith">
            <lrm_rsc_op id="ipmilan_node2_last_0" operation_key="ipmilan_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;2:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="9" rc-code="7" op-status="0" interval="0" last-rc-change="1596077508" last-run="1596077508" exec-time="0" queue-time="0" op-digest="e759a456df902485096d4a48725ed81c" op-secure-params=" password  passwd " op-secure-digest="47989163387c397e63fa3acdbec0d274"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_psu1" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_psu1_last_0" operation_key="apc_snmp_node1_psu1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="17:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;17:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="27" rc-code="0" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="783" queue-time="0" op-digest="bf350e059a2283cb416a705205fcef98" op-secure-params=" password  passwd " op-secure-digest="91abc2f7f37dfdd5f531054a74a66ced"/>
            <lrm_rsc_op id="apc_snmp_node1_psu1_monitor_60000" operation_key="apc_snmp_node1_psu1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="18:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;18:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="30" rc-code="0" op-status="0" interval="60000" last-rc-change="1596077509" exec-time="729" queue-time="0" op-digest="baa323cdbcb6e29b8e4ab11e6ec3829a" op-secure-params=" password  passwd " op-secure-digest="91abc2f7f37dfdd5f531054a74a66ced"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node1_psu2" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node1_psu2_last_0" operation_key="apc_snmp_node1_psu2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;4:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="17" rc-code="7" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="0" queue-time="0" op-digest="7ff7ebe3c6b94ef30b8074ffb385cacb" op-secure-params=" password  passwd " op-secure-digest="a3c98981d6a0382ece4146587d008b5c"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_psu1" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_psu1_last_0" operation_key="apc_snmp_node2_psu1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;21:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="28" rc-code="0" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="808" queue-time="0" op-digest="e4739b474ee5043eaf7233ee12ee51d3" op-secure-params=" password  passwd " op-secure-digest="3f31fc0be92206a110435411ffb3caf8"/>
            <lrm_rsc_op id="apc_snmp_node2_psu1_monitor_60000" operation_key="apc_snmp_node2_psu1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="22:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;22:0:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="31" rc-code="0" op-status="0" interval="60000" last-rc-change="1596077509" exec-time="766" queue-time="0" op-digest="69497c1e46db98fb718209f7a6a06515" op-secure-params=" password  passwd " op-secure-digest="3f31fc0be92206a110435411ffb3caf8"/>
          </lrm_resource>
          <lrm_resource id="apc_snmp_node2_psu2" type="fence_apc_snmp" class="stonith">
            <lrm_rsc_op id="apc_snmp_node2_psu2_last_0" operation_key="apc_snmp_node2_psu2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;6:0:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="25" rc-code="7" op-status="0" interval="0" last-rc-change="1596077509" last-run="1596077509" exec-time="0" queue-time="0" op-digest="f3b985aa75b8f5fa0df015dc0b03b1f1" op-secure-params=" password  passwd " op-secure-digest="26e92809fff4cf6b4cd47ff641d8276a"/>
          </lrm_resource>
          <lrm_resource id="delay_node1" type="fence_delay" class="stonith">
            <lrm_rsc_op id="delay_node1_last_0" operation_key="delay_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="21:13:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;21:13:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="54" rc-code="0" op-status="0" interval="0" last-rc-change="1596080690" last-run="1596080690" exec-time="16" queue-time="0" op-digest="cc9e9045724a0f58a4c1e20e87fc27e0"/>
            <lrm_rsc_op id="delay_node1_monitor_60000" operation_key="delay_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="22:13:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:0;22:13:0:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="55" rc-code="0" op-status="0" interval="60000" last-rc-change="1596080690" exec-time="15" queue-time="0" op-digest="76803906e86431fd72b35b182101783d"/>
          </lrm_resource>
          <lrm_resource id="delay_node2" type="fence_delay" class="stonith">
            <lrm_rsc_op id="delay_node2_last_0" operation_key="delay_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="8:14:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" transition-magic="0:7;8:14:7:b04a8d49-a133-4cd6-9d7e-6feeb76c5dcf" exit-reason="" on_node="mk-a02n01" call-id="59" rc-code="7" op-status="0" interval="0" last-rc-change="1596080694" last-run="1596080694" exec-time="0" queue-time="0" op-digest="3c18f0bcefeff3c4b79dda97eed85b65"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>
';

$anvil->Cluster->parse_cib({
	debug => 2,
	cib   => $xml,
});
