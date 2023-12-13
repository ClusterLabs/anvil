type MuiMenuItemProps = import('@mui/material').MenuItemProps;

type MuiMenuItemClickEventHandler = Exclude<
  MuiMenuItemProps['onClick'],
  undefined
>;
