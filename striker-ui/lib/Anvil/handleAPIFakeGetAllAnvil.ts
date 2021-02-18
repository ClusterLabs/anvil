import { NextApiHandler, NextApiRequest, NextApiResponse } from 'next';

const handleAPIFakeGetAllAnvil: NextApiHandler<AnvilList> = (
  request: NextApiRequest,
  response: NextApiResponse<AnvilList>,
): void => {
  response.send({
    anvils: [
      {
        uuid: '62ed925e-dddc-4541-acae-525fc99a9945',
      },
      {
        uuid: '1040f37a-9847-4025-af2e-973b0f136979',
      },
      {
        uuid: '52057dd0-04a6-4097-8a38-deb036116190',
      },
    ],
  });
};

export default handleAPIFakeGetAllAnvil;
