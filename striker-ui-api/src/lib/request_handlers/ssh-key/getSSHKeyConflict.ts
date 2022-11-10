import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';
import { toLocal } from '../../convertHostUUID';
import { match } from '../../match';

const HOST_KEY_CHANGED_PREFIX = 'host_key_changed::';

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
      [hostUUID: string]: {
        [stateUUID: string]: {
          badFile: string;
          badLine: number;
          hostName: string;
          hostUUID: string;
          ipAddress: string;
          stateUUID: string;
        };
      };
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
        badLine: parseInt(badLine),
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
