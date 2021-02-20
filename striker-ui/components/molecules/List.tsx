import { FunctionComponent } from 'react';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';
import Label from '../atoms/Label';

const StyledList = styled.div<ListProps>`
  display: flex;

  flex-direction: ${(props) => (props.isAlignHorizontal ? 'row' : 'column')};

  border-style: solid;
  border-color: ${(props) => props.theme.colors.tertiary};

  border-width: ${(props) =>
    props.isAlignHorizontal ? '1px 1px 1px 0' : '0 1px 1px 1px'};

  > * {
    display: flex;

    align-items: center;

    color: ${(props) => props.theme.colors.tertiary};

    border-style: solid;
    border-color: ${(props) => props.theme.colors.tertiary};

    border-width: ${(props) =>
      props.isAlignHorizontal ? '0 0 0 1px' : '1px 0 0 0'};

    padding: 1em;
  }
`;

const StyledListContainer = styled.div`
  > :first-child {
    margin-bottom: 1em;

    padding-left: 0;
  }
`;

StyledList.defaultProps = {
  theme: DEFAULT_THEME,
};

StyledListContainer.defaultProps = {
  theme: DEFAULT_THEME,
};

const List: FunctionComponent<ListProps> = ({
  isAlignHorizontal,
  labelText,
  children,
}) => {
  return (
    <StyledListContainer>
      {labelText !== undefined && <Label text={labelText} />}
      <StyledList {...{ isAlignHorizontal }}>{children}</StyledList>
    </StyledListContainer>
  );
};

export default List;
