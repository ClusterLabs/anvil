import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { query } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { Responder } from '../../Responder';

export const getAnvilStorage: RequestHandler<
  Express.RhParamsDictionary,
  AnvilDetailStorageList,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const anvilUuid = response.locals.target.uuid;

  let rows: string[][];

  const storages: AnvilDetailStorageList = {
    storageGroups: {},
    storageGroupTotals: {
      free: '',
      size: '',
      used: '',
    },
    unusedVolumeGroups: [],
    volumeGroups: {},
  };

  try {
    rows = await query(
      `SELECT
          a.storage_group_uuid,
          a.storage_group_name,
          MIN(c.scan_lvm_vg_size) AS sg_size,
          MIN(c.scan_lvm_vg_free) AS sg_free
        FROM storage_groups AS a
        JOIN storage_group_members AS b
          ON a.storage_group_uuid = b.storage_group_member_storage_group_uuid
        JOIN scan_lvm_vgs AS c
          ON b.storage_group_member_vg_uuid = c.scan_lvm_vg_internal_uuid
        WHERE
            a.storage_group_anvil_uuid = '${anvilUuid}'
          AND
            a.storage_group_name != '${DELETED}'
          AND
            c.scan_lvm_vg_name != '${DELETED}'
        GROUP BY
          a.storage_group_uuid,
          a.storage_group_name,
          c.scan_lvm_vg_size,
          c.scan_lvm_vg_free
        ORDER BY
          a.storage_group_name;`,
    );
  } catch (error) {
    return respond.s500(
      '313ce33',
      `Failed to get storage groups; CAUSE: ${error}`,
    );
  }

  const totals: {
    free: bigint;
    size: bigint;
    used: bigint;
  } = {
    free: BigInt(0),
    size: BigInt(0),
    used: BigInt(0),
  };

  rows.forEach((row) => {
    const [uuid, name, sgSize, sgFree] = row;

    let sgnUsed: bigint;

    try {
      const sgnFree = BigInt(sgFree);
      const sgnSize = BigInt(sgSize);

      sgnUsed = sgnSize - sgnFree;

      totals.free += sgnFree;
      totals.size += sgnSize;
      totals.used += sgnUsed;
    } catch (error) {
      // Something's wrong with the storage group's sizes; ignore.
      return;
    }

    storages.storageGroups[uuid] = {
      free: sgFree,
      members: {},
      name,
      size: sgSize,
      used: String(sgnUsed),
      uuid,
    };
  });

  storages.storageGroupTotals.free = String(totals.free);
  storages.storageGroupTotals.size = String(totals.size);
  storages.storageGroupTotals.used = String(totals.used);

  try {
    rows = await query(
      `SELECT
          a.scan_lvm_vg_uuid,
          a.scan_lvm_vg_internal_uuid,
          a.scan_lvm_vg_name,
          a.scan_lvm_vg_size,
          a.scan_lvm_vg_free,
          b.host_uuid,
          b.host_name,
          c.storage_group_member_uuid,
          c.storage_group_member_storage_group_uuid
        FROM scan_lvm_vgs AS a
        JOIN hosts AS b
          ON a.scan_lvm_vg_host_uuid = b.host_uuid
        LEFT JOIN storage_group_members AS c
          ON a.scan_lvm_vg_internal_uuid = c.storage_group_member_vg_uuid
        WHERE
            a.scan_lvm_vg_name != '${DELETED}'
          AND
            a.scan_lvm_vg_host_uuid IN (
              SELECT
                a.host_uuid
              FROM hosts AS a
              LEFT JOIN anvils AS b
                ON
                    a.host_uuid in (
                      b.anvil_node1_host_uuid,
                      b.anvil_node2_host_uuid
                    )
                  AND
                    b.anvil_uuid = '${anvilUuid}'
              WHERE
                a.host_type in ('dr', 'node')
            );`,
    );
  } catch (error) {
    return respond.s500(
      '56f0e7b',
      `Failed to get storage group members; CAUSE: ${error}`,
    );
  }

  rows.forEach((row) => {
    const [
      vgUuid,
      vgInternalUuid,
      vgName,
      vgSize,
      vgFree,
      hostUuid,
      hostName,
      sgmUuid,
      sgUuid,
    ] = row;

    let vgnUsed: bigint;

    try {
      const vgnFree = BigInt(vgFree);
      const vgnSize = BigInt(vgSize);

      vgnUsed = vgnSize - vgnFree;
    } catch (error) {
      // Something's wrong with the member's sizes; ignore.
      return;
    }

    const shortHostName = getShortHostName(hostName);

    const vg: AnvilDetailVolumeGroup = {
      free: vgFree,
      host: {
        name: hostName,
        short: shortHostName,
        uuid: hostUuid,
      },
      internalUuid: vgInternalUuid,
      name: vgName,
      size: vgSize,
      used: String(vgnUsed),
      uuid: vgUuid,
    };

    // Add this volume group to the list.
    storages.volumeGroups[vgUuid] = vg;

    if (!sgUuid) {
      // This volume group is not part of any storage group; don't continue.
      return;
    }

    const { [sgUuid]: sg } = storages.storageGroups;

    if (!sg) {
      // This vg is part of a storage group which is likely marked as DELETED; ignore.
      return;
    }

    sg.members[sgmUuid] = {
      volumeGroup: vgUuid,
      uuid: sgmUuid,
    };
  });

  return respond.s200(storages);
};
