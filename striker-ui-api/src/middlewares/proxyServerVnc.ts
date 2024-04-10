import { createProxyMiddleware } from 'http-proxy-middleware';

import { P_UUID } from '../lib/consts';

import { perr, pout } from '../lib/shell';
import { getVncinfo } from '../lib/accessModule';

const WS_SVR_VNC_URL_PREFIX = '/ws/server/vnc';

export const proxyServerVnc = createProxyMiddleware({
  changeOrigin: true,
  pathFilter: `${WS_SVR_VNC_URL_PREFIX}/*`,
  router: async (request) => {
    const { url = '' } = request;

    const serverUuid = url.replace(
      new RegExp(`^${WS_SVR_VNC_URL_PREFIX}/(${P_UUID})`),
      '$1',
    );

    pout(`Got param [${serverUuid}] from [${url}]`);

    let domain: string;
    let port: number;
    let protocol: string;

    try {
      ({ domain, port, protocol } = await getVncinfo(serverUuid));
    } catch (error) {
      perr(`Failed to get server ${serverUuid} VNC info; CAUSE: ${error}`);

      return;
    }

    return { host: domain, protocol, port };
  },
  on: {
    error: (error, request, response) => {
      perr(`VNC proxy error: ${error}`);

      let resType: string;

      if ('writeHead' in response) {
        resType = 'ServerResponse';

        response.writeHead(500).end();
      } else {
        resType = 'Socket';
      }

      pout(`Response type = ${resType}`);
    },
  },
  ws: true,
});

export const proxyServerVncUpgrade =
  proxyServerVnc.upgrade ??
  (() => {
    pout('No upgrade handler for server VNC connection(s).');
  });
