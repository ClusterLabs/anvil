type CheckboxChangeEventHandler = Exclude<CheckboxProps['onChange'], undefined>;

type ListItemButtonChangeEventHandler = Exclude<
  import('@mui/material/ListItemButton').ListItemButtonProps['onClick'],
  undefined
>;

type ListOptionalProps<T = unknown> = {
  allowAddItem?: boolean;
  allowCheckAll?: boolean;
  allowCheckItem?: boolean;
  allowDelete?: boolean;
  allowEdit?: boolean;
  allowEditItem?: boolean;
  allowItemButton?: boolean;
  disableDelete?: boolean;
  edit?: boolean;
  flexBoxProps?: import('../components/FlexBox').FlexBoxProps;
  getListCheckboxProps?: () => CheckboxProps;
  getListItemCheckboxProps?: (key: string, value: T) => CheckboxProps;
  header?: import('react').ReactNode;
  headerSpacing?: number | string;
  insertHeader?: boolean;
  listEmpty?: import('react').ReactNode;
  listItemIconMinWidth?: number | string;
  listItemKeyPrefix?: string;
  listItemProps?: import('@mui/material/ListItem').ListItemProps;
  listItems?: T[] | Record<string, T>;
  listProps?: import('@mui/material/List').ListProps;
  loading?: boolean;
  onAdd?: import('../components/IconButton').IconButtonProps['onClick'];
  onDelete?: import('../components/IconButton').IconButtonProps['onClick'];
  onEdit?: import('../components/IconButton').IconButtonProps['onClick'];
  onAllCheckboxChange?: CheckboxChangeEventHandler;
  onItemCheckboxChange?: (
    key: string,
    ...checkboxChangeEventHandlerArgs: Parameters<CheckboxChangeEventHandler>
  ) => ReturnType<CheckboxChangeEventHandler>;
  onItemClick?: (
    value: T,
    key: string,
    ...listItemButtonChangeEventHandlerArgs: Parameters<ListItemButtonChangeEventHandler>
  ) => ReturnType<ListItemButtonChangeEventHandler>;
  renderListItem?: (key: string, value: T) => import('react').ReactNode;
  renderListItemCheckboxState?: (key: string, value: T) => boolean;
  scroll?: boolean;
};

type ListProps<T = unknown> = ListOptionalProps<T>;
