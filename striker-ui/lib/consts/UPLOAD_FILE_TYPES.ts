export const UPLOAD_FILE_TYPES_ARRAY: ReadonlyArray<
  [FileType, [string, string]]
> = [
  ['iso', ['application/x-cd-image', 'ISO (optical disc)']],
  ['other', ['text/plain', 'Other file type']],
  ['script', ['text/plain', 'Script (program)']],
];
export const UPLOAD_FILE_TYPES: ReadonlyMap<FileType, [string, string]> =
  new Map(UPLOAD_FILE_TYPES_ARRAY);
