import { NextApiHandler, NextApiRequest, NextApiResponse } from 'next';

import getOneAnvil from './getOneAnvil';
import handleAPIFakeGetOneAnvil from './handleAPIFakeGetOneAnvil';

const handleAPIGetOneAnvil: NextApiHandler<AnvilStatus> = async (
  request: NextApiRequest,
  response: NextApiResponse<AnvilStatus>,
): Promise<void> => {
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
};

export default process.env.IS_USE_FAKE_DATA
  ? handleAPIFakeGetOneAnvil
  : handleAPIGetOneAnvil;
