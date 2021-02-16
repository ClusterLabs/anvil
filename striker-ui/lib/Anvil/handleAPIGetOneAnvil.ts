import { NextApiRequest, NextApiResponse } from 'next';

import getOneAnvil from './getOneAnvil';

async function handleAPIGetOneAnvil(
  request: NextApiRequest,
  response: NextApiResponse,
): Promise<void> {
  const {
    query: { uuid },
  }: NextApiRequest = request;

  const anvilUUID: string = uuid instanceof Array ? uuid[0] : uuid;

  const { anvilStatus, error }: GetOneAnvilResponse = await getOneAnvil(
    anvilUUID,
  );

  if (error) {
    response.status(503);
  } else {
    response.status(200);
  }

  response.send(anvilStatus);
}

export default handleAPIGetOneAnvil;
