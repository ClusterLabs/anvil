import express from 'express';

import {
  addServerDisk,
  addServerIface,
  changeServerIso,
  createServer,
  deleteServer,
  deleteServerIface,
  getProvisionServerResources,
  getServer,
  getServerDetail,
  growServerDisk,
  lsos,
  migrateServer,
  renameServer,
  setServerBootOrder,
  setServerCpu,
  setServerIfaceState,
  setServerMemory,
  setServerStartDependency,
} from '../lib/request_handlers/server';

const router = express.Router();

router
  .delete('/', deleteServer)
  .delete('/:serverUuid', deleteServer)
  .get('/lsos', lsos)
  .get('/provision', getProvisionServerResources)
  .get('/', getServer)
  .get('/:serverUUID', getServerDetail)
  .post('/', createServer)
  .put('/:uuid/add-disk', addServerDisk)
  .put('/:uuid/add-interface', addServerIface)
  .put('/:uuid/change-iso', changeServerIso)
  .put('/:uuid/delete-interface', deleteServerIface)
  .put('/:uuid/grow-disk', growServerDisk)
  .put('/:uuid/migrate', migrateServer)
  .put('/:uuid/rename', renameServer)
  .put('/:uuid/set-boot-order', setServerBootOrder)
  .put('/:uuid/set-cpu', setServerCpu)
  .put('/:uuid/set-interface-state', setServerIfaceState)
  .put('/:uuid/set-memory', setServerMemory)
  .put('/:uuid/set-start-dependency', setServerStartDependency);

export default router;
