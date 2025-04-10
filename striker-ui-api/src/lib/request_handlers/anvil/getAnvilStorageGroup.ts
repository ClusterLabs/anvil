import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import { query } from '../../accessModule';
import { getShortHostName } from '../../disassembleHostName';
import { Responder } from '../../Responder';

export const getAnvilStorageGroup: RequestHandler<
  Express.RhParamsDictionary,
  AnvilDetailStorageGroupList,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const anvilUuid = response.locals.target.uuid;

  let rows: string[][];

  const storageGroups: AnvilDetailStorageGroupList = {};

  try {
    rows = await query(
      `SELECT
          a.storage_group_uuid,
          a.storage_group_name,
          MIN(d.scan_lvm_vg_size) AS sg_size,
          MIN(d.scan_lvm_vg_free) AS sg_free
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
          d.scan_lvm_vg_size,
          d.scan_lvm_vg_free
        ORDER BY
          a.storage_group_name;`,
    );
  } catch (error) {
    return respond.s500(
      '313ce33',
      `Failed to get storage groups; CAUSE: ${error}`,
    );
  }

  rows.forEach((row) => {
    const [uuid, name, sgSize, sgFree] = row;

    let sgnUsed: bigint;

    try {
      const sgnFree = BigInt(sgFree);
      const sgnSize = BigInt(sgSize);

      sgnUsed = sgnSize - sgnFree;
    } catch (error) {
      // Something's wrong with the storage group's sizes; ignore.
      return;
    }

    storageGroups[uuid] = {
      free: sgFree,
      members: {},
      name,
      total: sgSize,
      used: String(sgnUsed),
      uuid,
    };
  });

  try {
    rows = await query(
      `SELECT
          a.storage_group_member_uuid,
          a.storage_group_member_storage_group_uuid,
          b.scan_lvm_vg_uuid,
          b.scan_lvm_vg_internal_uuid,
          b.scan_lvm_vg_name,
          b.scan_lvm_vg_size,
          b.scan_lvm_vg_free,
          c.host_uuid,
          c.host_name
        FROM storage_group_members AS a
        JOIN scan_lvm_vgs AS b
          ON a.storage_group_member_vg_uuid = b.scan_lvm_vg_internal_uuid
        JOIN hosts AS c
          ON a.storage_group_member_host_uuid = c.host_uuid
        WHERE b.scan_lvm_vg_name != '${DELETED}';`,
    );
  } catch (error) {
    return respond.s500(
      '56f0e7b',
      `Failed to get storage group members; CAUSE: ${error}`,
    );
  }

  rows.forEach((row) => {
    const [
      sgmUuid,
      sgUuid,
      vgUuid,
      vgInternalUuid,
      vgName,
      vgSize,
      vgFree,
      hostUuid,
      hostName,
    ] = row;

    const { [sgUuid]: sg } = storageGroups;

    if (!sg) {
      return;
    }

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

    sg.members[sgmUuid] = {
      volumeGroup: {
        free: vgFree,
        internalUuid: vgInternalUuid,
        name: vgName,
        size: vgSize,
        used: String(vgnUsed),
        uuid: vgUuid,
      },
      host: {
        name: hostName,
        short: shortHostName,
        uuid: hostUuid,
      },
      uuid: sgmUuid,
    };
  });

  return respond.s200(storageGroups);
};
