import { RequestHandler } from 'express';

import { query } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import join from '../../join';
import { Responder } from '../../Responder';
import { perr } from '../../shell';
import {
  sqlHosts,
  sqlScanLvmVgs,
  sqlStorageGroupMembers,
  sqlStorageGroups,
} from '../../sqls';

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
    hosts: {},
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
          MIN(
            COALESCE(c.scan_lvm_vg_size, 0)
          ) AS min_sg_size,
          MIN(
            COALESCE(c.scan_lvm_vg_free, 0)
          ) AS min_sg_free
        FROM (${sqlStorageGroups()}) AS a
        LEFT JOIN (${sqlStorageGroupMembers()}) AS b
          ON a.storage_group_uuid = b.storage_group_member_storage_group_uuid
        LEFT JOIN (${sqlScanLvmVgs()}) AS c
          ON b.storage_group_member_vg_uuid = c.scan_lvm_vg_internal_uuid
        WHERE a.storage_group_anvil_uuid = '${anvilUuid}'
        GROUP BY
          a.storage_group_uuid,
          a.storage_group_name
        ORDER BY a.storage_group_name;`,
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
      perr(
        `Failed to calculate storage group [${name}] sizes, skipping; CAUSE: ${error}`,
      );

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
          a.host_uuid,
          a.host_name
        FROM (${sqlHosts()}) AS a
        LEFT JOIN anvils AS b
          ON
            a.host_uuid in (
              b.anvil_node1_host_uuid,
              b.anvil_node2_host_uuid
            )
        WHERE
            a.host_type = 'dr'
          OR
            b.anvil_uuid = '${anvilUuid}'
        ORDER BY
          a.host_type DESC,
          a.host_name;`,
    );
  } catch (error) {
    return respond.s500('b22ef49', `Failed to get hosts; CAUSE: ${error}`);
  }

  rows.forEach((row) => {
    const [uuid, name] = row;

    const short = getShortHostName(name);

    storages.hosts[uuid] = {
      name,
      short,
      uuid,
    };
  });

  const hostUuidsCsv = join(Object.keys(storages.hosts), {
    elementWrapper: "'",
    separator: ', ',
  });

  try {
    rows = await query(
      `SELECT
          a.scan_lvm_vg_uuid,
          a.scan_lvm_vg_internal_uuid,
          a.scan_lvm_vg_name,
          a.scan_lvm_vg_size,
          a.scan_lvm_vg_free,
          a.scan_lvm_vg_host_uuid,
          b.storage_group_member_uuid,
          c.storage_group_uuid
        FROM (${sqlScanLvmVgs()}) AS a
        LEFT JOIN (${sqlStorageGroupMembers()}) AS b
          ON a.scan_lvm_vg_internal_uuid = b.storage_group_member_vg_uuid
        LEFT JOIN (${sqlStorageGroups()}) AS c
          ON b.storage_group_member_storage_group_uuid = c.storage_group_uuid
        WHERE a.scan_lvm_vg_host_uuid IN (${hostUuidsCsv})
        ORDER BY a.scan_lvm_vg_name;`,
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
      perr(
        `Failed to calculate volume group [${vgName}] sizes, skipping; CAUSE: ${error}`,
      );

      return;
    }

    const vg: AnvilDetailVolumeGroup = {
      free: vgFree,
      host: hostUuid,
      internalUuid: vgInternalUuid,
      name: vgName,
      size: vgSize,
      used: String(vgnUsed),
      uuid: vgUuid,
    };

    // Add this volume group to the list.
    storages.volumeGroups[vgUuid] = vg;

    if (!sgUuid) {
      // This volume group is not part of any storage group; list it as unused.
      storages.unusedVolumeGroups.push(vgUuid);

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
