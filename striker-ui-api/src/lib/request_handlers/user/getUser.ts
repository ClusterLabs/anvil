import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryResultReducer } from '../../buildQueryResultModifier';

export const getUser = buildGetRequestHandler((request, buildQueryOptions) => {
  const query = `
    SELECT
      use.user_name,
      use.user_uuid
    FROM users AS use;`;
  const afterQueryReturn: QueryResultModifierFunction | undefined =
    buildQueryResultReducer<
      Record<string, { userName: string; userUUID: string }>
    >((previous, [userName, userUUID]) => {
      previous[userUUID] = {
        userName,
        userUUID,
      };

      return previous;
    }, {});

  if (buildQueryOptions) {
    buildQueryOptions.afterQueryReturn = afterQueryReturn;
  }

  return query;
});
