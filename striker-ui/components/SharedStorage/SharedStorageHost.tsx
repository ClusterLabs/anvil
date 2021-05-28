import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import * as prettyBytes from 'pretty-bytes';
import { AllocationBar } from '../Bars';
import { BodyText } from '../Text';

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
  group,
}: {
  group: AnvilSharedStorageGroup;
}): JSX.Element => {
  const classes = useStyles();
  return (
    <>
      <Box display="flex" width="100%" className={classes.fs}>
        <Box flexGrow={1}>
          <BodyText
            text={`Used: ${prettyBytes.default(
              group.storage_group_total - group.storage_group_free,
              {
                binary: true,
              },
            )}`}
          />
        </Box>
        <Box>
          <BodyText
            text={`Free: ${prettyBytes.default(group.storage_group_free, {
              binary: true,
            })}`}
          />
        </Box>
      </Box>
      <Box display="flex" width="100%" className={classes.bar}>
        <Box flexGrow={1}>
          <AllocationBar
            allocated={
              ((group.storage_group_total - group.storage_group_free) /
                group.storage_group_total) *
              100
            }
          />
        </Box>
      </Box>
      <Box display="flex" justifyContent="center" width="100%">
        <BodyText
          text={`Total Storage: ${prettyBytes.default(
            group.storage_group_total,
            {
              binary: true,
            },
          )}`}
        />
      </Box>
    </>
  );
};

export default SharedStorageHost;
