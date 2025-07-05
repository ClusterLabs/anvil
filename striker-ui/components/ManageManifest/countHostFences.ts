import { createElement } from 'react';

import MessageBox from '../MessageBox';

const countHostFences = (
  body: APIBuildManifestRequestBody,
): {
  counts: Record<string, number>;
  messages: React.ReactNode[];
} => {
  const {
    hostConfig: { hosts },
  } = body;

  const counts = Object.values(hosts).reduce<Record<string, number>>(
    (previous, host) => {
      const { fences, hostType, hostNumber } = host;

      const hostName = `${hostType.replace(/node/, 'subnode')}${hostNumber}`;

      if (!fences) {
        previous[hostName] = 0;

        return previous;
      }

      previous[hostName] = Object.values(fences).reduce<number>(
        (count, fence) => {
          const { fencePort } = fence;

          const diff = fencePort.length ? 1 : 0;

          return count + diff;
        },
        0,
      );

      return previous;
    },
    {},
  );

  const messages = Object.entries(counts).map<React.ReactNode>((entry) => {
    const [hostName, fenceCount] = entry;

    if (fenceCount) {
      return null;
    }

    return createElement(
      MessageBox,
      {
        key: `${hostName}-no-fence-port-message`,
      },
      `No fence device port specified for ${hostName}.`,
    );
  });

  return { counts, messages };
};

export default countHostFences;
