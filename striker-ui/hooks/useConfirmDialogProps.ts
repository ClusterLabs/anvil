import { Dispatch, SetStateAction, useState } from 'react';

const useConfirmDialogProps = ({
  actionProceedText = '',
  content = '',
  titleText = '',
  ...restProps
}: Partial<ConfirmDialogProps> = {}): [
  ConfirmDialogProps,
  Dispatch<SetStateAction<ConfirmDialogProps>>,
] =>
  useState<ConfirmDialogProps>({
    actionProceedText,
    content,
    titleText,
    ...restProps,
  });

export default useConfirmDialogProps;
