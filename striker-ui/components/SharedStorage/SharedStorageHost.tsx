import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';
import * as prettyBytes from 'pretty-bytes';
import { AllocationBar } from '../Bars';
import { BodyText } from '../Text';

const PREFIX = 'SharedStorageHost';

const classes = {
  fs: `${PREFIX}-fs`,
  bar: `${PREFIX}-bar`,
  decoratorBox: `${PREFIX}-decoratorBox`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.fs}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
    paddingTop: '2.2em',
  },

  [`& .${classes.bar}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },

  [`& .${classes.decoratorBox}`]: {
    paddingRight: '.3em',
  },
}));

const SharedStorageHost = ({
  group,
}: {
  group: AnvilSharedStorageGroup;
}): JSX.Element => (
  <StyledDiv>
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
        text={`Total Storage: ${prettyBytes.default(group.storage_group_total, {
          binary: true,
        })}`}
      />
    </Box>
  </StyledDiv>
);

export default SharedStorageHost;
