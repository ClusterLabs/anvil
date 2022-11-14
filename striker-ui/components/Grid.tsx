import { Box as MUIBox, Grid as MUIGrid } from '@mui/material';
import { FC, useMemo } from 'react';

const Grid: FC<GridProps> = ({
  calculateItemBreakpoints = () => ({ xs: 1 }),
  layout,
  wrapperBoxProps,
  ...restGridProps
}) => {
  const itemElements = useMemo(() => {
    const items = Object.entries(layout);

    return items.map(([itemId, itemGridProps], index) => {
      const key = itemId;

      return (
        <MUIGrid
          {...calculateItemBreakpoints(index, key)}
          key={key}
          item
          {...itemGridProps}
        />
      );
    });
  }, [calculateItemBreakpoints, layout]);

  return (
    // Make Grid compatible with FlexBox by adding an extra empty wrapper.
    <MUIBox {...wrapperBoxProps}>
      <MUIGrid container {...restGridProps}>
        {itemElements}
      </MUIGrid>
    </MUIBox>
  );
};

export default Grid;
