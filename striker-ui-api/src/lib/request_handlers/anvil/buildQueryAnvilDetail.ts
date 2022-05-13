import { execSync } from 'child_process';

import NODE_AND_DR_RESERVED_MEMORY_SIZE from '../../consts/NODE_AND_DR_RESERVED_MEMORY_SIZE';
import SERVER_PATHS from '../../consts/SERVER_PATHS';

import join from '../../join';

const buildQueryAnvilDetail = ({
  anvilUUIDs,
  isForProvisionServer,
}: {
  anvilUUIDs?: string[] | '*';
  isForProvisionServer?: boolean;
}) => {
  const condAnvilsUUID = join(anvilUUIDs, {
    beforeReturn: (toReturn) =>
      toReturn ? `WHERE anv.anvil_uuid IN (${toReturn})` : '',
    elementWrapper: "'",
    separator: ', ',
  });

  console.log(`condAnvilsUUID=[${condAnvilsUUID}]`);

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
          anvil_node2_host_uuid,
          anvil_dr1_host_uuid
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
      server_memory`;
    let groupByPhrase = '';

    if (isSummary) {
      fieldsToSelect = `
        SUM(server_cpu_cores) AS anvil_total_allocated_cpu_cores,
        SUM(server_memory) AS anvil_total_allocated_memory`;

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
          server_cpu_cores,
          CASE server_memory_unit
            WHEN 'KiB' THEN server_memory_value * 1024
            ELSE server_memory_value
          END AS server_memory
        FROM (
          SELECT
            server_definition_server_uuid,
            CAST(
              SUBSTRING(
                server_definition_xml, '%cores=''#"[0-9]+#"''%', '#'
              ) AS INTEGER
            ) AS server_cpu_cores,
            CAST(
              SUBSTRING(
                server_definition_xml, '%memory%>#"[0-9]+#"</memory%', '#'
              ) AS BIGINT
            ) AS server_memory_value,
            SUBSTRING(
              server_definition_xml, '%memory%unit=''#"[A-Za-z]+#"''%', '#'
            ) AS server_memory_unit
          FROM server_definitions AS ser_def
        ) AS ser_def_memory_converted
      ) AS pos_ser_def
        ON server_uuid = server_definition_server_uuid
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
      file_location_anvil_uuid,
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
      server_list.server_memory,
      server_summary.anvil_total_allocated_cpu_cores,
      server_summary.anvil_total_allocated_memory,
      (host_summary.anvil_total_cpu_cores
          - server_summary.anvil_total_allocated_cpu_cores
        ) AS anvil_total_available_cpu_cores,
      (host_summary.anvil_total_memory
          - server_summary.anvil_total_allocated_memory
          - ${NODE_AND_DR_RESERVED_MEMORY_SIZE}
        ) AS anvil_total_available_memory,
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
      ON anv.anvil_uuid = file_list.file_location_anvil_uuid
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

    afterQueryReturn = (queryStdout: unknown) => {
      let results = queryStdout;

      if (queryStdout instanceof Array) {
        let rowStage: AnvilDetailForProvisionServer | undefined;

        const anvils = queryStdout.reduce<AnvilDetailForProvisionServer[]>(
          (
            reducedRows,
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
              serverMemory,
              anvilTotalAllocatedCPUCores,
              anvilTotalAllocatedMemory,
              anvilTotalAvailableCPUCores,
              anvilTotalAvailableMemory,
              storageGroupUUID,
              storageGroupName,
              storageGroupSize,
              storageGroupFree,
              fileUUID,
              fileName,
            ],
          ) => {
            if (!rowStage || anvilUUID !== rowStage.anvilUUID) {
              rowStage = {
                anvilUUID,
                anvilName,
                anvilDescription,
                anvilTotalCPUCores: parseInt(anvilTotalCPUCores),
                anvilTotalMemory: String(anvilTotalMemory),
                anvilTotalAllocatedCPUCores: parseInt(
                  anvilTotalAllocatedCPUCores,
                ),
                anvilTotalAllocatedMemory: String(anvilTotalAllocatedMemory),
                anvilTotalAvailableCPUCores: parseInt(
                  anvilTotalAvailableCPUCores,
                ),
                anvilTotalAvailableMemory: String(anvilTotalAvailableMemory),
                hosts: [],
                servers: [],
                storageGroups: [],
                files: [],
              };

              reducedRows.push(rowStage);
            }

            if (
              !rowStage.hosts.find(({ hostUUID: added }) => added === hostUUID)
            ) {
              rowStage.hosts.push({
                hostUUID,
                hostName,
                hostCPUCores: parseInt(hostCPUCores),
                hostMemory: String(hostMemory),
              });
            }

            if (
              !rowStage.servers.find(
                ({ serverUUID: added }) => added === serverUUID,
              )
            ) {
              rowStage.servers.push({
                serverUUID,
                serverName,
                serverCPUCores: parseInt(serverCPUCores),
                serverMemory: String(serverMemory),
              });
            }

            if (
              !rowStage.storageGroups.find(
                ({ storageGroupUUID: added }) => added === storageGroupUUID,
              )
            ) {
              rowStage.storageGroups.push({
                storageGroupUUID,
                storageGroupName,
                storageGroupSize: String(storageGroupSize),
                storageGroupFree: String(storageGroupFree),
              });
            }

            if (
              !rowStage.files.find(({ fileUUID: added }) => added === fileUUID)
            ) {
              rowStage.files.push({
                fileUUID,
                fileName,
              });
            }

            return reducedRows;
          },
          [],
        );

        const osList = execSync(
          `${SERVER_PATHS.usr.sbin['striker-parse-os-list'].self} | ${SERVER_PATHS.usr.bin['sed'].self} -E 's/^.*name="([^"]+).*CDATA[[]([^]]+).*$/\\1,\\2/'`,
          { encoding: 'utf-8', timeout: 10000 },
        ).split('\n');

        osList.pop();

        results = {
          anvils,
          osList,
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
