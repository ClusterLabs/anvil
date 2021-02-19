import { InputHTMLAttributes } from 'react';

type ToggleSwitchProps = Pick<
  InputHTMLAttributes<HTMLInputElement>,
  'checked' | 'disabled'
>;
