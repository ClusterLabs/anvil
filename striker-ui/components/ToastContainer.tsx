import styled from '@mui/material/styles/styled';
import { ToastContainer as BaseToastContainer } from 'react-toastify';

import {
  BLACK,
  BLUE,
  GREY,
  PURPLE,
  RED,
  TEXT,
} from '../lib/consts/DEFAULT_THEME';

// TODO: find out why dark theme doesn't work
// it's likely being controlled by MUI theme

const ToastContainer = styled(BaseToastContainer)({
  '--toastify-color-light': BLACK,
  '--toastify-color-error': RED,
  '--toastify-color-info': GREY,
  '--toastify-color-success': BLUE,
  '--toastify-color-warning': PURPLE,

  '--toastify-icon-color-error': 'var(--toastify-color-error)',
  '--toastify-icon-color-info': 'var(--toastify-color-info)',
  '--toastify-icon-color-success': 'var(--toastify-color-success)',
  '--toastify-icon-color-warning': 'var(--toastify-color-warning)',

  '--toastify-font-family': 'Roboto Condensed',
  '--toastify-text-color-light': TEXT,

  '--toastify-text-color-error': TEXT,
  '--toastify-text-color-info': TEXT,
  '--toastify-text-color-success': TEXT,
  '--toastify-text-color-warning': TEXT,

  '--toastify-color-progress-error': 'var(--toastify-color-error)',
  '--toastify-color-progress-info': 'var(--toastify-color-info)',
  '--toastify-color-progress-success': 'var(--toastify-color-success)',
  '--toastify-color-progress-warning': 'var(--toastify-color-warning)',

  '.Toastify__close-button--light': {
    color: `${GREY}9F`,
    opacity: 1,

    ':hover': {
      color: GREY,
    },
  },
});

export default ToastContainer as typeof BaseToastContainer;
