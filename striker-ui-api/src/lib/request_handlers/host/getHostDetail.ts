import { RequestHandler } from 'express';

import { buildHostDetailList } from './buildHostDetailList';
import { toHostUUID } from '../../convertHostUUID';
import { Responder } from '../../Responder';

export const getHostDetail: RequestHandler<
  Express.RhParamsDictionary,
  HostDetail,
  Express.RhReqBody,
  Express.RhReqQuery,
  LocalsRequestTarget
> = async (request, response) => {
  const respond = new Responder(response);

  const hostUuid = toHostUUID(response.locals.target.uuid);

  let host: HostDetail | undefined;

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
