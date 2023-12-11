import { MoreVert as MoreVertIcon } from '@mui/icons-material';
import { Box } from '@mui/material';
import { FC, MouseEventHandler, useCallback, useMemo, useState } from 'react';

import ContainedButton from './ContainedButton';
import IconButton from './IconButton/IconButton';
import Menu from './Menu';

const ButtonWithMenu: FC<ButtonWithMenuProps> = (props) => {
  const {
    children,
    muiMenuProps,
    onButtonClick,
    onItemClick,
    variant = 'icon',
    ...menuProps
  } = props;

  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);

  const open = useMemo(() => Boolean(anchorEl), [anchorEl]);

  const buttonContent = useMemo(() => children ?? <MoreVertIcon />, [children]);

  const buttonClickHandler = useCallback<MouseEventHandler<HTMLButtonElement>>(
    (...args) => {
      const {
        0: { currentTarget },
      } = args;

      setAnchorEl(currentTarget);

      return onButtonClick?.call(null, ...args);
    },
    [onButtonClick],
  );

  const buttonElement = useMemo(() => {
    if (variant === 'contained') {
      return (
        <ContainedButton onClick={buttonClickHandler}>
          {buttonContent}
        </ContainedButton>
      );
    }

    return (
      <IconButton onClick={buttonClickHandler}>{buttonContent}</IconButton>
    );
  }, [buttonClickHandler, buttonContent, variant]);

  const itemClickHandler = useCallback<
    Exclude<MenuProps['onItemClick'], undefined>
  >(
    (key, value, ...rest) => {
      setAnchorEl(null);

      return onItemClick?.call(null, key, value, ...rest);
    },
    [onItemClick],
  );

  return (
    <Box>
      {buttonElement}
      <Menu
        muiMenuProps={{
          anchorEl,
          keepMounted: true,
          onClose: () => setAnchorEl(null),
          ...muiMenuProps,
        }}
        onItemClick={itemClickHandler}
        open={open}
        {...menuProps}
      />
    </Box>
  );
};

export default ButtonWithMenu as <T>(
  props: ButtonWithMenuProps<T>,
) => ReturnType<FC<ButtonWithMenuProps<T>>>;
