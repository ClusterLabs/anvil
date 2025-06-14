import { Box as MuiBox, BoxProps as MuiBoxProps } from '@mui/material';
import { merge } from 'lodash';
import { useMemo } from 'react';

type FlexBoxDirection = 'column' | 'row';

type FlexBoxSpacing = number | string;

type FlexBoxOptionalPropsWithDefault = {
  fullWidth?: boolean;
  growFirst?: boolean;
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

type FlexBoxProps = MuiBoxProps & FlexBoxOptionalProps;

const FlexBox: React.FC<FlexBoxProps> = ({
  fullWidth,
  growFirst,
  lg: dlg,
  md: dmd,
  row: isRow,
  sm: dsm,
  spacing = '1em',
  xl: dxl,
  xs: dxs = 'column',
  // Input props that depend on other input props.
  columnSpacing = spacing,
  rowSpacing = spacing,
  ...restMuiBoxProps
}) => {
  const xs = useMemo(() => (isRow ? 'row' : dxs), [dxs, isRow]);
  const sm = useMemo(() => dsm || xs, [dsm, xs]);
  const md = useMemo(() => dmd || sm, [dmd, sm]);
  const lg = useMemo(() => dlg || md, [dlg, md]);
  const xl = useMemo(() => dxl || lg, [dxl, lg]);

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

  const firstChildFlexGrow = useMemo(
    () => (growFirst ? 1 : undefined),
    [growFirst],
  );

  const width = useMemo(() => (fullWidth ? '100%' : undefined), [fullWidth]);

  const mergedProps = useMemo<MuiBoxProps>(
    () =>
      merge(
        {
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
            width,

            '& > :first-child': {
              flexGrow: firstChildFlexGrow,
            },

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
          },
        },
        restMuiBoxProps,
      ),
    [firstChildFlexGrow, lg, mapToSx, md, restMuiBoxProps, sm, width, xl, xs],
  );

  return <MuiBox {...mergedProps} />;
};

export type { FlexBoxProps };

export default FlexBox;
