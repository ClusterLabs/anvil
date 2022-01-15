export const UPLOAD_FILE_TYPES_ARRAY: ReadonlyArray<
  [UploadFileType, [string, string]]
> = [
  ['iso', ['application/x-cd-image', 'ISO (optical disc)']],
  ['other', ['text/plain', 'Other file type']],
  ['script', ['text/plain', 'Script (program)']],
];
export const UPLOAD_FILE_TYPES: ReadonlyMap<
  UploadFileType,
  [string, string]
> = new Map(UPLOAD_FILE_TYPES_ARRAY);
