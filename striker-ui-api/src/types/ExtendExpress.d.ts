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
  }
}

export {};
