import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { ClassNameMap } from '@material-ui/styles';

import * as prettyBytes from 'pretty-bytes';

import { AllocationBar } from './Bars';
import { BodyText } from './Text';
import { BLUE, RED_ON } from '../lib/consts/DEFAULT_THEME';

const selectDecorator = (
  state: boolean,
): keyof ClassNameMap<'mounted' | 'notMounted'> => {
  return state ? 'mounted' : 'notMounted';
};

const useStyles = makeStyles(() => ({
  fs: {
    paddingLeft: '10px',
    paddingRight: '10px',
    paddingTop: '15px',
  },
  bar: {
    paddingLeft: '10px',
    paddingRight: '10px',
  },
  decorator: {
    width: '20px',
    height: '100%',
    borderRadius: 2,
  },
  decoratorBox: {
    paddingRight: '5px',
  },
  mounted: {
    backgroundColor: BLUE,
  },
  notMounted: {
    backgroundColor: RED_ON,
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
          <BodyText text={node.nodeInfo?.node_name} />
        </Box>
        <Box className={classes.decoratorBox}>
          <div
            className={`${classes.decorator} ${
              classes[selectDecorator(node.is_mounted)]
            }`}
          />
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
