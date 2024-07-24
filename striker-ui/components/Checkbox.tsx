import {
  Checkbox as MuiCheckbox,
  checkboxClasses as muiCheckboxClasses,
  styled,
} from '@mui/material';
import { FC, useMemo } from 'react';

import { BLACK, GREY } from '../lib/consts/DEFAULT_THEME';

const PREFIX = 'Checkbox';

const classes = {
  invert: `${PREFIX}-invert`,
  thinPadding: `${PREFIX}-thin-padding`,
};

const BaseStyle = styled(MuiCheckbox)({
  color: GREY,

  [`&.${muiCheckboxClasses.checked}`]: {
    color: GREY,
  },

  [`&.${classes.invert}`]: {
    color: BLACK,

    [`&.${muiCheckboxClasses.checked}`]: {
      color: BLACK,
    },
  },

  [`&.${classes.thinPadding}`]: {
    padding: '.2em',
  },
});

const Checkbox: FC<CheckboxProps> = (props) => {
  const {
    className: baseClassName,
    invert,
    thinPadding,
    ...restBaseProps
  } = props;

  const className = useMemo(() => {
    const cls = [];

    if (baseClassName) {
      cls.push(baseClassName);
    }

    if (invert) {
      cls.push(classes.invert);
    }

    if (thinPadding) {
      cls.push(classes.thinPadding);
    }

    return cls.join(' ');
  }, [baseClassName, invert, thinPadding]);

  return <BaseStyle className={className} {...restBaseProps} />;
};

export default Checkbox;
