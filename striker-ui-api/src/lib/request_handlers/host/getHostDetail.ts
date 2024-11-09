import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { toHostUUID } from '../../convertHostUUID';
import { sanitizeSQLParam } from '../../sanitizeSQLParam';

export const getHostDetail = buildGetRequestHandler(
  ({ params: { hostUUID: rawHostUUID } }, hooks) => {
    const hostUUID = toHostUUID(rawHostUUID);
    const { afterQueryReturn, query } = buildQueryHostDetail({
      keys: [sanitizeSQLParam(hostUUID)],
    });

    hooks.afterQueryReturn = afterQueryReturn;

    return query;
  },
);
