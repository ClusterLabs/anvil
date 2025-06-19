import path from 'path';

/**
 * Defines all external files required by the striker UI API.
 *
 * DO NOT use direct paths in the codebase.
 */
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
      access: {},
      'qemu-cache.xml': {},
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
      'osinfo-query': {},
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
      'anvil-join-anvil': {},
      'anvil-migrate-server': {},
      'anvil-manage-alerts': {},
      'anvil-manage-dr': {},
      'anvil-manage-keys': {},
      'anvil-manage-power': {},
      'anvil-manage-server': {},
      'anvil-manage-server-network': {},
      'anvil-manage-server-storage': {},
      'anvil-manage-server-system': {},
      'anvil-manage-storage-groups': {},
      'anvil-provision-server': {},
      'anvil-rename-server': {},
      'anvil-safe-start': {},
      'anvil-safe-stop': {},
      'anvil-shutdown-server': {},
      'anvil-sync-shared': {},
      'anvil-update-system': {},
      'striker-boot-machine': {},
      'striker-initialize-host': {},
      'striker-manage-install-target': {},
      'striker-manage-peers': {},
    },
    libexec: {
      'qemu-kvm': {},
    },
  },
  var: {
    www: {
      html: {},
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
