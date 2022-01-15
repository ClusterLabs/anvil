import { Box, IconButton } from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { styled } from '@mui/material/styles';
import EventEmitter from 'events';

import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';

import { Panel } from '../Panels';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';
import FileList from './FileList';
import FileUploadInfo from './FileUploadInfo';

const PREFIX = 'Files';

const classes = {
  addFileButton: `${PREFIX}-addFileButton`,
  addFileInput: `${PREFIX}-addFileInput`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.addFileButton}`]: ICON_BUTTON_STYLE,

  [`& .${classes.addFileInput}`]: {
    display: 'none',
  },
}));

const Files = (): JSX.Element => {
  const openFilePickerEventEmitter: EventEmitter = new EventEmitter();

  const { data: fileList, isLoading } = PeriodicFetch(
    `${process.env.NEXT_PUBLIC_API_URL?.replace('/cgi-bin', '/api')}/files`,
    0,
  );

  const onAddFileButtonClick = () => {
    openFilePickerEventEmitter.emit('open');
  };

  return (
    <Panel>
      <StyledDiv>
        <Box style={{ display: 'flex', width: '100%' }}>
          <Box style={{ flexGrow: 1 }}>
            <HeaderText text="Files" />
          </Box>
          <Box>
            <IconButton
              className={classes.addFileButton}
              onClick={onAddFileButtonClick}
            >
              <AddIcon />
            </IconButton>
          </Box>
        </Box>
        <FileUploadInfo
          openFilePickerEventEmitter={openFilePickerEventEmitter}
        />
        {isLoading ? <Spinner /> : <FileList list={fileList} />}
      </StyledDiv>
    </Panel>
  );
};

export default Files;
