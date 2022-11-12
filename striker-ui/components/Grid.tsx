import { Grid as MUIGrid } from '@mui/material';
import { FC, useMemo } from 'react';

const Grid: FC<GridProps> = ({
  calculateItemBreakpoints = () => ({ xs: 1 }),
  layout,
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
    <MUIGrid container {...restGridProps}>
      {itemElements}
    </MUIGrid>
  );
};

export default Grid;
