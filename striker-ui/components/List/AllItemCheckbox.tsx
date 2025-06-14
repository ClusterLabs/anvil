import { Box as MuiBox } from '@mui/material';

import Checkbox from '../Checkbox';
import Divider from '../Divider';

const AllItemCheckbox: React.FC<
  Pick<CheckboxProps, 'onChange'> & {
    allowAll?: boolean;
    allowItem?: boolean;
    edit?: boolean;
    minWidth?: number | string;
    slotProps?: {
      checkbox?: CheckboxProps;
    };
  }
> = (props) => {
  const { allowAll, allowItem, edit, minWidth, onChange, slotProps } = props;

  if (!edit || !allowItem) {
    return null;
  }

  return (
    <>
      {edit &&
        allowItem &&
        (allowAll ? (
          <MuiBox minWidth={minWidth}>
            <Checkbox
              edge="start"
              onChange={onChange}
              {...slotProps?.checkbox}
            />
          </MuiBox>
        ) : (
          <Divider
            sx={{
              minWidth,
            }}
          />
        ))}
    </>
  );
};

export default AllItemCheckbox;
