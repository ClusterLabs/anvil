import { MoreVert as MoreVertIcon } from '@mui/icons-material';
import { Box } from '@mui/material';
import { merge } from 'lodash';
import { MouseEventHandler, useCallback, useMemo, useState } from 'react';

import ContainedButton from './ContainedButton';
import IconButton from './IconButton/IconButton';
import Menu from './Menu';

const ButtonWithMenu = <T = unknown,>(
  ...[props]: Parameters<React.FC<ButtonWithMenuProps<T>>>
): ReturnType<React.FC<ButtonWithMenuProps<T>>> => {
  const {
    children,
    onClick,
    onItemClick,
    slotProps,
    variant = 'icon',
    ...restProps
  } = props;

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);

  const open = useMemo(() => Boolean(anchorEl), [anchorEl]);

  const buttonContent = useMemo(() => {
    if (children) {
      return children;
    }

    if (variant === 'icon') {
      return <MoreVertIcon fontSize={slotProps?.button?.icon?.size} />;
    }

    return 'Options';
  }, [children, slotProps?.button?.icon?.size, variant]);

  const buttonClickHandler = useCallback<MouseEventHandler<HTMLButtonElement>>(
    (...args) => {
      const {
        0: { currentTarget },
      } = args;

      setAnchorEl(currentTarget);

      return onClick?.call(null, ...args);
    },
    [onClick],
  );

  const buttonElement = useMemo(() => {
    if (variant === 'contained') {
      return (
        <ContainedButton
          onClick={buttonClickHandler}
          {...slotProps?.button?.contained}
        >
          {buttonContent}
        </ContainedButton>
      );
    }

    return (
      <IconButton onClick={buttonClickHandler} {...slotProps?.button?.icon}>
        {buttonContent}
      </IconButton>
    );
  }, [
    buttonClickHandler,
    buttonContent,
    slotProps?.button?.contained,
    slotProps?.button?.icon,
    variant,
  ]);

  const itemClickHandler = useCallback<
    Exclude<MenuProps<T>['onItemClick'], undefined>
  >(
    (key, value, ...rest) => {
      setAnchorEl(null);

      return onItemClick?.call(null, key, value, ...rest);
    },
    [onItemClick],
  );

  const mergedMenuSlotProps = useMemo<MenuProps['slotProps']>(
    () =>
      merge(
        {
          menu: {
            anchorEl,
            keepMounted: true,
            onClose: () => setAnchorEl(null),
          },
        },
        slotProps?.menu?.slotProps,
      ),
    [anchorEl, slotProps?.menu?.slotProps],
  );

  return (
    <Box>
      {buttonElement}
      <Menu<T>
        onItemClick={itemClickHandler}
        open={open}
        {...restProps}
        {...slotProps?.menu}
        slotProps={mergedMenuSlotProps}
      />
    </Box>
  );
};

export default ButtonWithMenu;
