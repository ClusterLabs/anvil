interface AnvilDataStruct {
  [key: string]: AnvilDataStruct | boolean;
}

type AnvilDataAnvilListHash = {
  anvil_uuid: {
    [uuid: string]: {
      anvil_description: string;
      anvil_dr1_host_uuid?: string;
      anvil_name: string;
      anvil_node1_host_uuid: string;
      anvil_node2_host_uuid: string;
      modified_date: string;
    };
  };
  host_uuid: {
    [uuid: string]: {
      anvil_name: string;
      anvil_uuid: string;
      role: string;
    };
  };
};

type AnvilDataDatabaseHash = {
  [hostUUID: string]: {
    host: string;
    name?: string;
    password: string;
    ping: string;
    port: string;
    user?: string;
  };
};

type AnvilDataFenceParameterType =
  | 'boolean'
  | 'integer'
  | 'second'
  | 'select'
  | 'string';

type AnvilDataFenceHash = {
  [agent: string]: {
    actions: string[];
    description: string;
    parameters: {
      [parameterId: string]: {
        content_type: AnvilDataFenceParameterType;
        default?: string;
        deprecated: number;
        description: string;
        obsoletes: number;
        options?: string[];
        replacement: string;
        required: '0' | '1';
        switches: string;
        unique: '0' | '1';
      };
    };
    switch: {
      [switchId: string]: { name: string };
    };
    symlink?: { [agent: string]: string };
  };
};

type AnvilDataHostListHash = {
  host_uuid: {
    [hostUuid: string]: {
      anvil_name?: string;
      anvil_uuid?: string;
      host_ipmi: string;
      host_key: string;
      host_name: string;
      host_status: string;
      host_type: string;
      short_host_name: string;
    };
  };
};

type AnvilDataHostNetworkBond = {
  active_interface: string;
  bridge_uuid: string;
  down_delay: number;
  interfaces: string[];
  mac_address: string;
  mii_polling_interval: number;
  mode: string;
  mtu: number;
  operational: 'up' | 'down';
  primary_interface: string;
  primary_reselect: string;
  type: 'bond';
  up_delay: number;
  uuid: string;
};

type AnvilDataHostNetworkBridge = {
  id: string;
  interfaces: string[];
  mac_address: string;
  mtu: number;
  stp_enabled: string;
  type: 'bridge';
  uuid: string;
};

type AnvilDataHostNetworkLink = {
  bond_name: string;
  bond_uuid: string;
  bridge_name: string;
  bridge_uuid: string;
  changed_order: number;
  duplex: string;
  link_state: string;
  mac_address: string;
  medium: string;
  mtu: number;
  operational: 'up' | 'down';
  speed: number;
  type: 'interface';
  uuid: string;
};

type AnvilDataHostNetworkPrimaryLink = AnvilDataHostNetworkLink & {
  default_gateway: NumberBoolean;
  dns: string;
  gateway: string;
  ip: string;
  network_interface_uuid: string;
  subnet_mask: string;
};

type AnvilDataLvmHostLv = {
  scan_lvm_lv_uuid: string;
  scan_lvm_lv_attributes: string;
  scan_lvm_lv_path: string;
  scan_lvm_lv_size: string;
  scan_lvm_lv_on_vg: string;
  scan_lvm_lv_internal_uuid: string;
  scan_lvm_lv_on_pvs: string;
};

type AnvilDataLvmHostPv = {
  scan_lvm_pv_sector_size: string;
  scan_lvm_pv_used_by_vg: string;
  scan_lvm_pv_internal_uuid: string;
  scan_lvm_pv_free: string;
  scan_lvm_pv_attributes: string;
  scan_lvm_pv_uuid: string;
  scan_lvm_pv_size: string;
};

type AnvilDataLvmHostVg = {
  storage_group_uuid: string;
  scan_lvm_vg_internal_uuid: string;
  scan_lvm_vg_extent_size: string;
  scan_lvm_vg_size: string;
  scan_lvm_vg_free: string;
  scan_lvm_vg_attributes: string;
  scan_lvm_vg_uuid: string;
};

