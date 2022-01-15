import {
  Checkbox,
  FormControl,
  FormControlLabel,
  MenuItem,
  Select,
  TextField,
} from '@mui/material';

import { TEXT } from '../../lib/consts/DEFAULT_THEME';
import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

const FileInfo = ({
  fileName,
  fileType,
  fileSyncAnvils,
  onChange,
}: FileInfoProps): JSX.Element => {
  return (
    <FormControl>
      <TextField
        defaultValue={fileName}
        id="file-name"
        label="File name"
        onChange={({ target: { value } }) =>
          onChange?.call(null, { fileName: value })
        }
        sx={{ color: TEXT }}
      />
      <Select
        defaultValue={fileType}
        id="file-type"
        label="File type"
        onChange={({ target: { value } }) =>
          onChange?.call(null, { fileType: value as UploadFileType })
        }
        sx={{ color: TEXT }}
      >
        {UPLOAD_FILE_TYPES_ARRAY.map(
          ([fileTypeKey, [, fileTypeDisplayString]]) => {
            return (
              <MenuItem key={fileTypeKey} value={fileTypeKey}>
                {fileTypeDisplayString}
              </MenuItem>
            );
          },
        )}
      </Select>
      {fileSyncAnvils.map(
        ({ anvilName, anvilDescription, anvilUUID, isSync }) => {
          return (
            <FormControlLabel
              control={<Checkbox checked={isSync} />}
              key={anvilUUID}
              label={`${anvilName}: ${anvilDescription}`}
              value={`${anvilUUID}-sync`}
            />
          );
        },
      )}
    </FormControl>
  );
};

export default FileInfo;
