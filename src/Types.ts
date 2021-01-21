export interface PayResult {
  code?: number;
  memo?: string;
  result?: string;
}

export type Listener = (...args: any[]) => any;
