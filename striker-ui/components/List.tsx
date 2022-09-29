import {
  Add as MUIAddIcon,
  Delete,
  Done as MUIDoneIcon,
  Edit as MUIEditIcon,
} from '@mui/icons-material';
import {
  Box as MUIBox,
  List as MUIList,
  ListItem as MUIListItem,
  ListItemIcon as MUIListItemIcon,
  ListItemProps as MUIListItemProps,
  ListProps as MUIListProps,
  SxProps,
  Theme,
} from '@mui/material';
import { FC, ReactNode, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import { BLUE, DIVIDER, GREY, RED } from '../lib/consts/DEFAULT_THEME';

import Checkbox, { CheckboxProps } from './Checkbox';
import FlexBox, { FlexBoxProps } from './FlexBox';
import IconButton, { IconButtonProps } from './IconButton';
import { BodyText } from './Text';

type ListOptionalProps<T = unknown> = {
  header?: ReactNode;
  isAllowAddItem?: boolean;
  isAllowCheckItem?: boolean;
  isAllowDelete?: boolean;
  isAllowEdit?: boolean;
  isAllowEditItem?: boolean;
  isEdit?: boolean;
  isScroll?: boolean;
  listItemKeyPrefix?: string;
  listItemProps?: MUIListItemProps;
  listProps?: MUIListProps;
  onAdd?: IconButtonProps['onClick'];
  onDelete?: IconButtonProps['onClick'];
  onEdit?: IconButtonProps['onClick'];
  onItemCheckboxChange?: CheckboxProps['onChange'];
  renderListItem?: (key: string, value: T) => ReactNode;
};

type ListProps<T = unknown> = FlexBoxProps &
  ListOptionalProps<T> & {
    listItems: Record<string, T>;
  };

const LIST_DEFAULT_PROPS: Required<
  Omit<
    ListOptionalProps,
    | 'header'
    | 'isAllowAddItem'
    | 'isAllowCheckItem'
    | 'isAllowDelete'
    | 'isAllowEditItem'
    | 'onAdd'
    | 'onDelete'
    | 'onEdit'
    | 'onItemCheckboxChange'
  >
> &
  Pick<
    ListOptionalProps,
    | 'header'
    | 'isAllowAddItem'
    | 'isAllowCheckItem'
    | 'isAllowDelete'
    | 'isAllowEditItem'
    | 'onAdd'
    | 'onDelete'
    | 'onEdit'
    | 'onItemCheckboxChange'
  > = {
  header: undefined,
  isAllowAddItem: undefined,
  isAllowCheckItem: undefined,
  isAllowDelete: undefined,
  isAllowEdit: false,
  isAllowEditItem: undefined,
  isEdit: false,
  isScroll: false,
  listItemKeyPrefix: uuidv4(),
  listItemProps: {},
  listProps: {},
  onAdd: undefined,
  onDelete: undefined,
  onEdit: undefined,
  onItemCheckboxChange: undefined,
  renderListItem: (key) => <BodyText>{key}</BodyText>,
};

const List = <T,>({
  header,
  isAllowEdit = LIST_DEFAULT_PROPS.isAllowEdit,
  isEdit = LIST_DEFAULT_PROPS.isEdit,
  isScroll = LIST_DEFAULT_PROPS.isScroll,
  listItemKeyPrefix = LIST_DEFAULT_PROPS.listItemKeyPrefix,
  listItemProps: {
    sx: listItemSx,
    ...restListItemProps
  } = LIST_DEFAULT_PROPS.listItemProps,
  listItems,
  listProps: { sx: listSx, ...restListProps } = LIST_DEFAULT_PROPS.listProps,
  onAdd,
  onDelete,
  onEdit,
  onItemCheckboxChange,
  renderListItem = LIST_DEFAULT_PROPS.renderListItem,
  // Input props that depend on other input props.
  isAllowAddItem = isAllowEdit,
  isAllowCheckItem = isAllowEdit,
  isAllowDelete = isAllowEdit,
  isAllowEditItem = isAllowEdit,

  ...rootProps
}: ListProps<T>): ReturnType<FC<ListProps<T>>> => {
  const addItemButton = useMemo(
    () =>
      isAllowAddItem ? (
        <IconButton onClick={onAdd} size="small">
          <MUIAddIcon />
        </IconButton>
      ) : undefined,
    [isAllowAddItem, onAdd],
  );
  const deleteItemButton = useMemo(
    () =>
      isEdit && isAllowDelete ? (
        <IconButton
          onClick={onDelete}
          size="small"
          sx={{
            backgroundColor: RED,
            color: GREY,

            '&:hover': { backgroundColor: `${RED}F0` },
          }}
        >
          <Delete />
        </IconButton>
      ) : undefined,
    [isAllowDelete, isEdit, onDelete],
  );
  const editItemButton = useMemo(() => {
    if (isAllowEditItem) {
      return (
        <IconButton onClick={onEdit} size="small">
          {isEdit ? <MUIDoneIcon sx={{ color: BLUE }} /> : <MUIEditIcon />}
        </IconButton>
      );
    }

    return undefined;
  }, [isAllowEditItem, isEdit, onEdit]);
  const headerElement = useMemo(
    () =>
      typeof header === 'string' ? (
        <FlexBox row spacing=".3em" sx={{ height: '2.4em' }}>
          <BodyText>{header}</BodyText>
          <MUIBox
            sx={{
              borderTopColor: DIVIDER,
              borderTopStyle: 'solid',
              borderTopWidth: '1px',
              flexGrow: 1,
            }}
          />
          {deleteItemButton}
          {editItemButton}
          {addItemButton}
        </FlexBox>
      ) : (
        header
      ),
    [addItemButton, deleteItemButton, editItemButton, header],
  );
  const listItemCheckbox = useMemo(
    () =>
      isEdit && isAllowCheckItem ? (
        <MUIListItemIcon>
          <Checkbox edge="start" onChange={onItemCheckboxChange} />
        </MUIListItemIcon>
      ) : undefined,
    [isAllowCheckItem, isEdit, onItemCheckboxChange],
  );
  const listItemElements = useMemo(
    () =>
      Object.entries(listItems).map(([key, value]) => (
        <MUIListItem
          {...restListItemProps}
          key={`${listItemKeyPrefix}-${key}`}
          sx={{ paddingLeft: 0, paddingRight: 0, ...listItemSx }}
        >
          {listItemCheckbox}
          {renderListItem(key, value)}
        </MUIListItem>
      )),
    [
      listItemCheckbox,
      listItemKeyPrefix,
      listItems,
      listItemSx,
      renderListItem,
      restListItemProps,
    ],
  );
  const listScrollSx: SxProps<Theme> | undefined = useMemo(
    () => (isScroll ? { maxHeight: '100%', overflowY: 'scroll' } : undefined),
    [isScroll],
  );

  return (
    <FlexBox spacing={0} {...rootProps}>
      {headerElement}
      <MUIList
        {...restListProps}
        sx={{ paddingBottom: 0, paddingTop: 0, ...listScrollSx, ...listSx }}
      >
        {listItemElements}
      </MUIList>
    </FlexBox>
  );
};

List.defaultProps = LIST_DEFAULT_PROPS;

export default List;
