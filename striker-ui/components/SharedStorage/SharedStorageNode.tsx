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

const SharedStorageNode = ({
  node,
}: {
  node: AnvilSharedStorageNode;
}): JSX.Element => {
  const classes = useStyles();
  return (
    <>
      <Box display="flex" width="100%" className={classes.fs}>
        <Box flexGrow={1}>
          <BodyText text={node.nodeInfo?.node_name || 'Not Available'} />
        </Box>
        <Box className={classes.decoratorBox}>
          <Decorator colour={node.is_mounted ? 'ok' : 'error'} />
        </Box>
        <Box>
          <BodyText text={node.is_mounted ? 'Mounted' : 'Not Mounted'} />
        </Box>
      </Box>
      {node.is_mounted && (
        <>
          <Box display="flex" width="100%" className={classes.fs}>
            <Box flexGrow={1}>
              <BodyText
                text={`Used: ${prettyBytes.default(node.total - node.free, {
                  binary: true,
                })}`}
              />
            </Box>
            <Box>
              <BodyText
                text={`Free: ${prettyBytes.default(node.free, {
                  binary: true,
                })}`}
              />
            </Box>
          </Box>
          <Box display="flex" width="100%" className={classes.bar}>
            <Box flexGrow={1}>
              <AllocationBar
                allocated={((node.total - node.free) / node.total) * 100}
              />
            </Box>
          </Box>
          <Box display="flex" justifyContent="center" width="100%">
            <BodyText
              text={`Total Storage: ${prettyBytes.default(node.total, {
                binary: true,
              })}`}
            />
          </Box>
        </>
      )}
    </>
  );
};

export default SharedStorageNode;
