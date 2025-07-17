import IconButton from '../IconButton';

const EditItemButton: React.FC<EditItemButtonProps> = (props) => {
  const { allow, edit = false, onClick, slotProps } = props;

  return (
    <>
      {allow ? (
        <IconButton
          mapPreset="edit"
          onClick={onClick}
          size="small"
          state={String(edit)}
          {...slotProps?.button}
        />
      ) : null}
    </>
  );
};

export default EditItemButton;
