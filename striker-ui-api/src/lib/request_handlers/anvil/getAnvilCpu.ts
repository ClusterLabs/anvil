import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { query } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { perr } from '../../shell';

export const getAnvilCpu: RequestHandler<AnvilDetailParamsDictionary> = async (
  request,
  response,
) => {
  const {
    params: { anvilUuid },
  } = request;

  let rCpus: [
    hostUuid: string,
    hostName: string,
    cpuModel: string,
    cpuCores: string,
    cpuThreads: string,
    cpuMinCores: string,
    cpuMinThreads: string,
  ][];

  try {
    rCpus = await query(
      `SELECT
          b.host_uuid,
          b.host_name,
          c.scan_hardware_cpu_model,
          c.scan_hardware_cpu_cores,
          c.scan_hardware_cpu_threads,
          MIN(c.scan_hardware_cpu_cores) AS cores,
          MIN(c.scan_hardware_cpu_threads) AS threads
        FROM anvils AS a
        JOIN hosts AS b
          ON b.host_uuid IN (
            a.anvil_node1_host_uuid,
            a.anvil_node2_host_uuid
          )
        JOIN scan_hardware AS c
          ON b.host_uuid = c.scan_hardware_host_uuid
        WHERE a.anvil_uuid = '${anvilUuid}'
        GROUP BY
          b.host_uuid,
          b.host_name,
          c.scan_hardware_cpu_model,
          c.scan_hardware_cpu_cores,
          c.scan_hardware_cpu_threads
        ORDER BY b.host_name;`,
    );
  } catch (error) {
    perr(`Failed to get anvil ${anvilUuid} cpu info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  if (!rCpus.length) return response.status(404).send();

  let rAllocatedRow: [cpuAllocated: string][];

  try {
    rAllocatedRow = await query(
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
        WHERE a.server_state != '${DELETED}'
          AND a.server_anvil_uuid = '${anvilUuid}';`,
    );
  } catch (error) {
    perr(`Failed to get anvil ${anvilUuid} server cpu info; CAUSE: ${error}`);

    return response.status(500).send();
  }

  if (!rAllocatedRow.length) return response.status(404).send();

  const {
    0: { 5: rMinCores, 6: rMinThreads },
  } = rCpus;

  const minCores = Number(rMinCores);
  const minThreads = Number(rMinThreads);

  const [[rAllocated]] = rAllocatedRow;

  const allocated = Number(rAllocated);

  const rsBody = rCpus.reduce<AnvilDetailCpuSummary>(
    (previous, current) => {
      const { 0: uuid, 1: name, 2: model, 3: rCores, 4: rThreads } = current;

      const cores = Number(rCores);
      const threads = Number(rThreads);
      const matched = model.match(/amd|arm|intel|powerpc/i);
      const vendor = matched ? matched[0] : model.replace(/^(\w+).*$/, '$1');

      previous.hosts[uuid] = {
        cores,
        model,
        name: getShortHostName(name),
        threads,
        uuid,
        vendor,
      };

      return previous;
    },
    {
      allocated,
      cores: minCores,
      hosts: {},
      threads: minThreads,
    },
  );

  response.status(200).send(rsBody);
};
