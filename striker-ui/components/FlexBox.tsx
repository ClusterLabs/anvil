import { Box as MUIBox, BoxProps as MUIBoxProps } from '@mui/material';
import { FC, useMemo } from 'react';

type FlexBoxDirection = 'column' | 'row';

type FlexBoxSpacing = number | string;

type FlexBoxOptionalPropsWithDefault = {
  row?: boolean;
  spacing?: FlexBoxSpacing;
  xs?: FlexBoxDirection;
};

type FlexBoxOptionalPropsWithoutDefault = {
  columnSpacing?: FlexBoxSpacing;
  rowSpacing?: FlexBoxSpacing;
  lg?: FlexBoxDirection;
  md?: FlexBoxDirection;
  sm?: FlexBoxDirection;
  xl?: FlexBoxDirection;
};

type FlexBoxOptionalProps = FlexBoxOptionalPropsWithDefault &
  FlexBoxOptionalPropsWithoutDefault;

type FlexBoxProps = MUIBoxProps & FlexBoxOptionalProps;

const FLEX_BOX_DEFAULT_PROPS: Required<FlexBoxOptionalPropsWithDefault> &
  FlexBoxOptionalPropsWithoutDefault = {
  columnSpacing: undefined,
  row: false,
  rowSpacing: undefined,
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
  // Input props that depend on other input props.
  columnSpacing = spacing,
  rowSpacing = spacing,

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
      marginLeft: FlexBoxSpacing;
      marginTop: FlexBoxSpacing;
    }
  > = useMemo(
    () => ({
      column: {
        alignItems: 'normal',
        marginLeft: 0,
        marginTop: columnSpacing,
      },
      row: {
        alignItems: 'center',
        marginLeft: rowSpacing,
        marginTop: 0,
      },
    }),
    [columnSpacing, rowSpacing],
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
