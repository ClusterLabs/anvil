// Next.js API route support: https://nextjs.org/docs/api-routes/introduction

import type { NextApiRequest, NextApiResponse } from 'next';

function hello(req: NextApiRequest, res: NextApiResponse): void {
  res.status(200).json({ name: 'John Doe' });
}

export default hello;
