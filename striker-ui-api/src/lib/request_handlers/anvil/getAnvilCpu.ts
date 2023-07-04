import { RequestHandler } from 'express';

import { query } from '../../accessModule';
import { stderr } from '../../shell';

export const getAnvilCpu: RequestHandler<AnvilDetailParamsDictionary> = async (
  request,
  response,
) => {
  const {
    params: { anvilUuid },
  } = request;

  let rCores: null | string;
  let rThreads: null | string;

  try {
    [[rCores = '', rThreads = '']] = await query<
      [[cpuCores: null | string, cpuThreads: null | string]]
    >(
      `SELECT
          MIN(c.scan_hardware_cpu_cores) AS cores,
          MIN(c.scan_hardware_cpu_threads) AS threads
        FROM anvils AS a
        JOIN hosts AS b
          ON b.host_uuid IN (
            a.anvil_node1_host_uuid,
            a.anvil_node2_host_uuid,
            a.anvil_dr1_host_uuid
          )
        JOIN scan_hardware AS c
          ON b.host_uuid = c.scan_hardware_host_uuid
        WHERE a.anvil_uuid = '${anvilUuid}';`,
    );
  } catch (error) {
    stderr(`Failed to get anvil ${anvilUuid} cpu info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const cores = Number.parseInt(rCores);
  const threads = Number.parseInt(rThreads);

  let rAllocated: null | string;

  try {
    [[rAllocated = '']] = await query<[[cpuAllocated: null | string]]>(
      `SELECT
          SUM(
            CAST(
              SUBSTRING(
                b.server_definition_xml, 'cores=''([\\d]*)'''
              ) AS INTEGER
            )
          ) AS allocated
        FROM servers AS a
        JOIN server_definitions AS b
          ON a.server_uuid = b.server_definition_server_uuid
        WHERE a.server_anvil_uuid = '${anvilUuid}';`,
    );
  } catch (error) {
    stderr(`Failed to get anvil ${anvilUuid} server cpu info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const allocated = Number.parseInt(rAllocated);

  response.status(200).send({
    allocated,
    cores,
    threads,
  });
};
