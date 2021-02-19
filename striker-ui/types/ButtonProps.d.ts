import { ButtonHTMLAttributes } from 'react';
import { LinkProps } from 'next/link';

import { ButtonImageProps } from './ButtonImageProps';

type ButtonProps = {
  imageProps?: ButtonImageProps;
  isSubmit?: boolean;
  labelProps?: LabelProps;
  linkProps?: LinkProps;
} & Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'type'>;
