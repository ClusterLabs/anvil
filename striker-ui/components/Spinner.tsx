import MuiBox, { BoxProps as MuiBoxProps } from '@mui/material/Box';
import { CircularProgressProps as MuiCircularProgressProps } from '@mui/material/CircularProgress';
import styled from '@mui/material/styles/styled';

import CircularProgress from './CircularProgress';

type SpinnerOptionalProps = {
  progressProps?: MuiCircularProgressProps;
};

type SpinnerProps = MuiBoxProps & SpinnerOptionalProps;

const SpinnerWrapper = styled(MuiBox)({
  alignItems: 'center',
  display: 'flex',
  justifyContent: 'center',
});

const Spinner: React.FC<SpinnerProps> = (props): React.ReactElement => {
  const { mt = '3em', progressProps, ...restProps } = props;

  return (
    <SpinnerWrapper mt={mt} {...restProps}>
      <CircularProgress variant="indeterminate" {...progressProps} />
    </SpinnerWrapper>
  );
};

export default Spinner;
