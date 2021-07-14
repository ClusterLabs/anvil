const ControlL = '0xffe3';
const AltL = '0xffe9';

const F1 = '0xffbe';
const F2 = '0xffbf';
const F3 = '0xffc0';
const F4 = '0xffc1';
const F5 = '0xffc2';
const F6 = '0xffc3';
const F7 = '0xffc4';
const F8 = '0xffc5';
const F9 = '0xffc6';

const keyCombinations: Array<{ keys: string; scans: string[] }> = [
  { keys: 'Ctrl + Alt + Delete', scans: [] },
  { keys: 'Ctrl + Alt + F1', scans: [ControlL, AltL, F1] },
  { keys: 'Ctrl + Alt + F2', scans: [ControlL, AltL, F2] },
  { keys: 'Ctrl + Alt + F3', scans: [ControlL, AltL, F3] },
  { keys: 'Ctrl + Alt + F4', scans: [ControlL, AltL, F4] },
  { keys: 'Ctrl + Alt + F5', scans: [ControlL, AltL, F5] },
  { keys: 'Ctrl + Alt + F6', scans: [ControlL, AltL, F6] },
  { keys: 'Ctrl + Alt + F7', scans: [ControlL, AltL, F7] },
  { keys: 'Ctrl + Alt + F8', scans: [ControlL, AltL, F8] },
  { keys: 'Ctrl + Alt + F9', scans: [ControlL, AltL, F9] },
];

export default keyCombinations;
