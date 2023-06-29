type FenceAutocompleteOption = {
  fenceDescription: string;
  fenceId: string;
  label: string;
};

type AddFenceInputGroupOptionalProps = {
  fenceTemplate?: APIFenceTemplate;
  loading?: boolean;
};

type AddFenceInputGroupProps<M extends MapToInputTestID> =
  AddFenceInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };
