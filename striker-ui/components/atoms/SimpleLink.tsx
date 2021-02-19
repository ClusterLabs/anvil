import { FunctionComponent } from 'react';
import Link from 'next/link';

import { SimpleLinkProps } from '../../types/SimpleLinkProps';

const SimpleLink: FunctionComponent<SimpleLinkProps> = ({
  linkProps,
  anchorProps = {},
  children,
}) => {
  return (
    // eslint-disable-next-line react/jsx-props-no-spreading
    <Link {...{ passRef: true, ...linkProps }}>
      {/* eslint-disable-next-line react/jsx-props-no-spreading */}
      <a {...anchorProps}>{children}</a>
    </Link>
  );
};

export default SimpleLink;
