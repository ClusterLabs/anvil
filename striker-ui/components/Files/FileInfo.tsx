import { useEffect, useRef } from 'react';
import {
  Box,
  Button,
  Checkbox,
  FormControlLabel,
  Input,
  InputLabel,
  MenuItem,
  Select,
  TextField,
} from '@mui/material';
import { BodyText } from '../Text';

type FileInfoProps = {
  anvilList: {
    anvilName: string;
    anvilDescription: string;
    anvilUUID: string;
  }[];
  isShowSelectFileOnStart?: boolean;
};

const FILE_TYPE_LIST = {
  iso: 'ISO (optical disc)',
  other: 'Other file type',
  script: 'Script (program)',
};

// Used to solve react/require-default-params AND ensure linting works within the function component.
const FILE_INFO_DEFAULT_PROPS = { isShowSelectFileOnStart: false };

const FileInfo = ({
  anvilList,
  isShowSelectFileOnStart = FILE_INFO_DEFAULT_PROPS.isShowSelectFileOnStart,
}: FileInfoProps): JSX.Element => {
  const selectFileRef = useRef<HTMLInputElement>();

  const openFilePicker = () => {
    selectFileRef.current?.click();
  };

  useEffect(() => {
    if (isShowSelectFileOnStart) {
      openFilePicker();
    }
  }, [isShowSelectFileOnStart]);

  return (
    <form encType="multipart/form-data">
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
        <InputLabel htmlFor="select-file">
          <Input
            id="select-file"
            ref={selectFileRef}
            sx={{ display: 'none' }}
            type="file"
          />
        </InputLabel>
        <Box
          sx={{ alignItems: 'center', display: 'flex', flexDirection: 'row' }}
        >
          <TextField id="file-name" label="File name" sx={{ flexGrow: 1 }} />
          <Button onClick={openFilePicker} sx={{ textTransform: 'none' }}>
            <BodyText text="Browse" />
          </Button>
        </Box>
        <Select id="file-type" label="File type" value="other">
          {Object.entries(FILE_TYPE_LIST).map(
            ([fileType, fileTypeDisplayString]) => {
              return (
                <MenuItem key={fileType} value={fileType}>
                  {fileTypeDisplayString}
                </MenuItem>
              );
            },
          )}
        </Select>
        {anvilList.map(({ anvilName, anvilDescription, anvilUUID }) => {
          return (
            <FormControlLabel
              control={<Checkbox />}
              key={anvilUUID}
              label={`${anvilName}: ${anvilDescription}`}
              value={`${anvilUUID}-sync`}
            />
          );
        })}
      </Box>
    </form>
  );
};

FileInfo.defaultProps = FILE_INFO_DEFAULT_PROPS;

export default FileInfo;