type AnvilDataLvmHost = {
  lv: Record<string, AnvilDataLvmHostLv>;
  pv: Record<string, AnvilDataLvmHostPv>;
  vg: Record<string, AnvilDataLvmHostVg>;
};

type AnvilDataLvm = {
  host_name: Record<string, AnvilDataLvmHost>;
};

type AnvilDataStrikerNetworkPrimaryLink = Omit<
  AnvilDataHostNetworkPrimaryLink,
  | 'bond_name'
  | 'bond_uuid'
  | 'bridge_name'
  | 'bridge_uuid'
  | 'changed_order'
  | 'duplex'
  | 'link_state'
  | 'medium'
  | 'mtu'
  | 'operational'
  | 'speed'
  | 'type'
  | 'uuid'
  | 'network_interface_uuid'
> & {
  file: string;
  mtu: string;
  rx_bytes: string;
  status: string;
  tx_bytes: string;
  variable: {
    BOOTPROTO: string;
    DEFROUTE: string;
    DEVICE: string;
    DSN1?: string;
    GATEWAY?: string;
    HWADDR: string;
    IPADDR: string;
    IPV6INIT: string;
    NAME: string;
    NM_CONTROLLED: string;
    ONBOOT: string;
    PREFIX: string;
    TYPE: string;
    USERCTL: string;
    UUID: string;
    ZONE: string;
  };
};

type AnvilDataSubnodeNetwork = {
  bond_uuid: {
    [uuid: string]: { name: string };
  };
  bridge_uuid: {
    [uuid: string]: { name: string };
  };
  interface: {
    [name: string]:
      | AnvilDataHostNetworkBond
      | AnvilDataHostNetworkBridge
      | AnvilDataHostNetworkLink
      | AnvilDataHostNetworkPrimaryLink;
  };
};

type AnvilDataStrikerNetwork = {
  interface: {
    [ifname: string]:
      | AnvilDataHostNetworkLink
      | AnvilDataHostNetworkPrimaryLink;
  };
};

type AnvilDataHostNetworkHash =
  | AnvilDataSubnodeNetwork
  | AnvilDataStrikerNetwork;

type AnvilDataNetworkListHash = {
  [hostId: string]: AnvilDataHostNetworkHash;
};

type AnvilDataManifestListHash = {
  manifest_uuid: {
    [manifestUUID: string]: {
      parsed: {
        domain: string;
        fences?: {
          [fenceId: string]: {
            uuid: string;
          };
        };
        machine: {
          [hostId: string]: {
            fence?: {
              [fenceName: string]: {
                port: string;
              };
            };
            ipmi_ip: string;
            name: string;
            network: {
              [networkId: string]: {
                ip: string;
              };
            };
            ups?: {
              [upsName: string]: {
                used: string;
              };
            };
          };
        };
        name: string;
        networks: {
          count: {
            [networkType: string]: number;
          };
          dns: string;
          mtu: string;
          name: {
            [networkId: string]: {
              gateway: string;
              network: string;
              subnet: string;
            };
          };
          ntp: string;
        };
        prefix: string;
        sequence: string;
        upses?: {
          [upsId: string]: {
            uuid: string;
          };
        };
      };
    };
  };
  name_to_uuid: Record<string, string>;
} & Record<
  string,
  {
    manifest_last_ran: number;
    manifest_name: string;
    manifest_note: string;
    manifest_xml: string;
  }
>;

type AnvilDataSysHash = {
  hosts?: {
    by_uuid: { [hostUuid: string]: string };
    by_name: { [hostName: string]: string };
  };
};

type AnvilDataUPSHash = {
  [upsName: string]: {
    agent: string;
    brand: string;
    description: string;
  };
};

type GetAnvilDataOptions = {
  predata?: Array<[string, ...unknown[]]>;
};
