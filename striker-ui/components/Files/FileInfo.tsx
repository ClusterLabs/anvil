import {
  Checkbox,
  checkboxClasses,
  FormControl,
  FormControlLabel,
  FormGroup,
  InputLabel,
  inputLabelClasses,
  MenuItem,
  menuItemClasses,
  Select,
  selectClasses,
  styled,
} from '@mui/material';
import {
  Sync as SyncIcon,
  SyncDisabled as SyncDisabledIcon,
} from '@mui/icons-material';
import { v4 as uuidv4 } from 'uuid';

import {
  BLACK,
  BLUE,
  BORDER_RADIUS,
  GREY,
  RED,
  TEXT,
} from '../../lib/consts/DEFAULT_THEME';
import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

import OutlinedInput from '../OutlinedInput';

type FileInfoProps = Pick<FileDetailMetadata, 'fileName' | 'fileLocations'> &
  Partial<Pick<FileDetailMetadata, 'fileType'>> & {
    isReadonly?: boolean;
    onChange?: FileInfoChangeHandler;
  };

const FILE_INFO_DEFAULT_PROPS: Partial<FileInfoProps> = {
  isReadonly: undefined,
  onChange: undefined,
};

const StyledInputLabel = styled(InputLabel)({
  color: GREY,

  [`&.${inputLabelClasses.focused}`]: {
    backgroundColor: GREY,
    borderRadius: BORDER_RADIUS,
    color: BLACK,
    padding: '.1em .6em',
  },
});

const StyledSelect = styled(Select)({
  [`& .${selectClasses.icon}`]: {
    color: GREY,
  },
});

const StyledMenuItem = styled(MenuItem)({
  backgroundColor: TEXT,
  paddingRight: '3em',

  [`&.${menuItemClasses.selected}`]: {
    backgroundColor: GREY,
    fontWeight: 400,

    '&:hover': {
      backgroundColor: GREY,
    },
  },

  '&:hover': {
    backgroundColor: GREY,
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
  const idExtension = uuidv4();

  const fileNameElementId = `file-name-${idExtension}`;
  const fileNameElementLabel = 'File name';

  const fileTypeElementId = `file-type-${idExtension}`;
  const fileTypeElementLabel = 'File type';

  return (
    <FormGroup sx={{ '> :not(:first-child)': { marginTop: '1em' } }}>
      <FormControl>
        <StyledInputLabel htmlFor={fileNameElementId} variant="outlined">
          {fileNameElementLabel}
        </StyledInputLabel>
        <OutlinedInput
          defaultValue={fileName}
          disabled={isReadonly}
          id={fileNameElementId}
          label={fileNameElementLabel}
          onChange={({ target: { value } }) =>
            onChange?.call(null, { fileName: value })
          }
        />
      </FormControl>
      {fileType && (
        <FormControl>
          <StyledInputLabel htmlFor={fileTypeElementId} variant="outlined">
            {fileTypeElementLabel}
          </StyledInputLabel>
          <StyledSelect
            defaultValue={fileType}
            disabled={isReadonly}
            id={fileTypeElementId}
            input={<OutlinedInput label={fileTypeElementLabel} />}
            onChange={({ target: { value } }) =>
              onChange?.call(null, { fileType: value as FileType })
            }
          >
            {UPLOAD_FILE_TYPES_ARRAY.map(
              ([fileTypeKey, [, fileTypeDisplayString]]) => {
                return (
                  <StyledMenuItem key={fileTypeKey} value={fileTypeKey}>
                    {fileTypeDisplayString}
                  </StyledMenuItem>
                );
              },
            )}
          </StyledSelect>
        </FormControl>
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
    </FormGroup>
  );
};

FileInfo.defaultProps = FILE_INFO_DEFAULT_PROPS;

export default FileInfo;
