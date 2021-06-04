import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import * as prettyBytes from 'pretty-bytes';
import { AllocationBar } from '../Bars';
import { BodyText } from '../Text';
import Decorator from '../Decorator';

const useStyles = makeStyles(() => ({
  fs: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
    paddingTop: '1.2em',
  },
  bar: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },
  decoratorBox: {
    paddingRight: '.3em',
  },
}));

const SharedStorageHost = ({
  host,
}: {
  host: AnvilFileSystemHost;
}): JSX.Element => {
  const classes = useStyles();
  return (
    <>
      <Box display="flex" width="100%" className={classes.fs}>
        <Box flexGrow={1}>
          <BodyText text={host.host_name || 'Not Available'} />
        </Box>
        <Box className={classes.decoratorBox}>
          <Decorator colour={host.is_mounted ? 'ok' : 'error'} />
        </Box>
        <Box>
          <BodyText text={host.is_mounted ? 'Mounted' : 'Not Mounted'} />
        </Box>
      </Box>
      {host.is_mounted && (
        <>
          <Box display="flex" width="100%" className={classes.fs}>
            <Box flexGrow={1}>
              <BodyText
                text={`Used: ${prettyBytes.default(host.total - host.free, {
                  binary: true,
                })}`}
              />
            </Box>
            <Box>
              <BodyText
                text={`Free: ${prettyBytes.default(host.free, {
                  binary: true,
                })}`}
              />
            </Box>
          </Box>
          <Box display="flex" width="100%" className={classes.bar}>
            <Box flexGrow={1}>
              <AllocationBar
                allocated={((host.total - host.free) / host.total) * 100}
              />
            </Box>
          </Box>
          <Box display="flex" justifyContent="center" width="100%">
            <BodyText
              text={`Total Storage: ${prettyBytes.default(host.total, {
                binary: true,
              })}`}
            />
          </Box>
        </>
      )}
    </>
  );
};

export default SharedStorageHost;
