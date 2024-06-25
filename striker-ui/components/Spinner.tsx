import {
  Box as MuiBox,
  BoxProps as MuiBoxProps,
  CircularProgressProps as MuiCircularProgressProps,
  styled,
} from '@mui/material';
import { FC } from 'react';

import CircularProgress from './CircularProgress';

type SpinnerOptionalProps = {
  progressProps?: MuiCircularProgressProps;
};

type SpinnerProps = MuiBoxProps & SpinnerOptionalProps;

const SPINNER_DEFAULT_PROPS: Required<SpinnerOptionalProps> = {
  progressProps: {},
};

const SpinnerWrapper = styled(MuiBox)({
  alignItems: 'center',
  display: 'flex',
  justifyContent: 'center',
});

const Spinner: FC<SpinnerProps> = (props): JSX.Element => {
  const {
    mt = '3em',
    progressProps = SPINNER_DEFAULT_PROPS.progressProps,
    ...restProps
  } = props;

  return (
    <SpinnerWrapper mt={mt} {...restProps}>
      <CircularProgress variant="indeterminate" {...progressProps} />
    </SpinnerWrapper>
  );
};

Spinner.defaultProps = SPINNER_DEFAULT_PROPS;

export default Spinner;
