type MuiMenuItemProps = import('@mui/material/MenuItem').MenuItemProps;

type MuiMenuItemClickEventHandler = Exclude<
  MuiMenuItemProps['onClick'],
  undefined
>;
