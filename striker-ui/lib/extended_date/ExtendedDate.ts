class ExtendedDate extends Date {
  toLocaleISOString(): string {
    const localeDateParts: string[] = this.toLocaleDateString('en-US', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).split('/', 3);
    const localDate = `${localeDateParts[2]}-${localeDateParts[0]}-${localeDateParts[1]}`;
    const localeTime: string = this.toLocaleTimeString('en-US', {
      hour12: false,
    });
    const timezoneOffset: number = (this.getTimezoneOffset() / 60) * -1;

    return `${localDate}T${localeTime}${timezoneOffset}`;
  }
}

export default ExtendedDate;
