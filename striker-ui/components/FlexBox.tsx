import { FC } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  SxProps,
  Theme,
} from '@mui/material';

type FlexBoxOptionalProps = {
  row?: boolean;
};

type FlexBoxProps = MUIBoxProps & FlexBoxOptionalProps;

const FLEX_BOX_DEFAULT_PROPS: Required<FlexBoxOptionalProps> = {
  row: false,
};

const FlexBox: FC<FlexBoxProps> = ({ row: isRow, sx, ...muiBoxRestProps }) => {
  let rootSxAppend: SxProps<Theme> = {
    flexDirection: 'column',
  };
  let notFirstChildSxAppend: SxProps<Theme> = {
    marginTop: '1em',
  };

  if (isRow) {
    rootSxAppend = {
      flexDirection: 'row',
    };
    notFirstChildSxAppend = {
      marginLeft: '1em',
    };
  }

  return (
    <MUIBox
      {...{
        ...muiBoxRestProps,
        sx: {
          display: 'flex',

          ...rootSxAppend,

          '& > :not(:first-child)': {
            ...notFirstChildSxAppend,
          },

          ...sx,
        },
      }}
    />
  );
};

FlexBox.defaultProps = FLEX_BOX_DEFAULT_PROPS;

export type { FlexBoxProps };

export default FlexBox;
