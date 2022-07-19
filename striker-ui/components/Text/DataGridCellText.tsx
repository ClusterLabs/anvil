import { FC } from 'react';

import BodyText, { BodyTextProps } from './BodyText';

const DataGridCellText: FC<BodyTextProps> = ({
  ...dataGridCellTextRestProps
}) => (
  <BodyText
    {...{
      variant: 'body2',
      ...dataGridCellTextRestProps,
    }}
  />
);

export default DataGridCellText;
