import { RequestHandler } from 'express';

import buildGetRequestHandler from '../buildGetRequestHandler';
import { buildHostDetailList } from './buildHostDetailList';
import { buildQueryHostDetail } from './buildQueryHostDetail';
import { toHostUUID } from '../../convertHostUUID';
import { Responder } from '../../Responder';
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

export const getHostDetailAlt: RequestHandler<
  Express.RhParamsDictionary,
  HostDetailAlt,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const hostUuid = response.locals.target.uuid;

  let host: HostDetailAlt | undefined;

  try {
    const hosts = await buildHostDetailList({ lshost: [hostUuid] });

    ({ [hostUuid]: host } = hosts);
  } catch (error) {
    return respond.s500(
      '8957311',
      `Failed to get host detail; CAUSE: ${error}`,
    );
  }

  if (!host) {
    return respond.s404();
  }

  return respond.s200(host);
};
