import { createProxyMiddleware } from 'http-proxy-middleware';

import { P_UUID } from '../lib/consts';

import { stderr, stdout } from '../lib/shell';
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

    stdout(`Got param [${serverUuid}] from [${url}]`);

    let domain: string;
    let port: number;
    let protocol: string;

    try {
      ({ domain, port, protocol } = await getVncinfo(serverUuid));
    } catch (error) {
      throw new Error(
        `Failed to get server ${serverUuid} VNC info; CAUSE: ${error}`,
      );
    }

    return { host: domain, protocol, port };
  },
  on: {
    error: (error, request, response) => {
      stderr(`VNC proxy error: ${error}`);

      let resType: string;

      if ('writeHead' in response) {
        resType = 'ServerResponse';

        response.writeHead(500).end();
      } else {
        resType = 'Socket';
      }

      stdout(`Response type = ${resType}`);
    },
  },
  ws: true,
});

export const proxyServerVncUpgrade =
  proxyServerVnc.upgrade ??
  (() => {
    stdout('No upgrade handler for server VNC connection(s).');
  });
