import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';
import { useMemo } from 'react';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const BaseStyle = styled(MuiBox)({
  borderWidth: '1px',
  borderRadius: BORDER_RADIUS,
  borderStyle: 'solid',
  borderColor: DIVIDER,
  paddingBottom: 0,
  position: 'relative',
});

const InnerPanel: React.FC<InnerPanelProps> = ({
  headerMarginOffset: hmo = '.3em',
  ml,
  mv = '1.4em',
  // Dependants:
  mb = mv,
  mt = mv,
  ...restMuiBoxProps
}) => {
  const marginLeft = useMemo(
    () => (ml ? `calc(${ml} + ${hmo})` : hmo),
    [hmo, ml],
  );
  const marginTop = useMemo(() => {
    const resultMt = typeof mt === 'number' ? `${mt}px` : mt;

    return `calc(${resultMt} + ${hmo})`;
  }, [hmo, mt]);

  return (
    <BaseStyle mb={mb} ml={marginLeft} mt={marginTop} {...restMuiBoxProps} />
  );
};

export default InnerPanel;
