import { RequestHandler } from 'express';
import path from 'path';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { sanitize } from '../../sanitize';

export const getFileDetail: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const { fileUUID: rFileUuid } = request.params;

    const fileUuid = sanitize(rFileUuid, 'string', {
      modifierType: 'sql',
    });

    const query = `
      SELECT
        a.file_uuid,
        a.file_name,
        a.file_size,
        a.file_type,
        a.file_md5sum,
        a.file_directory,
        b.file_location_uuid,
        b.file_location_active,
        b.file_location_ready,
        c.anvil_uuid,
        c.anvil_name,
        c.anvil_description,
        d.host_uuid,
        d.host_name,
        d.host_type
      FROM files AS a
      JOIN file_locations AS b
        ON a.file_uuid = b.file_location_file_uuid
      LEFT JOIN anvils AS c
        ON b.file_location_host_uuid IN (
          c.anvil_node1_host_uuid,
          c.anvil_node2_host_uuid
        )
      JOIN hosts AS d
        ON b.file_location_host_uuid = d.host_uuid
      WHERE a.file_type != '${DELETED}'
        AND a.file_uuid = '${fileUuid}'
      ORDER BY a.file_name ASC;`;

    const afterQueryReturn = buildQueryResultModifier<FileDetail | undefined>(
      (rows: string[][]) => {
        const { 0: first } = rows;

        if (!first) return undefined;

        const [uuid, name, size, type, checksum, directory] = first;

        return rows.reduce<FileDetail>(
          (previous, row) => {
            const [
              locationUuid,
              locationActive,
              locationReady,
              anvilUuid,
              anvilName,
              anvilDescription,
              hostUuid,
              hostName,
              hostType,
            ] = row.slice(6);

            const { anvils, hosts, locations } = previous;

            if (!anvils[anvilUuid]) {
              anvils[anvilUuid] = {
                description: anvilDescription,
                locationUuids: [],
                name: anvilName,
                uuid: anvilUuid,
              };
            }

            if (!hosts[hostUuid]) {
              hosts[hostUuid] = {
                locationUuids: [],
                name: hostName,
                type: hostType,
                uuid: hostUuid,
              };
            }

            if (anvilUuid) {
              anvils[anvilUuid].locationUuids.push(locationUuid);
            }

            hosts[hostUuid].locationUuids.push(locationUuid);

            locations[locationUuid] = {
              anvilUuid,
              active: Boolean(locationActive),
              hostUuid,
              ready: Boolean(locationReady),
              uuid: locationUuid,
            };

            return previous;
          },
          {
            anvils: {},
            checksum,
            hosts: {},
            locations: {},
            name,
            path: {
              directory: directory,
              full: path.join(directory, name),
            },
            size,
            type,
            uuid,
          },
        );
      },
    );

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
