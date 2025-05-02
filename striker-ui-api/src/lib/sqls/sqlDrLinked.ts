import join from '../join';
import { sqlDrLinks } from './sqlDrLinks';
import { sqlHosts } from './sqlHosts';
import { sqlScanLvmVgs } from './sqlScanLvmVgs';
import { sqlStorageGroupMembers } from './sqlStorageGroupMembers';
import { sqlStorageGroups } from './sqlStorageGroups';

export const sqlDrLinked = (anvilUuid: string, sqlHostUuids: string) => {
  const sql = `
    SELECT
      a.host_uuid,
      b.dr_link_uuid IS NOT NULL AS dr_linked,
      COUNT(c.storage_group_member_uuid) AS dr_members
    FROM (${sqlHosts()}) AS a
    LEFT JOIN (${sqlDrLinks()}) AS b
      ON
          b.dr_link_anvil_uuid = '${anvilUuid}'
        AND
          b.dr_link_host_uuid = a.host_uuid
    LEFT JOIN (${sqlStorageGroupMembers()}) AS c
      ON c.storage_group_member_host_uuid = a.host_uuid
    WHERE
        a.host_type = 'dr'
      AND
        a.host_uuid IN (${sqlHostUuids})
    GROUP BY
      a.host_uuid,
      b.dr_link_uuid;`;

  return sql;
};

export const sqlDrLinkedFromVg = (anvilUuid: string, lvmVgUuids: string[]) => {
  const lvmVgUuidsCsv = join(lvmVgUuids, {
    elementWrapper: "'",
    separator: ', ',
  });

  const sqlHostUuids = `
    SELECT a.scan_lvm_vg_host_uuid
    FROM (${sqlScanLvmVgs()}) AS a
    WHERE a.scan_lvm_vg_internal_uuid IN (${lvmVgUuidsCsv})`;

  const sql = sqlDrLinked(anvilUuid, sqlHostUuids);

  return sql;
};

export const sqlDrLinkedFromSg = (
  anvilUuid: string,
  sgValue: string,
  sgKey = 'uuid',
) => {
  const sqlHostUuids = `
    SELECT b.storage_group_member_host_uuid
    FROM (${sqlStorageGroups()}) AS a
    LEFT JOIN (${sqlStorageGroupMembers()}) AS b
      ON b.storage_group_member_storage_group_uuid = a.storage_group_uuid
    WHERE a.storage_group_${sgKey} = '${sgValue}'`;

  const sql = sqlDrLinked(anvilUuid, sqlHostUuids);

  return sql;
};
