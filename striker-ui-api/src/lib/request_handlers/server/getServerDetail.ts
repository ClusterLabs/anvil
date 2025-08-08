import assert from 'assert';
import { RequestHandler } from 'express';
import { XMLParser } from 'fast-xml-parser';
import { dSize } from 'format-data-size';
import { readFileSync, readdirSync } from 'fs';
import path from 'path';

import { P_UUID, REP_UUID, SERVER_PATHS } from '../../consts';

import {
  getLvmData,
  getVncinfo,
  listNicModels,
  query,
} from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { Responder } from '../../Responder';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';
import {
  sqlHosts,
  sqlScanDrbdPeers,
  sqlScanDrbdResources,
  sqlScanDrbdVolumes,
  sqlServers,
} from '../../sqls';

type ServerSsMeta = {
  name: string;
  timestamp: number;
  uuid: string;
};

const disassembleServerSsName = (name: string): ServerSsMeta => {
  const csv = name.replace(
    new RegExp(`^server-uuid_(${P_UUID})_timestamp-(\\d+).*$`),
    '$1,$2',
  );

  const [uuid, t] = csv.split(',', 2);
  const timestamp = Number(t);

  return { name, timestamp, uuid };
};

export const getServerDetail: RequestHandler<
  ServerDetailParamsDictionary,
  unknown,
  unknown,
  ServerDetailParsedQs
