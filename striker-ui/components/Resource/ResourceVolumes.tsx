import * as prettyBytes from 'pretty-bytes';
import { Box, Divider } from '@mui/material';
import { styled } from '@mui/material/styles';
import InsertLinkIcon from '@mui/icons-material/InsertLink';
import { InnerPanel, InnerPanelHeader } from '../Panels';
import { BodyText } from '../Text';
import Decorator, { Colours } from '../Decorator';
import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'ResourceVolumes';

const classes = {
  connection: `${PREFIX}-connection`,
  bar: `${PREFIX}-bar`,
  header: `${PREFIX}-header`,
  label: `${PREFIX}-label`,
  decoratorBox: `${PREFIX}-decoratorBox`,
  divider: `${PREFIX}-divider`,
};

const StyledBox = styled(Box)(({ theme }) => ({
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
}): JSX.Element => {
  return (
    <StyledBox>
      {resource &&
        resource.volumes.map((volume) => {
          return (
            <InnerPanel key={volume.drbd_device_minor}>
              <InnerPanelHeader>
                <Box display="flex" width="100%" className={classes.header}>
                  <Box flexGrow={1}>
                    <BodyText text={`Volume: ${volume.number}`} />
                  </Box>
                  <Box>
                    <BodyText
                      text={`Size: ${prettyBytes.default(volume.size, {
                        binary: true,
                      })}`}
                    />
                  </Box>
                </Box>
              </InnerPanelHeader>
              {volume.connections.map(
                (connection, index): JSX.Element => {
                  return (
                    <>
                      <Box
                        key={connection.fencing}
                        display="flex"
                        width="100%"
                        className={classes.connection}
                      >
                        <Box className={classes.decoratorBox}>
                          <Decorator
                            colour={selectDecorator(
                              connection.connection_state,
                            )}
                          />
                        </Box>
                        <Box>
                          <Box display="flex" width="100%">
                            <BodyText
                              text={connection.targets[0].target_name}
                            />
                            <InsertLinkIcon style={{ color: DIVIDER }} />
                            <BodyText
                              text={connection.targets[1].target_name}
                            />
                          </Box>
                          <Box
                            display="flex"
                            justifyContent="center"
                            width="100%"
                          >
                            <BodyText text={connection.connection_state} />
                          </Box>
                        </Box>
                      </Box>
                      {volume.connections.length - 1 !== index ? (
                        <Divider className={classes.divider} />
                      ) : null}
                    </>
                  );
                },
              )}
            </InnerPanel>
          );
        })}
    </StyledBox>
  );
};

export default ResourceVolumes;
