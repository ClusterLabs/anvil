import { Response } from 'express';

import { ResponseError } from './ResponseError';
import { perr } from './shell';

export class Responder<
  ResBody = unknown,
  Locals extends Record<string, unknown> = Record<string, unknown>,
> {
  private response: Response<ResBody, Locals>;

  constructor(response: Response<ResBody, Locals>) {
    this.response = response;
  }

  private respond(status: number, body?: ResBody) {
    return this.response.status(status).send(body);
  }

  private respondError(status: number, ...params: ResponseErrorParams) {
    const error = new ResponseError(...params);

    perr(error.toString());

    return this.response.status(status).send(error.body as ResBody);
  }

  public s200(body?: ResBody) {
    return this.respond(200, body);
  }

  public s201(body?: ResBody) {
    return this.respond(201, body);
  }

  public s400(...params: ResponseErrorParams) {
    return this.respondError(400, ...params);
  }

  public s404(body?: ResBody) {
    return this.respond(404, body);
  }

  public s500(...params: ResponseErrorParams) {
    return this.respondError(500, ...params);
  }
}
