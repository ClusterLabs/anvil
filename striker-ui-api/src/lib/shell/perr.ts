import { print } from './print';

export const perr = (message: string, error?: unknown) => {
  let msg = message;

  if (error instanceof Error) {
    msg += `\n${error.cause}`;
  }

  print(msg, { stream: 'stderr' });
};
