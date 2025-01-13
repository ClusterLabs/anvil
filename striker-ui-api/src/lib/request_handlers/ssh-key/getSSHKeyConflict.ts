import { HOST_KEY_CHANGED_PREFIX, REP_IPV4 } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getSSHKeyConflict = buildGetRequestHandler((request, hooks) => {
  const query = `
      SELECT
        a.target,
        a.key
      FROM (
        SELECT
          state_uuid,
          SUBSTRING(
            state_name, '${HOST_KEY_CHANGED_PREFIX}(.*)'
          ) AS target,
          SUBSTRING(
            state_note, 'key=(.*)'
          ) AS key
        FROM states
        WHERE state_name LIKE '${HOST_KEY_CHANGED_PREFIX}%'
      ) AS a
      ORDER BY target;`;

  const afterQueryReturn = buildQueryResultReducer<SshKeyConflictList>(
    (previous, row) => {
      const [target, key] = row;

      if (!previous[key]) {
        previous[key] = {
          target: {
            ip: '',
            name: '',
            short: '',
          },
        };
      }

      const { target: group } = previous[key];

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
