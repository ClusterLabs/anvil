import express from 'express';

import { handleSharedFile } from '../middlewares/file';
import {
  createFile,
  deleteFile,
  getFile,
  getFileDetail,
  updateFile,
} from '../lib/request_handlers/file';

const router = express.Router();

router
  .delete('/:fileUUID', deleteFile)
  .get('/', getFile)
  .get('/:fileUUID', getFileDetail)
  .post('/', handleSharedFile, createFile)
  .put('/:fileUUID', updateFile);

export default router;
