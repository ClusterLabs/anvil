import MuiBox from '@mui/material/Box';
import MuiGrid from '@mui/material/Grid';
import { useMemo } from 'react';

const Grid: React.FC<GridProps> = ({
  calculateItemBreakpoints = () => ({ xs: 1 }),
  layout,
  wrapperBoxProps,
  ...restGridProps
}) => {
  const itemElements = useMemo(() => {
    const items = Object.entries(layout);

    return items.map(([itemId, itemGridProps], index) => {
      const key = itemId;

      return itemGridProps ? (
        <MuiGrid
          {...calculateItemBreakpoints(index, key)}
          key={key}
          item
          {...itemGridProps}
        />
      ) : undefined;
    });
  }, [calculateItemBreakpoints, layout]);

  return (
    // Make Grid compatible with FlexBox by adding an extra empty wrapper.
    <MuiBox {...wrapperBoxProps}>
      <MuiGrid container {...restGridProps}>
        {itemElements}
      </MuiGrid>
    </MuiBox>
  );
};

export default Grid;
