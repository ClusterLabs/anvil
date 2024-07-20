export class ResponseError extends Error {
  public readonly code: string;

  constructor(code: string, message: string) {
    super(message);

    Object.setPrototypeOf(this, ResponseError.prototype);

    this.code = code;
  }

  public get body(): ResponseErrorBody {
    return {
      code: this.code,
      message: this.message,
      name: this.name,
    };
  }

  public toString(): string {
    return `${this.name}(${this.code}): ${this.message}`;
  }
}
