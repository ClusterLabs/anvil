import {
  Tab as MUITab,
  tabClasses as muiTabClasses,
  TabProps as MUITabProps,
} from '@mui/material';
import { FC, useMemo } from 'react';

import { BLUE, BORDER_RADIUS, GREY } from '../lib/consts/DEFAULT_THEME';

import { BodyText } from './Text';

const Tab: FC<MUITabProps> = ({ label: originalLabel, ...restTabProps }) => {
  const label = useMemo(
    () =>
      typeof originalLabel === 'string' ? (
        <BodyText inheritColour>{originalLabel}</BodyText>
      ) : (
        originalLabel
      ),
    [originalLabel],
  );

  return (
    <MUITab
      {...restTabProps}
      label={label}
      sx={{
        borderRadius: BORDER_RADIUS,
        color: GREY,
        padding: '.4em .8em',
        textTransform: 'none',

        [`&.${muiTabClasses.selected}`]: {
          color: BLUE,
        },
      }}
    />
  );
};

export default Tab;
