import { NextApiRequest, NextApiResponse } from 'next';

import { APIRouteHandlerMap } from '../../../types/APIRouteHandlerMap';

import handleAPIGetOneAnvil from '../../../lib/anvil/handleAPIGetOneAnvil';

const ROUTE_HANDLER_MAP: APIRouteHandlerMap = {
  GET: handleAPIGetOneAnvil,
};

async function handleAPIOneAnvil(
  request: NextApiRequest,
  response: NextApiResponse,
): Promise<void> {
  const { method: httpMethod = 'GET' }: NextApiRequest = request;

  await ROUTE_HANDLER_MAP[httpMethod](request, response);
}

export default handleAPIOneAnvil;
