import { ImageProps } from 'next/image';

type ButtonImageProps = Omit<ImageProps, 'width' | 'height'> &
  Partial<Pick<ImageProps, 'width' | 'height'>>;
