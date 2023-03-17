export const getHostNameDomain = (hostName: string) =>
  hostName.replace(/^.*?[.]/, '');

export const getHostNamePrefix = (hostName: string) =>
  hostName.replace(/-.*$/, '');

export const getShortHostName = (hostName: string) =>
  hostName.replace(/[.].*$/, '');
