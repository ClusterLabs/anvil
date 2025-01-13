import { HOST_KEY_CHANGED_PREFIX, REP_IPV4 } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getSSHKeyConflict = buildGetRequestHandler((request, hooks) => {
  const query = `
      SELECT
        a.target,
        a.bad_key
      FROM (
        SELECT
          state_uuid,
          SUBSTRING(
            state_name, '${HOST_KEY_CHANGED_PREFIX}(.*)'
          ) AS target,
          SUBSTRING(
            state_note, 'key=(.*)'
          ) AS bad_key
        FROM states
        WHERE state_name LIKE '${HOST_KEY_CHANGED_PREFIX}%'
      ) AS a
      ORDER BY target;`;

  const afterQueryReturn = buildQueryResultReducer<SshKeyConflictList>(
    (previous, row) => {
      const [target, badKey] = row;

      if (!previous[badKey]) {
        previous[badKey] = {
          target: {
            ip: '',
            name: '',
            short: '',
          },
        };
      }

      const { target: group } = previous[badKey];

      if (REP_IPV4.test(target)) {
        group.ip = target;
      } else if (target.includes('.')) {
        group.name = target;
      } else {
        group.short = target;
      }

      return previous;
    },
    {},
  );

  hooks.afterQueryReturn = afterQueryReturn;

  return query;
});
