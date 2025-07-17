import IconButton from '../IconButton';

const DeleteItemButton: React.FC<DeleteItemButtonProps> = (props) => {
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
