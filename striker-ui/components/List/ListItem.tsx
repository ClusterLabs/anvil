import MuiListItem, {
  ListItemProps as MuiListItemProps,
} from '@mui/material/ListItem';
import { ListItemButtonProps as MuiListItemButtonProps } from '@mui/material/ListItemButton';
import styled from '@mui/material/styles/styled';

import ListItemCheckbox, { ListItemCheckboxProps } from './ListItemCheckbox';
import ListItemButton from './ListItemButton';
import { BodyText } from '../Text';

type ListItemProps<ItemValue> = {
  allowButton?: boolean;
  allowCheck?: boolean;
  edit?: boolean;
  getChecked?: (k: string, v: ItemValue) => boolean;
  itemKey: string;
  itemValue: ItemValue;
  onCheckboxChange?: (
    k: string,
    ...rest: Parameters<CheckboxChangeEventHandler>
  ) => ReturnType<CheckboxChangeEventHandler>;
  onClick?: (
    k: string,
    v: ItemValue,
    ...rest: Parameters<ListItemButtonChangeEventHandler>
  ) => ReturnType<ListItemButtonChangeEventHandler>;
  renderItem?: (k: string, v: ItemValue) => React.ReactNode;
  slotProps?: {
    checkbox?: Partial<ListItemCheckboxProps>;
    item?: Partial<MuiListItemProps>;
    button?: Partial<MuiListItemButtonProps>;
  };
};

const StyledListItem = styled(MuiListItem)({
  paddingLeft: 0,
  paddingRight: 0,
});

const ListItem = <ItemValue,>(
  ...[props]: Parameters<React.FC<ListItemProps<ItemValue>>>
): ReturnType<React.FC<ListItemProps<ItemValue>>> => {
  const {
    allowButton,
    allowCheck,
    edit,
    getChecked,
    itemKey,
    itemValue,
    onCheckboxChange,
    onClick,
    renderItem = (k) => <BodyText>{k}</BodyText>,
    slotProps,
  } = props;

  const itemNode = renderItem(itemKey, itemValue);

  return (
    <StyledListItem {...slotProps?.item}>
      {allowCheck && edit && (
        <ListItemCheckbox
          checked={getChecked?.(itemKey, itemValue)}
          itemKey={itemKey}
          onChange={onCheckboxChange}
          {...slotProps?.checkbox}
        />
      )}
      {allowButton ? (
        <ListItemButton
          onClick={(...params) => onClick?.(itemKey, itemValue, ...params)}
          {...slotProps?.button}
        >
          {itemNode}
        </ListItemButton>
      ) : (
        itemNode
      )}
    </StyledListItem>
  );
};

export default ListItem;
