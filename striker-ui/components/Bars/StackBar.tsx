import { Box, linearProgressClasses, styled } from '@mui/material';
import { merge } from 'lodash';
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
  const { barProps: commonBarProps, thin, underlineProps, value } = props;

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
      entries.map<ReactElement>(([id, barOptions], index) => {
        const { barProps, colour = GREY, value: val } = barOptions;

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

        // Props should override in order default->common->bar-specific

        return createElement(
          creatableBar,
          merge(
            {
              key: `stack-bar-${id}`,
              sx: {
                position,
                top,
                width,

                [`& .${linearProgressClasses.bar}`]: {
                  backgroundColor,
                },
              },
              variant: 'determinate',
              value: val,
            },
            commonBarProps,
            barProps,
          ),
        );
      }),
    [commonBarProps, creatableBar, entries],
  );

  return (
    <Box position="relative">
      {bars}
      {createElement(creatableUnderline, underlineProps)}
    </Box>
  );
};

export default StackBar;
