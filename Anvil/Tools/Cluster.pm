package Anvil::Tools::Cluster;
# 
# This module contains methods related to Pacemaker/pcs and clustering functions in general.
# 

use strict;
use warnings;
use Data::Dumper;
use XML::Simple qw(:strict);
use XML::LibXML;
use Scalar::Util qw(weaken isweak);

our $VERSION  = "3.0.0";
my $THIS_FILE = "Cluster.pm";

### Methods;
# parse_cib

=pod

=encoding utf8

=head1 NAME

Anvil::Tools::Cluster

Provides all methods related to clustering specifically (pacemaker, pcs, etc).

=head1 SYNOPSIS

 use Anvil::Tools;

 # Get a common object handle on all Anvil::Tools modules.
 my $anvil = Anvil::Tools->new();
 
 # Access to methods using '$anvil->Cluster->X'. 
 # 

=head1 METHODS

Methods in this module;

=cut
sub new
{
	my $class = shift;
	my $self  = {};
	
	bless $self, $class;
	
	return ($self);
}

# Get a handle on the Anvil::Tools object. I know that technically that is a sibling module, but it makes more 
# sense in this case to think of it as a parent.
sub parent
{
	my $self   = shift;
	my $parent = shift;
	
	$self->{HANDLE}{TOOLS} = $parent if $parent;
	
	# Defend against memory leads. See Scalar::Util'.
	if (not isweak($self->{HANDLE}{TOOLS}))
	{
		weaken($self->{HANDLE}{TOOLS});
	}
	
	return ($self->{HANDLE}{TOOLS});
}


#############################################################################################################
# Public methods                                                                                            #
#############################################################################################################

=head2 parse_cib

