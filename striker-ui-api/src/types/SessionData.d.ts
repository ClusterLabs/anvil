type SessionData = import('express-session').SessionData & {
  passport: { user: string };
};
