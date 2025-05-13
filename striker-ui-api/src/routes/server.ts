import express from 'express';

import { validateRequestTarget } from '../middlewares';
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
  resetServer,
  setServerBootOrder,
  setServerCpu,
  setServerIfaceState,
  setServerMemory,
  setServerProtect,
  setServerStartDependency,
} from '../lib/request_handlers/server';

const single = express.Router();

single
  .put('/add-disk', addServerDisk)
  .put('/add-interface', addServerIface)
  .put('/change-iso', changeServerIso)
  .put('/delete-interface', deleteServerIface)
  .put('/grow-disk', growServerDisk)
  .put('/migrate', migrateServer)
  .put('/rename', renameServer)
  .put('/reset', resetServer)
  .put('/set-boot-order', setServerBootOrder)
  .put('/set-cpu', setServerCpu)
  .put('/set-interface-state', setServerIfaceState)
  .put('/set-memory', setServerMemory)
  .put('/set-protect', setServerProtect)
  .put('/set-start-dependency', setServerStartDependency);

const router = express.Router();

router
  .delete('/', deleteServer)
  .delete('/:serverUuid', deleteServer)
  .get('/lsos', lsos)
  .get('/provision', getProvisionServerResources)
  .get('/', getServer)
  .get('/:serverUUID', getServerDetail)
  .post('/', createServer);

router.use('/:uuid', validateRequestTarget(), single);

export default router;
