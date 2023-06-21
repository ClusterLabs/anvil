import { RequestHandler } from 'express';

export const createHost: RequestHandler = (request, response) => {
  return response.status(204).send();
};
