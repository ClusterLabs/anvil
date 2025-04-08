import assert from 'assert';
import { RequestHandler } from 'express';

import { DELETED, REP_UUID } from '../../consts';

import { query } from '../../accessModule';
import { sanitize } from '../../sanitize';
import { perr } from '../../shell';

export const getAnvilStorageGroup: RequestHandler<
  AnvilDetailParamsDictionary
> = async (request, response) => {
  const {
    params: { anvilUuid: rAnUuid },
  } = request;

  const anUuid = sanitize(rAnUuid, 'string', { modifierType: 'sql' });

  try {
    assert(
      REP_UUID.test(anUuid),
      `Param UUID must be a valid UUIDv4; got [${anUuid}]`,
    );
  } catch (error) {
    perr(`Failed to assert value during get anvil storage; CAUSE: ${error}`);

    return response.status(400).send();
  }

  let rows: [
    uuid: string,
    name: string,
    size: string,
    free: string,
    totalSize: string,
    totalFree: string,
  ][];

  try {
    rows = await query(
      `SELECT
          DISTINCT ON (b.storage_group_uuid) storage_group_uuid,
          b.storage_group_name,
          d.scan_lvm_vg_size,
          d.scan_lvm_vg_free,
          MIN(d.scan_lvm_vg_size) AS total_vg_size,
          MIN(d.scan_lvm_vg_free) AS total_vg_free
        FROM anvils AS a
        JOIN storage_groups AS b
          ON a.anvil_uuid = b.storage_group_anvil_uuid
        JOIN storage_group_members AS c
          ON b.storage_group_uuid = c.storage_group_member_storage_group_uuid
        JOIN scan_lvm_vgs AS d
          ON c.storage_group_member_vg_uuid = d.scan_lvm_vg_internal_uuid
        WHERE
            a.anvil_uuid = '${anUuid}'
          AND
            b.storage_group_name != '${DELETED}'
          AND
            d.scan_lvm_vg_name != '${DELETED}'
        GROUP BY
          b.storage_group_uuid,
          b.storage_group_name,
          d.scan_lvm_vg_size,
          d.scan_lvm_vg_free
        ORDER BY b.storage_group_uuid, d.scan_lvm_vg_free;`,
    );
  } catch (error) {
    perr(`Failed to get anvil storage summary; CAUSE: ${error}`);

    return response.status(500).send();
  }

  if (!rows.length) return response.status(404).send();

  const {
    0: { 4: totalSize, 5: totalFree },
  } = rows;

  const rsbody: AnvilDetailStoreSummary = {
    storage_groups: rows.map<AnvilDetailStore>(
      ([sgUuid, sgName, sgSize, sgFree]) => ({
        storage_group_free: sgFree,
        storage_group_name: sgName,
        storage_group_total: sgSize,
        storage_group_uuid: sgUuid,
      }),
    ),
    total_free: totalFree,
    total_size: totalSize,
  };

  return response.json(rsbody);
};
