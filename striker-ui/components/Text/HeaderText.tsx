import { styled, Typography, TypographyProps } from '@mui/material';
import { FC, useMemo } from 'react';

import { TEXT } from '../../lib/consts/DEFAULT_THEME';

const WhiteTypography = styled(Typography)({
  color: TEXT,
});

type HeaderTextOptionalPropsWithoutDefault = {
  text?: string;
};

type HeaderTextOptionalProps = HeaderTextOptionalPropsWithoutDefault;

type HeaderTextProps = TypographyProps & HeaderTextOptionalProps;

const HEADER_TEXT_DEFAULT_PROPS: HeaderTextOptionalPropsWithoutDefault = {
  text: undefined,
};

const HeaderText: FC<HeaderTextProps> = ({
  children,
  text,
  ...restHeaderTextProps
}) => {
  const content = useMemo(() => children ?? text, [children, text]);

  return (
    <WhiteTypography variant="h4" {...restHeaderTextProps}>
      {content}
    </WhiteTypography>
  );
};

HeaderText.defaultProps = HEADER_TEXT_DEFAULT_PROPS;

export default HeaderText;
