import {
  Tab as MuiTab,
  tabClasses as muiTabClasses,
  TabProps as MuiTabProps,
  styled,
} from '@mui/material';
import { useMemo } from 'react';

import { BLUE, BORDER_RADIUS, GREY } from '../lib/consts/DEFAULT_THEME';

import { BodyText } from './Text';

const StyledTab = styled(MuiTab)({
  borderRadius: BORDER_RADIUS,
  color: GREY,
  padding: '.4em .8em',
  textTransform: 'none',

  [`&.${muiTabClasses.selected}`]: {
    color: BLUE,
  },
});

const Tab: React.FC<MuiTabProps> = ({
  label: originalLabel,
  ...restTabProps
}) => {
  const label = useMemo(
    () =>
      typeof originalLabel === 'string' ? (
        <BodyText inheritColour>{originalLabel}</BodyText>
      ) : (
        originalLabel
      ),
    [originalLabel],
  );

  return <StyledTab label={label} {...restTabProps} />;
};

export default Tab;
