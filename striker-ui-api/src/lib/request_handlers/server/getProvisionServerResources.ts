import { RequestHandler } from 'express';
import { XMLParser } from 'fast-xml-parser';
import { dSize } from 'format-data-size';

import { NODE_AND_DR_RESERVED_MEMORY_SIZE } from '../../consts';

import { query } from '../../accessModule';
import { Responder } from '../../Responder';

const memorySystem = {
  bigint: BigInt(NODE_AND_DR_RESERVED_MEMORY_SIZE),
  string: String(NODE_AND_DR_RESERVED_MEMORY_SIZE),
};

const min = (...values: (bigint | string)[]): bigint => {
  const [first, ...rest] = values;

  return rest.reduce<bigint>((a, value) => {
    const b = BigInt(value);

    return a < b ? a : b;
  }, BigInt(first));
};

export const getProvisionServerResources: RequestHandler<
  undefined,
  ProvisionServerResources
> = async (request, response) => {
  const respond = new Responder(response);

  const sqlGetFiles = `
    SELECT
      a.file_uuid,
      a.file_name,
      c.anvil_uuid
    FROM files AS a
    JOIN file_locations AS b
      ON a.file_uuid = b.file_location_file_uuid
    JOIN anvils AS c
      ON b.file_location_host_uuid IN (
        c.anvil_node1_host_uuid,
        c.anvil_node2_host_uuid
      )
    WHERE a.file_type = 'iso'
    GROUP BY
      a.file_uuid,
      a.file_name,
      c.anvil_uuid
    ORDER BY
      a.file_name ASC,
      c.anvil_name ASC;`;

  const sqlGetNodes = `
    SELECT
      a.anvil_uuid,
      a.anvil_name,
      a.anvil_description
    FROM anvils AS a
    ORDER BY a.anvil_name ASC;`;

  const sqlGetServers = `
    SELECT
      b.anvil_uuid,
      a.server_uuid,
      a.server_name,
      c.server_definition_xml
    FROM servers AS a
    JOIN anvils AS b
      ON a.server_anvil_uuid = b. anvil_uuid
    JOIN server_definitions AS c
      ON a.server_uuid = c.server_definition_server_uuid
    ORDER BY
      a.server_name ASC,
      b.anvil_name ASC;`;

  const sqlGetStorageGroups = `
    SELECT
      b.anvil_uuid,
      a.storage_group_uuid,
      a.storage_group_name,
      MIN(d.scan_lvm_vg_size) AS storage_group_size,
      MIN(d.scan_lvm_vg_free) AS storage_group_free
    FROM storage_groups AS a
    JOIN anvils AS b
      ON a.storage_group_anvil_uuid = b.anvil_uuid
    JOIN storage_group_members AS c
      ON a.storage_group_uuid = c.storage_group_member_storage_group_uuid
    JOIN scan_lvm_vgs AS d
      ON c.storage_group_member_vg_uuid = d.scan_lvm_vg_internal_uuid
    GROUP BY
      b.anvil_uuid,
      a.storage_group_uuid,
      a.storage_group_name
    ORDER BY
      a.storage_group_name ASC,
      b.anvil_name ASC;`;

  const sqlGetSubnodes = `
    SELECT
      b.anvil_uuid,
      a.host_uuid,
      a.host_name,
      SUBSTRING(a.host_name, '^([^.]+)') AS short_host_name,
      c.scan_hardware_cpu_cores,
      c.scan_hardware_ram_total
    FROM hosts AS a
    JOIN anvils AS b
      ON a.host_uuid IN (
        b.anvil_node1_host_uuid,
        b.anvil_node2_host_uuid
      )
    JOIN scan_hardware AS c
      ON a.host_uuid = c.scan_hardware_host_uuid
    ORDER BY
      a.host_name ASC,
      b.anvil_name ASC;`;

  const sqlGetProvisioning = `
    SELECT *
    FROM (
      SELECT
        a.job_uuid,
        a.job_progress,
        CASE
          WHEN a.job_data LIKE '%peer_mode=true%'
            THEN 1
          ELSE 0
        END AS job_on_peer,
        SUBSTRING(a.job_data, 'cpu_cores=([^\\n]*)') AS cpu_cores,
        SUBSTRING(a.job_data, 'ram=([^\\n]*)') AS memory_size,
        SUBSTRING(a.job_data, 'server_name=([^\\n]*)') AS server_name,
        SUBSTRING(a.job_data, 'storage_group_uuid=([^\\n]*)') AS storage_group_uuid,
        SUBSTRING(a.job_data, 'storage_size=([^\\n]*)') AS storage_size,
        b.anvil_uuid
      FROM jobs AS a
      LEFT JOIN anvils AS b
        ON a.job_host_uuid IN (
          b.anvil_node1_host_uuid,
          b.anvil_node2_host_uuid
        )
      WHERE
          a.job_command LIKE '%anvil-provision-server%'
        AND
          a.modified_date > current_timestamp - interval '5 minutes'
      ORDER BY
        server_name ASC,
        job_on_peer ASC
    ) AS s
    WHERE
      s.server_name NOT IN (
        SELECT server_name
        FROM servers
      );`;

  const promises = [
    sqlGetFiles,
    sqlGetNodes,
    sqlGetServers,
    sqlGetStorageGroups,
    sqlGetSubnodes,
    sqlGetProvisioning,
  ].map<Promise<QueryResult>>((sql) => query(sql));

  let results: QueryResult[];

  try {
    results = await Promise.all(promises);
  } catch (error) {
    return respond.s500(
      '3c9e79f',
      `Failed to get data for provision server; CAUSE: ${error}`,
    );
  }

  const [
    fileRows,
    nodeRows,
    serverRows,
    storageGroupRows,
    subnodeRows,
    provisioningRows,
  ] = results;

  const resources: ProvisionServerResources = {
    files: {},
    nodes: {},
    servers: {},
    storageGroups: {},
    subnodes: {},
  };

  nodeRows.reduce<ProvisionServerResources>((previous, row) => {
    const [anvilUuid, anvilName, anvilDescription] = row;

    const uuid = String(anvilUuid);
    const name = String(anvilName);
    const description = String(anvilDescription);

    const { nodes } = previous;

    nodes[uuid] = {
      cpu: {
        cores: {
          total: 0,
        },
      },
      description,
      files: [],
      memory: {
        allocated: '',
        available: '',
        system: memorySystem.string,
        total: '',
      },
      name,
      servers: [],
      storageGroups: [],
      subnodes: [],
      uuid,
    };

    return previous;
  }, resources);

  fileRows.reduce<ProvisionServerResources>((previous, row) => {
    const [fileUuid, fileName, anvilUuid] = row;

    if (row.some((field) => field === null)) {
      return previous;
    }

    const uuid = String(fileUuid);
    const name = String(fileName);
    const node = String(anvilUuid);

    const { files, nodes } = previous;

    if (!files[uuid]) {
      files[uuid] = {
        jobs: {},
        name,
        nodes: [],
        uuid,
      };
    }

    files[uuid].nodes.push(node);

    nodes[node].files.push(uuid);

    return previous;
  }, resources);

  const xmlParser = new XMLParser({
    ignoreAttributes: false,
    parseAttributeValue: true,
  });

  serverRows.reduce<ProvisionServerResources>((previous, row) => {
    const [anvilUuid, serverUuid, serverName, serverDefinition] = row;

    if (row.some((field) => field === null)) {
      return previous;
    }

    const node = String(anvilUuid);
    const uuid = String(serverUuid);
    const name = String(serverName);
    const definition = String(serverDefinition);

    const xml = xmlParser.parse(definition);

    const cpuTopology = xml?.domain?.cpu?.topology;

    const cpuCores = cpuTopology?.['@_cores'];

    const memory = xml?.domain?.memory;

    const memoryValue = memory?.['#text'];
    const memoryUnit = memory?.['@_unit'];

    const memorySize = dSize(memoryValue, {
      fromUnit: memoryUnit,
      toUnit: 'B',
    });

    const memoryTotal = memorySize ? memorySize.value : '0';

    const { nodes, servers } = previous;

    servers[uuid] = {
      cpu: {
        cores: Number(cpuCores),
      },
      jobs: {},
      memory: {
        total: memoryTotal,
      },
      name,
      node,
      uuid,
    };

    const nodeObj = nodes[node];

    nodeObj.servers.push(uuid);

    nodeObj.memory.allocated = String(
      BigInt(nodeObj.memory.allocated) + BigInt(memoryTotal),
    );

    return previous;
  }, resources);

  storageGroupRows.reduce<ProvisionServerResources>((previous, row) => {
    const [
      anvilUuid,
      storageGroupUuid,
      storageGroupName,
      storageGroupSize,
      storageGroupFree,
    ] = row;

    if (row.some((field) => field === null)) {
      return previous;
    }

    const node = String(anvilUuid);
    const uuid = String(storageGroupUuid);
    const name = String(storageGroupName);
    const total = BigInt(String(storageGroupSize));
    const free = BigInt(String(storageGroupFree));
    const used = total - free;

    const { nodes, storageGroups } = previous;

    storageGroups[uuid] = {
      name,
      node,
      usage: {
        free: String(free),
        total: String(total),
        used: String(used),
      },
      uuid,
    };

    nodes[node].storageGroups.push(uuid);

    return previous;
  }, resources);

  subnodeRows.reduce<ProvisionServerResources>((previous, row) => {
    const [
      anvilUuid,
      hostUuid,
      hostName,
      shortHostName,
      hostCpuCores,
      hostMemoryTotal,
    ] = row;

    if (row.some((field) => field === null)) {
      return previous;
    }

    const node = String(anvilUuid);
    const uuid = String(hostUuid);
    const name = String(hostName);
    const short = String(shortHostName);
    const cpuCores = Number(hostCpuCores);
    const memoryTotal = String(hostMemoryTotal);

    const { nodes, subnodes } = previous;

    subnodes[uuid] = {
      cpu: {
        cores: {
          total: cpuCores,
        },
      },
      memory: {
        total: memoryTotal,
      },
      name,
      node,
      short,
      uuid,
    };

    const nodeObj = nodes[node];

    nodeObj.subnodes.push(uuid);

    nodeObj.cpu.cores.total =
      nodeObj.cpu.cores.total === 0
        ? cpuCores
        : Math.min(nodeObj.cpu.cores.total, cpuCores);

    nodeObj.memory.total = String(
      nodeObj.memory.total === ''
        ? memoryTotal
        : min(nodeObj.memory.total, memoryTotal),
    );

    return previous;
  }, resources);

  provisioningRows.reduce<ProvisionServerResources>((previous, row) => {
    const [
      provisionJobUuid,
      provisionJobProgress,
      provisionJobOnPeer,
      serverCpuCores,
      serverMemorySize,
      serverName,
      storageGroupUuid,
      storageSize,
      nodeUuid,
    ] = row;

    if (row.some((field) => field === null)) {
      return previous;
    }

    const jobUuid = String(provisionJobUuid);
    const jobProgress = Number(provisionJobProgress);
    const jobOnPeer = Boolean(provisionJobOnPeer);

    const name = String(serverName);

    const { nodes, servers, storageGroups } = previous;

    if (!servers[name]) {
      const cpuCores = Number(serverCpuCores);
      const memoryTotal = BigInt(String(serverMemorySize));
      const sgUuid = String(storageGroupUuid);
      const diskSize = BigInt(String(storageSize));
      const node = String(nodeUuid);

      servers[name] = {
        cpu: {
          cores: cpuCores,
        },
        jobs: {},
        memory: {
          total: String(memoryTotal),
        },
        name,
        node,
        uuid: name,
      };

      // Only do the following updates **once**!

      // 1. Update memory numbers on the node that owns the provisioning server

      const nodeObj = nodes[node];

      const allocated = BigInt(nodeObj.memory.allocated);
      const available = BigInt(nodeObj.memory.available);

      nodeObj.memory.allocated = String(allocated + memoryTotal);
      nodeObj.memory.available = String(available - memoryTotal);

      // 2. Update storage numbers on the storage group that holds the disk used by
      // the provisioning server

      const sgObj = storageGroups[sgUuid];

      const sgFree = BigInt(sgObj.usage.free);
      const sgUsed = BigInt(sgObj.usage.used);

      sgObj.usage.free = String(sgFree - diskSize);
      sgObj.usage.used = String(sgUsed + diskSize);
    }

    servers[name].jobs[jobUuid] = {
      peer: jobOnPeer,
      progress: jobProgress,
      uuid: jobUuid,
    };

    return previous;
  }, resources);

  Object.values(resources.nodes).forEach((node) => {
    const { memory } = node;

    memory.available = String(
      BigInt(memory.total) - memorySystem.bigint - BigInt(memory.allocated),
    );
  });

  return respond.s200(resources);
};
