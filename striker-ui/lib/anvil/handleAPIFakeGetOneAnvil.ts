import { NextApiHandler, NextApiRequest, NextApiResponse } from 'next';

const handleAPIFakeGetOneAnvil: NextApiHandler<AnvilStatus> = (
  request: NextApiRequest,
  response: NextApiResponse<AnvilStatus>,
): void => {
  const generateNodeState: () => 0 | 1 = (): 0 | 1 =>
    Math.random() > 0.5 ? 1 : 0;

  response.send({
    nodes: [
      {
        on: generateNodeState(),
      },
      {
        on: generateNodeState(),
      },
    ],
    timestamp: Math.round(Date.now() / 1000),
  });
};

export default handleAPIFakeGetOneAnvil;
