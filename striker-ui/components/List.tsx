import {
  Add as MUIAddIcon,
  Delete,
  Done as MUIDoneIcon,
  Edit as MUIEditIcon,
} from '@mui/icons-material';
import {
  List as MUIList,
  ListItem as MUIListItem,
  ListItemIcon as MUIListItemIcon,
  ListProps as MUIListProps,
} from '@mui/material';
import { FC, ReactNode, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { BLUE, GREY, RED } from '../lib/consts/DEFAULT_THEME';

import Checkbox, { CheckboxProps } from './Checkbox';
import FlexBox from './FlexBox';
import IconButton, { IconButtonProps } from './IconButton';
import { BodyText } from './Text';

type ListOptionalProps<T = unknown> = {
  header?: ReactNode;
  isEdit?: boolean;
  isAllowAddItem?: boolean;
  isAllowCheckItem?: boolean;
  isAllowDelete?: boolean;
  isAllowEdit?: boolean;
  isAllowEditItem?: boolean;
  listItemKeyPrefix?: string;
  listProps?: MUIListProps;
  onAdd?: IconButtonProps['onClick'];
  onDelete?: IconButtonProps['onClick'];
  onEdit?: IconButtonProps['onClick'];
  onItemCheckboxChange?: CheckboxProps['onChange'];
  renderListItem?: (key: string, value: T) => ReactNode;
};

type ListProps<T = unknown> = ListOptionalProps<T> & {
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
  isEdit: false,
  isAllowAddItem: undefined,
  isAllowCheckItem: undefined,
  isAllowDelete: undefined,
  isAllowEdit: false,
  isAllowEditItem: undefined,
  listItemKeyPrefix: uuidv4(),
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
  listItemKeyPrefix = LIST_DEFAULT_PROPS.listItemKeyPrefix,
  listItems,
  listProps = LIST_DEFAULT_PROPS.listProps,
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
        <FlexBox
          row
          spacing=".3em"
          sx={{ height: '2.4em', '& > :first-child': { flexGrow: 1 } }}
        >
          <BodyText>{header}</BodyText>
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
          key={`${listItemKeyPrefix}-${key}`}
          sx={{ paddingLeft: 0, paddingRight: 0 }}
        >
          {listItemCheckbox}
          {renderListItem(key, value)}
        </MUIListItem>
      )),
    [listItemCheckbox, listItemKeyPrefix, listItems, renderListItem],
  );

  return (
    <FlexBox spacing={0}>
      {headerElement}
      <MUIList {...listProps}>{listItemElements}</MUIList>
    </FlexBox>
  );
};

List.defaultProps = LIST_DEFAULT_PROPS;

export default List;
