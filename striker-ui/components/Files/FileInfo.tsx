import {
  Checkbox,
  checkboxClasses,
  FormControl,
  FormControlLabel,
  inputClasses,
  MenuItem,
  outlinedInputClasses,
  Select,
  styled,
  TextField,
} from '@mui/material';
import {
  Sync as SyncIcon,
  SyncDisabled as SyncDisabledIcon,
} from '@mui/icons-material';

import { BLUE, GREY, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';
import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

type FileInfoProps = Pick<FileDetailMetadata, 'fileName' | 'fileLocations'> &
  Partial<Pick<FileDetailMetadata, 'fileType'>> & {
    isReadonly?: boolean;
    onChange?: FileInfoChangeHandler;
  };

const FILE_INFO_DEFAULT_PROPS: Partial<FileInfoProps> = {
  isReadonly: undefined,
  onChange: undefined,
};

const StyledTextField = styled(TextField)({
  [`& .${outlinedInputClasses.root}`]: {
    color: GREY,
  },

  [`& .${inputClasses.focused}`]: {
    color: TEXT,
  },
});

const FileLocationActiveCheckbox = styled(Checkbox)({
  color: RED,

  [`&.${checkboxClasses.checked}`]: {
    color: BLUE,
  },
});

const FileInfo = (
  {
    fileName,
    fileType,
    fileLocations,
    isReadonly,
    onChange,
  }: FileInfoProps = FILE_INFO_DEFAULT_PROPS as FileInfoProps,
): JSX.Element => {
  return (
    <FormControl>
      <StyledTextField
        defaultValue={fileName}
        disabled={isReadonly}
        id="file-name"
        label="File name"
        onChange={({ target: { value } }) =>
          onChange?.call(null, { fileName: value })
        }
      />
      {fileType && (
        <Select
          defaultValue={fileType}
          disabled={isReadonly}
          id="file-type"
          label="File type"
          onChange={({ target: { value } }) =>
            onChange?.call(null, { fileType: value as FileType })
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
      )}
      {fileLocations.map(
        (
          { anvilName, anvilDescription, anvilUUID, isFileLocationActive },
          fileLocationIndex,
        ) => (
          <FormControlLabel
            control={
              <FileLocationActiveCheckbox
                checkedIcon={<SyncIcon />}
                defaultChecked={isFileLocationActive}
                disabled={isReadonly}
                icon={<SyncDisabledIcon />}
                onChange={({ target: { checked } }) =>
                  onChange?.call(
                    null,
                    { isFileLocationActive: checked },
                    { fileLocationIndex },
                  )
                }
              />
            }
            key={anvilUUID}
            label={`${anvilName}: ${anvilDescription}`}
            sx={{ color: TEXT }}
            value={`${anvilUUID}-sync`}
          />
        ),
      )}
    </FormControl>
  );
};

FileInfo.defaultProps = FILE_INFO_DEFAULT_PROPS;

export default FileInfo;
