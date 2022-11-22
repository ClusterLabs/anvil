type OnCheckboxChange = Exclude<
  import('../components/Checkbox').CheckboxProps['onChange'],
  undefined
>;

type ListOptionalProps<T extends unknown = unknown> = {
  allowCheckAll?: boolean;
  allowAddItem?: boolean;
  allowCheckItem?: boolean;
  allowEdit?: boolean;
  allowDelete?: boolean;
  allowEditItem?: boolean;
  edit?: boolean;
  flexBoxProps?: import('../components/FlexBox').FlexBoxProps;
  header?: import('react').ReactNode;
  headerSpacing?: number | string;
  initialCheckAll?: boolean;
  insertHeader?: boolean;
  listEmpty?: import('react').ReactNode;
  listItemIconMinWidth?: number | string;
  listItemKeyPrefix?: string;
  listItemProps?: import('@mui/material').ListItemProps;
  listItems?: Record<string, T>;
  listProps?: import('@mui/material').ListProps;
  onAdd?: import('../components/IconButton').IconButtonProps['onClick'];
  onDelete?: import('../components/IconButton').IconButtonProps['onClick'];
  onEdit?: import('../components/IconButton').IconButtonProps['onClick'];
  onAllCheckboxChange?: OnCheckboxChange;
  onItemCheckboxChange?: (
    key: string,
    ...onChangeParams: Parameters<OnCheckboxChange>
  ) => ReturnType<OnCheckboxChange>;
  renderListItem?: (key: string, value: T) => import('react').ReactNode;
  renderListItemCheckboxState?: (key: string, value: T) => boolean;
  scroll?: boolean;
};

type ListProps<T extends unknown = unknown> = ListOptionalProps<T>;

type ListForwardedRefContent = {
  setCheckAll?: (value: boolean) => void;
};
