export const getShortHostName = (hostName: string) =>
  hostName.replace(/[.].*$/, '');
