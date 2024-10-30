import { RequestHandler } from 'express';
import { DataSizeUnit, dSize } from 'format-data-size';

import { DELETED, NODE_AND_DR_RESERVED_MEMORY_SIZE } from '../../consts';

import { query } from '../../accessModule';
import { perr } from '../../shell';

export const getAnvilMemory: RequestHandler<
  AnvilDetailParamsDictionary
> = async (request, response) => {
  const {
    params: { anvilUuid },
  } = request;

  let hostMemoryRows: [
    hostUuid: string,
    minMemoryTotal: null | string,
    hostMemoryTotal: string,
    hostMemoryFree: string,
    hostSwapTotal: string,
    hostSwapFree: string,
  ][];

  try {
    hostMemoryRows = await query(
      `SELECT
          b.host_uuid,
          MIN(c.scan_hardware_ram_total) AS min_memory_total,
          c.scan_hardware_ram_total,
          c.scan_hardware_memory_free,
          c.scan_hardware_swap_total,
          c.scan_hardware_swap_free
        FROM anvils AS a
        JOIN hosts AS b
          ON b.host_uuid IN (
            a.anvil_node1_host_uuid,
            a.anvil_node2_host_uuid,
            a.anvil_dr1_host_uuid
          )
        JOIN scan_hardware AS c
          ON b.host_uuid = c.scan_hardware_host_uuid
        WHERE a.anvil_uuid = '${anvilUuid}'
        GROUP BY
          b.host_uuid,
          c.scan_hardware_ram_total,
          c.scan_hardware_memory_free,
          c.scan_hardware_swap_total,
          c.scan_hardware_swap_free
        ORDER BY b.host_name;`,
    );
  } catch (error) {
    perr(`Failed to get anvil ${anvilUuid} memory info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const {
    0: { 1: minTotal },
  } = hostMemoryRows;

  if (minTotal === null) return response.status(404).send();

  const hosts: AnvilDetailHostMemory[] =
    hostMemoryRows.map<AnvilDetailHostMemory>(
      ([host_uuid, , total, free, swap_total, swap_free]) => ({
        free,
        host_uuid,
        swap_free,
        swap_total,
        total,
      }),
    );

  let serverMemoryRows: [serverMemoryValue: string, serverMemoryUnit: string][];

  try {
    serverMemoryRows = await query(
      `SELECT
          CAST(
            SUBSTRING(
              a.server_definition_xml, 'memory.*>([\\d]*)</memory'
            ) AS BIGINT
          ) AS server_memory_value,
          SUBSTRING(
            a.server_definition_xml, 'memory.*unit=''([A-Za-z]*)'''
          ) AS server_memory_unit
        FROM server_definitions AS a
        JOIN servers AS b
          ON b.server_uuid = a.server_definition_server_uuid
        WHERE b.server_state != '${DELETED}'
          AND b.server_anvil_uuid = '${anvilUuid}';`,
    );
  } catch (error) {
    perr(`Failed to get anvil ${anvilUuid} server info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  let allocated = '0';

  if (serverMemoryRows.length > 0) {
    allocated = String(
      serverMemoryRows.reduce<bigint>((previous, [mvalue, munit]) => {
        const serverMemory =
          dSize(mvalue, {
            fromUnit: munit as DataSizeUnit,
            toUnit: 'B',
          })?.value ?? '0';

        return previous + BigInt(serverMemory);
      }, BigInt(0)),
    );
  }

  const available = String(
    BigInt(minTotal) -
      BigInt(allocated) -
      BigInt(NODE_AND_DR_RESERVED_MEMORY_SIZE),
  );

  return response.status(200).send({
    allocated,
    available,
    hosts,
    reserved: String(NODE_AND_DR_RESERVED_MEMORY_SIZE),
    total: minTotal,
  });
};
