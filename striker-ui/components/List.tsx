import {
  Add as MuiAddIcon,
  Delete as MuiDeleteIcon,
  Done as MuiDoneIcon,
  Edit as MuiEditIcon,
} from '@mui/icons-material';
import {
  Box as MuiBox,
  List as MuiList,
  ListItem as MuiListItem,
  ListItemButton as MuiListItemButton,
  ListItemIcon as MuiListItemIcon,
  ListProps as MuiListProps,
} from '@mui/material';
import { useCallback, useMemo } from 'react';

import { BLUE, BORDER_RADIUS, GREY, RED } from '../lib/consts/DEFAULT_THEME';

import Checkbox from './Checkbox';
import Divider from './Divider';
import FlexBox from './FlexBox';
import IconButton from './IconButton';
import Spinner from './Spinner';
import { BodyText } from './Text';

const List = <Item,>(
  ...[props]: Parameters<React.FC<ListProps<Item>>>
): ReturnType<React.FC<ListProps<Item>>> => {
  const {
    allowCheckAll: isAllowCheckAll = false,
    allowEdit: isAllowEdit = false,
    allowItemButton: isAllowItemButton = false,
    disableDelete = false,
    edit: isEdit = false,
    flexBoxProps,
    getListCheckboxProps,
    getListItemCheckboxProps,
    header,
    headerSpacing = '.3em',
    insertHeader: isInsertHeader = true,
    listEmpty,
    listItemIconMinWidth = '56px',
    listItemKeyPrefix = 'list',
    listItemProps: { sx: listItemSx, ...restListItemProps } = {},
    listItems,
    listProps: { sx: listSx, ...restListProps } = {},
    loading,
    onAdd,
    onDelete,
    onEdit,
    onAllCheckboxChange,
    onItemCheckboxChange,
    onItemClick,
    renderListItem = (key) => <BodyText>{key}</BodyText>,
    renderListItemCheckboxState,
    scroll: isScroll = false,
    // Input props that depend on other input props.
    allowAddItem: isAllowAddItem = isAllowEdit,
    allowCheckItem: isAllowCheckItem = isAllowEdit,
    allowDelete: isAllowDelete = isAllowEdit,
    allowEditItem: isAllowEditItem = isAllowEdit,
  } = props;

  const checkAllMinWidth = useMemo(
    () => `calc(${listItemIconMinWidth} - ${headerSpacing})`,
    [headerSpacing, listItemIconMinWidth],
  );

  const addItemButton = useMemo(
    () =>
      isAllowAddItem ? (
        <IconButton onClick={onAdd} size="small">
          <MuiAddIcon />
        </IconButton>
      ) : undefined,
    [isAllowAddItem, onAdd],
  );
  const deleteItemButton = useMemo(
    () =>
      isEdit && isAllowDelete ? (
        <IconButton
          disabled={disableDelete}
          onClick={onDelete}
          size="small"
          sx={{
            backgroundColor: RED,
            color: GREY,

            '&:hover': { backgroundColor: `${RED}F0` },
          }}
        >
          <MuiDeleteIcon />
        </IconButton>
      ) : undefined,
    [disableDelete, isAllowDelete, isEdit, onDelete],
  );
  const editItemButton = useMemo(() => {
    if (isAllowEditItem) {
      return (
        <IconButton onClick={onEdit} size="small">
          {isEdit ? <MuiDoneIcon sx={{ color: BLUE }} /> : <MuiEditIcon />}
        </IconButton>
      );
    }

    return undefined;
  }, [isAllowEditItem, isEdit, onEdit]);
  const checkAllElement = useMemo(() => {
    let element;

    if (isEdit && isAllowCheckItem) {
      element = isAllowCheckAll ? (
        <MuiBox sx={{ minWidth: checkAllMinWidth }}>
          <Checkbox
            edge="start"
            onChange={onAllCheckboxChange}
            {...getListCheckboxProps?.call(null)}
          />
        </MuiBox>
      ) : (
        <Divider sx={{ minWidth: checkAllMinWidth }} />
      );
    }

    return element;
  }, [
    checkAllMinWidth,
    getListCheckboxProps,
    isAllowCheckAll,
    isAllowCheckItem,
    isEdit,
    onAllCheckboxChange,
  ]);
  const headerElement = useMemo(() => {
    const headerType = typeof header;

    return isInsertHeader && header ? (
      <FlexBox row spacing={headerSpacing} sx={{ height: '2.4em' }}>
        {checkAllElement}
        {['boolean', 'string'].includes(headerType) ? (
          <>
            {headerType === 'string' && <BodyText>{header}</BodyText>}
            <Divider sx={{ flexGrow: 1 }} />
          </>
        ) : (
          header
        )}
        {deleteItemButton}
        {editItemButton}
        {addItemButton}
      </FlexBox>
    ) : (
      header
    );
  }, [
    addItemButton,
    checkAllElement,
    deleteItemButton,
    editItemButton,
    header,
    headerSpacing,
    isInsertHeader,
  ]);
  const listEmptyElement = useMemo(
    () =>
      typeof listEmpty === 'string' ? (
        <BodyText align="center">{listEmpty}</BodyText>
      ) : (
        listEmpty
      ),
    [listEmpty],
  );

  const listItemCheckbox = useCallback(
    (key: string, checked?: boolean, checkboxProps?: CheckboxProps) =>
      isEdit && isAllowCheckItem ? (
        <MuiListItemIcon sx={{ minWidth: listItemIconMinWidth }}>
          <Checkbox
            checked={checked}
            edge="start"
            onChange={(...args) =>
              onItemCheckboxChange?.call(null, key, ...args)
            }
            {...checkboxProps}
          />
        </MuiListItemIcon>
      ) : undefined,
    [isAllowCheckItem, isEdit, listItemIconMinWidth, onItemCheckboxChange],
  );

  const listItemElements = useMemo(() => {
    if (loading) return <Spinner />;

    if (!listItems) return listEmptyElement;

    const entries = Object.entries(listItems);

    if (entries.length <= 0) return listEmptyElement;

    return entries.map(([key, value]) => {
      const listItem = renderListItem(key, value);

      return (
        <MuiListItem
          {...restListItemProps}
          key={`${listItemKeyPrefix}-${key}`}
          sx={{ paddingLeft: 0, paddingRight: 0, ...listItemSx }}
        >
          {listItemCheckbox(
            key,
            renderListItemCheckboxState?.call(null, key, value),
            getListItemCheckboxProps?.call(null, key, value),
          )}
          {isAllowItemButton ? (
            <MuiListItemButton
              onClick={(...args) => {
                onItemClick?.call(null, value, key, ...args);
              }}
              sx={{ borderRadius: BORDER_RADIUS }}
            >
              {listItem}
            </MuiListItemButton>
          ) : (
            listItem
          )}
        </MuiListItem>
      );
    });
  }, [
    getListItemCheckboxProps,
    isAllowItemButton,
    listEmptyElement,
    listItemCheckbox,
    listItemKeyPrefix,
    listItemSx,
    listItems,
    loading,
    onItemClick,
    renderListItem,
    renderListItemCheckboxState,
    restListItemProps,
  ]);
  const listScrollSx: MuiListProps['sx'] = useMemo(
    () => (isScroll ? { maxHeight: '100%', overflowY: 'scroll' } : undefined),
    [isScroll],
  );

  return (
    <FlexBox spacing={0} {...flexBoxProps}>
      {headerElement}
      <MuiList
        {...restListProps}
        sx={{ paddingBottom: 0, paddingTop: 0, ...listScrollSx, ...listSx }}
      >
        {listItemElements}
      </MuiList>
    </FlexBox>
  );
};

export default List;
