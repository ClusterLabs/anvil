import {
  Checkbox,
  checkboxClasses,
  FormControl,
  FormControlLabel,
  inputClasses,
  inputLabelClasses,
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

import {
  BLUE,
  BORDER_RADIUS,
  GREY,
  RED,
  TEXT,
  UNSELECTED,
} from '../../lib/consts/DEFAULT_THEME';
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
  [`& .${inputLabelClasses.root}`]: {
    color: GREY,

    [`&.${inputClasses.focused}`]: {
      backgroundColor: BLUE,
      borderRadius: BORDER_RADIUS,
      color: TEXT,
      padding: '.1em .6em',
    },
  },

  [`& .${outlinedInputClasses.root}`]: {
    color: GREY,

    [`& .${outlinedInputClasses.notchedOutline}`]: {
      borderColor: UNSELECTED,
    },

    '&:hover': {
      [`& .${outlinedInputClasses.notchedOutline}`]: {
        borderColor: GREY,
      },
    },

    [`&.${inputClasses.focused}`]: {
      color: TEXT,

      [`& .${outlinedInputClasses.notchedOutline}`]: {
        borderColor: BLUE,

        '& legend': {
          paddingRight: '1.2em',
        },
      },
    },
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
