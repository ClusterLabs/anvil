import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { sanitize } from '../../sanitize';

export const getFileDetail: RequestHandler = buildGetRequestHandler(
  (response, hooks) => {
    const { fileUUID: rFileUuid } = response.params;

    const fileUuid = sanitize(rFileUuid, 'string', {
      modifierType: 'sql',
    });

    const query = `
      SELECT
        fil.file_uuid,
        fil.file_name,
        fil.file_size,
        fil.file_type,
        fil.file_md5sum,
        fil_loc.file_location_uuid,
        fil_loc.file_location_active,
        anv.anvil_uuid,
        anv.anvil_name,
        anv.anvil_description,
        hos.host_uuid,
        hos.host_name,
        hos.host_type
      FROM files AS fil
      JOIN file_locations AS fil_loc
        ON fil.file_uuid = fil_loc.file_location_file_uuid
      JOIN anvils AS anv
        ON fil_loc.file_location_host_uuid IN (
          anv.anvil_node1_host_uuid,
          anv.anvil_node2_host_uuid,
          anv.anvil_dr1_host_uuid
        )
      JOIN hosts AS hos
        ON fil_loc.file_location_host_uuid = hos.host_uuid
      WHERE fil.file_type != '${DELETED}'
        AND fil.file_uuid = '${fileUuid}'
      ORDER BY fil.file_name ASC;`;

    const afterQueryReturn = buildQueryResultModifier<FileDetail | undefined>(
      (rows: string[][]) => {
        const { 0: first } = rows;

        if (!first) return undefined;

        const [uuid, name, size, type, checksum] = first;

        return rows.reduce<FileDetail>(
          (previous, row) => {
            const [
              locationUuid,
              locationActive,
              anvilUuid,
              anvilName,
              anvilDescription,
              hostUuid,
              hostName,
              hostType,
            ] = row.slice(5);

            if (!previous.anvils[anvilUuid]) {
              previous.anvils[anvilUuid] = {
                description: anvilDescription,
                locationUuids: [],
                name: anvilName,
                uuid: anvilUuid,
              };
            }

            if (!previous.hosts[hostUuid]) {
              previous.hosts[hostUuid] = {
                locationUuids: [],
                name: hostName,
                type: hostType,
                uuid: hostUuid,
              };
            }

            if (hostType === 'dr') {
              previous.hosts[hostUuid].locationUuids.push(locationUuid);
            } else {
              previous.anvils[anvilUuid].locationUuids.push(locationUuid);
            }

            const active = Number(locationActive) === 1;

            previous.locations[locationUuid] = {
              anvilUuid,
              active,
              hostUuid,
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
