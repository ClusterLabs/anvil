import { Box as MuiBox, BoxProps as MuiBoxProps } from '@mui/material';
import { merge } from 'lodash';
import { useMemo } from 'react';

const InnerPanelBody: React.FC<MuiBoxProps> = ({
  sx,
  ...innerPanelBodyRestProps
}) => {
  const combinedSx = useMemo<MuiBoxProps['sx']>(
    () =>
      merge(
        {
          position: 'relative',
          zIndex: 20,
        },
        sx,
      ),
    [sx],
  );

  return (
    <MuiBox padding=".3em .7em" {...innerPanelBodyRestProps} sx={combinedSx} />
  );
};

export default InnerPanelBody;
