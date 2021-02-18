import { FunctionComponent } from 'react';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

type ListProps = {
  isAlignHorizontal?: boolean;
};

const StyledList = styled.div<ListProps>`
  display: flex;
  flex-direction: ${(props) => (props.isAlignHorizontal ? 'row' : 'column')};
`;

StyledList.defaultProps = {
  theme: DEFAULT_THEME,
};

const List: FunctionComponent<ListProps> = ({ children }) => {
  return <StyledList>{children}</StyledList>;
};

export default List;
