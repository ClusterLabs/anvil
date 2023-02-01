import {
  Tabs as MUITabs,
  tabsClasses as muiTabsClasses,
  TabsProps as MUITabsProps,
} from '@mui/material';
import { FC } from 'react';

import { BLUE, BORDER_RADIUS } from '../lib/consts/DEFAULT_THEME';

const Tabs: FC<MUITabsProps> = ({
  variant = 'fullWidth',
  ...restTabsProps
}) => (
  <MUITabs
    {...restTabsProps}
    variant={variant}
    sx={{
      [`& .${muiTabsClasses.indicator}`]: {
        backgroundColor: BLUE,
        borderRadius: BORDER_RADIUS,
      },
    }}
  />
);

export default Tabs;
