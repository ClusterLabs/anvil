type Checklist = Record<string, boolean>;

type ArrayChecklist = (keyof Checklist)[];

type BuildDeleteDialogPropsFunction = (args: {
  confirmDialogProps?: Partial<Omit<ConfirmDialogProps, 'content'>>;
  formSummaryProps?: Omit<FormSummaryProps<Checklist>, 'entries'>;
  getConfirmDialogTitle: (length: number) => ReactNode;
}) => ConfirmDialogProps;

type GetCheckFunction = (key: string) => boolean;

type SetAllChecksFunction = (checked?: boolean) => void;

type SetCheckFunction = (key: string, checked?: boolean) => void;
