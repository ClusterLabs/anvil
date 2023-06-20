declare module 'express-session' {
  /**
   * Extended with passport property.
   */
  interface SessionData {
    passport: { user: string };
    returnTo?: string;
  }
}

// Required to avoid overwritting the original express-session module.
export {};
