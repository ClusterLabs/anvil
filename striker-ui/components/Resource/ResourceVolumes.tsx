import MuiInsertLinkIcon from '@mui/icons-material/InsertLink';
import { Box as MuiBox, styled } from '@mui/material';
import * as prettyBytes from 'pretty-bytes';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import Decorator, { Colours } from '../Decorator';
import Divider from '../Divider';
import { InnerPanel, InnerPanelHeader } from '../Panels';
import { BodyText } from '../Text';

const PREFIX = 'ResourceVolumes';

const classes = {
  connection: `${PREFIX}-connection`,
  bar: `${PREFIX}-bar`,
  header: `${PREFIX}-header`,
  label: `${PREFIX}-label`,
  decoratorBox: `${PREFIX}-decoratorBox`,
  divider: `${PREFIX}-divider`,
};

const StyledBox = styled(MuiBox)(({ theme }) => ({
  overflow: 'auto',
  height: '100%',
  paddingLeft: '.3em',
  [theme.breakpoints.down('md')]: {
    overflow: 'hidden',
  },

  [`& .${classes.connection}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
    paddingTop: '1em',
    paddingBottom: '.7em',
  },

  [`& .${classes.bar}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },

  [`& .${classes.header}`]: {
    paddingTop: '.3em',
    paddingRight: '.7em',
  },

  [`& .${classes.label}`]: {
    paddingTop: '.3em',
  },

  [`& .${classes.decoratorBox}`]: {
    paddingRight: '.3em',
  },

  [`& .${classes.divider}`]: {
    backgroundColor: DIVIDER,
  },
}));

const selectDecorator = (state: string): Colours => {
  switch (state) {
    case 'connected':
      return 'ok';
    case 'connecting':
      return 'warning';
    default:
      return 'error';
  }
};

const ResourceVolumes = ({
  resource,
}: {
  resource: AnvilReplicatedStorage;
}): React.ReactElement => (
  <StyledBox>
    {resource &&
      resource.volumes.map((volume) => (
        <InnerPanel key={volume.drbd_device_minor}>
          <InnerPanelHeader>
            <MuiBox display="flex" width="100%" className={classes.header}>
              <MuiBox flexGrow={1}>
                <BodyText text={`Volume: ${volume.number}`} />
              </MuiBox>
              <MuiBox>
                <BodyText
                  text={`Size: ${prettyBytes.default(volume.size, {
                    binary: true,
                  })}`}
                />
              </MuiBox>
            </MuiBox>
          </InnerPanelHeader>
          {volume.connections.map(
            (connection, index): React.ReactElement => (
              <>
                <MuiBox
                  key={connection.fencing}
                  display="flex"
                  width="100%"
                  className={classes.connection}
                >
                  <MuiBox className={classes.decoratorBox}>
                    <Decorator
                      colour={selectDecorator(connection.connection_state)}
                    />
                  </MuiBox>
                  <MuiBox>
                    <MuiBox display="flex" width="100%">
                      <BodyText text={connection.targets[0].target_name} />
                      <MuiInsertLinkIcon style={{ color: DIVIDER }} />
                      <BodyText text={connection.targets[1].target_name} />
                    </MuiBox>
                    <MuiBox display="flex" justifyContent="center" width="100%">
                      <BodyText text={connection.connection_state} />
                    </MuiBox>
                  </MuiBox>
                </MuiBox>
                {volume.connections.length - 1 !== index ? <Divider /> : null}
              </>
            ),
          )}
        </InnerPanel>
      ))}
  </StyledBox>
);

export default ResourceVolumes;
