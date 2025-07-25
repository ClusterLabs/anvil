import styled from '@mui/material/styles/styled';

import AddItemButton from './AddItemButton';
import AllItemCheckbox from './AllItemCheckbox';
import DeleteItemButton from './DeleteItemButton';
import Divider from '../Divider';
import EditItemButton from './EditItemButton';
import FlexBox from '../FlexBox';
import { BodyText } from '../Text';
import sxstring from '../../lib/sxstring';

type ListHeaderProps = {
  divide?: boolean;
  edit?: boolean;
  slotProps?: {
    add?: AddItemButtonProps;
    all?: AllItemCheckboxProps;
    delete?: DeleteItemButtonProps;
    edit?: EditItemButtonProps;
  };
  spacing?: number | string;
};

const StyledDivider = styled(Divider)({
  flexGrow: 1,
});

const ListHeader: React.FC<React.PropsWithChildren<ListHeaderProps>> = (
  props,
) => {
  const {
    children,
    edit,
    slotProps,
    spacing,
    // Dependents:
    divide = ['boolean', 'string'].includes(typeof children),
  } = props;

  return (
    <FlexBox height="2.4em" row spacing={spacing}>
      <AllItemCheckbox edit={edit} {...slotProps?.all} />
      {sxstring(children, BodyText)}
      {divide && <StyledDivider />}
      <DeleteItemButton edit={edit} {...slotProps?.delete} />
      <EditItemButton edit={edit} {...slotProps?.edit} />
      <AddItemButton {...slotProps?.add} />
    </FlexBox>
  );
};

export type { ListHeaderProps };

export default ListHeader;
