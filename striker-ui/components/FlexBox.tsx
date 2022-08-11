import { Box as MUIBox, BoxProps as MUIBoxProps } from '@mui/material';
import { FC, useMemo } from 'react';

type FlexBoxDirection = 'column' | 'row';

type FlexBoxOptionalProps = {
  row?: boolean;
  lg?: FlexBoxDirection;
  md?: FlexBoxDirection;
  sm?: FlexBoxDirection;
  spacing?: number | string;
  xl?: FlexBoxDirection;
  xs?: FlexBoxDirection;
};

type FlexBoxProps = MUIBoxProps & FlexBoxOptionalProps;

const FLEX_BOX_DEFAULT_PROPS: Required<
  Omit<FlexBoxOptionalProps, 'lg' | 'md' | 'sm' | 'xl'>
> &
  Pick<FlexBoxOptionalProps, 'lg' | 'md' | 'sm' | 'xl'> = {
  row: false,
  lg: undefined,
  md: undefined,
  sm: undefined,
  spacing: '1em',
  xl: undefined,
  xs: 'column',
};

const FlexBox: FC<FlexBoxProps> = ({
  lg: dLg = FLEX_BOX_DEFAULT_PROPS.lg,
  md: dMd = FLEX_BOX_DEFAULT_PROPS.md,
  row: isRow,
  sm: dSm = FLEX_BOX_DEFAULT_PROPS.sm,
  spacing = FLEX_BOX_DEFAULT_PROPS.spacing,
  sx,
  xl: dXl = FLEX_BOX_DEFAULT_PROPS.xl,
  xs: dXs = FLEX_BOX_DEFAULT_PROPS.xs,
  ...muiBoxRestProps
}) => {
  const xs = useMemo(() => (isRow ? 'row' : dXs), [dXs, isRow]);
  const sm = useMemo(() => dSm || xs, [dSm, xs]);
  const md = useMemo(() => dMd || sm, [dMd, sm]);
  const lg = useMemo(() => dLg || md, [dLg, md]);
  const xl = useMemo(() => dXl || lg, [dXl, lg]);

  const mapToSx: Record<
    FlexBoxDirection,
    {
      alignItems: string;
      marginLeft: string | number;
      marginTop: string | number;
    }
  > = useMemo(
    () => ({
      column: {
        alignItems: 'normal',
        marginLeft: 0,
        marginTop: spacing,
      },
      row: {
        alignItems: 'center',
        marginLeft: spacing,
        marginTop: 0,
      },
    }),
    [spacing],
  );

  return (
    <MUIBox
      {...{
        ...muiBoxRestProps,
        sx: {
          alignItems: {
            xs: mapToSx[xs].alignItems,
            sm: mapToSx[sm].alignItems,
            md: mapToSx[md].alignItems,
            lg: mapToSx[lg].alignItems,
            xl: mapToSx[xl].alignItems,
          },
          display: 'flex',
          flexDirection: { xs, sm, md, lg, xl },

          '& > :not(:first-child)': {
            marginLeft: {
              xs: mapToSx[xs].marginLeft,
              sm: mapToSx[sm].marginLeft,
              md: mapToSx[md].marginLeft,
              lg: mapToSx[lg].marginLeft,
              xl: mapToSx[xl].marginLeft,
            },
            marginTop: {
              xs: mapToSx[xs].marginTop,
              sm: mapToSx[sm].marginTop,
              md: mapToSx[md].marginTop,
              lg: mapToSx[lg].marginTop,
              xl: mapToSx[xl].marginTop,
            },
          },

          ...sx,
        },
      }}
    />
  );
};

FlexBox.defaultProps = FLEX_BOX_DEFAULT_PROPS;

export type { FlexBoxProps };

export default FlexBox;
