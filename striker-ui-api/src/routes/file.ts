import express from 'express';

import {
  createFile,
  deleteFile,
  getFile,
  getFileDetail,
  updateFile,
} from '../lib/request_handlers/file';
import uploadSharedFiles from '../middlewares/uploadSharedFiles';

const router = express.Router();

router
  .delete('/:fileUUID', deleteFile)
  .get('/', getFile)
  .get('/:fileUUID', getFileDetail)
  .post('/', uploadSharedFiles.single('file'), createFile)
  .put('/:fileUUID', updateFile);

export default router;
