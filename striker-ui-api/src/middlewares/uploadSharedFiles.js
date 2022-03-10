const multer = require('multer');

const SERVER_PATHS = require('../lib/consts/SERVER_PATHS');

const storage = multer.diskStorage({
  destination: (request, file, callback) => {
    callback(null, SERVER_PATHS.mnt.shared.incoming.self);
  },
  filename: (request, file, callback) => {
    callback(null, file.originalname);
  },
});

const uploadSharedFiles = multer({ storage });

module.exports = uploadSharedFiles;
