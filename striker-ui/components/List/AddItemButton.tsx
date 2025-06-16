import IconButton from '../IconButton';

const AddItemButton: React.FC<AddItemButtonProps> = (props) => {
  const { allow, onClick, slotProps } = props;

  return (
    <>
      {allow ? (
        <IconButton
          mapPreset="add"
          onClick={onClick}
          size="small"
          {...slotProps?.button}
        />
      ) : null}
    </>
  );
};

export default AddItemButton;
