import { useEffect, useState } from 'react';
import { Box, IconButton } from '@mui/material';
import {
  Add as AddIcon,
  Check as CheckIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import EventEmitter from 'events';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { BLUE, PURPLE, RED } from '../../lib/consts/DEFAULT_THEME';
import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';

import { Panel } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import FileList from './FileList';
import FileUploadForm from './FileUploadForm';
import FileEditForm from './FileEditForm';

import fetchJSON from '../../lib/fetchers/fetchJSON';

const StyledIconButton = styled(IconButton)(ICON_BUTTON_STYLE);

const MESSAGE_BOX_CLASS_PREFIX = 'MessageBox';

const MESSAGE_BOX_CLASSES = {
  error: `${MESSAGE_BOX_CLASS_PREFIX}-error`,
  warning: `${MESSAGE_BOX_CLASS_PREFIX}-warning`,
};

const MessageBox = styled(Box)({
  padding: '.2em .4em',

  [`&.${MESSAGE_BOX_CLASSES.error}`]: {
    backgroundColor: RED,
  },

  [`&.${MESSAGE_BOX_CLASSES.warning}`]: {
    backgroundColor: PURPLE,
  },
});

const Files = (): JSX.Element => {
  const [rawFilesOverview, setRawFilesOverview] = useState<string[][]>([]);
  const [fetchRawFilesError, setFetchRawFilesError] = useState<string>();
  const [
    isLoadingRawFilesOverview,
    setIsLoadingRawFilesOverview,
  ] = useState<boolean>(false);
  const [isEditMode, setIsEditMode] = useState<boolean>(false);

  const fileUploadFormEventEmitter: EventEmitter = new EventEmitter();

  const onAddFileButtonClick = () => {
    fileUploadFormEventEmitter.emit('openFilePicker');
  };

  const onEditFileButtonClick = () => {
    fileUploadFormEventEmitter.emit('clearSelectedFiles');

    setIsEditMode(!isEditMode);
  };

  const buildFileList = (): JSX.Element => {
    let elements: JSX.Element;
    if (isLoadingRawFilesOverview) {
      elements = <Spinner />;
    } else {
      const filesOverview: FileOverviewMetadata[] = rawFilesOverview.map(
        ([fileUUID, fileName, fileSizeInBytes, fileType, fileChecksum]) => ({
          fileChecksum,
          fileName,
          fileSizeInBytes: parseInt(fileSizeInBytes, 10),
          fileType: fileType as FileType,
          fileUUID,
        }),
      );

      elements = isEditMode ? (
        <FileEditForm {...{ filesOverview }} />
      ) : (
        <FileList {...{ filesOverview }} />
      );
    }

    return elements;
  };

  const fetchRawFilesOverview = async () => {
    setIsLoadingRawFilesOverview(true);

    try {
      const data = await fetchJSON<string[][]>(`${API_BASE_URL}/files`);
      setRawFilesOverview(data);
    } catch (fetchError) {
      setFetchRawFilesError('Failed to get files due to a network issue.');
    }

    setIsLoadingRawFilesOverview(false);
  };

  useEffect(() => {
    if (!isEditMode) {
      fetchRawFilesOverview();
    }
  }, [isEditMode]);

  return (
    <Panel>
      <Box
        sx={{
          alignItems: 'center',
          display: 'flex',
          flexDirection: 'row',
          marginBottom: '1em',
          width: '100%',
          '& > :first-child': { flexGrow: 1 },
          '& > :not(:first-child, :last-child)': {
            marginRight: '.3em',
          },
        }}
      >
        <HeaderText text="Files" />
        {!isEditMode && (
          <StyledIconButton onClick={onAddFileButtonClick}>
            <AddIcon />
          </StyledIconButton>
        )}
        <StyledIconButton onClick={onEditFileButtonClick}>
          {isEditMode ? <CheckIcon sx={{ color: BLUE }} /> : <EditIcon />}
        </StyledIconButton>
      </Box>
      {fetchRawFilesError && (
        <MessageBox className={MESSAGE_BOX_CLASSES.error}>
          <BodyText text={fetchRawFilesError} />
        </MessageBox>
      )}
      <FileUploadForm
        {...{ eventEmitter: fileUploadFormEventEmitter }}
        onFileUploadComplete={() => {
          fetchRawFilesOverview();
        }}
      />
      {buildFileList()}
    </Panel>
  );
};

export default Files;
