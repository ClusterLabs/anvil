import { FC, useMemo } from 'react';
import { Box as MUIBox, SxProps, Theme } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const InnerPanel: FC<InnerPanelProps> = ({
  headerMarginOffset: hmo = '.3em',
  ml,
  mv = '1.4em',
  sx,
  // Props that depend on others.
  mb = mv,
  mt = mv,

  ...muiBoxRestProps
}) => {
  const marginLeft = useMemo(
    () => (ml ? `calc(${ml} + ${hmo})` : hmo),
    [hmo, ml],
  );
  const marginTop = useMemo(() => {
    const resultMt = typeof mt === 'number' ? `${mt}px` : mt;

    return `calc(${resultMt} + ${hmo})`;
  }, [hmo, mt]);

  const combinedSx = useMemo<SxProps<Theme>>(
    () => ({
      borderWidth: '1px',
      borderRadius: BORDER_RADIUS,
      borderStyle: 'solid',
      borderColor: DIVIDER,
      paddingBottom: 0,
      position: 'relative',

      ...sx,
    }),
    [sx],
  );

  return (
    <MUIBox
      mb={mb}
      ml={marginLeft}
      mt={marginTop}
      {...muiBoxRestProps}
      sx={combinedSx}
    />
  );
};

export default InnerPanel;
