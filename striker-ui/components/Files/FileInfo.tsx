import {
  Checkbox,
  checkboxClasses,
  FormControl,
  FormControlLabel,
  FormGroup,
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

import { BLUE, GREY, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';
import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

import OutlinedInput from '../OutlinedInput';
import OutlinedInputLabel from '../OutlinedInputLabel';

type FileInfoProps = Pick<FileDetailMetadata, 'fileName' | 'fileLocations'> &
  Partial<Pick<FileDetailMetadata, 'fileType'>> & {
    isReadonly?: boolean;
    onChange?: FileInfoChangeHandler;
  };

const FILE_INFO_DEFAULT_PROPS: Partial<FileInfoProps> = {
  isReadonly: undefined,
  onChange: undefined,
};

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
        <OutlinedInputLabel htmlFor={fileNameElementId}>
          {fileNameElementLabel}
        </OutlinedInputLabel>
        <OutlinedInput
          defaultValue={fileName}
          disabled={isReadonly}
          id={fileNameElementId}
          label={fileNameElementLabel}
          onChange={({ target: { value } }) => {
            onChange?.call(null, {
              fileName: value === fileName ? undefined : value,
            });
          }}
        />
      </FormControl>
      {fileType && (
        <FormControl>
          <OutlinedInputLabel htmlFor={fileTypeElementId}>
            {fileTypeElementLabel}
          </OutlinedInputLabel>
          <StyledSelect
            defaultValue={fileType}
            disabled={isReadonly}
            id={fileTypeElementId}
            input={<OutlinedInput label={fileTypeElementLabel} />}
            onChange={({ target: { value } }) => {
              onChange?.call(null, {
                fileType: value === fileType ? undefined : (value as FileType),
              });
            }}
          >
            {UPLOAD_FILE_TYPES_ARRAY.map(
              ([fileTypeKey, [, fileTypeDisplayString]]) => (
                <StyledMenuItem key={fileTypeKey} value={fileTypeKey}>
                  {fileTypeDisplayString}
                </StyledMenuItem>
              ),
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
                onChange={({ target: { checked } }) => {
                  onChange?.call(
                    null,
                    {
                      isFileLocationActive:
                        checked === isFileLocationActive ? undefined : checked,
                    },
                    { fileLocationIndex },
                  );
                }}
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
