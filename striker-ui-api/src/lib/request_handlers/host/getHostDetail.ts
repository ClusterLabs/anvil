import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { toHostUUID } from '../../convertHostUUID';
import { sanitizeSQLParam } from '../../sanitizeSQLParam';

export const getHostDetail = buildGetRequestHandler(
  ({ params: { hostUUID: rawHostUUID } }, buildQueryOptions) => {
    const hostUUID = toHostUUID(rawHostUUID);
    const { afterQueryReturn, query } = buildQueryHostDetail({
      keys: [sanitizeSQLParam(hostUUID)],
    });

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = afterQueryReturn;
    }

    return query;
  },
);
