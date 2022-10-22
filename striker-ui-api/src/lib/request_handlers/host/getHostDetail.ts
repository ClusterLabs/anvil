import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { sanitizeSQLParam } from '../../sanitizeSQLParam';

export const getHostDetail = buildGetRequestHandler(
  ({ params: { hostUUID } }, buildQueryOptions) => {
    const { afterQueryReturn, query } = buildQueryHostDetail({
      keys: [sanitizeSQLParam(hostUUID)],
    });

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = afterQueryReturn;
    }

    return query;
  },
);
