import muiTabClasses from '@mui/material/Tab/tabClasses';
import MuiTabs, { tabsClasses as muiTabsClasses } from '@mui/material/Tabs';
import useMediaQuery from '@mui/material/useMediaQuery';
import { Breakpoint as MuiBreakpoint } from '@mui/material/node_modules/@mui/system/createBreakpoints/createBreakpoints';
import useTheme from '@mui/material/styles/useTheme';
import styled from '@mui/material/styles/styled';
import { useCallback, useMemo } from 'react';

import { BLUE, BORDER_RADIUS } from '../lib/consts/DEFAULT_THEME';

const TABS_MIN_HEIGHT = '1em';
const TABS_VERTICAL_MIN_HEIGHT = '1.8em';

const StyledTabs = styled(MuiTabs)({
  minHeight: TABS_MIN_HEIGHT,

  [`&.${muiTabsClasses.vertical}`]: {
    minHeight: TABS_VERTICAL_MIN_HEIGHT,

    [`& .${muiTabClasses.root}`]: {
      alignItems: 'flex-start',
      minHeight: TABS_VERTICAL_MIN_HEIGHT,
      paddingLeft: '2em',
    },

    [`& .${muiTabsClasses.indicator}`]: {
      right: 'initial',
    },
  },

  [`& .${muiTabClasses.root}`]: {
    minHeight: TABS_MIN_HEIGHT,
  },

  [`& .${muiTabsClasses.indicator}`]: {
    backgroundColor: BLUE,
    borderRadius: BORDER_RADIUS,
  },
});

const Tabs: React.FC<TabsProps> = ({
  orientation: rawOrientation,
  variant = 'fullWidth',
  ...restTabsProps
}) => {
  const theme = useTheme();

  const bp = useCallback(
    (breakpoint: MuiBreakpoint) => theme.breakpoints.up(breakpoint),
    [theme],
  );

  const bpxs = useMediaQuery(bp('xs'));
  const bpsm = useMediaQuery(bp('sm'));
  const bpmd = useMediaQuery(bp('md'));
  const bplg = useMediaQuery(bp('lg'));
  const bpxl = useMediaQuery(bp('xl'));

  const mapToBreakpointUp: [MuiBreakpoint, boolean][] = useMemo(
    () => [
      ['xs', bpxs],
      ['sm', bpsm],
      ['md', bpmd],
      ['lg', bplg],
      ['xl', bpxl],
    ],
    [bplg, bpmd, bpsm, bpxl, bpxs],
  );

  const orientation = useMemo(() => {
    let result: TabsOrientation | undefined;

    if (typeof rawOrientation === 'object') {
      mapToBreakpointUp.some(([breakpoint, isUp]) => {
        if (isUp && rawOrientation[breakpoint]) {
          result = rawOrientation[breakpoint];
        }

        return !isUp;
      });
    } else {
      result = rawOrientation;
    }

    return result;
  }, [mapToBreakpointUp, rawOrientation]);

  return (
    <StyledTabs
      orientation={orientation}
      variant={variant}
      {...restTabsProps}
    />
  );
};

export default Tabs;
