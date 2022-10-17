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
import { FC, ReactNode, useCallback, useMemo, useState } from 'react';
import { v4 as uuidv4 } from 'uuid';

import { BLUE, GREY, RED } from '../lib/consts/DEFAULT_THEME';

import Checkbox, { CheckboxProps } from './Checkbox';
import Divider from './Divider';
import FlexBox, { FlexBoxProps } from './FlexBox';
import IconButton, { IconButtonProps } from './IconButton';
import { BodyText } from './Text';

type OnCheckboxChange = Exclude<CheckboxProps['onChange'], undefined>;

type ListOptionalPropsWithDefaults<T = unknown> = {
  allowCheckAll?: boolean;
  allowEdit?: boolean;
  edit?: boolean;
  initialCheckAll?: boolean;
  insertHeader?: boolean;
  listItemKeyPrefix?: string;
  listItemProps?: MUIListItemProps;
  listProps?: MUIListProps;
  renderListItem?: (key: string, value: T) => ReactNode;
  scroll?: boolean;
};

type ListOptionalPropsWithoutDefaults<T = unknown> = {
  allowAddItem?: boolean;
  allowCheckItem?: boolean;
  allowDelete?: boolean;
  allowEditItem?: boolean;
  header?: ReactNode;
  listEmpty?: ReactNode;
  onAdd?: IconButtonProps['onClick'];
  onDelete?: IconButtonProps['onClick'];
  onEdit?: IconButtonProps['onClick'];
  onAllCheckboxChange?: CheckboxProps['onChange'];
  onItemCheckboxChange?: (
    key: string,
    ...onChangeParams: Parameters<OnCheckboxChange>
  ) => ReturnType<OnCheckboxChange>;
  renderListItemCheckboxState?: (key: string, value: T) => boolean;
};

type ListOptionalProps<T = unknown> = ListOptionalPropsWithDefaults<T> &
  ListOptionalPropsWithoutDefaults<T>;

type ListProps<T = unknown> = FlexBoxProps &
  ListOptionalProps<T> & {
    listItems: Record<string, T>;
  };

const HEADER_SPACING = '.3em';
const LIST_DEFAULT_PROPS: Required<ListOptionalPropsWithDefaults> &
  ListOptionalPropsWithoutDefaults = {
  header: undefined,
  allowAddItem: undefined,
  allowCheckAll: false,
  allowCheckItem: undefined,
  allowDelete: undefined,
  allowEdit: false,
  allowEditItem: undefined,
  edit: false,
  initialCheckAll: false,
  insertHeader: true,
  listEmpty: undefined,
  listItemKeyPrefix: uuidv4(),
  listItemProps: {},
  listProps: {},
  onAdd: undefined,
  onDelete: undefined,
  onEdit: undefined,
  onAllCheckboxChange: undefined,
  onItemCheckboxChange: undefined,
  renderListItem: (key) => <BodyText>{key}</BodyText>,
  renderListItemCheckboxState: undefined,
  scroll: false,
};
const LIST_ICON_MIN_WIDTH = '56px';

const CHECK_ALL_MIN_WIDTH = `calc(${LIST_ICON_MIN_WIDTH} - ${HEADER_SPACING})`;

const List = <T,>({
  header,
  allowCheckAll: isAllowCheckAll = LIST_DEFAULT_PROPS.allowCheckAll,
  allowEdit: isAllowEdit = LIST_DEFAULT_PROPS.allowEdit,
  edit: isEdit = LIST_DEFAULT_PROPS.edit,
  initialCheckAll = LIST_DEFAULT_PROPS.initialCheckAll,
  insertHeader: isInsertHeader = LIST_DEFAULT_PROPS.insertHeader,
  listEmpty = LIST_DEFAULT_PROPS.listEmpty,
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
  onAllCheckboxChange,
  onItemCheckboxChange,
  renderListItem = LIST_DEFAULT_PROPS.renderListItem,
  renderListItemCheckboxState,
  scroll: isScroll = LIST_DEFAULT_PROPS.scroll,
  // Input props that depend on other input props.
  allowAddItem: isAllowAddItem = isAllowEdit,
  allowCheckItem: isAllowCheckItem = isAllowEdit,
  allowDelete: isAllowDelete = isAllowEdit,
  allowEditItem: isAllowEditItem = isAllowEdit,

  ...rootProps
}: ListProps<T>): ReturnType<FC<ListProps<T>>> => {
  const [isCheckAll, setIsCheckAll] = useState<boolean>(initialCheckAll);

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
  const checkAllElement = useMemo(() => {
    let element;

    if (isEdit && isAllowCheckItem) {
      element = isAllowCheckAll ? (
        <MUIBox sx={{ minWidth: CHECK_ALL_MIN_WIDTH }}>
          <Checkbox
            checked={isCheckAll}
            edge="start"
            onChange={(...args) => {
              const [, isChecked] = args;

              onAllCheckboxChange?.call(null, ...args);
              setIsCheckAll(isChecked);
            }}
          />
        </MUIBox>
      ) : (
        <Divider sx={{ minWidth: CHECK_ALL_MIN_WIDTH }} />
      );
    }

    return element;
  }, [
    isAllowCheckAll,
    isAllowCheckItem,
    isCheckAll,
    isEdit,
    onAllCheckboxChange,
  ]);
  const headerElement = useMemo(
    () =>
      isInsertHeader ? (
        <FlexBox row spacing={HEADER_SPACING} sx={{ height: '2.4em' }}>
          {checkAllElement}
          {typeof header === 'string' ? (
            <>
              <BodyText>{header}</BodyText>
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
      ),
    [
      addItemButton,
      checkAllElement,
      deleteItemButton,
      editItemButton,
      header,
      isInsertHeader,
    ],
  );
  const listEmptyElement = useMemo(
    () =>
      typeof listEmpty === 'string' ? (
        <BodyText>{listEmpty}</BodyText>
      ) : (
        listEmpty
      ),
    [listEmpty],
  );

  const listItemCheckbox = useCallback(
    (key: string, checked?: boolean) =>
      isEdit && isAllowCheckItem ? (
        <MUIListItemIcon sx={{ minWidth: LIST_ICON_MIN_WIDTH }}>
          <Checkbox
            checked={checked}
            edge="start"
            onChange={(...args) =>
              onItemCheckboxChange?.call(null, key, ...args)
            }
          />
        </MUIListItemIcon>
      ) : undefined,
    [isAllowCheckItem, isEdit, onItemCheckboxChange],
  );

  const listItemElements = useMemo(() => {
    const entries = Object.entries(listItems);

    return entries.length > 0
      ? entries.map(([key, value]) => (
          <MUIListItem
            {...restListItemProps}
            key={`${listItemKeyPrefix}-${key}`}
            sx={{ paddingLeft: 0, paddingRight: 0, ...listItemSx }}
          >
            {listItemCheckbox(
              key,
              renderListItemCheckboxState?.call(null, key, value),
            )}
            {renderListItem(key, value)}
          </MUIListItem>
        ))
      : listEmptyElement;
  }, [
    listEmptyElement,
    listItemCheckbox,
    listItemKeyPrefix,
    listItems,
    listItemSx,
    renderListItem,
    renderListItemCheckboxState,
    restListItemProps,
  ]);
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
