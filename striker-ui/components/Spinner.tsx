import {
  Box as MuiBox,
  BoxProps as MuiBoxProps,
  CircularProgressProps as MuiCircularProgressProps,
  styled,
} from '@mui/material';

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
