import MuiBox from '@mui/material/Box';

import Checkbox from '../Checkbox';
import Divider from '../Divider';

const AllItemCheckbox: React.FC<AllItemCheckboxProps> = (props) => {
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
