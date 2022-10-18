import path from 'path';

const EMPTY_SERVER_PATHS: ServerPath = {
  mnt: {
    shared: {
      incoming: {},
    },
  },
  tmp: {},
  usr: {
    bin: {
      date: {},
      mkfifo: {},
      rm: {},
      sed: {},
    },
    sbin: {
      'anvil-access-module': {},
      'anvil-configure-host': {},
      'anvil-get-server-screenshot': {},
      'anvil-manage-power': {},
      'anvil-provision-server': {},
      'anvil-sync-shared': {},
      'striker-parse-os-list': {},
    },
  },
};

const generatePaths = (
  currentObject: ServerPath,
  parents = path.parse(process.cwd()).root,
) => {
  Object.keys(currentObject).forEach((pathKey) => {
    if (pathKey !== 'self') {
      const currentPath = path.join(parents, pathKey);

      currentObject[pathKey].self = currentPath;

      generatePaths(currentObject[pathKey], currentPath);
    }
  });

  return currentObject as ReadonlyServerPath;
};

const SERVER_PATHS = generatePaths(EMPTY_SERVER_PATHS);

export default SERVER_PATHS;
