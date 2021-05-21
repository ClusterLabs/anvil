import * as prettyBytes from 'pretty-bytes';
import { makeStyles, Box, Divider } from '@material-ui/core';
import InsertLinkIcon from '@material-ui/icons/InsertLink';
import { InnerPanel, PanelHeader } from '../Panels';
import { BodyText } from '../Text';
import Decorator, { Colours } from '../Decorator';
import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles((theme) => ({
  root: {
    overflow: 'auto',
    height: '100%',
    paddingLeft: '.3em',
    [theme.breakpoints.down('md')]: {
      overflow: 'hidden',
    },
  },
  connection: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
    paddingTop: '1em',
    paddingBottom: '.7em',
  },
  bar: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },
  header: {
    paddingTop: '.3em',
    paddingRight: '.7em',
  },
  label: {
    paddingTop: '.3em',
  },
  decoratorBox: {
    paddingRight: '.3em',
  },
  divider: {
    background: DIVIDER,
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
  const classes = useStyles();

  return (
    <Box className={classes.root}>
      {resource &&
        resource.volumes.map((volume) => {
          return (
            <InnerPanel key={volume.drbd_device_minor}>
              <PanelHeader>
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
              </PanelHeader>
              {volume.connections.map(
                (connection): JSX.Element => {
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
                      <Divider className={classes.divider} />
                    </>
                  );
                },
              )}
            </InnerPanel>
          );
        })}
    </Box>
  );
};

export default ResourceVolumes;
