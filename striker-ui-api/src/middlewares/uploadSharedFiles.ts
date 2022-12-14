import multer from 'multer';

import SERVER_PATHS from '../lib/consts/SERVER_PATHS';

const storage = multer.diskStorage({
  destination: (request, file, callback) => {
    callback(null, SERVER_PATHS.mnt.shared.incoming.self);
  },
  filename: (request, file, callback) => {
    callback(null, file.originalname);
  },
});

const uploadSharedFiles = multer({ storage });

export default uploadSharedFiles;
