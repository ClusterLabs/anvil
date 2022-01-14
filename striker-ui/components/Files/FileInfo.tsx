import {
  Checkbox,
  FormControl,
  FormControlLabel,
  MenuItem,
  Select,
  TextField,
} from '@mui/material';

import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

type FileInfoProps = {
  fileName: string;
  fileType: string;
  fileSyncAnvilList: {
    anvilName: string;
    anvilDescription: string;
    anvilUUID: string;
    isSync: boolean;
  }[];
};

const FileInfo = ({
  fileName,
  fileType,
  fileSyncAnvilList,
}: FileInfoProps): JSX.Element => {
  return (
    <FormControl>
      <TextField
        defaultValue={fileName}
        id="file-name"
        label="File name"
        sx={{ flexGrow: 1 }}
      />
      <Select defaultValue={fileType} id="file-type" label="File type">
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
      {fileSyncAnvilList.map(
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
