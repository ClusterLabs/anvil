import { styled } from '@mui/material';
import { FC, ReactElement, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import Spinner from './Spinner';

const FlexEndBox = styled(FlexBox)({
  justifyContent: 'flex-end',
  width: '100%',
});

const ActionGroup: FC<ActionGroupProps> = (props) => {
  const { actions = [], loading } = props;

  const elements = useMemo(
    () =>
      actions.map<ReactElement>((actionProps) => (
        <ContainedButton key={uuidv4()} {...actionProps}>
          {actionProps.children}
        </ContainedButton>
      )),
    [actions],
  );

  return loading ? (
    <Spinner mt={0} />
  ) : (
    <FlexEndBox row spacing=".5em">
      {elements}
    </FlexEndBox>
  );
};

export default ActionGroup;
