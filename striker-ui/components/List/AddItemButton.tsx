import IconButton, { IconButtonProps } from '../IconButton';

const AddItemButton: React.FC<
  Pick<IconButtonProps, 'onClick'> & {
    allow?: boolean;
    slotProps?: {
      button?: IconButtonProps;
    };
  }
> = (props) => {
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
