import MuiGrid, { Grid2Props as MuiGridProps } from '@mui/material/Grid2';

type FormGridProps<V extends FormikValues> = {
  formikUtils: FormikUtils<V>;
  slotProps?: {
    grid: MuiGridProps;
  };
};

const FormGrid = <V extends FormikValues>(
  ...[props]: Parameters<React.FC<React.PropsWithChildren<FormGridProps<V>>>>
): ReturnType<React.FC<FormGridProps<V>>> => {
  const { children, formikUtils, slotProps } = props;

  return (
    <MuiGrid
      component="form"
      container
      onSubmit={(event: React.FormEvent<HTMLFormElement>) => {
        event.preventDefault();

        formikUtils.formik.handleSubmit(event);
      }}
      {...slotProps?.grid}
    >
      {children}
    </MuiGrid>
  );
};

export type { FormGridProps };

export default FormGrid;
