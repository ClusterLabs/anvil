import MuiListItemIcon, {
  ListItemIconProps as MuiListItemIconProps,
} from '@mui/material/ListItemIcon';

import Checkbox from '../Checkbox';

type ChangeHandler = Exclude<CheckboxProps['onChange'], undefined>;

type ListItemCheckboxProps = {
  checked?: boolean;
  itemKey: string;
  onChange?: (
    key: string,
    ...rest: Parameters<ChangeHandler>
  ) => ReturnType<ChangeHandler>;
  slotProps?: {
    checkbox?: CheckboxProps;
    listItemIcon?: MuiListItemIconProps;
  };
};

const ListItemCheckbox: React.FC<ListItemCheckboxProps> = (props) => {
  const { checked, itemKey, onChange: handleChange, slotProps } = props;

  return (
    <MuiListItemIcon {...slotProps?.listItemIcon}>
      <Checkbox
        checked={checked}
        edge="start"
        onChange={(...params) => handleChange?.(itemKey, ...params)}
        {...slotProps?.checkbox}
      />
    </MuiListItemIcon>
  );
};

export type { ListItemCheckboxProps };

export default ListItemCheckbox;
