import path from 'path';

const EMPTY_SERVER_PATHS: ServerPath = {
  mnt: {
    shared: {
      incoming: {},
    },
  },
  usr: {
    bin: {
      sed: {},
    },
    sbin: {
      'anvil-sync-shared': {},
      'striker-access-database': {},
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
