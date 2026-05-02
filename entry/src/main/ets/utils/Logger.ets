import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xA001;
const TAG: string = 'PhotoThumb';

export class Logger {
  static info(message: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', message);
  }

  static warn(message: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', message);
  }

  static error(message: string, err?: Object): void {
    if (err === undefined) {
      hilog.error(DOMAIN, TAG, '%{public}s', message);
      return;
    }
    hilog.error(DOMAIN, TAG, '%{public}s %{public}s', message, JSON.stringify(err));
  }
}
