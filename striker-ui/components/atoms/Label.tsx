import { FunctionComponent } from 'react';
import styled from 'styled-components';

import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

const StyledLabel = styled.h2`
  padding: 0;
  margin: 0;

  color: ${(props) => props.theme.colors.primary};

  font-size: 1em;
  font-weight: normal;
`;

StyledLabel.defaultProps = {
  theme: DEFAULT_THEME,
};

const Label: FunctionComponent<LabelProps> = ({ text }) => {
  return <StyledLabel>{text}</StyledLabel>;
};

export default Label;
