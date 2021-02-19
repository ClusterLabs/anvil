import { AnchorHTMLAttributes } from 'react';
import { LinkProps } from 'next/link';

type SimpleLinkProps = {
  linkProps: Omit<LinkProps, 'passRef'>;
  anchorProps?: AnchorHTMLAttributes<HTMLAnchorElement>;
};
