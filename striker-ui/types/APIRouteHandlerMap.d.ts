import { NextApiHandler } from 'next';

declare type APIRouteHandlerMap = Readonly<{
  [httpMethod: string]: NextApiHandler;
}>;
