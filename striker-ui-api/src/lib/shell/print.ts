export const print = (
  message: string,
  {
    eol = '\n',
    stream = 'stdout',
  }: { eol?: string; stream?: 'stderr' | 'stdout' } = {},
) => process[stream].write(`${message}${eol}`);
