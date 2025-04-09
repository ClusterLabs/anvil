import { Box, styled } from '@mui/material';
import { useMemo } from 'react';

import { AllocationBar } from '../Bars';
import { toBinaryByte } from '../../lib/format_data_size_wrappers';
import { BodyText } from '../Text';

const PREFIX = 'StorageGroup';

const classes = {
  fs: `${PREFIX}-fs`,
  bar: `${PREFIX}-bar`,
  decoratorBox: `${PREFIX}-decoratorBox`,
};

const StyledDiv = styled('div')(() => ({
  [`& .${classes.fs}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },

  [`& .${classes.bar}`]: {
    paddingLeft: '.7em',
    paddingRight: '.7em',
  },

  [`& .${classes.decoratorBox}`]: {
    paddingRight: '.3em',
  },
}));

const StorageGroup: React.FC<StorageGroupProps> = (props) => {
  const { storageGroup: group } = props;

  const { free: nFree, size: nTotal, used: nUsed } = group;

  const percentAllocated = useMemo(
    () => Number((nUsed * BigInt(100)) / nTotal),
    [nUsed, nTotal],
  );

  return (
    <StyledDiv>
      <Box display="flex" width="100%" className={classes.fs}>
        <Box flexGrow={1}>
          <BodyText text={`Used: ${toBinaryByte(nTotal - nFree)}`} />
        </Box>
        <Box>
          <BodyText text={`Free: ${toBinaryByte(nFree)}`} />
        </Box>
      </Box>
      <Box display="flex" width="100%" className={classes.bar}>
        <Box flexGrow={1}>
          <AllocationBar allocated={percentAllocated} />
        </Box>
      </Box>
      <Box display="flex" justifyContent="center" width="100%">
        <BodyText text={`Total Storage: ${toBinaryByte(nTotal)}`} />
      </Box>
    </StyledDiv>
  );
};

export default StorageGroup;
