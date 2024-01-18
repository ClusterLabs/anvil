type Checklist = Record<string, boolean>;

type ArrayChecklist = (keyof Checklist)[];

type BuildDeleteDialogPropsArgs = Pick<ConfirmDialogProps, 'onProceedAppend'> &
  Pick<FormSummaryProps<Checklist>, 'renderEntry'> & {
    confirmDialogProps?: Partial<Omit<ConfirmDialogProps, 'content'>>;
    formSummaryProps?: Omit<FormSummaryProps<Checklist>, 'entries'>;
    getConfirmDialogTitle: (length: number) => ReactNode;
  };

type BuildDeleteDialogPropsFunction = (
  args: BuildDeleteDialogPropsArgs,
) => ConfirmDialogProps;

type GetCheckFunction = (key: string) => boolean;

type SetAllChecksFunction = (checked?: boolean) => void;

type SetCheckFunction = (key: string, checked?: boolean) => void;
