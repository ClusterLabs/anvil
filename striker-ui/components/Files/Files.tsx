import { useRef } from 'react';
import { Box, IconButton, Input, InputLabel } from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { styled } from '@mui/material/styles';

import ICON_BUTTON_STYLE from '../../lib/consts/ICON_BUTTON_STYLE';

import { Panel } from '../Panels';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';

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
  const addFileInputRef = useRef<HTMLInputElement>();

  const { data, isLoading } = PeriodicFetch(
    `${process.env.NEXT_PUBLIC_API_URL?.replace('/cgi-bin', '/api')}/files`,
  );

  // Let the icon button trigger the invisible input element.
  const onAddFileButtonClick = () => {
    addFileInputRef.current?.click();
  };

  return (
    <Panel>
      <StyledDiv>
        <Box style={{ display: 'flex', width: '100%' }}>
          <Box style={{ flexGrow: 1 }}>
            <HeaderText text="Files" />
          </Box>
          <Box>
            <form encType="multipart/form-data">
              <InputLabel htmlFor="add-file-input">
                <Input
                  className={classes.addFileInput}
                  id="add-file-input"
                  ref={addFileInputRef}
                  type="file"
                />
                <IconButton
                  className={classes.addFileButton}
                  onClick={onAddFileButtonClick}
                >
                  <AddIcon />
                </IconButton>
              </InputLabel>
            </form>
          </Box>
        </Box>
        {isLoading ? (
          <Spinner />
        ) : (
          <Box>
            <span>{data}</span>
          </Box>
        )}
      </StyledDiv>
    </Panel>
  );
};

export default Files;
