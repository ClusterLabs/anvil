import { NextApiRequest, NextApiResponse } from 'next';

import getAllAnvil from './getAllAnvil';

async function handleAPIGetAllAnvil(
  request: NextApiRequest,
  response: NextApiResponse,
): Promise<void> {
  const { anvilList, error }: GetAllAnvilResponse = await getAllAnvil();

  if (error) {
    response.status(503);
  } else {
    response.status(200);
  }

  response.send(anvilList);
}

export default handleAPIGetAllAnvil;
