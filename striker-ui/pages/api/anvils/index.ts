import { NextApiRequest, NextApiResponse } from 'next';

import { APIRouteHandlerMap } from '../../../types/APIRouteHandlerMap';

import handleAPIGetAllAnvil from '../../../lib/anvil/handleAPIGetAllAnvil';

const ROUTE_HANDLER_MAP: APIRouteHandlerMap = {
  GET: handleAPIGetAllAnvil,
};

async function handleAPIAllAnvil(
  request: NextApiRequest,
  response: NextApiResponse,
): Promise<void> {
  const { method: httpMethod = 'GET' }: NextApiRequest = request;

  await ROUTE_HANDLER_MAP[httpMethod](request, response);
}

export default handleAPIAllAnvil;
