import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import * as prettyBytes from 'pretty-bytes';

import InnerPanel from './InnerPanel';
import { AllocationBar } from './Bars';
import { BodyText } from './Text';
import PanelHeader from './PanelHeader';

const useStyles = makeStyles(() => ({
  fs: {
    paddingLeft: '10px',
    paddingRight: '10px',
    paddingTop: '20px',
  },
  bar: {
    paddingLeft: '10px',
    paddingRight: '10px',
  },
}));

const SharedStorageNode = ({
  node,
}: {
  node: AnvilSharedStorageNode;
}): JSX.Element => {
  const classes = useStyles();

  return (
    <InnerPanel>
      <PanelHeader>
        <Box display="flex" width="100%">
          <Box>
            <BodyText text={node.nodeInfo?.node_name} />
          </Box>
        </Box>
      </PanelHeader>
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
    </InnerPanel>
  );
};

export default SharedStorageNode;
