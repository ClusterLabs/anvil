import assert from 'assert';

import { job, query } from '../../accessModule';
import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { linkDrFrom } from '../../drLink';
import { serverSetProtectRequestBodySchema } from './schemas';
import { perr } from '../../shell';
import {
  sqlHosts,
  sqlScanLvmLvs,
  sqlScanLvmVgs,
  sqlServers,
  sqlStorageGroupMembers,
  sqlStorageGroups,
} from '../../sqls';

export const setServerProtect =
  buildServerUpdateHandler<ServerSetProtectRequestBody>(
    async ({ body }) => {
      await serverSetProtectRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { lvmVgUuid, operation, protocol } = body;

      const command = sbin['anvil-manage-dr'].self;

      const commandArgs = ['--server', server.uuid, `--${operation}`];

      if (operation === 'protect' && lvmVgUuid) {
        const sqlGetDr = `
          SELECT b.host_uuid
          FROM (${sqlScanLvmVgs()}) AS a
          JOIN (${sqlHosts()} AND host_type = 'dr') AS b
            ON b.host_uuid = a.scan_lvm_vg_host_uuid
          WHERE a.scan_lvm_vg_internal_uuid = '${lvmVgUuid}';`;

        let drRows: [[string]];

        try {
          drRows = await query(sqlGetDr);

          assert.ok(drRows.length, 'No record');
        } catch (error) {
          perr(
            `Failed to get DR host from volume group [${lvmVgUuid}]; CAUSE: ${error}`,
          );

          throw error;
        }

        const [[drUuid]] = drRows;

        commandArgs.push('--dr-host', drUuid);

        try {
          linkDrFrom(server.anvil.uuid, { drUuid });
        } catch (error) {
          perr(`Failed to link DR host [${drUuid}]; CAUSE: ${error}`);

          throw error;
        }

        const sqlGetSg = `
          SELECT DISTINCT(e.storage_group_name) AS sg_name
          FROM (
            ${sqlServers()} AND server_uuid = '${server.uuid}'
          ) AS a
          JOIN (${sqlScanLvmLvs()}) AS b
            ON b.scan_lvm_lv_name LIKE CONCAT(a.server_name, '%')
          JOIN (${sqlScanLvmVgs()}) AS c
            ON
                c.scan_lvm_vg_host_uuid = b.scan_lvm_lv_host_uuid
              AND
                c.scan_lvm_vg_name = b.scan_lvm_lv_on_vg
          JOIN (${sqlStorageGroupMembers()}) AS d
            ON d.storage_group_member_vg_uuid = c.scan_lvm_vg_internal_uuid
          JOIN (${sqlStorageGroups()}) AS e
            ON e.storage_group_uuid = d.storage_group_member_storage_group_uuid;`;

        let sgRows: [[string]];

        try {
          sgRows = await query(sqlGetSg);

          assert.ok(sgRows.length, 'No record');
        } catch (error) {
          perr(
            `Failed to get storage group name from server [${server.name}]; CAUSE: ${error}`,
          );

          throw error;
        }

        const [[sgName]] = sgRows;

        try {
          await job({
            file: __filename,
            job_command: [
              sbin['anvil-manage-storage-groups'].self,
              '--anvil',
              `'${server.anvil.uuid}'`,
              '--group',
              `'${sgName}'`,
              '--add',
              '--member',
              `'${lvmVgUuid}'`,
            ].join(' '),
            job_description: 'job_0534',
            job_host_uuid: server.host.uuid,
            job_name: `storage-group-member::add::${lvmVgUuid}`,
            job_title: 'job_0533',
          });
        } catch (error) {
          perr(
            `Failed to add member [${lvmVgUuid}] to storage group [${sgName}]; CAUSE: ${error}`,
          );

          throw error;
        }
      }

      if (protocol) {
        commandArgs.push('--protocol', protocol);
      }

      return {
        file: __filename,
        job_command: [command, ...commandArgs].join(' '),
        job_description: 'job_0384',
        job_host_uuid: server.host.uuid,
        job_name: `dr::${operation}`,
        job_title: 'job_0385',
      };
    },
  );
