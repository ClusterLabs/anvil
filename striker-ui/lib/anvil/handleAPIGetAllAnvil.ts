import { NextApiHandler, NextApiRequest, NextApiResponse } from 'next';

import getAllAnvil from './getAllAnvil';
import handleAPIFakeGetAllAnvil from './handleAPIFakeGetAllAnvil';

const handleAPIGetAllAnvil: NextApiHandler<AnvilList> = async (
  request: NextApiRequest,
  response: NextApiResponse<AnvilList>,
): Promise<void> => {
  const { anvilList, error }: GetAllAnvilResponse = await getAllAnvil();

  if (error) {
    response.status(503);
  } else {
    response.status(200);
  }

  response.send(anvilList);
};

export default process.env.IS_USE_FAKE_DATA
  ? handleAPIFakeGetAllAnvil
  : handleAPIGetAllAnvil;
