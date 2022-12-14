declare interface TypedEventEmitter<
  MapToEventListenerParameters extends Record<string | symbol, unknown[]>,
  EventName = keyof MapToEventListenerParameters,
> extends import('events').EventEmitter {
  emit(
    event: EventName,
    ...args: MapToEventListenerParameters[EventName]
  ): boolean;

  listenerCount(event: EventName): number;

  on(
    event: EventName,
    listener: (...args: MapToEventListenerParameters[EventName]) => void,
  ): this;

  once(
    event: EventName,
    listener: (...args: MapToEventListenerParameters[EventName]) => void,
  ): this;
}
