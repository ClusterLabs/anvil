import Grid from '@mui/material/Grid';

const ServerFormGrid = <Values extends FormikValues>(
  ...[props]: Parameters<React.FC<ServerFormGridProps<Values>>>
): ReturnType<React.FC<ServerFormGridProps<Values>>> => {
  const { children, formik, ...restProps } = props;

  return (
    <Grid
      columns={{
        xs: 1,
        sm: 2,
        md: 3,
      }}
      component="form"
      container
      onSubmit={(event: React.FormEvent<HTMLFormElement>) => {
        event.preventDefault();

        formik.handleSubmit(event);
      }}
      spacing="1em"
      {...restProps}
    >
      {children}
    </Grid>
  );
};

export default ServerFormGrid;
