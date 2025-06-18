import styled from '@mui/material/styles/styled';
import { useMemo } from 'react';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import Spinner from './Spinner';

const FlexEndBox = styled(FlexBox)({
  justifyContent: 'flex-end',
  width: '100%',
});

const ActionGroup: React.FC<ActionGroupProps> = (props) => {
  const { actions = [], loading } = props;

  const elements = useMemo(
    () =>
      actions.map<React.ReactElement>((actionProps) => {
        const { children } = actionProps;

        const key = `action-${
          ['number', 'string'].includes(typeof children) ? children : 'none'
        }`;

        return (
          <ContainedButton key={key} {...actionProps}>
            {children}
          </ContainedButton>
        );
      }),
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
