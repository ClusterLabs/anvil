import { Box, linearProgressClasses, styled } from '@mui/material';
import { FC, ReactElement, createElement, useMemo } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import RoundedLinearProgress from './BorderLinearProgress';
import Underline from './Underline';

const ThinRoundedLinearProgress = styled(RoundedLinearProgress)({
  height: '.4em',
});

const ThinUnderline = styled(Underline)({
  height: '.2em',
});

const StackBar: FC<StackBarProps> = (props) => {
  const { barProps = {}, thin, underlineProps, value } = props;

  const { sx: barSx, ...restBarProps } = barProps;

  const values = useMemo<Record<string, StackBarValue>>(
    () => ('value' in value ? { default: value as StackBarValue } : value),
    [value],
  );

  const entries = useMemo<[string, StackBarValue][]>(
    () => Object.entries(values).reverse(),
    [values],
  );

  const creatableBar = useMemo(
    () => (thin ? ThinRoundedLinearProgress : RoundedLinearProgress),
    [thin],
  );

  const creatableUnderline = useMemo(
    () => (thin ? ThinUnderline : Underline),
    [thin],
  );

  const bars = useMemo<ReactElement[]>(
    () =>
      entries.map<ReactElement>(
        ([id, { colour = GREY, value: val }], index) => {
          const backgroundColor =
            typeof colour === 'string'
              ? colour
              : Object.entries(colour)
                  .reverse()
                  .find(([mark]) => val >= Number(mark))?.[1] ?? GREY;

          let position: 'absolute' | 'relative' = 'relative';
          let top: 0 | undefined;
          let width: string | undefined;

          if (index) {
            position = 'absolute';
            top = 0;
            width = '100%';
          }

          return createElement(creatableBar, {
            key: `stack-bar-${id}`,
            sx: {
              position,
              top,
              width,

              [`& .${linearProgressClasses.bar}`]: {
                backgroundColor,
              },

              ...barSx,
            },
            variant: 'determinate',
            value: val,
            ...restBarProps,
          });
        },
      ),
    [barSx, entries, creatableBar, restBarProps],
  );

  return (
    <Box position="relative">
      {bars}
      {createElement(creatableUnderline, underlineProps)}
    </Box>
  );
};

export default StackBar;
