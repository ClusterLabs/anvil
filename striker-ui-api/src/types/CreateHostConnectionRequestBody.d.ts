type CreateHostConnectionRequestBody = {
  dbName?: string;
  ipAddress: string;
  isPing?: boolean;
  // Host password; same as database password.
  password: string;
  port?: number;
  sshPort?: number;
  // database user.
  user?: string;
};
