import MuiBox, { BoxProps as MuiBoxProps } from '@mui/material/Box';

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
