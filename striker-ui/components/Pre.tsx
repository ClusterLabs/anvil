import { Box as MuiBox, BoxProps as MuiBoxProps } from '@mui/material';

import { TEXT } from '../lib/consts/DEFAULT_THEME';

const Pre: React.FC<MuiBoxProps> = (props) => {
  const { children, ...restProps } = props;

  return (
    <MuiBox
      color={TEXT}
      component="pre"
      whiteSpace="pre-wrap"
      width="100%"
      {...restProps}
    >
      {children}
    </MuiBox>
  );
};

export default Pre;
