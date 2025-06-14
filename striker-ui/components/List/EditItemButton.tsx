import IconButton, { IconButtonProps } from '../IconButton';

const EditItemButton: React.FC<
  Pick<IconButtonProps, 'onClick'> & {
    allow?: boolean;
    edit?: boolean;
    slotProps?: {
      button?: IconButtonProps;
    };
  }
> = (props) => {
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
