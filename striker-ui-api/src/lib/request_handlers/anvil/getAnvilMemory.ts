import { RequestHandler } from 'express';

import { NODE_AND_DR_RESERVED_MEMORY_SIZE } from '../../consts';

import { query } from '../../accessModule';
import { stderr } from '../../shell';

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
    stderr(`Failed to get anvil ${anvilUuid} memory info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const {
    0: { 1: rTotal },
  } = hostMemoryRows;

  if (rTotal === null) return response.status(404).send();

  const total = Number.parseInt(rTotal);

  const hosts: AnvilDetailHostMemory[] =
    hostMemoryRows.map<AnvilDetailHostMemory>(
      ([host_uuid, , mtotal, mfree, stotal, sfree]) => ({
        free: Number.parseInt(mfree),
        host_uuid,
        swap_free: Number.parseInt(sfree),
        swap_total: Number.parseInt(stotal),
        total: Number.parseInt(mtotal),
      }),
    );

  return response.status(200).send({
    hosts,
    reserved: NODE_AND_DR_RESERVED_MEMORY_SIZE,
    total,
  });
};
