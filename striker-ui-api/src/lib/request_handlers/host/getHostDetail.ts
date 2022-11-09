import { LOCAL } from '../../consts/LOCAL';

import { getLocalHostUUID } from '../../accessModule';
import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { sanitizeSQLParam } from '../../sanitizeSQLParam';

export const getHostDetail = buildGetRequestHandler(
  ({ params: { hostUUID: host } }, buildQueryOptions) => {
    const hostUUID = host === LOCAL ? getLocalHostUUID() : host;
    const { afterQueryReturn, query } = buildQueryHostDetail({
      keys: [sanitizeSQLParam(hostUUID)],
    });

    if (buildQueryOptions) {
      buildQueryOptions.afterQueryReturn = afterQueryReturn;
    }

    return query;
  },
);
