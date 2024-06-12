import { HOST_KEY_CHANGED_PREFIX } from '../../consts';

import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { match } from '../../match';

export const getSSHKeyConflict = buildGetRequestHandler(
  (request, buildQueryOptions) => {
    const localHostUUID: string = getLocalHostUUID();

    const query = `
      SELECT
        hos.host_name,
        hos.host_uuid,
        sta.state_name,
        sta.state_note,
        sta.state_uuid
      FROM states AS sta
      JOIN hosts AS hos
        ON sta.state_host_uuid = hos.host_uuid
      WHERE sta.state_name LIKE '${HOST_KEY_CHANGED_PREFIX}%';`;
    const afterQueryReturn = buildQueryResultReducer<{
      [hostUUID: string]: SshKeyConflict;
    }>((previous, [hostName, hostUUID, stateName, stateNote, stateUUID]) => {
      const hostUUIDKey = toLocal(hostUUID, localHostUUID);

      if (previous[hostUUIDKey] === undefined) {
        previous[hostUUIDKey] = {};
      }

      const ipAddress = stateName.slice(HOST_KEY_CHANGED_PREFIX.length);
      const [, badFile, badLine = '0'] = match(
        stateNote,
        /file=([^\s]+),line=(\d+)/,
      );

      previous[hostUUIDKey][stateUUID] = {
        badFile,
        badLine: Number(badLine),
        hostName,
        hostUUID,
        ipAddress,
        stateUUID,
      };

      return previous;
    }, {});

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = afterQueryReturn;
    }

    return query;
  },
);