This reads in the CIB XML and parses it. On success, it returns C<< 0 >>. On failure (ie: pcsd isn't running), returns C<< 1 >>.

=cut
sub parse_cib
{
	my $self      = shift;
	my $parameter = shift;
	my $anvil     = $self->parent;
	my $debug     = defined $parameter->{debug} ? $parameter->{debug} : 3;
	$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "log_0125", variables => { method => "Cluster->parse_cib()" }});
	
	# If we parsed before, delete it.
	if (exists $anvil->data->{cib}{parsed})
	{
		delete $anvil->data->{cib}{parsed};
	}
	
	my $problem    = 1;
	my $shell_call = $anvil->data->{path}{exe}{pcs}." cluster cib";
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { shell_call => $shell_call }});
	
	my ($cib_data, $return_code) = $anvil->System->call({debug => 3, shell_call => $shell_call});
	$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
		cib_data    => $cib_data,
		return_code => $return_code, 
	}});
	if ($return_code)
	{
		# Failed to read the CIB.
		$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0052"});
	}
	else
	{
		my $dom = eval { XML::LibXML->load_xml(string => $cib_data); };
		if ($@)
		{
			$anvil->Log->entry({source => $THIS_FILE, line => __LINE__, level => $debug, key => "warning_0053", variables => { 
				cib   => $cib_data,
				error => $@,
			}});
		}
		else
		{
			# Successful parse!
=cut
<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="5" num_updates="0" admin_epoch="0" cib-last-written="Fri Jul 10 19:51:41 2020" update-origin="el8-a01n01" update-client="crmd" update-user="hacluster" have-quorum="1">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="el8-anvil-01"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="el8-a01n01"/>
      <node id="2" uname="el8-a01n02"/>
    </nodes>
    <resources/>
    <constraints/>
  </configuration>
  <status/>
</cib>

==================

<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="5" num_updates="4" admin_epoch="0" cib-last-written="Fri Jul 10 17:35:48 2020" update-origin="el8-a01n01" update-client="crmd" update-user="hacluster" have-quorum="1" dc-uuid="2">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="el8-anvil-01"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="el8-a01n01"/>
      <node id="2" uname="el8-a01n02"/>
    </nodes>
    <resources/>
    <constraints/>
  </configuration>
  <status>
    <node_state id="2" uname="el8-a01n02" in_ccm="true" crmd="online" crm-debug-origin="do_state_transition" join="member" expected="member">
      <lrm id="2">
        <lrm_resources/>
      </lrm>
    </node_state>
    <node_state id="1" uname="el8-a01n01" in_ccm="true" crmd="online" crm-debug-origin="do_state_transition" join="member" expected="member">
      <lrm id="1">
        <lrm_resources/>
      </lrm>
    </node_state>
  </status>
</cib>

================== First fence

<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="6" num_updates="8" admin_epoch="0" cib-last-written="Sat Jul 11 04:49:06 2020" update-origin="el8-a01n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="1">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="el8-anvil-01"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="el8-a01n01"/>
      <node id="2" uname="el8-a01n02"/>
    </nodes>
    <resources>
      <primitive class="stonith" id="virsh_node1" type="fence_virsh">
        <instance_attributes id="virsh_node1-instance_attributes">
          <nvpair id="virsh_node1-instance_attributes-delay" name="delay" value="15"/>
          <nvpair id="virsh_node1-instance_attributes-ipaddr" name="ipaddr" value="192.168.122.1"/>
          <nvpair id="virsh_node1-instance_attributes-login" name="login" value="root"/>
          <nvpair id="virsh_node1-instance_attributes-passwd" name="passwd" value="high generous distance"/>
          <nvpair id="virsh_node1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="el8-a01n01"/>
          <nvpair id="virsh_node1-instance_attributes-port" name="port" value="el8-a01n01"/>
        </instance_attributes>
        <operations>
          <op id="virsh_node1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
    </resources>
    <constraints/>
  </configuration>
  <status>
    <node_state id="1" uname="el8-a01n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="virsh_node1" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node1_last_0" operation_key="virsh_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="3:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;3:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="6" rc-code="0" op-status="0" interval="0" last-rc-change="1594442946" last-run="1594442946" exec-time="737" queue-time="0" op-digest="608a523c27162c0c4648550326dd1b26" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
            <lrm_rsc_op id="virsh_node1_monitor_60000" operation_key="virsh_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;4:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="7" rc-code="0" op-status="0" interval="60000" last-rc-change="1594442947" exec-time="614" queue-time="0" op-digest="5be687ff1e141e610106215889894545" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="2" uname="el8-a01n02" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="2">
        <lrm_resources>
          <lrm_resource id="virsh_node1" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node1_last_0" operation_key="virsh_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:4:7:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:7;2:4:7:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1594442946" last-run="1594442946" exec-time="3" queue-time="0" op-digest="608a523c27162c0c4648550326dd1b26" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>

================== Second fence

<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="7" num_updates="8" admin_epoch="0" cib-last-written="Sat Jul 11 04:55:41 2020" update-origin="el8-a01n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="1">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="el8-anvil-01"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="el8-a01n01"/>
      <node id="2" uname="el8-a01n02"/>
    </nodes>
    <resources>
      <primitive class="stonith" id="virsh_node1" type="fence_virsh">
        <instance_attributes id="virsh_node1-instance_attributes">
          <nvpair id="virsh_node1-instance_attributes-delay" name="delay" value="15"/>
          <nvpair id="virsh_node1-instance_attributes-ipaddr" name="ipaddr" value="192.168.122.1"/>
          <nvpair id="virsh_node1-instance_attributes-login" name="login" value="root"/>
          <nvpair id="virsh_node1-instance_attributes-passwd" name="passwd" value="high generous distance"/>
          <nvpair id="virsh_node1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="el8-a01n01"/>
          <nvpair id="virsh_node1-instance_attributes-port" name="port" value="el8-a01n01"/>
        </instance_attributes>
        <operations>
          <op id="virsh_node1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="virsh_node2" type="fence_virsh">
        <instance_attributes id="virsh_node2-instance_attributes">
          <nvpair id="virsh_node2-instance_attributes-ipaddr" name="ipaddr" value="192.168.122.1"/>
          <nvpair id="virsh_node2-instance_attributes-login" name="login" value="root"/>
          <nvpair id="virsh_node2-instance_attributes-passwd" name="passwd" value="high generous distance"/>
          <nvpair id="virsh_node2-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="el8-a01n02"/>
          <nvpair id="virsh_node2-instance_attributes-port" name="port" value="el8-a01n02"/>
        </instance_attributes>
        <operations>
          <op id="virsh_node2-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
    </resources>
    <constraints/>
  </configuration>
  <status>
    <node_state id="1" uname="el8-a01n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="virsh_node1" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node1_last_0" operation_key="virsh_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="3:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;3:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="6" rc-code="0" op-status="0" interval="0" last-rc-change="1594442946" last-run="1594442946" exec-time="737" queue-time="0" op-digest="608a523c27162c0c4648550326dd1b26" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
            <lrm_rsc_op id="virsh_node1_monitor_60000" operation_key="virsh_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;4:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="7" rc-code="0" op-status="0" interval="60000" last-rc-change="1594442947" exec-time="614" queue-time="0" op-digest="5be687ff1e141e610106215889894545" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
          </lrm_resource>
          <lrm_resource id="virsh_node2" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node2_last_0" operation_key="virsh_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:5:7:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:7;2:5:7:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="11" rc-code="7" op-status="0" interval="0" last-rc-change="1594443341" last-run="1594443341" exec-time="0" queue-time="0" op-digest="e545a3390de0c9d2624ef4cac775b9c9" op-secure-params=" password  passwd " op-secure-digest="8065dc4867c73abfb780e52db7525148"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="2" uname="el8-a01n02" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="2">
        <lrm_resources>
          <lrm_resource id="virsh_node1" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node1_last_0" operation_key="virsh_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:4:7:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:7;2:4:7:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1594442946" last-run="1594442946" exec-time="3" queue-time="0" op-digest="608a523c27162c0c4648550326dd1b26" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
          </lrm_resource>
          <lrm_resource id="virsh_node2" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node2_last_0" operation_key="virsh_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;6:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="10" rc-code="0" op-status="0" interval="0" last-rc-change="1594443341" last-run="1594443341" exec-time="992" queue-time="0" op-digest="e545a3390de0c9d2624ef4cac775b9c9" op-secure-params=" password  passwd " op-secure-digest="8065dc4867c73abfb780e52db7525148"/>
            <lrm_rsc_op id="virsh_node2_monitor_60000" operation_key="virsh_node2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;7:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="11" rc-code="0" op-status="0" interval="60000" last-rc-change="1594443342" exec-time="763" queue-time="1" op-digest="73223e8083cc6447a379293b74bbab9d" op-secure-params=" password  passwd " op-secure-digest="8065dc4867c73abfb780e52db7525148"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>

================ Enable stonith

<cib crm_feature_set="3.3.0" validate-with="pacemaker-3.2" epoch="8" num_updates="0" admin_epoch="0" cib-last-written="Sat Jul 11 04:57:22 2020" update-origin="el8-a01n01" update-client="cibadmin" update-user="root" have-quorum="1" dc-uuid="1">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-bootstrap-options">
        <nvpair id="cib-bootstrap-options-have-watchdog" name="have-watchdog" value="false"/>
        <nvpair id="cib-bootstrap-options-dc-version" name="dc-version" value="2.0.3-5.el8_2.1-4b1f869f0f"/>
        <nvpair id="cib-bootstrap-options-cluster-infrastructure" name="cluster-infrastructure" value="corosync"/>
        <nvpair id="cib-bootstrap-options-cluster-name" name="cluster-name" value="el8-anvil-01"/>
        <nvpair id="cib-bootstrap-options-stonith-enabled" name="stonith-enabled" value="true"/>
      </cluster_property_set>
    </crm_config>
    <nodes>
      <node id="1" uname="el8-a01n01"/>
      <node id="2" uname="el8-a01n02"/>
    </nodes>
    <resources>
      <primitive class="stonith" id="virsh_node1" type="fence_virsh">
        <instance_attributes id="virsh_node1-instance_attributes">
          <nvpair id="virsh_node1-instance_attributes-delay" name="delay" value="15"/>
          <nvpair id="virsh_node1-instance_attributes-ipaddr" name="ipaddr" value="192.168.122.1"/>
          <nvpair id="virsh_node1-instance_attributes-login" name="login" value="root"/>
          <nvpair id="virsh_node1-instance_attributes-passwd" name="passwd" value="high generous distance"/>
          <nvpair id="virsh_node1-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="el8-a01n01"/>
          <nvpair id="virsh_node1-instance_attributes-port" name="port" value="el8-a01n01"/>
        </instance_attributes>
        <operations>
          <op id="virsh_node1-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
      <primitive class="stonith" id="virsh_node2" type="fence_virsh">
        <instance_attributes id="virsh_node2-instance_attributes">
          <nvpair id="virsh_node2-instance_attributes-ipaddr" name="ipaddr" value="192.168.122.1"/>
          <nvpair id="virsh_node2-instance_attributes-login" name="login" value="root"/>
          <nvpair id="virsh_node2-instance_attributes-passwd" name="passwd" value="high generous distance"/>
          <nvpair id="virsh_node2-instance_attributes-pcmk_host_list" name="pcmk_host_list" value="el8-a01n02"/>
          <nvpair id="virsh_node2-instance_attributes-port" name="port" value="el8-a01n02"/>
        </instance_attributes>
        <operations>
          <op id="virsh_node2-monitor-interval-60" interval="60" name="monitor"/>
        </operations>
      </primitive>
    </resources>
    <constraints/>
  </configuration>
  <status>
    <node_state id="1" uname="el8-a01n01" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="1">
        <lrm_resources>
          <lrm_resource id="virsh_node1" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node1_last_0" operation_key="virsh_node1_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="3:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;3:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="6" rc-code="0" op-status="0" interval="0" last-rc-change="1594442946" last-run="1594442946" exec-time="737" queue-time="0" op-digest="608a523c27162c0c4648550326dd1b26" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
            <lrm_rsc_op id="virsh_node1_monitor_60000" operation_key="virsh_node1_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="4:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;4:4:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="7" rc-code="0" op-status="0" interval="60000" last-rc-change="1594442947" exec-time="614" queue-time="0" op-digest="5be687ff1e141e610106215889894545" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
          </lrm_resource>
          <lrm_resource id="virsh_node2" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node2_last_0" operation_key="virsh_node2_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:5:7:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:7;2:5:7:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n01" call-id="11" rc-code="7" op-status="0" interval="0" last-rc-change="1594443341" last-run="1594443341" exec-time="0" queue-time="0" op-digest="e545a3390de0c9d2624ef4cac775b9c9" op-secure-params=" password  passwd " op-secure-digest="8065dc4867c73abfb780e52db7525148"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
    <node_state id="2" uname="el8-a01n02" in_ccm="true" crmd="online" crm-debug-origin="do_update_resource" join="member" expected="member">
      <lrm id="2">
        <lrm_resources>
          <lrm_resource id="virsh_node1" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node1_last_0" operation_key="virsh_node1_monitor_0" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="2:4:7:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:7;2:4:7:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="5" rc-code="7" op-status="0" interval="0" last-rc-change="1594442946" last-run="1594442946" exec-time="3" queue-time="0" op-digest="608a523c27162c0c4648550326dd1b26" op-secure-params=" password  passwd " op-secure-digest="56bdf46bebc74266a3efb03c61e05c7d"/>
          </lrm_resource>
          <lrm_resource id="virsh_node2" type="fence_virsh" class="stonith">
            <lrm_rsc_op id="virsh_node2_last_0" operation_key="virsh_node2_start_0" operation="start" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="6:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;6:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="10" rc-code="0" op-status="0" interval="0" last-rc-change="1594443341" last-run="1594443341" exec-time="992" queue-time="0" op-digest="e545a3390de0c9d2624ef4cac775b9c9" op-secure-params=" password  passwd " op-secure-digest="8065dc4867c73abfb780e52db7525148"/>
            <lrm_rsc_op id="virsh_node2_monitor_60000" operation_key="virsh_node2_monitor_60000" operation="monitor" crm-debug-origin="do_update_resource" crm_feature_set="3.3.0" transition-key="7:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" transition-magic="0:0;7:5:0:b6d5caa1-2120-49f4-a534-29b724e74161" exit-reason="" on_node="el8-a01n02" call-id="11" rc-code="0" op-status="0" interval="60000" last-rc-change="1594443342" exec-time="763" queue-time="1" op-digest="73223e8083cc6447a379293b74bbab9d" op-secure-params=" password  passwd " op-secure-digest="8065dc4867c73abfb780e52db7525148"/>
          </lrm_resource>
        </lrm_resources>
      </lrm>
    </node_state>
  </status>
</cib>

=cut
			$problem = 0;
			$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { problem => $problem }});
			foreach my $primitive ($dom->findnodes('/cib/configuration/resources/primitive'))
			{
				my $class                                                                    = $primitive->{class};
				my $id                                                                       = $primitive->{id};
				my $type                                                                     = $primitive->{type};
				   $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{type} = $type;
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::cib::resources::primitive:${class}::${id}::type" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{type}, 
				}});
				foreach my $nvpair ($primitive->findnodes('./instance_attributes/nvpair'))
				{
					my $name = $nvpair->{name};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "name";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{instance_attributes}{$name}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
							"cib::parsed::cib::resources::primitive::${class}::${id}::instance_attributes::${name}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{instance_attributes}{$name}{$variable}, 
						}});
					}
				}
				foreach my $nvpair ($primitive->findnodes('./operations/op'))
				{
					my $id = $nvpair->{id};
					foreach my $variable (sort {$a cmp $b} keys %{$nvpair})
					{
						next if $variable eq "id";
						$anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{operations}{op}{$id}{$variable} = $nvpair->{$variable};;
						$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
							"cib::parsed::cib::resources::primitive::${class}::${id}::operations::op::${id}::${variable}" => $anvil->data->{cib}{parsed}{cib}{resources}{primitive}{$class}{$id}{operations}{op}{$id}{$variable}, 
						}});
					}
				}
			}
			die;
			foreach my $attribute ($dom->findnodes('/cib'))
			{
				foreach my $variable (sort {$a cmp $b} keys %{$attribute})
				{
					$anvil->data->{cib}{parsed}{cib}{$variable} = $attribute->{$variable};
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::cib::${variable}" => $anvil->data->{cib}{parsed}{cib}{$variable}, 
					}});
				}
			}
			foreach my $nvpair ($dom->findnodes('/cib/configuration/crm_config/cluster_property_set/nvpair'))
			{
				my $name                                                                                              = $nvpair->{name};
				   $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{id}    = $nvpair->{id};
				   $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{value} = $nvpair->{value};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::configuration::crm_config::cluster_property_set::nvpair::${name}::id"    => $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{id}, 
					"cib::parsed::configuration::crm_config::cluster_property_set::nvpair::${name}::value" => $anvil->data->{cib}{parsed}{configuration}{crm_config}{cluster_property_set}{nvpair}{$name}{value}, 
				}});
			}
			foreach my $node ($dom->findnodes('/cib/configuration/nodes/node'))
			{
				my $uname                                                        = $node->{uname};
				   $anvil->data->{cib}{parsed}{configuration}{nodes}{$uname}{id} = $node->{id};
				$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
					"cib::parsed::configuration::nodes::${uname}::id" => $anvil->data->{cib}{parsed}{configuration}{nodes}{$uname}{id}, 
				}});
			}
			# Status isn't available until the cluster has been up for a bit.
			foreach my $node_state ($dom->findnodes('/cib/status/node_state'))
			{
				my $uname = $node_state->{uname};
				foreach my $variable (sort {$a cmp $b} keys %{$node_state})
				{
					next if $variable eq "uname";
					$anvil->data->{cib}{parsed}{cib}{node_state}{$uname}{$variable} = $node_state->{$variable};;
					$anvil->Log->variables({source => $THIS_FILE, line => __LINE__, level  => $debug, list => { 
						"cib::parsed::cib::node_state::${uname}::${variable}" => $anvil->data->{cib}{parsed}{cib}{node_state}{$uname}{$variable}, 
					}});
				}
			}
		}
	}
	
	#print Dumper $anvil->data->{cib}{parsed};
	
	return($problem);
}

# =head3
# 
# Private Functions;
# 
# =cut

#############################################################################################################
# Private functions                                                                                         #
#############################################################################################################
