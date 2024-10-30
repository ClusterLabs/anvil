import assert from 'assert';
import { RequestHandler } from 'express';
import { XMLParser } from 'fast-xml-parser';
import { dSize } from 'format-data-size';
import { readFileSync, readdirSync } from 'fs';
import path from 'path';

import { P_UUID, REP_UUID, SERVER_PATHS } from '../../consts';

import { getVncinfo, query } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { ResponseError } from '../../ResponseError';
import { sanitize } from '../../sanitize';
import { perr, poutvar } from '../../shell';

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
      JOIN hosts AS c
        ON a.server_host_uuid = c.host_uuid
      JOIN server_definitions AS d
        ON a.server_uuid = d.server_definition_server_uuid
      WHERE a.server_uuid = '${serverUuid}';`;

    let rows: string[][];

    try {
      rows = await query(sql);
    } catch (error) {
      const rserror = new ResponseError(
        '30f956f',
        `Failed to get server details; CAUSE: ${error}`,
      );

      perr(rserror.toString());

      return response.status(500).send(rserror.body);
    }

    if (!rows.length) {
      return response.status(404).send();
    }

    const {
      0: [
        serverName,
        serverState,
        serverStartAfterServerUuid,
        serverStartDelay,
        anUuid,
        anName,
        anDescription,
        hostUuid,
        hostName,
        hostType,
        serverDefinitionUuid,
        serverDefinitionXml,
      ],
    } = rows;

    // Get bridges separately to avoid passing duplicate definition XMLs

    sql = `
      SELECT
        bridge_uuid,
        bridge_name,
        bridge_id,
        bridge_mac_address
      FROM bridges
      WHERE bridge_host_uuid = '${hostUuid}';`;

    try {
      rows = await query(sql);

      assert.ok(rows.length, 'No bridges found');
    } catch (error) {
      const rserror = new ResponseError(
        '9806598',
        `Failed to get bridges for server details; CAUSE: ${error}`,
      );

      perr(rserror.toString());

      return response.status(500).send(rserror.body);
    }

    const hostBridges = rows.reduce<ServerDetailHostBridgeList>(
      (previous, row) => {
        const [uuid, name, id, mac] = row;

        previous[uuid] = {
          id,
          mac,
          name,
          uuid,
        };

        return previous;
      },
      {},
    );

    // Get interfaces to include state

    sql = `
      SELECT
        server_network_uuid,
        server_network_mac_address,
        server_network_vnet_device,
        server_network_link_state
      FROM server_networks
      WHERE server_network_server_uuid = '${serverUuid}';`;

    try {
      rows = await query(sql);

      assert.ok(rows.length, 'No interfaces found');
    } catch (error) {
      const rserror = new ResponseError(
        '27888e0',
        `Failed to get interfaces for server details; CAUSE: ${error}`,
      );

      perr(rserror.toString());

      return response.status(500).send(rserror.body);
    }

    const netIfaces = rows.reduce<ServerNetworkInterfaceList>(
      (previous, row) => {
        const [uuid, mac, device, state] = row;

        previous[mac] = {
          device,
          mac,
          state,
          uuid,
        };

        return previous;
      },
      {},
    );

    const xmlParser = new XMLParser({
      ignoreAttributes: false,
      parseAttributeValue: true,
    });

    let serverDefinition;

    try {
      serverDefinition = xmlParser.parse(serverDefinitionXml);
    } catch (error) {
      const rserror = new ResponseError(
        'dbaab5f',
        `Failed to parse libvirt XML of ${serverUuid}; CAUSE: ${error}`,
      );

      perr(rserror.toString());

      return response.status(500).send(rserror.body);
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
    } else if (disk) {
      ifaceArray = [iface];
    }

    const diskOrderByBoot: number[] = [];
    const diskOrderBySource: number[] = [];

    const disks = diskArray.map<ServerDetailDisk>((value, index) => {
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

      return {
        alias: {
          name: alias?.['@_name'],
        },
        boot: {
          order: bootOrder,
        },
        device: diskDevice,
        source: {
          dev: source?.['@_dev'],
          file: source?.['@_file'],
          index: sourceIndex,
        },
        target: {
          bus: target?.['@_bus'],
          dev: target?.['@_dev'],
        },
        type: diskType,
      };
    });

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

    const rsBody: ServerDetail = {
      anvil: {
        description: anDescription,
        name: anName,
        uuid: anUuid,
      },
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
      host: {
        bridges: hostBridges,
        name: hostName,
        short: getShortHostName(hostName),
        type: hostType,
        uuid: hostUuid,
      },
      memory: {
        size: memorySize ? memorySize.value : '0',
      },
      name: serverName,
      start: {
        after: serverStartAfterServerUuid,
        delay: Number(serverStartDelay),
      },
      state: serverState,
      uuid: serverUuid,
    };

    response.send(rsBody);
  }
};
