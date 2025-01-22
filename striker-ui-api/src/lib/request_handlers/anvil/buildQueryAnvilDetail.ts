import { dSize } from 'format-data-size';

import {
  DELETED,
  NODE_AND_DR_RESERVED_MEMORY_SIZE,
  OS_LIST_MAP,
} from '../../consts';

import join from '../../join';
import { poutvar } from '../../shell';

const buildQueryAnvilDetail = ({
  anvilUUIDs = ['*'],
  isForProvisionServer,
}: {
  anvilUUIDs?: string[] | '*';
  isForProvisionServer?: boolean;
}) => {
  const condAnvilsUUID = ['all', '*'].includes(anvilUUIDs[0])
    ? ''
    : join(anvilUUIDs, {
        beforeReturn: (toReturn) =>
          toReturn ? `WHERE anv.anvil_uuid IN (${toReturn})` : '',
        elementWrapper: "'",
        separator: ', ',
      });

  poutvar({ condAnvilsUUID });

  const buildHostQuery = ({
    isSummary = false,
  }: { isSummary?: boolean } = {}) => {
    let fieldsToSelect = `
      host_uuid,
      host_name,
      scan_hardware_cpu_cores,
      scan_hardware_ram_total`;
    let groupByPhrase = '';

    if (isSummary) {
      fieldsToSelect = `
        MIN(scan_hardware_cpu_cores) AS anvil_total_cpu_cores,
        MIN(scan_hardware_ram_total) AS anvil_total_memory`;

      groupByPhrase = 'GROUP BY anvil_uuid';
    }

    return `
      SELECT
        anvil_uuid,
        ${fieldsToSelect}
      FROM anvils AS anv
      JOIN hosts AS hos
        ON host_uuid IN (
          anvil_node1_host_uuid,
          anvil_node2_host_uuid
        )
      JOIN scan_hardware AS sca_har
        ON host_uuid = scan_hardware_host_uuid
      ${groupByPhrase}`;
  };

  const buildServerQuery = ({
    isSummary = false,
  }: { isSummary?: boolean } = {}) => {
    let fieldsToSelect = `
      server_uuid,
      server_name,
      server_cpu_cores,
      server_memory_value,
      server_memory_unit`;
    let groupByPhrase = '';

    if (isSummary) {
      fieldsToSelect =
        'SUM(server_cpu_cores) AS anvil_total_allocated_cpu_cores';

      groupByPhrase = 'GROUP BY server_anvil_uuid';
    }

    return `
      SELECT
        server_anvil_uuid,
        ${fieldsToSelect}
      FROM servers AS ser
      JOIN (
        SELECT
          server_definition_server_uuid,
          CAST(
            SUBSTRING(
              server_definition_xml, 'cores=''([\\d]*)'''
            ) AS INTEGER
          ) AS server_cpu_cores,
          CAST(
            SUBSTRING(
              server_definition_xml, 'memory.*>([\\d]*)</memory'
            ) AS BIGINT
          ) AS server_memory_value,
          SUBSTRING(
            server_definition_xml, 'memory.*unit=''([A-Za-z]*)'''
          ) AS server_memory_unit
        FROM server_definitions AS ser_def
      ) AS pos_ser_def
        ON server_uuid = server_definition_server_uuid
      WHERE ser.server_state != '${DELETED}'
      ${groupByPhrase}`;
  };

  const buildStorageGroupQuery = () => `
    SELECT
      storage_group_anvil_uuid,
      storage_group_uuid,
      storage_group_name,
      MIN(scan_lvm_vg_size) AS storage_group_size,
      MIN(scan_lvm_vg_free) AS storage_group_free
    FROM storage_groups AS sto_gro
    JOIN storage_group_members AS sto_gro_mem
      ON storage_group_uuid = storage_group_member_storage_group_uuid
    JOIN scan_lvm_vgs AS sca_lvm_vgs
      ON storage_group_member_vg_uuid = scan_lvm_vg_internal_uuid
    GROUP BY
      storage_group_anvil_uuid,
      storage_group_uuid,
      storage_group_name`;

  const buildFileQuery = () => `
    SELECT
      file_location_host_uuid,
      file_uuid,
      file_name
    FROM file_locations as fil_loc
    JOIN files as fil
      ON file_location_file_uuid = file_uuid
    WHERE
      file_type = 'iso'
      AND file_location_active = 't'`;

  const buildQueryForProvisionServer = () => `
    SELECT
      anv.anvil_uuid,
      anv.anvil_name,
      anv.anvil_description,
      host_list.host_uuid,
      host_list.host_name,
      host_list.scan_hardware_cpu_cores,
      host_list.scan_hardware_ram_total,
      host_summary.anvil_total_cpu_cores,
      host_summary.anvil_total_memory,
      server_list.server_uuid,
      server_list.server_name,
      server_list.server_cpu_cores,
      server_list.server_memory_value,
      server_list.server_memory_unit,
      server_summary.anvil_total_allocated_cpu_cores,
      (host_summary.anvil_total_cpu_cores
          - server_summary.anvil_total_allocated_cpu_cores
        ) AS anvil_total_available_cpu_cores,
      storage_group_list.storage_group_uuid,
      storage_group_list.storage_group_name,
      storage_group_list.storage_group_size,
      storage_group_list.storage_group_free,
      file_list.file_uuid,
      file_list.file_name
    FROM anvils AS anv
    JOIN (${buildHostQuery()}) AS host_list
      ON anv.anvil_uuid = host_list.anvil_uuid
    JOIN (${buildHostQuery({ isSummary: true })}) AS host_summary
      ON anv.anvil_uuid = host_summary.anvil_uuid
    LEFT JOIN (${buildServerQuery()}) AS server_list
      ON anv.anvil_uuid = server_list.server_anvil_uuid
    LEFT JOIN (${buildServerQuery({ isSummary: true })}) AS server_summary
      ON anv.anvil_uuid = server_summary.server_anvil_uuid
    LEFT JOIN (${buildStorageGroupQuery()}) AS storage_group_list
      ON anv.anvil_uuid = storage_group_list.storage_group_anvil_uuid
    LEFT JOIN (${buildFileQuery()}) AS file_list
      ON file_list.file_location_host_uuid IN (
        anv.anvil_node1_host_uuid,
        anv.anvil_node2_host_uuid
      )
    ;`;

  let query = `
    SELECT
      *
    FROM anvils AS anv
    ${condAnvilsUUID}
    ;`;
  let afterQueryReturn = undefined;

  if (isForProvisionServer) {
    query = buildQueryForProvisionServer();

    afterQueryReturn = (qoutput: unknown) => {
      let results = qoutput;

      if (qoutput instanceof Array) {
        const lasti = qoutput.length - 1;

        let puuid = '';

        let anvilTotalAllocatedMemory = BigInt(0);
        let files: Record<string, AnvilDetailFileForProvisionServer> = {};
        let hosts: Record<string, AnvilDetailHostForProvisionServer> = {};
        let servers: Record<string, AnvilDetailServerForProvisionServer> = {};
        let stores: Record<string, AnvilDetailStoreForProvisionServer> = {};

        const anvils = qoutput.reduce<
          Record<string, AnvilDetailForProvisionServer>
        >(
          (
            previous,
            [
              anvilUUID,
              anvilName,
              anvilDescription,
              hostUUID,
              hostName,
              hostCPUCores,
              hostMemory,
              anvilTotalCPUCores,
              anvilTotalMemory,
              serverUUID,
              serverName,
              serverCPUCores,
              serverMemoryValue,
              serverMemoryUnit,
              anvilTotalAllocatedCPUCores,
              anvilTotalAvailableCPUCores,
              storageGroupUUID,
              storageGroupName,
              storageGroupSize,
              storageGroupFree,
              fileUUID,
              fileName,
            ],
            index,
          ) => {
            if (index === lasti || (puuid.length && anvilUUID !== puuid)) {
              const { [puuid]: p } = previous;

              p.anvilTotalAllocatedMemory = String(anvilTotalAllocatedMemory);
              p.anvilTotalAvailableMemory = String(
                BigInt(p.anvilTotalMemory) -
                  anvilTotalAllocatedMemory -
                  BigInt(NODE_AND_DR_RESERVED_MEMORY_SIZE),
              );
              p.files = Object.values(files);
              p.hosts = Object.values(hosts);
              p.servers = Object.values(servers);
              p.storageGroups = Object.values(stores);

              anvilTotalAllocatedMemory = BigInt(0);
              files = {};
              hosts = {};
              servers = {};
              stores = {};
            }

            if (anvilUUID && !previous[anvilUUID]) {
              previous[anvilUUID] = {
                anvilUUID,
                anvilName,
                anvilDescription,
                anvilTotalCPUCores: Number(anvilTotalCPUCores),
                anvilTotalMemory: String(anvilTotalMemory),
                anvilTotalAllocatedCPUCores: Number(
                  anvilTotalAllocatedCPUCores,
                ),
                anvilTotalAvailableCPUCores: Number(
                  anvilTotalAvailableCPUCores,
                ),
              } as AnvilDetailForProvisionServer;

              puuid = anvilUUID;
            }

            if (hostUUID && !hosts[hostUUID]) {
              hosts[hostUUID] = {
                hostUUID,
                hostName,
                hostCPUCores: Number(hostCPUCores),
                hostMemory: String(hostMemory),
              };
            }

            if (serverUUID && !servers[serverUUID]) {
              const serverMemory =
                dSize(serverMemoryValue, {
                  fromUnit: serverMemoryUnit,
                  toUnit: 'B',
                })?.value ?? '0';

              anvilTotalAllocatedMemory += BigInt(serverMemory);

              servers[serverUUID] = {
                serverUUID,
                serverName,
                serverCPUCores: Number(serverCPUCores),
                serverMemory,
              };
            }

            if (storageGroupUUID && !stores[storageGroupUUID]) {
              stores[storageGroupUUID] = {
                storageGroupUUID,
                storageGroupName,
                storageGroupSize: String(storageGroupSize),
                storageGroupFree: String(storageGroupFree),
              };
            }

            if (fileUUID && !files[fileUUID]) {
              files[fileUUID] = {
                fileUUID,
                fileName,
              };
            }

            return previous;
          },
          {},
        );

        results = {
          anvils: Object.values(anvils),
          oses: OS_LIST_MAP,
        };
      }

      return results;
    };
  }

  return {
    query,
    afterQueryReturn,
  };
};

export default buildQueryAnvilDetail;
