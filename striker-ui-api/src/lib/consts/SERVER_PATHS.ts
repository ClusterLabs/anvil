import path from 'path';

const EMPTY_SERVER_PATHS: ServerPath = {
  etc: {
    anvil: { 'host.uuid': {} },
    hostname: {},
  },
  mnt: {
    shared: {
      incoming: {},
    },
  },
  opt: {
    alteeve: {
      screenshots: {},
    },
  },
  tmp: {},
  usr: {
    bin: {
      date: {},
      getent: {},
      mkfifo: {},
      openssl: {},
      psql: {},
      rm: {},
      sed: {},
      uuidgen: {},
    },
    sbin: {
      'anvil-access-module': {},
      'anvil-boot-server': {},
      'anvil-configure-host': {},
      'anvil-delete-server': {},
      'anvil-get-server-screenshot': {},
      'anvil-join-anvil': {},
      'anvil-manage-keys': {},
      'anvil-manage-power': {},
      'anvil-provision-server': {},
      'anvil-safe-start': {},
      'anvil-safe-stop': {},
      'anvil-shutdown-server': {},
      'anvil-sync-shared': {},
      'anvil-update-system': {},
      'striker-boot-machine': {},
      'striker-initialize-host': {},
      'striker-manage-install-target': {},
      'striker-manage-peers': {},
      'striker-parse-os-list': {},
    },
  },
  var: { www: { html: {} } },
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
