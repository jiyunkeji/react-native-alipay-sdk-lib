import type { PayResult } from './Types';

export type OnPaySuccessResponse = (info: PayResult) => void;
export type OnPayFailResponse = (info: PayResult) => void;

export interface AlipaySdkEvents {
  onPaySuccessResponse: OnPaySuccessResponse;
  onPayFailResponse: OnPayFailResponse;
}
