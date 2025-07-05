type TabsOrientation = Exclude<
  import('@mui/material/Tabs').TabsProps['orientation'],
  undefined
>;

type TabsProps = Omit<import('@mui/material/Tabs').TabsProps, 'orientation'> & {
  orientation?:
    | TabsOrientation
    | Partial<
        Record<
          import('@mui/material/node_modules/@mui/system/createBreakpoints/createBreakpoints').Breakpoint,
          TabsOrientation
        >
      >;
};
