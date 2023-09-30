import { Box, linearProgressClasses } from '@mui/material';
import { FC, ReactElement, useMemo } from 'react';

import { GREY } from '../../lib/consts/DEFAULT_THEME';

import BorderLinearProgress from './BorderLinearProgress';
import Underline from './Underline';

const StackBar: FC<StackBarProps> = (props) => {
  const { value } = props;

  const values = useMemo<Record<string, StackBarValue>>(
    () => ('value' in value ? { default: value as StackBarValue } : value),
    [value],
  );

  const entries = useMemo<[string, StackBarValue][]>(
    () => Object.entries(values).reverse(),
    [values],
  );

  const bars = useMemo<ReactElement[]>(
    () =>
      entries.map<ReactElement>(
        ([id, { colour = GREY, value: val }], index) => {
          const backgroundColor =
            typeof colour === 'string'
              ? colour
              : Object.entries(colour).findLast(
                  ([mark]) => val >= Number(mark),
                )?.[1] ?? GREY;

          let position: 'absolute' | 'relative' = 'relative';
          let top: 0 | undefined;
          let width: string | undefined;

          if (index) {
            position = 'absolute';
            top = 0;
            width = '100%';
          }

          return (
            <BorderLinearProgress
              key={`stack-bar-${id}`}
              sx={{
                position,
                top,
                width,

                [`& .${linearProgressClasses.bar}`]: {
                  backgroundColor,
                },
              }}
              variant="determinate"
              value={val}
            />
          );
        },
      ),
    [entries],
  );

  return (
    <Box position="relative">
      {bars}
      <Underline />
    </Box>
  );
};

export default StackBar;
