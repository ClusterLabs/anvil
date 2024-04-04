import { AssertionError } from 'assert';
import { RequestHandler } from 'express';

import { sanitize } from '../sanitize';
import { perr, poutvar } from '../shell';

export const buildDeleteRequestHandler =
  <
    P extends Record<string, string> = Record<string, string>,
    ResBody = undefined,
    ReqBody extends Record<string, unknown> | undefined = Record<
      string,
      unknown
    >,
    ReqQuery = qs.ParsedQs,
    Locals extends Record<string, unknown> = Record<string, unknown>,
  >({
    delete: handleDelete,
    key = 'uuid',
    listKey = 'uuids',
  }: {
    delete: (
      list: string[],
      ...handlerArgs: Parameters<
        RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals>
      >
    ) => Promise<void>;
    key?: string;
    listKey?: string;
  }): RequestHandler<P, ResBody, ReqBody, ReqQuery, Locals> =>
  async (...handlerArgs) => {
    const { 0: request, 1: response } = handlerArgs;
    const {
      body: { [listKey]: rList } = {},
      params: { [key]: rId },
    } = request;

    const list = sanitize(rList, 'string[]');

    if (rId !== undefined) {
      list.push(rId);
    }

    poutvar(list, `Process delete request with list: `);

    try {
      await handleDelete(list, ...handlerArgs);
    } catch (error) {
      let scode;

      if (error instanceof AssertionError) {
        scode = 400;

        perr(`Failed to assert value during delete request; CAUSE: ${error}`);
      } else {
        scode = 500;

        perr(`Failed to complete delete request; CAUSE: ${error}`);
      }

      return response.status(scode).send();
    }

    return response.status(204).send();
  };
