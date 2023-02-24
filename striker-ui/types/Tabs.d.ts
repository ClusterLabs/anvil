type TabsOrientation = Exclude<
  import('@mui/material').TabsProps['orientation'],
  undefined
>;

type TabsProps = Omit<import('@mui/material').TabsProps, 'orientation'> & {
  orientation?:
    | TabsOrientation
    | Partial<Record<import('@mui/material').Breakpoint, TabsOrientation>>;
};
