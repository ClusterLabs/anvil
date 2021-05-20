import * as prettyBytes from 'pretty-bytes';
import { makeStyles } from '@material-ui/core/styles';
import { Box } from '@material-ui/core';
import { InnerPanel, PanelHeader } from '../Panels';
import { BodyText } from '../Text';

const useStyles = makeStyles((theme) => ({
  root: {
    overflow: 'auto',
    height: '100%',
    paddingLeft: '.3em',
    [theme.breakpoints.down('md')]: {
      overflow: 'hidden',
    },
  },
  state: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
    paddingTop: '1em',
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
}));

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
            </InnerPanel>
          );
        })}
    </Box>
  );
};

export default ResourceVolumes;
