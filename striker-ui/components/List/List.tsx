import MuiList from '@mui/material/List';
import styled from '@mui/material/styles/styled';
import { createElement, useMemo } from 'react';

import FlexBox from '../FlexBox';
import ListHeader from './ListHeader';
import ListItem from './ListItem';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import sxstring from '../../lib/sxstring';

const StyledList = styled(MuiList)({
  paddingBottom: 0,
  paddingTop: 0,
});

const ScrollableList = styled(StyledList)({
  maxHeight: '100%',
  overflowY: 'scroll',
});

const ListItems = <Item,>(
  ...[props]: Parameters<React.FC<ListProps<Item>>>
): ReturnType<React.FC<ListProps<Item>>> => {
  const {
    allowEdit: isAllowEdit = false,
    allowItemButton: isAllowItemButton = false,
    edit: isEdit = false,
    getListItemCheckboxProps,
    listEmpty,
    listItemIconMinWidth = '56px',
    listItemKeyPrefix = 'list-item',
    listItemProps,
    listItems,
    loading,
    onItemCheckboxChange,
    onItemClick,
    renderListItem = (key) => <BodyText>{key}</BodyText>,
    renderListItemCheckboxState,
    // Dependents:
    allowCheckItem: isAllowCheckItem = isAllowEdit,
  } = props;

  const listEmptyElement = useMemo(
    () => sxstring(listEmpty, BodyText, { align: 'center' }),
    [listEmpty],
  );

  const listEntries = useMemo(
    () => (listItems ? Object.entries(listItems) : []),
    [listItems],
  );

  if (loading) {
    return <Spinner mt={0} />;
  }

  return (
    <>
      {listEntries.length > 0
        ? listEntries.map(([itemKey, itemValue]) => {
            const key = `${listItemKeyPrefix}-${itemKey}`;

            return (
              <ListItem
                allowButton={isAllowItemButton}
                allowCheck={isAllowCheckItem}
                edit={isEdit}
                getChecked={renderListItemCheckboxState}
                itemKey={itemKey}
                itemValue={itemValue}
                key={key}
                onCheckboxChange={onItemCheckboxChange}
                onClick={(k, v, ...rest) => onItemClick?.(v, k, ...rest)}
                renderItem={renderListItem}
                slotProps={{
                  checkbox: {
                    slotProps: {
                      checkbox: getListItemCheckboxProps?.(itemKey, itemValue),
                      listItemIcon: {
                        sx: {
                          minWidth: listItemIconMinWidth,
                        },
                      },
                    },
                  },
                  item: listItemProps,
                }}
              />
            );
          })
        : listEmptyElement}
    </>
  );
};

const List = <Item,>(
  ...[props]: Parameters<React.FC<ListProps<Item>>>
): ReturnType<React.FC<ListProps<Item>>> => {
  const {
    allowCheckAll: isAllowCheckAll = false,
    allowEdit: isAllowEdit = false,
    disableDelete = false,
    edit: isEdit = false,
    flexBoxProps,
    getListCheckboxProps,
    header,
    headerSpacing = '.3em',
    insertHeader: isInsertHeader = true,
    listItemIconMinWidth = '56px',
    listProps,
    onAdd,
    onDelete,
    onEdit,
    onAllCheckboxChange,
    scroll: isScroll = false,
    // Dependents:
    allowAddItem: isAllowAddItem = isAllowEdit,
    allowCheckItem: isAllowCheckItem = isAllowEdit,
    allowDelete: isAllowDelete = isAllowEdit,
    allowEditItem: isAllowEditItem = isAllowEdit,
  } = props;

  const checkAllMinWidth = `calc(${listItemIconMinWidth} - ${headerSpacing})`;

  const headerElement = useMemo<React.ReactNode>(() => {
    if (isInsertHeader && header) {
      return (
        <ListHeader
          edit={isEdit}
          slotProps={{
            add: {
              allow: isAllowAddItem,
              onClick: onAdd,
            },
            all: {
              allowAll: isAllowCheckAll,
              allowItem: isAllowCheckItem,
              minWidth: checkAllMinWidth,
              onChange: onAllCheckboxChange,
              slotProps: {
                checkbox: getListCheckboxProps?.call(null),
              },
            },
            delete: {
              allow: isAllowDelete,
              disabled: disableDelete,
              onClick: onDelete,
            },
            edit: {
              allow: isAllowEditItem,
              onClick: onEdit,
            },
          }}
          spacing={headerSpacing}
        >
          {header}
        </ListHeader>
      );
    }

    return null;
  }, [
    checkAllMinWidth,
    disableDelete,
    getListCheckboxProps,
    header,
    headerSpacing,
    isAllowAddItem,
    isAllowCheckAll,
    isAllowCheckItem,
    isAllowDelete,
    isAllowEditItem,
    isEdit,
    isInsertHeader,
    onAdd,
    onAllCheckboxChange,
    onDelete,
    onEdit,
  ]);

  return (
    <FlexBox spacing={0} {...flexBoxProps}>
      {headerElement}
      {createElement(
        isScroll ? ScrollableList : StyledList,
        listProps,
        <ListItems<Item> {...props} />,
      )}
    </FlexBox>
  );
};

export default List;