> = async (request, response) => {
  const respond = new Responder(response);

  const {
    params: { serverUUID: serverUuid },
    query: { ss: rSs, vnc: rVnc },
  } = request;

  const ss = sanitize(rSs, 'boolean');
  const vnc = sanitize(rVnc, 'boolean');

  poutvar({ serverUuid, ss, vnc }, 'Request variables: ');

  try {
    assert(
      REP_UUID.test(serverUuid),
      `Server UUID must be a valid UUID; got [${serverUuid}]`,
    );
  } catch (assertError) {
    perr(
      `Failed to assert value when trying to get server detail; CAUSE: ${assertError}.`,
    );

    return response.status(500).send();
  }

  if (ss) {
    const rsBody: ServerDetailScreenshot = { screenshot: '', timestamp: 0 };
    const ssDir = SERVER_PATHS.opt.alteeve.screenshots.self;

    let ssNames: string[];

    try {
      ssNames = readdirSync(SERVER_PATHS.opt.alteeve.screenshots.self, {
        encoding: 'utf-8',
      });
    } catch (error) {
      perr(`Failed to list server ${serverUuid} screenshots; CAUSE: ${error}`);

      return response.status(500).send();
    }

    const ssMetas = ssNames
      .reduce<ServerSsMeta[]>((previous, name) => {
        const meta = disassembleServerSsName(name);

        if (meta.uuid === serverUuid) {
          previous.push(meta);
        }

        return previous;
      }, [])
      .sort((a, b) => {
        if (a.timestamp === b.timestamp) return 0;

        return a.timestamp > b.timestamp ? 1 : -1;
      });

    const ssMetaLatest = ssMetas.pop();

    poutvar(ssMetaLatest, `Latest server screenshot: `);

    if (ssMetaLatest) {
      const { name, timestamp } = ssMetaLatest;

      const ssLatest = readFileSync(path.join(ssDir, name), {
        encoding: 'base64',
      });

      rsBody.screenshot = ssLatest;
      rsBody.timestamp = timestamp;
    }

    return response.send(rsBody);
  } else if (vnc) {
    let rsbody: ServerDetailVncInfo;

    try {
      rsbody = await getVncinfo(serverUuid);
    } catch (error) {
      perr(`Failed to get server ${serverUuid} VNC info; CAUSE: ${error}`);

      return response.status(500).send();
    }

    return response.send(rsbody);
  } else {
    let sql = `
      SELECT
        a.server_name,
        a.server_state,
        a.server_start_after_server_uuid,
        a.server_start_delay,
        b.anvil_uuid,
        b.anvil_name,
        b.anvil_description,
        c.host_uuid,
        c.host_name,
        c.host_type,
        d.server_definition_uuid,
        d.server_definition_xml
      FROM servers AS a
      JOIN anvils AS b
        ON a.server_anvil_uuid = b.anvil_uuid
      LEFT JOIN hosts AS c
        ON a.server_host_uuid = c.host_uuid
      JOIN server_definitions AS d
        ON a.server_uuid = d.server_definition_server_uuid
      WHERE a.server_uuid = '${serverUuid}';`;

    let rows: string[][];

    try {
      rows = await query(sql);
    } catch (error) {
      return respond.s500(
        '30f956f',
        `Failed to get server details; CAUSE: ${error}`,
      );
    }

    if (!rows.length) {
      return respond.s404();
    }

    const {
      0: [
        serverName,
        serverState,
        serverStartAfterServerUuid,
        serverStartDelay,
        anvilUuid,
        anvilName,
        anvilDescription,
        hostUuid,
        hostName,
        hostType,
        serverDefinitionUuid,
        serverDefinitionXml,
      ],
    } = rows;

    let shortHostName: string | undefined;

    let host: ServerOverviewHost | undefined;

    let nicModelsHostUuid: string;

    if (hostUuid) {
      shortHostName = getShortHostName(hostName);

      host = {
        name: hostName,
        short: shortHostName,
        type: hostType,
        uuid: hostUuid,
      };

      nicModelsHostUuid = hostUuid;
    } else {
      const sqlGetSubnode1Uuid = `
        SELECT anvil_node1_host_uuid
        FROM anvils
        WHERE anvil_uuid = '${anvilUuid}';`;

      try {
        [[nicModelsHostUuid]] = await query<[[string]]>(sqlGetSubnode1Uuid);
      } catch (error) {
        return respond.s500(
          'a4eff57',
          `Failed to faillback on the first subnode's UUID; CAUSE: ${error}`,
        );
      }
    }

    // Get bridges separately to avoid passing duplicate definition XMLs

    sql = `
      SELECT
        a.bridge_uuid,
        a.bridge_name,
        a.bridge_id,
        a.bridge_mac_address
      FROM bridges as a
      JOIN anvils as b
        ON a.bridge_host_uuid IN (
          b.anvil_node1_host_uuid,
          b.anvil_node2_host_uuid
        )
      WHERE b.anvil_uuid = '${anvilUuid}';`;

    try {
      rows = await query(sql);

      assert.ok(rows.length, 'No bridges found');
    } catch (error) {
      return respond.s500(
        '9806598',
        `Failed to get bridges for server details; CAUSE: ${error}`,
      );
    }

    const bridges = rows.reduce<ServerDetailHostBridgeList>((previous, row) => {
      const [uuid, name, id, mac] = row;

      previous[uuid] = {
        id,
        mac,
        name,
        uuid,
      };

      return previous;
    }, {});

    // Get interfaces to include state

    sql = `
      SELECT
        a.server_network_uuid,
        a.server_network_mac_address,
        a.server_network_vnet_device,
        a.server_network_link_state,
        COALESCE(b.mac_to_ip_ip_address, '')
      FROM server_networks AS a
      LEFT JOIN mac_to_ip AS b
        ON b.mac_to_ip_mac_address = a.server_network_mac_address
      WHERE a.server_network_server_uuid = '${serverUuid}';`;

    try {
      rows = await query(sql);

      assert.ok(rows.length, 'No interfaces found');
    } catch (error) {
      return respond.s500(
        '27888e0',
        `Failed to get interfaces for server details; CAUSE: ${error}`,
      );
    }

    const netIfaces = rows.reduce<ServerNetworkInterfaceList>(
      (previous, row) => {
        const [uuid, mac, device, state, ip] = row;

        previous[mac] = {
          device,
          ip,
          mac,
          state,
          uuid,
        };

        return previous;
      },
      {},
    );

    // Get server variables

    sql = `
      SELECT
        variable_uuid,
        variable_name,
        variable_value
      FROM variables
      WHERE variable_name IN (
        'server::${serverName}::stay-off',
        'server::${serverUuid}::vncinfo'
      );`;

    try {
      rows = await query(sql);
    } catch (error) {
      return respond.s500(
        'c9bd36c',
        `Failed to get server variables; ${error}`,
      );
    }

    const variables: Record<string, ServerDetailVariable> = {};

    let startActive = true;

    if (rows.length) {
      rows.reduce<
        Record<
          string,
          { name: string; short: string; uuid: string; value: string }
        >
      >((previous, row) => {
        const [uuid, name, value] = row;

        const short = name.split('::').pop() ?? '';

        if (short === 'stay-off') {
          startActive = value !== '1';
        }

        previous[uuid] = {
          name,
          short,
          uuid,
          value,
        };

        return previous;
      }, variables);
    }

    // Get LVM info

    let hostLvm: AnvilDataLvmHost;

    try {
      const lvm = await getLvmData();

      if (!shortHostName) {
        // All subnodes should have the exact same storage setup,
        // pick the first one if we don't already have any.
        [shortHostName = ''] = Object.keys(lvm.host_name);
      }

      hostLvm = lvm.host_name?.[shortHostName];

      assert.ok(hostLvm);
    } catch (error) {
      return respond.s500(
        'dd8a119',
        `Failed to get storage (LVM) data; CAUSE: ${error}`,
      );
    }

    // Get list of NIC models

    let nicModels: string[];

    try {
      nicModels = await listNicModels(nicModelsHostUuid);
    } catch (error) {
      return respond.s500(
        '8451d62',
        `Failed to get NIC models; CAUSE: ${error}`,
      );
    }

    // Extract necessary values from the libvirt domain XML

    const xmlParser = new XMLParser({
      ignoreAttributes: false,
      parseAttributeValue: true,
    });

    let serverDefinition;

    try {
      serverDefinition = xmlParser.parse(serverDefinitionXml);
    } catch (error) {
      return respond.s500(
        'dbaab5f',
        `Failed to parse libvirt XML of ${serverUuid}; CAUSE: ${error}`,
      );
    }

    const {
      domain: {
        cpu: {
          topology: {
            '@_clusters': cpuClusters,
            '@_cores': cpuCores,
            '@_dies': cpuDies,
            '@_sockets': cpuSockets,
            '@_threads': cpuThreads,
          },
        },
        devices: { disk, interface: iface },
        memory: { '#text': memoryValue, '@_unit': memoryUnit },
      },
    } = serverDefinition;

    const memorySize = dSize(memoryValue, {
      fromUnit: memoryUnit,
      toUnit: 'B',
    });

    let diskArray = [];

    if (Array.isArray(disk)) {
      diskArray = disk;
    } else if (disk) {
      diskArray = [disk];
    }

    let ifaceArray = [];

    if (Array.isArray(iface)) {
      ifaceArray = iface;
    } else if (iface) {
      ifaceArray = [iface];
    }

    const diskOrderByBoot: number[] = [];
    const diskOrderBySource: number[] = [];

    const disks = await Promise.all(
      diskArray.map<Promise<ServerDetailDisk>>(async (value, index) => {
        const {
          '@_type': diskType,
          '@_device': diskDevice,
          alias,
          boot,
          source,
          target,
        } = value;

        const bootOrder = boot?.['@_order'];
        const sourceIndex = source?.['@_index'];

        if (bootOrder) {
          diskOrderByBoot[bootOrder] = index;
        }

        if (sourceIndex) {
          diskOrderBySource[sourceIndex] = index;
        }

        const sourceDev = source?.['@_dev'];
        const sourceFile = source?.['@_file'];

        const lv: ServerDetailDisk['source']['dev']['lv'] = {};

        let sgUuid: string | undefined;

        if (sourceDev) {
          const drbdResourceIndex = path.basename(sourceDev);
          const lvName = `${serverName}_${drbdResourceIndex}`;

          const hostLv = hostLvm.lv?.[lvName];

          if (hostLv) {
            lv.name = lvName;
            lv.size = hostLv.scan_lvm_lv_size;
            lv.uuid = hostLv.scan_lvm_lv_uuid;

            const { scan_lvm_lv_on_vg: vgName } = hostLv;

            ({ storage_group_uuid: sgUuid } = hostLvm.vg[vgName]);
          }
        }

        let fileUuid: string | undefined;

        if (sourceFile) {
          const dir = path.dirname(sourceFile);
          const name = path.basename(sourceFile);

          try {
            const rows = await query<[[string]]>(`
              SELECT file_uuid
              FROM files
              WHERE file_directory = '${dir}'
                AND file_name = '${name}';`);

            assert.ok(rows.length);

            ({
              0: [fileUuid],
            } = rows);
          } catch (error) {
            // Let the field be blank
          }
        }

        return {
          alias: {
            name: alias?.['@_name'],
          },
          boot: {
            order: bootOrder,
          },
          device: diskDevice,
          source: {
            dev: {
              lv,
              path: sourceDev,
              sg: sgUuid,
            },
            file: {
              path: sourceFile,
              uuid: fileUuid,
            },
            index: sourceIndex,
          },
          target: {
            bus: target?.['@_bus'],
            dev: target?.['@_dev'],
          },
          type: diskType,
        };
      }),
    );

    const interfaces = ifaceArray.map<ServerDetailInterface>((value) => {
      const {
        '@_type': ifaceType,
        alias,
        link,
        mac,
        model,
        source,
        target,
      } = value;

      const macAddress = mac?.['@_address'] ?? '';

      const { [macAddress]: netIface } = netIfaces;

      return {
        alias: {
          name: alias?.['@_name'],
        },
        link: {
          state: link?.['@_state'] ?? netIface?.state,
        },
        mac: {
          address: macAddress,
        },
        model: {
          type: model?.['@_type'],
        },
        source: {
          bridge: source?.['@_bridge'],
        },
        target: {
          dev: target?.['@_dev'],
        },
        type: ifaceType,
        uuid: netIface?.uuid,
      };
    });

    const server: ServerDetail = {
      anvil: {
        description: anvilDescription,
        name: anvilName,
        uuid: anvilUuid,
      },
      bridges,
      cpu: {
        topology: {
          clusters: cpuClusters,
          cores: cpuCores,
          dies: cpuDies,
          sockets: cpuSockets,
          threads: cpuThreads,
        },
      },
      definition: {
        uuid: serverDefinitionUuid,
      },
      devices: {
        diskOrderBy: {
          boot: diskOrderByBoot,
          source: diskOrderBySource,
        },
        disks,
        interfaces,
      },
      host,
      libvirt: {
        nicModels,
      },
      memory: {
        size: memorySize ? memorySize.value : '0',
      },
      name: serverName,
      protect: {},
      start: {
        active: startActive,
        after: serverStartAfterServerUuid,
        delay: Number(serverStartDelay),
      },
      state: serverState,
      uuid: serverUuid,
      variables,
    };

    const sqlGetDrHosts = `${sqlHosts()} AND host_type = 'dr'`;

    const sqlGetProtectScope = `
      SELECT
        i.scan_drbd_resource_name,
        CAST(i.scan_drbd_resource_xml AS xml) AS resource_xml,
        COUNT(iii.scan_drbd_peer_uuid) AS peer_count,
        SUM(
          CAST(
            iii.scan_drbd_peer_connection_state IN (
              'standalone'
            ) AS int
          )
        ) AS standalone_count,
        SUM(
          CAST(
            iii.scan_drbd_peer_connection_state IN (
              'established',
              'syncsource',
              'synctarget'
            ) AS int
          )
        ) AS connected_count,
        SUM(
          CAST(iii.scan_drbd_peer_connection_state = 'off' AS int)
        ) AS off_count,
        SUM(
          CAST(iii.scan_drbd_peer_local_disk_state = 'uptodate' AS int)
        ) AS local_uptodate_count,
        SUM(
          CAST(iii.scan_drbd_peer_disk_state = 'uptodate' AS int)
        ) AS peer_uptodate_count,
        MAX(
          iii.scan_drbd_peer_estimated_time_to_sync
        ) AS max_estimated_time_to_sync
      FROM (${sqlScanDrbdResources()}) AS i
      LEFT JOIN (${sqlScanDrbdVolumes()}) AS ii
        ON ii.scan_drbd_volume_scan_drbd_resource_uuid = i.scan_drbd_resource_uuid
      LEFT JOIN (
        SELECT *
        FROM (${sqlScanDrbdPeers()}) AS i
        JOIN (${sqlGetDrHosts}) AS ii
          ON ii.host_uuid = i.scan_drbd_peer_host_uuid
      ) AS iii
        ON iii.scan_drbd_peer_scan_drbd_volume_uuid = ii.scan_drbd_volume_uuid
      GROUP BY
        i.scan_drbd_resource_name,
        i.scan_drbd_resource_xml`;

    const sqlGetProtectStatus = `
      WITH
        scope AS (${sqlGetProtectScope})
      SELECT
        d.host_uuid,
        CASE
          WHEN b.drbd_connection_protocol = 'C'
            THEN 'sync'
          ELSE 'short-throw'
        END as dr_connection_protocol,
        a.peer_count,
        a.standalone_count,
        a.connected_count,
        a.off_count,
        a.local_uptodate_count,
        a.peer_uptodate_count,
        a.max_estimated_time_to_sync
      FROM
        scope AS a,
        XMLTABLE(
          'resource/connection/host'
          PASSING resource_xml
          COLUMNS
            connection_host text
              PATH '@name',
            drbd_connection_protocol text
              PATH '../section[@name="net"]/option[@name="protocol"]/@value'
        ) AS b,
        (${sqlServers()}) AS c,
        (${sqlGetDrHosts}) AS d
      WHERE
          c.server_name = a.scan_drbd_resource_name
        AND
          b.connection_host = d.host_short_name
        AND
          c.server_uuid = '${serverUuid}'
      GROUP BY
        a.connected_count,
        a.local_uptodate_count,
        a.max_estimated_time_to_sync,
        a.off_count,
        a.peer_count,
        a.peer_uptodate_count,
        a.standalone_count,
        b.drbd_connection_protocol,
        d.host_uuid;`;

    let protectStatusRows: string[][];

    try {
      protectStatusRows = await query(sqlGetProtectStatus);
    } catch (error) {
      return respond.s500(
        'f1921a7',
        `Failed to get server protect status; CAUSE: ${error}`,
      );
    }

    protectStatusRows.forEach((row) => {
      const [
        drUuid,
        protocol,
        numPeers,
        numStandalone,
        numConnected,
        numOff,
        numLocalUptodate,
        numPeerUptodate,
        maxEstimatedTimeToSync,
      ] = row as [string, string, ...number[]];

      const protect: ServerDetailProtect = {
        drUuid,
        protocol,
        status: {
          connection: '',
          maxEstimatedTimeToSync: 0,
          overall: '',
        },
      };

      if (numOff === numPeers) {
        protect.status.connection = 'off';
      } else if (numStandalone > 0) {
        protect.status.connection = 'standalone';
      } else if (numConnected === numPeers) {
        protect.status.connection = 'connected';
      } else {
        protect.status.connection = 'disconnected';
      }

      if (numOff === numPeers) {
        protect.status.overall = 'offline';
      } else if (maxEstimatedTimeToSync > 0) {
        protect.status.maxEstimatedTimeToSync = maxEstimatedTimeToSync;
        protect.status.overall = 'syncing';
      } else if (numLocalUptodate + numPeerUptodate === numPeers * 2) {
        protect.status.overall = 'optimal';
      } else {
        protect.status.overall = 'degraded';
      }

      server.protect[drUuid] = protect;
    });

    return respond.s200(server);
  }
};
