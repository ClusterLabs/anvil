import IconButton, { IconButtonProps } from '../IconButton';

const DeleteItemButton: React.FC<
  Pick<IconButtonProps, 'disabled' | 'onClick'> & {
    allow?: boolean;
    edit?: boolean;
    slotProps?: {
      button?: IconButtonProps;
    };
  }
> = (props) => {
  const { allow, disabled, edit, onClick, slotProps } = props;

  return (
    <>
      {edit && allow ? (
        <IconButton
          disabled={disabled}
          mapPreset="delete"
          onClick={onClick}
          size="small"
          variant="redcontained"
          {...slotProps?.button}
        />
      ) : null}
    </>
  );
};

export default DeleteItemButton;
