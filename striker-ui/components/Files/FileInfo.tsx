import {
  Checkbox,
  checkboxClasses,
  FormControl,
  FormControlLabel,
  FormGroup,
  Grid,
  styled,
} from '@mui/material';
import {
  Sync as SyncIcon,
  SyncDisabled as SyncDisabledIcon,
} from '@mui/icons-material';
import { ReactElement, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import { BLUE, RED, TEXT } from '../../lib/consts/DEFAULT_THEME';
import { UPLOAD_FILE_TYPES_ARRAY } from '../../lib/consts/UPLOAD_FILE_TYPES';

import List from '../List';
import MenuItem from '../MenuItem';
import OutlinedInput from '../OutlinedInput';
import OutlinedInputLabel from '../OutlinedInputLabel';
import { ExpandablePanel, InnerPanelBody } from '../Panels';
import Select from '../Select';

type FileInfoProps = Pick<FileDetailMetadata, 'fileName' | 'fileLocations'> &
  Partial<Pick<FileDetailMetadata, 'fileType'>> & {
    isReadonly?: boolean;
    onChange?: FileInfoChangeHandler;
  };

const FILE_INFO_DEFAULT_PROPS: Partial<FileInfoProps> = {
  isReadonly: undefined,
  onChange: undefined,
};

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

  const anFileLocations = useMemo(
    () =>
      fileLocations.reduce<
        Record<
          string,
          Pick<FileLocation, 'anvilDescription' | 'anvilName' | 'anvilUUID'> & {
            flocs: FileLocation[];
          }
        >
      >((previous, fileLocation) => {
        const { anvilDescription, anvilName, anvilUUID } = fileLocation;

        if (!previous[anvilUUID]) {
          previous[anvilUUID] = {
            anvilDescription,
            anvilName,
            anvilUUID,
            flocs: [],
          };
        }

        previous[anvilUUID].flocs.push(fileLocation);

        return previous;
      }, {}),
    [fileLocations],
  );

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
          <Select
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
                <MenuItem key={fileTypeKey} value={fileTypeKey}>
                  {fileTypeDisplayString}
                </MenuItem>
              ),
            )}
          </Select>
        </FormControl>
      )}
      <List
        listItems={anFileLocations}
        listProps={{ dense: true, disablePadding: true }}
        renderListItem={(anvilUUID, { anvilDescription, anvilName, flocs }) => (
          <ExpandablePanel
            header={`${anvilName}: ${anvilDescription}`}
            panelProps={{ padding: 0, width: '100%' }}
          >
            <InnerPanelBody>
              <Grid
                columns={{ xs: 1, sm: 2, md: 3, lg: 4, xl: 5 }}
                columnSpacing="1em"
                container
                direction="row"
              >
                {flocs.map<ReactElement>(
                  ({
                    fileLocationUUID: flocUUID,
                    hostName,
                    hostUUID,
                    isFileLocationActive,
                  }) => (
                    <Grid item key={`floc-${anvilUUID}-${hostUUID}`} xs={1}>
                      <FormControlLabel
                        control={
                          <FileLocationActiveCheckbox
                            checkedIcon={<SyncIcon />}
                            defaultChecked={isFileLocationActive}
                            disabled={isReadonly}
                            edge="start"
                            icon={<SyncDisabledIcon />}
                            onChange={({ target: { checked } }) => {
                              onChange?.call(
                                null,
                                {
                                  isFileLocationActive:
                                    checked === isFileLocationActive
                                      ? undefined
                                      : checked,
                                },
                                {
                                  fileLocationIndex: fileLocations.findIndex(
                                    ({ fileLocationUUID }) =>
                                      flocUUID === fileLocationUUID,
                                  ),
                                },
                              );
                            }}
                          />
                        }
                        label={hostName}
                        sx={{ color: TEXT }}
                        value={`${hostUUID}-sync`}
                      />
                    </Grid>
                  ),
                )}
              </Grid>
            </InnerPanelBody>
          </ExpandablePanel>
        )}
      />
    </FormGroup>
  );
};

FileInfo.defaultProps = FILE_INFO_DEFAULT_PROPS;

export default FileInfo;
