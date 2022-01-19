const path = require('path');

const SERVER_PATHS = {
  mnt: {
    shared: {
      incoming: {},
    },
  },
  usr: {
    sbin: {
      'striker-access-database': {},
    },
  },
};

const generatePaths = (
  currentObject,
  parents = path.parse(process.cwd()).root,
) => {
  Object.keys(currentObject).forEach((pathKey) => {
    const currentPath = path.join(parents, pathKey);

    currentObject[pathKey].self = currentPath;

    if (pathKey !== 'self') {
      generatePaths(currentObject[pathKey], currentPath);
    }
  });
};

generatePaths(SERVER_PATHS);

module.exports = SERVER_PATHS;
