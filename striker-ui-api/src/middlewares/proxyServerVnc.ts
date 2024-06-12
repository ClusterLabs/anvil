import { createHash } from 'crypto';
import { createProxyMiddleware } from 'http-proxy-middleware';

import { P_UUID, WS_GUID } from '../lib/consts';

import { getVncinfo } from '../lib/accessModule';
import { cname } from '../lib/cname';
import { ResponseError } from '../lib/ResponseError';
import { perr, pout, poutvar } from '../lib/shell';

const WS_SVR_VNC_URL_PREFIX = '/ws/server/vnc';

const getServerUuid = (url = '') =>
  url.replace(new RegExp(`^${WS_SVR_VNC_URL_PREFIX}/(${P_UUID})`), '$1');

export const proxyServerVnc = createProxyMiddleware({
  changeOrigin: true,
  pathFilter: `${WS_SVR_VNC_URL_PREFIX}/*`,
  router: async (request) => {
    const { url } = request;

    const serverUuid = getServerUuid(url);

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

      if (!response) {
        perr(`Missing response; got [${response}]`);

        return;
      }

      const serverUuid = getServerUuid(request.url);

      const errapiName = cname(`vncerror.${serverUuid}`);
      const errapiObj = new ResponseError(
        '72c969b',
        `${error.name}: ${error.message}`,
      );
      const errapiStr = JSON.stringify(errapiObj.body);
      const errapiValue = encodeURIComponent(errapiStr);
      const errapiCookie = `${errapiName}=j:${errapiValue}; Path=/server; SameSite=Lax; Max-Age=3`;

      poutvar({ errapiCookie }, 'Error cookie: ');

      if ('writeHead' in response) {
        pout('Found ServerResponse object');

        return response
          .writeHead(500, {
            'Set-Cookie': `${errapiCookie}`,
          })
          .end();
      }

      pout(`Found Socket object`);

      const {
        headers: { 'sec-websocket-key': wskey },
      } = request;

      const wsaccept = createHash('sha1')
        .update(wskey + WS_GUID, 'binary')
        .digest('base64');

      const headers = [
        'HTTP/1.1 101 Switching Protocols',
        'Connection: upgrade',
        `Sec-WebSocket-Accept: ${wsaccept}`,
        `Set-Cookie: ${errapiCookie}`,
        'Upgrade: websocket',
      ];

      response.end(`${headers.join('\r\n')}\r\n`, 'utf-8');
    },
  },
  ws: true,
});

export const proxyServerVncUpgrade =
  proxyServerVnc.upgrade ??
  (() => {
    pout('No upgrade handler for server VNC connection(s).');
  });
