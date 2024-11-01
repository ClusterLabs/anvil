declare global {
  namespace Express {
    /**
     * Extended Express.Request with optional files list for handling file
     * uploads.
     */
    interface Request {
      files?: FileInfoAppend[];
    }

    /**
     * Extended Express.User object used by express-session and passport to
     * identify which user owns a session.
     */
    interface User {
      name: string;
      uuid: string;
    }

    type ExtractRh<T> = T extends import('express').RequestHandler<
      infer P,
      infer ResBody,
      infer ReqBody,
      infer ReqQuery,
      // @ts-expect-error Discard type constraint because we only want the default
      infer Locals
    >
      ? [P, ResBody, ReqBody, ReqQuery, Locals]
      : never;

    type RhDefaults = ExtractRh<import('express').RequestHandler>;

    type RhParamsDictionary = RhDefaults['0'];

    type RhResBody = RhDefaults['1'];

    type RhReqBody = RhDefaults['2'];

    type RhReqQuery = RhDefaults['3'];

    type RhLocals = RhDefaults['4'];
  }
}

export {};
