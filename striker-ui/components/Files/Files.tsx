import { useEffect, useState } from 'react';
import { Box } from '@mui/material';
import {
  Add as AddIcon,
  Check as CheckIcon,
  Edit as EditIcon,
} from '@mui/icons-material';
import EventEmitter from 'events';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { BLUE } from '../../lib/consts/DEFAULT_THEME';

import FileEditForm from './FileEditForm';
import FileList from './FileList';
import FileUploadForm from './FileUploadForm';
import IconButton from '../IconButton';
import { Panel } from '../Panels';
import MessageBox from '../MessageBox';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';

import fetchJSON from '../../lib/fetchers/fetchJSON';
import periodicFetch from '../../lib/fetchers/periodicFetch';

const FILES_ENDPOINT_URL = `${API_BASE_URL}/files`;

const Files = (): JSX.Element => {
  const [rawFilesOverview, setRawFilesOverview] = useState<string[][]>([]);
  const [fetchRawFilesError, setFetchRawFilesError] = useState<string>();
  const [isLoadingRawFilesOverview, setIsLoadingRawFilesOverview] =
    useState<boolean>(false);
  const [isEditMode, setIsEditMode] = useState<boolean>(false);

  const fileUploadFormEventEmitter: EventEmitter = new EventEmitter();

  const onAddFileButtonClick = () => {
    fileUploadFormEventEmitter.emit('openFilePicker');
  };

  const onEditFileButtonClick = () => {
    fileUploadFormEventEmitter.emit('clearSelectedFiles');

    setIsEditMode(!isEditMode);
  };

  const fetchRawFilesOverview = async () => {
    setIsLoadingRawFilesOverview(true);

    try {
      const data = await fetchJSON<string[][]>(FILES_ENDPOINT_URL);
      setRawFilesOverview(data);
    } catch (fetchError) {
      setFetchRawFilesError('Failed to get files due to a network issue.');
    }

    setIsLoadingRawFilesOverview(false);
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
        <FileEditForm
          {...{ filesOverview }}
          onEditFilesComplete={fetchRawFilesOverview}
          onPurgeFilesComplete={fetchRawFilesOverview}
        />
      ) : (
        <FileList {...{ filesOverview }} />
      );
    }

    return elements;
  };

  /**
   * Check for new files periodically and update the file list.
   *
   * We need this because adding new files is done async; adding the file may
   * not finish before the request returns.
   *
   * We don't care about edit because database updates are done before the
   * edit request returns.
   */
  periodicFetch<string[][]>(FILES_ENDPOINT_URL, {
    onSuccess: (periodicFilesOverview) => {
      if (periodicFilesOverview.length !== rawFilesOverview.length) {
        setRawFilesOverview(periodicFilesOverview);
      }
    },
  });

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
          <IconButton onClick={onAddFileButtonClick}>
            <AddIcon />
          </IconButton>
        )}
        <IconButton onClick={onEditFileButtonClick}>
          {isEditMode ? <CheckIcon sx={{ color: BLUE }} /> : <EditIcon />}
        </IconButton>
      </Box>
      {fetchRawFilesError && (
        <MessageBox text={fetchRawFilesError} type="error" />
      )}
      <FileUploadForm
        {...{ eventEmitter: fileUploadFormEventEmitter }}
        onFileUploadComplete={fetchRawFilesOverview}
      />
      {buildFileList()}
    </Panel>
  );
};

export default Files;
