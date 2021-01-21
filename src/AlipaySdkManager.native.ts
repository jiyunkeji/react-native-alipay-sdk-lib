import { NativeEventEmitter, NativeModules } from 'react-native';
import type { AlipaySdkEvents } from './AlipaySdkEvent';
import type { Listener } from './Types';

const { AlipaySdkLibModule } = NativeModules;
// const Prefix = AlipaySdkLibModule.WeChatSdk;

const AlipaySdkLibModuleEvent = new NativeEventEmitter(AlipaySdkLibModule);

let alipaySdkManager: AlipaySdkManager | undefined;

export default class AlipaySdkManager {
  private _listeners = new Map<string, Listener>();

  static instance(): AlipaySdkManager {
    if (alipaySdkManager == null) {
      alipaySdkManager = new AlipaySdkManager();
    }
    return alipaySdkManager;
  }

  pay(orderInfo: string): Promise<void> {
    return AlipaySdkLibModule.pay(orderInfo);
  }

  destroy() {
    this.removeAllListener();
    alipaySdkManager = undefined;
  }
  addListener<EventType extends keyof AlipaySdkEvents>(
    event: EventType,
    listener: AlipaySdkEvents[EventType]
  ) {
    if (!this._listeners.has(event)) {
      this._listeners.set(event, listener);
      AlipaySdkLibModuleEvent.addListener(event, listener);
    }
  }
  removeListener<EventType extends keyof AlipaySdkEvents>(
    event: EventType,
    listener: AlipaySdkEvents[EventType]
  ) {
    if (this._listeners.has(event)) {
      this._listeners.delete(event);
      AlipaySdkLibModuleEvent.removeListener(event, listener);
    }
  }
  removeAllListener() {
    this._listeners.forEach((value, key) => {
      this._listeners.delete(key);
      AlipaySdkLibModuleEvent.removeListener(key, value);
    });
    this._listeners.clear();
  }
}